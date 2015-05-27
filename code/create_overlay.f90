!+
! Subroutine create_overlay (lord, contl, err, err_print_flag)
!
! Subroutine to add the controller information to slave elements of an overlay_lord.
!
! Note: If the stack (in contl(i)%stack(:)) array has a single numeric term,
! the arithmatic expression is modified so that the controlled attribute is linear
! in lord%control_var(1) with a coefficient given by the single numeric term.
!
! Note: See the Bmad manual for directions as to how to use this routine.
!
! Modules needed:
!   use bmad
!
! Input:
!   lord           -- ele_struct: Overlay element.
!   contl(:)       -- Control_struct: control info. 1 element for each slave.
!     %stack         -- Arithmetic expression stack for evaluating the controlled parameter value.
!     slave%ix_ele      -- Index of element to control
!     %ix_branch     -- Index of branch element belongs to.
!     %ix_attrib     -- Index of attribute controlled
!   err            -- Logical: Set True if an attribute is not free to be controlled.
!   err_print_flag -- Logical, optional: If present and False then suppress
!                       printing of an error message if attribute is not free.  
!
! Output:
!   lord          -- ele_struct: Modified overlay elment
!-

subroutine create_overlay (lord, contl, err, err_print_flag)

use bmad_interface, except_dummy => create_overlay
use expression_mod
use bookkeeper_mod, only: control_bookkeeper

implicit none

type (ele_struct), target :: lord
type (lat_struct), pointer :: lat
type (ele_struct), pointer :: slave
type (control_struct)  contl(:)
type (control_struct), pointer :: c

integer i, j, nc0, nc2, ix_con, is, n
integer ix_slave, n_slave, ix_attrib, ix_branch

character(40) at_name
character(16), parameter :: r_name = 'create_overlay'
logical err, free, var_found
logical, optional :: err_print_flag

! Error check

lat => lord%branch%lat
n_slave = size (contl)
err = .true.

do j = 1, n_slave
  ix_slave  = contl(j)%slave%ix_ele
  ix_branch = contl(j)%slave%ix_branch

  if (ix_branch < 0 .or. ix_branch > ubound(lat%branch, 1)) then
    call out_io (s_fatal$, r_name,  'BRANCH INDEX OUT OF BOUNDS. \i0\ ', ix_branch)
    if (global_com%exit_on_error) call err_exit
    return
  endif

  if (ix_slave <= 0 .or. ix_slave > ubound(lat%branch(ix_branch)%ele, 1)) then
    call out_io (s_fatal$, r_name,  'INDEX OUT OF BOUNDS. \i0\ ', ix_slave)
    if (global_com%exit_on_error) call err_exit
    return
  endif
enddo

! Mark element as an overlay lord

call check_controller_controls (contl, lord%name, err)
if (err) return

lord%lord_status = overlay_lord$
lord%key = overlay$
call set_ele_defaults(lord)

if (n_slave == 0) return ! If no slaves then nothing to do.

! Loop over all slaves.

nc0 = lat%n_control_max
nc2 = nc0

do j = 1, n_slave
  ix_attrib = contl(j)%ix_attrib
  ix_slave = contl(j)%slave%ix_ele
  slave => lat%branch(contl(j)%slave%ix_branch)%ele(ix_slave)

  if (nc2+4 > size(lat%control)) call reallocate_control (lat, nc2+100)

  ! If the slave attribute is a multipole component, make sure it exists.
  if (is_attribute(ix_attrib, multipole$) .and. .not. associated (slave%a_pole)) then
    call multipole_init(slave)
  endif
  free = attribute_free (slave, attribute_name(slave, ix_attrib), err_print_flag, .true.)
  err = err .or. .not. free
  c => lat%control(nc2+1)
  call reallocate_expression_stack(c%stack, size(contl(j)%stack))
  c = contl(j)
  c%ix_lord = lord%ix_ele
  nc2 = nc2 + 1

  ! Convert a stack of a single constant "const" to "const * control_var(1)"
  var_found = .false.
  do is = 1, size(c%stack)
    if (c%stack(is)%type < old_var_offset$) cycle
    if (c%stack(is)%type == end_stack$) exit
    var_found = .true.
    exit
  enddo

  if (.not. var_found) then
    if (size(c%stack) == 1 .and. c%stack(1)%name == '1' .or. c%stack(1)%name == '1.0') then
      c%stack(1) = expression_atom_struct(lord%control_var(1)%name, 1+var_offset$, 0.0_rp)
    else
      n = size(c%stack)
      call reallocate_expression_stack(c%stack, n+2)
      c%stack(n+1) = expression_atom_struct(lord%control_var(1)%name, 1+var_offset$, 0.0_rp)
      c%stack(n+2) = expression_atom_struct('', times$, 0.0_rp)
    endif
  endif

enddo

lord%n_slave = n_slave
lord%ix1_slave = nc0 + 1
lord%ix2_slave = nc0 + n_slave
lat%n_control_max = nc2

! Loop over all slaves
! Free elements convert to overlay slaves.

do i = 1, lord%n_slave

  slave => pointer_to_slave(lord, i, ix_con)

  if (slave%slave_status == free$) slave%slave_status = control_slave$

  ! You cannot overlay super_slaves 

  if (slave%slave_status == super_slave$) then
    call out_io (s_fatal$, r_name,  'ILLEGAL OVERLAY ON ' // slave%name, &
                                    ' BY: ' // lord%name)
    if (global_com%exit_on_error) call err_exit
  endif

  ! update controller info for the slave ele

  slave%n_lord = slave%n_lord + 1
  call add_lattice_control_structs (lat, slave)
  lat%ic(slave%ic2_lord) = ix_con

enddo

! Finish: Do control bookkeeping.

call control_bookkeeper (lat, lord)

end subroutine


