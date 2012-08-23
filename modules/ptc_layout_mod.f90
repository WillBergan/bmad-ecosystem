!+
! Module ptc_layout_mod
!
! Module of PTC layout interface routines.
! Also see: ptc_interface_mod
!-

module ptc_layout_mod

use ptc_interface_mod

contains

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Subroutine type_ptc_layout (lay)
!
! Subroutine to print the global information in a layout
!
! Module Needed:
!   use ptc_layout_mod
!
! Input:
!   lay - layout: layout to use.
!+

subroutine type_ptc_layout (lay)

use s_def_all_kinds, only: layout

implicit none

type (layout) lay

!

if (.not. associated(lay%start)) then
  print *, 'Warning from TYPE_LAYOUT: Layout NOT Associated'
  return
endif

print *, 'Name:         ', lay%name
print *, 'N:            ', lay%N,        '  ! Number of Elements'
print *, 'LatPos:       ', lay%lastpos,  '  ! Last position'

end subroutine type_ptc_layout

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Subroutine lat_to_ptc_layout (lat)
!
! Subroutine to create a PTC layout from a Bmad lat.
! Note: If ptc_layout has been already used then you should first do a 
!           call kill(ptc_layout)
! This deallocates the pointers in the layout
!
! Note: Before you call this routine you need to first call:
!    call set_ptc (...)
!
! Module Needed:
!   use ptc_layout_mod
!
! Input:
!   lat -- lat_struct: Input lattice
!
! Output:
!   lat%branch(:)%ptc          -- Pointers to generated layouts.
!   lat%branch(:)%ele(:)%fiber -- Pointer to fibers
!-

subroutine lat_to_ptc_layout (lat)

use s_fibre_bundle, only: ring_l, append, lp, layout, fibre
use mad_like, only: set_up, kill
use madx_ptc_module, only: m_u, append_empty_layout, survey, make_node_layout

implicit none

type (lat_struct), target :: lat
type (branch_struct), pointer :: branch
type (fibre), pointer :: fib
type (ele_struct) drift_ele
type (ele_struct), pointer :: ele

integer ib, ie
logical doneit

! transfer elements.

do ib = 0, ubound(lat%branch, 1)
  branch => lat%branch(ib)

  call append_empty_layout(m_u)
  call set_up(m_u%end)

  allocate(branch%ptc%layout(1))
  branch%ptc%layout(1)%ptr => m_u%end   ! Save layout

  do ie = 0, branch%n_ele_track
    ele => branch%ele(ie)
    if (tracking_uses_hard_edge_model(ele)) then
      call create_hard_edge_drift (ele, drift_ele)
      call ele_to_fibre (drift_ele, fib, branch%param%particle, .true., for_layout = .true.)
    endif

    call ele_to_fibre (ele, ele%ptc_fiber, branch%param%particle, .true., for_layout = .true.)

    if (tracking_uses_hard_edge_model(ele)) then
      call ele_to_fibre (drift_ele, fib, branch%param%particle, .true., for_layout = .true.)
    endif
  enddo

  ! End stuff

  if (branch%param%lattice_type == circular_lattice$) then
    m_u%end%closed = .true.
  else
    m_u%end%closed = .false.
  endif

  doneit = .true.
  call ring_l (m_u%end, doneit)
  call survey (m_u%end)
  call make_node_layout (m_u%end)

enddo

end subroutine lat_to_ptc_layout

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Subroutine kill_ptc_layouts (lat)
!
! Routine to kill the layouts associated with a Bmad lattice.
!
! Module Needed:
!   use ptc_layout_mod
!
! Input: 
!   lat  -- lat_struct: Bmad lattice with associated layouts.
!-

subroutine kill_ptc_layouts (lat)

use madx_ptc_module

implicit none

type (lat_struct), target :: lat
type (branch_struct), pointer :: branch

integer ib

!

do ib = 0, ubound(lat%branch, 1)
  branch => lat%branch(ib)
  call kill_layout_in_universe(branch%ptc%layout(1)%ptr)
  nullify(branch%ptc%layout(1)%ptr)
enddo

end subroutine kill_ptc_layouts

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Subroutine ptc_emit_calc (ele, norm_mode, sigma_mat, closed_orb)
!
! Routine to calculate emittances, etc.
!
! Module Needed:
!   use ptc_layout_mod
!
! Input: 
!   ele -- ele_struct: Element at which to evaluate the parameters.
!
! Output:
!   norm_mode       -- Normal_modes_struct
!     %e_loss
!     %a%tune, %b%tune, %z%tune
!     %a%alpha_damp, etc.
!     %a%emittance, etc.
!   sigma_map(6,6)  -- real(rp): Sigma matrix.
!   closed_orb      -- coord_struct: Closed orbit at ele.
!-

subroutine ptc_emit_calc (ele, norm_mode, sigma_mat, closed_orb)

