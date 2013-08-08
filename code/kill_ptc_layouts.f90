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

use ptc_layout_mod, except_dummy => kill_ptc_layouts
use madx_ptc_module

implicit none

type (lat_struct), target :: lat
type (branch_struct), pointer :: branch

integer ib, il

!

if (.not. allocated(lat%branch)) return

do ib = 0, ubound(lat%branch, 1)
  branch => lat%branch(ib)
  if (.not. allocated(branch%ptc%layout)) cycle
  do il = 1, size(branch%ptc%layout)
    call kill_layout_in_universe(branch%ptc%layout(il)%ptr)
  enddo
  deallocate(branch%ptc%layout)
enddo

end subroutine kill_ptc_layouts

