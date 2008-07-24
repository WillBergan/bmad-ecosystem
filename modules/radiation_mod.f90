#include "CESR_platform.inc"

module radiation_mod

  use bmad_struct
  use bmad_interface
  use runge_kutta_mod
  use rad_int_common

contains

!---------------------------------------------------------------------
!---------------------------------------------------------------------
!---------------------------------------------------------------------
!+
! Subroutine release_rad_int_cache (ix_cache)
!
! Subroutine to release the memory associated with caching wiggler values.
! See the radiation_integrals routine for further details.
!
! Modules needed:
!   use radiation_mod
!
! Input:
!   ix_cache -- Integer: Cache number.
!
! Output:
!   ix_cache -- Integer: Cache number set to 0,
!-

subroutine release_rad_int_cache (ix_cache)

  implicit none

  integer i, ix_cache

!

!  do i = 1, size(rad_int_cache_common(ix_cache)%ele)
!    if (allocated(rad_int_cache_common(ix_cache)%ele(i)%pt)) &
!                                deallocate (rad_int_cache_common(ix_cache)%ele(i)%pt)
!  enddo

!  deallocate (rad_int_cache_common(ix_cache)%ele)
!  deallocate (rad_int_cache_common(ix_cache)%ix_ele)

  rad_int_cache_common(ix_cache)%set = .false.
  ix_cache = 0

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! Subroutine track1_radiation (start, ele, param, end, edge)
!
! Subroutine to put in radiation dampling and/or fluctuations.
! This routine calculates half the radiation of an element so this routine
! needs to be called before entering an element and just after exiting.
!
! Use the setup_radiation_tracking routine initially prior to tracking.
!
! Modules needed:
!   use radiation_mod
!
! Input:
!   start -- Coord_struct: Starting particle position.
!   ele   -- Ele_struct: Element that causes radiation.
!   edge  -- Integer: Where the particle is: start_edge$ or end_edge$.
!
! Output:
!   end   -- Ele_struct: Particle position after radiation has been applied.
!-

subroutine track1_radiation (start, ele, param, end, edge)

  use random_mod

  implicit none

  type (coord_struct) :: start
  type (ele_struct) :: ele
  type (lat_param_struct) :: param
  type (coord_struct) :: end
  type (coord_struct) start2

  integer :: edge

  real(rp), save :: z_start
  real(rp) s_len, g, g2, g3, g_x, g_y, this_ran
  real(rp) x_ave, y_ave, gamma_0, dE_p, fact_d, fact_f

  integer direc

  logical set
  logical :: init_needed = .true.

  character(20) :: r_name = 'track1_radiation'

! If not a magnetic element then nothing to do.
! Also symplectic tracking handles the radiation.

  if (ele%tracking_method == symp_lie_bmad$ .or. .not. any (ele%key == &
        (/ quadrupole$, sextupole$, octupole$, sbend$, sol_quad$, wiggler$ /))) then
    end = start
    return
  endif

! The total radiation length is the element length + any change in path length.
! If entering the element then the length over which radiation is generated
! is taken to be 1/2 the element length.
! If leaving the element the radiation length is taken to be 1/2 the element
! length + delta_Z

  if (edge == start_edge$) then
    set = set$
    s_len = ele%value(l$) / 2
    direc = +1
    z_start = start%vec(5)
  elseif (edge == end_edge$) then
    set = unset$
    s_len = ele%value(l$)/2 + (start%vec(5) - z_start)
    direc = -1
  else
    call out_io (s_fatal$, r_name, 'BAD EDGE ARGUMENT:', set)
    call err_exit
  endif

  if (s_len < 0) s_len = 0

! Get the coords in the frame of reference of the element

  start2 = start
  call offset_particle (ele, param, start2, set)

