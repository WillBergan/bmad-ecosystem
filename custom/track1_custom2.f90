!+
! Subroutine track1_custom2 (start_orb, ele, param, end_orb, track, err_flag)
!
! Dummy routine for custom tracking. 
! If called, this routine will generate an error message and quit.
! This routine needs to be replaced for a custom calculation.
!
! Note: This routine is not to be confused with track1_custom.
! See the Bmad manual for more details.
!
! General rule: Your code may NOT modify any argument that is not listed as
! an output agument below."
!
! Modules Needed:
!   use bmad
!
! Input:
!   start_orb  -- Coord_struct: Starting position.
!   ele        -- Ele_struct: Element.
!   param      -- lat_param_struct: Lattice parameters.
!
! Output:
!   end_orb   -- Coord_struct: End position.
!   track     -- track_struct, optional: Structure holding the track information if the 
!                  tracking method does tracking step-by-step.
!   err_flag  -- Logical, optional: Set true if there is an error. False otherwise.
!-

subroutine track1_custom2 (start_orb, ele, param, end_orb, track, err_flag)

use bmad_interface, except_dummy => track1_custom2

implicit none

type (coord_struct) :: start_orb
type (coord_struct) :: end_orb
type (ele_struct) :: ele
type (lat_param_struct) :: param
type (track_struct), optional :: track

logical err_flag

character(32) :: r_name = 'track1_custom2'

!

call out_io (s_fatal$, r_name, 'THIS DUMMY ROUTINE SHOULD NOT HAVE BEEN CALLED IN THE FIRST PLACE.')
err_flag = .true.

! Remember to also set end_orb%t

end_orb = start_orb
end_orb%s = ele%s 

end subroutine
