!+
! Function I_bessel(m, arg) result (i_bes)
!
! Function to evaluate the modified bessel function of the 
! first kind I.
!
! Modules needed:
!   use sim_utils
!
! Input:
!   m    -- Integer: Bessel order.
!   arg  -- Real(rp): Bessel argument.
!
! Output:
!   i_bes -- Real: Bessel value.
!-

function I_bessel(m, arg) result (i_bes)

use physical_constants
use fgsl

implicit none

integer m
real(rp) arg, i_bes
real(rp), parameter :: arg_min(0:50) = &
            [0.0_rp, 0.0_rp, 10.0_rp**(-153), 10.0_rp**(-101), 10.0_rp**(-76), 10.0_rp**(-60), &  !  0 -  5
               10.0_rp**(-50), 10.0_rp**(-43), 10.0_rp**(-37), 10.0_rp**(-33), 10.0_rp**(-29), &      !  6 - 10
               10.0_rp**(-26), 10.0_rp**(-24), 10.0_rp**(-22), 10.0_rp**(-20), 10.0_rp**(-19), &      ! 11 - 15
               10.0_rp**(-18), 10.0_rp**(-16), 10.0_rp**(-15), 10.0_rp**(-14), 10.0_rp**(-14), &      ! 16 - 20
               10.0_rp**(-13), 10.0_rp**(-12), 10.0_rp**(-12), 10.0_rp**(-11), 10.0_rp**(-10), &      ! 21 - 25
               10.0_rp**(-10), 10.0_rp**(-10), 10.0_rp**(-09), 10.0_rp**(-09), 10.0_rp**(-08), &      ! 26 - 30
               10.0_rp**(-08), 10.0_rp**(-08), 10.0_rp**(-07), 10.0_rp**(-07), 10.0_rp**(-07), &      ! 31 - 35
               10.0_rp**(-07), 10.0_rp**(-06), 10.0_rp**(-06), 10.0_rp**(-06), 10.0_rp**(-06), &      ! 36 - 40
               10.0_rp**(-05), 10.0_rp**(-05), 10.0_rp**(-05), 10.0_rp**(-05), 10.0_rp**(-05), &      ! 41 - 45
               10.0_rp**(-05), 10.0_rp**(-04), 10.0_rp**(-04), 10.0_rp**(-04), 10.0_rp**(-04)]        ! 46 - 50

! Note: The GSL bessel function does not properly trap overflow or underflow!

if (arg > 700) then
  i_bes = 1d300  ! Something large.
  return
elseif (m <= ubound(arg_min, 1)) then
  if (arg < arg_min(m)) then
    i_bes = 0
    return
  endif
endif

select case(m)
case (0);     i_bes = fgsl_sf_bessel_ic0(arg)
case (1);     i_bes = fgsl_sf_bessel_ic1(arg)
case default; i_bes = fgsl_sf_bessel_icn(m, arg)
end select

end function I_bessel