! Calculate the radius of curvature for an on-energy particle

  select case (ele%key)

  case (quadrupole$, sol_quad$)
    x_ave = start2%vec(1) + direc * start2%vec(2) * ele%value(l$) / 4
    y_ave = start2%vec(3) + direc * start2%vec(4) * ele%value(l$) / 4
    g_x =  ele%value(k1$) * x_ave
    g_y = -ele%value(k1$) * y_ave
    g2 = g_x**2 + g_y**2
    if (bmad_com%radiation_fluctuations_on) g3 = sqrt(g2)**3

  case (sextupole$)
    g = ele%value(k2$) * (start2%vec(1)**2 + start2%vec(3)**2)
    g2 = g**2
    if (bmad_com%radiation_fluctuations_on) g3 = g2 * abs(g)

  case (octupole$)
    g2 = ele%value(k3$)**2 * (start2%vec(1)**2 + start2%vec(3)**2)**3
    if (bmad_com%radiation_fluctuations_on) g3 = sqrt(g2)**3

  case (sbend$)
    if (ele%value(k1$) == 0) then
      g = ele%value(g$) + ele%value(g_err$)
      g2 = g**2 
      if (bmad_com%radiation_fluctuations_on) g3 = g2 * abs(g)
    else
      x_ave = start2%vec(1) + direc * start2%vec(2) * ele%value(l$) / 4
      y_ave = start2%vec(3) + direc * start2%vec(4) * ele%value(l$) / 4
      g_x = ele%value(g$) + ele%value(g_err$) + ele%value(k1$) * x_ave
      g_y = ele%value(k1$) * y_ave
      g2 = g_x**2 + g_y**2
      if (bmad_com%radiation_fluctuations_on) g3 = sqrt(g2)**3
    endif

  case (wiggler$)
    if (ele%sub_key == map_type$) then
      if (.not. associated(ele%const)) then
        call out_io (s_fatal$, r_name, 'SETUP_RADIATION_TRACKING HAS NOT BEEN CALLED FOR THIS LATTICE!')
        call err_exit
      endif
      g2 = ele%const(10) + &
                  dot_product(start2%vec(1:4)-ele%const(1:4), ele%const(11:14))
      g3 = ele%const(20) + &
                  dot_product(start2%vec(1:4)-ele%const(1:4), ele%const(21:24))
      if (g3 < 0) g3 = 0
    elseif (ele%sub_key == periodic_type$) then
      g2 = abs(ele%value(k1$))
      g3 = 4 * sqrt(2*g2)**3 / (3 * pi)  
    endif

  end select

! Apply the radiation kicks
! Basic equation is E_radiated = xi * (dE/dt) * sqrt(L) / c_light
! where xi is a random number with sigma = 1.

  gamma_0 = ele%value(E_TOT$) / m_electron

  fact_d = 0
  if (bmad_com%radiation_damping_on) fact_d = 2 * r_e * gamma_0**3 * g2 * s_len / 3

  fact_f = 0
  if (bmad_com%radiation_fluctuations_on) then
    call ran_gauss (this_ran)
    fact_f = sqrt(rad_fluct_const * s_len * gamma_0**5 * g3) * this_ran
  endif

  dE_p = (1 + start%vec(6)) * (fact_d + fact_f) * synch_rad_com%scale 

  end = start
  end%vec(2) = end%vec(2) * (1 - dE_p)
  end%vec(4) = end%vec(4) * (1 - dE_p)
  end%vec(6) = end%vec(6)  - dE_p * (1 + end%vec(6))

  if (synch_rad_com%i_calc_on) then
    synch_rad_com%i2 = synch_rad_com%i2 + g2 * s_len
    synch_rad_com%i3 = synch_rad_com%i3 + g3 * s_len
  endif

