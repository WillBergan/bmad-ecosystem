!+
! Subroutine tao_set_flags_for_changed_attribute (u, ele_name, ele_ptr, val_ptr)
!
! Routine to set flags in the model lattice indicating that a parameter value has changed.
! Call this routine *after* setting the variable.
!
! Input:
!   u        -- tao_universe_sturct: Universe containing the lattice.
!   ele_name -- character(*): Associated "element" of the changed parameter.
!   ele_ptr  -- ele_struct, pointer, optional: Pointer to the element. 
!                 May be null, for example, if ele_name = "PARTICLE_START".
!   val_ptr  -- real(rp):, pointer, optional: Pointer to the attribute that was changed.
!-

subroutine tao_set_flags_for_changed_attribute (u, ele_name, ele_ptr, val_ptr)

use tao_interface, dummy => tao_set_flags_for_changed_attribute
use bookkeeper_mod, only: set_flags_for_changed_attribute

implicit none

type (tao_universe_struct) u
type (ele_struct), pointer, optional :: ele_ptr

real(rp), pointer, optional :: val_ptr

character(*) ele_name

! If the beginning element is modified, need to reinit any beam distribution.

u%calc%lattice = .true.

if (ele_name == 'PARTICLE_START') return

if (present(ele_ptr)) then
  if (associated(ele_ptr)) then
    if (ele_ptr%ix_ele == 0) u%beam%init_starting_distribution = .true.
    if (present(val_ptr)) call set_flags_for_changed_attribute (ele_ptr, val_ptr)
  endif
endif

end subroutine tao_set_flags_for_changed_attribute