use madx_ptc_module

implicit none

type (ele_struct) ele
type (layout), pointer :: ptc_layout
type (internal_state) state
type (normal_modes_struct) norm_mode
type (normal_spin) normal
type (damapspin) da_map
type (probe) x_probe
type (probe_8) x_probe8  
type (coord_struct) closed_orb

real(rp) sigma_mat(6,6)
real(dp) x(6), energy, deltap

!

check_krein = .false.

ptc_layout => ele%branch%ptc%layout(1)%ptr

state = (default - nocavity0) + radiation0  ! Set state flags

x = 0
call find_orbit_x (x, state, 1.0d-5, fibre1 = ele%ptc_fiber%next)  ! find_orbit == find closed orbit
closed_orb%vec = x

call get_loss (ptc_layout, energy, deltap)
norm_mode%e_loss = 1d9 * energy
norm_mode%z%alpha_damp = deltap

call init (state, 1, 0)  ! First order DA
call alloc(normal)
call alloc(da_map)
call alloc(x_probe8)

normal%stochastic = .false. ! Normalization of the stochastic kick not needed.

x_probe = x
da_map = 1
x_probe8 = x_probe + da_map

! Remember: ptc calculates things referenced to the beginning of a fibre while
! Bmad references things at the exit end.

state = state+envelope0
call track_probe (x_probe8, state, fibre1 = ele%ptc_fiber%next)
da_map = x_probe8
normal = da_map

norm_mode%a%tune = normal%tune(1)   ! Fractional tune with damping
norm_mode%b%tune = normal%tune(2)
norm_mode%z%tune = normal%tune(3)

norm_mode%a%alpha_damp = normal%damping(1)
norm_mode%b%alpha_damp = normal%damping(2)
norm_mode%z%alpha_damp = normal%damping(3)

norm_mode%a%emittance = normal%emittance(1)
norm_mode%b%emittance = normal%emittance(2)
norm_mode%z%emittance = normal%emittance(3)

sigma_mat = normal%s_ij0

call kill(normal)
call kill(da_map)
call kill(x_probe8)

end subroutine ptc_emit_calc 

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Subroutine one_turn_ptc_map (ele, map, order, rf_on)
!
! Routine to calculate the one turn map for a ring
!
! Module Needed:
!   use ptc_layout_mod
!
! Input:
!   ele     -- ele_struct: Element determining start/end position for one turn map.
!   order   -- integer, optional: Order of the map. If not given then default order is used.
!   rf_on   -- logical, optional: Turn RF on or off? Default is to leave things as they are.
!
! Output:
!   map(6)  -- taylor_struct: Bmad taylor map
!-

subroutine one_turn_map (ele, map, order, rf_on)

implicit none

type (ele_struct), target :: ele
type (taylor_struct) map(6)


integer, optional :: order
logical, optional :: rf_on

!




end Subroutine one_turn_map

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Subroutine type2_ptc_fiber (fiber, lines, n_lines)
!
! Routine to put information on a PTC fiber element into a string array.
!
! Module Needed:
!   use ptc_layout_mod
!
! Input:
!   fiber     -- fibre: 
!
! Output:
!   lines(:)  -- character(100), allocatable: Character array to hold the output.
!   n_lines   -- integer: Number of lines used in lines(:)
!-

subroutine type2_ptc_fiber (fiber, lines, n_lines)

use s_status

implicit none

type (fibre), target :: fiber
type (patch), pointer :: ptch
type (element), pointer :: mag

integer n_lines, nl

character(*), allocatable :: lines(:)
character(100) str

character(16) :: patch_at(0:3) = [character(16) :: &
              'Nothing (0)', 'Front only (1)', 'Back only (2)', 'Both (3)']

!

nl = 0
call re_allocate(lines, 100, .false.)

select case (fiber%mag%kind)
case (KIND0);   str = 'KIND0 [Marker, Patch]'
case (KIND1);   str = 'KIND1 [Drift]'
case (KIND2);   str = 'KIND2 [Drift-Kick-Drift EXACT_MODEL = F]'
case (KIND3);   str = 'KIND3 [Thin Element, L == 0]'
case (KIND4);   str = 'KIND4 [RFcavity]'
case (KIND5);   str = 'KIND5 [Solenoid]'
case (KIND6);   str = 'KIND6 [Kick-SixTrack-Kick]'
case (KIND7);   str = 'KIND7 [Matrix-Kick-Matrix]'
case (KIND8);   str = 'KIND8 [Normal SMI]'
case (KIND9);   str = 'KIND9 [Skew SMI]'
case (KIND10);  str = 'KIND10 [Sector Bend, Exact_Model]'
case (KIND11);  str = 'KIND11 [Monitor]'
case (KIND12);  str = 'KIND12 [HMonitor]'
case (KIND13);  str = 'KIND13 [VMonitor]'
case (KIND14);  str = 'KIND14 [Instrument]'
case (KIND15);  str = 'KIND15 [ElSeparator]'
case (KIND16);  str = 'KIND16 [True RBend, EXACT_MODEL = T]'
case (KIND17);  str = 'KIND17 [SixTrack Solenoid]'
case (KIND18);  str = 'KIND18 [Rcollimator]'
case (KIND19);  str = 'KIND19 [Ecollimator]'
case (KIND20);  str = 'KIND20 [Straight Geometry MAD RBend]'
case (KIND21);  str = 'KIND21 [Traveling Wave Cavity]'
case (KIND22);  str = 'KIND22'
case (KIND23);  str = 'KIND23'
case (KINDWIGGLER);  str = 'KINDWIGGLER [Wiggler]'
case (KINDPA);  str = 'KINDPA'
case default;   write (str, '(a, i0, a)') 'UNKNOWN! [', fiber%mag%kind, ']'
end select