end subroutine

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! Subroutine setup_radiation_tracking (lat, closed_orb,
!                                        fluctuations_on, damping_on) 
!
! Subroutine to compute synchrotron radiation parameters prior to tracking.
!
! Note: The fluctuations_on and damping_on flags are global and are applied
! to all lattices. If either fluctuations or damping is turned on then this
! routine must be called for each lattice in use.
! Initially, fluctuations and damping are turned off.
!
! Modules needed:
!   use radiation_mod
!
! Input:
!   lat            -- lat_struct:
!   closed_orb(0:)  -- Coord_struct: Closed_orbit.
!   fluctuations_on -- Logical, optional: If True then radiation fluctuations
!                        will be present. 
!   damping_on      -- Logical, optional: If True then radiation damping
!                        will be present. 
!
! Output:
!   lat           -- lat_struct: Lattice with radiation parameters computed. 
!-

subroutine setup_radiation_tracking (lat, closed_orb, &
                                        fluctuations_on, damping_on)

  use symp_lie_mod

  implicit none

  type (lat_struct), target :: lat
  type (coord_struct) :: closed_orb(0:)
  type (coord_struct) start0, start1, start, end
  type (track_struct), save :: track

  real(rp), save :: del_orb(6) = (/ 1e-4, 1e-4, 1e-4, 1e-4, 1e-4, 1e-5 /)
  real(rp) g2, g3

  integer i, j

  logical, optional :: fluctuations_on, damping_on

! Set logicals.

  if (present(fluctuations_on)) bmad_com%radiation_fluctuations_on = fluctuations_on
  if (present(damping_on)) bmad_com%radiation_damping_on = damping_on

! Compute for a map_type wiggler the change in g2 and g3 
!   with respect to transverse orbit for an on-energy particle..
! This is done with (x, x', y, y') to take out the energy dependence.
! start0 is in local coords                    
! start1 is lab coords with vec(6) = dE/E = 0 

  do i = 1, lat%n_ele_track

    if (lat%ele(i)%key /= wiggler$) cycle
    if (lat%ele(i)%sub_key /= map_type$) cycle

    track%save_track = .true.

    start0 = closed_orb(i-1)
    call offset_particle (lat%ele(i), lat%param, start0, set$)

    start1 = closed_orb(i-1)
    start1%vec(2) = start0%vec(2)
    start1%vec(4) = start0%vec(4)
    start1%vec(6) = 0

    if (.not. associated(lat%ele(i)%const)) allocate (lat%ele(i)%const(1:26))
    lat%ele(i)%const(1:6) = start0%vec  ! Local coords
    call symp_lie_bmad (lat%ele(i), lat%param, start1, end, .false., track)
    call calc_g (track, lat%ele(i)%const(10), lat%ele(i)%const(20))

    do j = 1, 4
      start = start1
      start%vec(j) = start%vec(j) + del_orb(j)
      call symp_lie_bmad (lat%ele(i), lat%param, start, end, .false., track)
      call calc_g (track, g2, g3)
      lat%ele(i)%const(j+10) = (g2 - lat%ele(i)%const(10)) / del_orb(j)
      lat%ele(i)%const(j+20) = (g3 - lat%ele(i)%const(20)) / del_orb(j)
    enddo

  enddo

!-------------------------------------------------------
contains

subroutine calc_g (track, g2, g3)

  type (track_struct) track
  real(rp) g2, g3, k2, k3, kick(6)
  integer j, n0, n1

! g2 is the average kick^2 over the element.

  g2 = 0; g3 = 0

  n0 = lbound(track%pt, 1)
  n1 = track%n_pt
  do j = n0, n1

    call em_field_kick (lat%ele(i), lat%param, track%pt(j)%s, &
                                    track%pt(j)%orb%vec, .false., kick)

    k2 = kick(2)**2 + kick(4)**2
    k3 = sqrt(k2)**3

    if (i == n0 .or. i == n1) then
      k2 = k2 / 2
      k3 = k3 / 2
    endif

    g2 = g2 + k2
    g3 = g3 + k3

  enddo

  g2 = g2 / (n1 - n0 + 1)
  g3 = g3 / (n1 - n0 + 1)

end subroutine

end subroutine

end module
