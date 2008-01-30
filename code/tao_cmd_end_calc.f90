!+
! Subroutine tao_cmd_end_calc ()
! 
! After every command this will do the standard lattice calculations and
! regenerate the plotting window
!
! Input:
!
! Output:
! s        -- tao_super_universe_struct: lattice calculations and plotting
!                                        update
!
!-

subroutine tao_cmd_end_calc

use tao_mod
use tao_plot_mod
use tao_scale_mod
use tao_x_scale_mod

implicit none

real(rp) this_merit !not really used here

logical err

! Note: tao_merit calls tao_lattice_calc.

this_merit =  tao_merit()         

! update variable values to reflect lattice values

call tao_plot_data_setup()       ! transfer data to the plotting structures
call tao_hook_plot_data_setup()
if (s%global%auto_scale) then
  call tao_scale_cmd (' ', '', 0.0_rp, 0.0_rp) 
  call tao_x_scale_cmd (' ', 0.0_rp, 0.0_rp, err)
endif
call tao_plot_out()              ! Update the plotting window


end subroutine tao_cmd_end_calc