!

nl=nl+1; lines(nl) = 'Fiber:'
nl=nl+1; write (lines(nl), '(2x, a, i0)')     'Index in layout:   ', fiber%pos
nl=nl+1; write (lines(nl), '(2x, a, i0)')     'Index in universe: ', fiber%loc
nl=nl+1; write (lines(nl), '(2x, a, a)')     'Direction:         ', int_of (fiber%dir, 'i0')
nl=nl+1; write (lines(nl), '(2x, a, es16.4)') 'Beta velocity:     ', fiber%beta0
nl=nl+1; write (lines(nl), '(2x, a, es16.4)') 'Mass:              ', fiber%mass * 1e9
nl=nl+1; write (lines(nl), '(2x, a, es16.4)') 'Charge:            ', fiber%charge

!

ptch => fiber%patch
nl=nl+1; lines(nl) = 'Patch (fiber%patch):'
nl=nl+1; write (lines(nl), '(2x, a, a)') 'Patch at: ', patch_at(ptch%patch)

!

mag => fiber%mag
nl=nl+1; lines(nl) = 'Element (fiber%mag):'
nl=nl+1; lines(nl) = '  Kind:     ' // str
nl=nl+1; write (lines(nl), '(2x, a, a)') 'Name:   ', name_of(mag%name)
nl=nl+1; write (lines(nl), '(2x, a, a)') 'L       ', real_of(mag%l, 'es16.4')
nl=nl+1; write (lines(nl), '(2x, a, a)')
nl=nl+1; write (lines(nl), '(2x, a, a)')

!-----------------------------------------------------------------------------
contains

function name_of (name_in) result (name_out)

character(*), pointer :: name_in
character(len(name_in)) :: name_out

if (associated(name_in)) then
  name_out = name_in
else
  name_out = 'Not Associated'
endif

end function name_of

!-----------------------------------------------------------------------------
! contains

function real_of (real_in, fmt) result (str)

real(dp), pointer :: real_in
character(*) fmt
character(20) str

if (associated(real_in)) then
  write (str, fmt) real_in
else
  str = 'Not Associated'
endif

end function real_of

!-----------------------------------------------------------------------------
! contains

function int_of (int_in, fmt) result (str)

integer, pointer :: int_in
character(*) fmt
character(20) str

if (associated(int_in)) then
  write (str, fmt) int_in
else
  str = 'Not Associated'
endif

end function int_of

end subroutine type2_ptc_fiber

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Subroutine write_ptc_flat_file_lattice (file_name, branch)
!
! Routine to create a PTC flat file lattice from a Bmad branch.
!
! Module Needed:
!   use ptc_layout_mod
!
! Input:
!   file_name     -- character(*): Flat file name.
!   branch        -- branch_struct: Branch containing a layout.
!-

subroutine write_ptc_flat_file_lattice (file_name, branch)

use pointer_lattice

implicit none

type (branch_struct) branch
character(*) file_name

!

call print_complex_single_structure (branch%ptc%layout(1)%ptr, file_name)

end subroutine write_ptc_flat_file_lattice

!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!-----------------------------------------------------------------------------
!+
! Subroutine modify_ptc_fiber (ele)
!
! Routine to modify an existing fiber. 
!
! Module Needed:
!   use ptc_layout_mod
!
! Input:
!   ele           -- ele_struct: Element with corresponding fiber.
!
! Output:
!   ele%ptc_fiber 
!-

subroutine modify_ptc_fiber_attribute (ele, attribute, value)

implicit none

type (ele_struct), target :: ele

real(rp) value

character(*) attribute
character(32), parameter :: r_name = 'modify_ptc_fiber_attribute'

!

select case (ele%key)

case default
  call out_io (s_fatal$, r_name, 'UNKNOWN ELEMENT TYPE: ' // ele%name)
  if (bmad_status%exit_on_error) call err_exit
end select

!

end subroutine modify_ptc_fiber_attribute 

end module
