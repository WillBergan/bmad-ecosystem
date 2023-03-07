module space_charge_mod

use bmad

contains

!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!+
! Subroutine sc_field_calc (bunch, include_image, t_end, sc_field, newborn)
!
! Routine to calculate the space charge field of a bunch
!
! Input:
!   bunch           -- bunch_struct: Starting bunch position in time-based coordinates
!   include_image   -- logical: True if cathode image charge fields are to be included.
!   t_end           -- real(rp): Calculate space charge field for preborn particles emitted before t_end.
!   newborn         -- logical(:), optional: Array of logicals the same size as bunch%particle.
!                        If true, the corresponding particle will have zero charge for sc calculation.
!   bunch_params    -- bunch_params_struct, optional: If present, particles too far from the bunch will be ignored.
!                        The threashold is set by space_charge_com%particle_sigma_cutoff. 
! Output:
!   include_image   -- logical: Set False if image charge calc no longer needed (Note: never set True).
!   sc_field        -- em_field_struct: Space charge field at particle positions
!-

subroutine sc_field_calc (bunch, include_image, t_end, sc_field, newborn, bunch_params)

use csr_and_space_charge_mod

implicit none

type (bunch_struct), target :: bunch
type (coord_struct), pointer :: p
type (csr_particle_position_struct) :: position(size(bunch%particle))
type (em_field_struct) :: sc_field(size(bunch%particle))
type (mesh3d_struct) :: mesh3d, mesh3d_image
type (bunch_params_struct), optional :: bunch_params

integer :: n, n_alive, i, imin(1)
real(rp) :: beta, ratio, t_end
real(rp) :: Evec(3), Bvec(3), Evec_image(3), cutoff(3)
logical :: include_image, err
logical, optional :: newborn(:)

! Initialize variables
mesh3d%nhi = space_charge_com%space_charge_mesh_size
if (present(bunch_params)) then
  cutoff(1) = sqrt(bunch_params%sigma(1,1))
  cutoff(2) = sqrt(bunch_params%sigma(3,3))
  cutoff(3) = sqrt(bunch_params%sigma(5,5))
endif

! Gather particles
n = 0
n_alive = 0
beta = 0
do i = 1, size(bunch%particle)
  p => bunch%particle(i)
  if (p%state == pre_born$ .and. p%t <= t_end) then ! Particles to be emitted
    n = n + 1
    position(n)%r = [p%vec(1), p%vec(3), p%s]
    position(n)%charge = 0
  else if (p%state /= alive$) then  ! Lost particles
    cycle
  else if (present(newborn)) then  ! Newly emitted particles
    if (newborn(i)) then
      n = n + 1
      position(n)%r = [p%vec(1), p%vec(3), p%s]
      position(n)%charge = 0
    endif
  else  ! Living particles
    if (present(bunch_params)) then
      if (out_of_sigma_cutoff(p)) cycle  ! Ignore particles too far off the bunch
    endif
    n = n + 1
    position(n)%r = [p%vec(1), p%vec(3), p%s]
    position(n)%charge = p%charge * charge_of(p%species)
    beta = beta + p%beta
    n_alive = n_alive + 1
  endif
enddo

! Return if not enough living particles
if (n_alive<2) return
beta = beta/n_alive

! Calculate space charge field
mesh3d%gamma = 1/sqrt(1- beta**2)
call deposit_particles (position(1:n)%r(1), position(1:n)%r(2), position(1:n)%r(3), mesh3d, qa=position(1:n)%charge)
call space_charge_3d(mesh3d, at_cathode=include_image, calc_bfield=.true., image_efield=mesh3d_image%efield)

! Determine if cathode image field should be turned off
if (include_image) then
  ! Copy mesh3d dimensions and allocate image_efield
  mesh3d_image%nlo = mesh3d%nlo
  mesh3d_image%nhi = mesh3d%nhi
  mesh3d_image%min = mesh3d%min
  mesh3d_image%max = mesh3d%max
  mesh3d_image%delta = mesh3d%delta

  ! Compare efield and image_efield on the last particle
  imin = minloc(bunch%particle%s,mask=(bunch%particle%state == alive$))
  p => bunch%particle(imin(1))
  call interpolate_field(p%vec(1), p%vec(3), p%s,  mesh3d, E=Evec)
  call interpolate_field(p%vec(1), p%vec(3), p%s,  mesh3d_image, E=Evec_image)
  ratio = maxval(abs(Evec_image/Evec))
  ! If image field is small compared to the bunch field, turn it off from here on
  if (ratio <= space_charge_com%cathode_strength_cutoff) include_image = .false.
endif

! Calculate field at particle locations

do i = 1, size(bunch%particle)
  p => bunch%particle(i)
  if (p%state == pre_born$ .and. p%t <= t_end) then  ! Particles to be emitted
    call interpolate_field(p%vec(1), p%vec(3), p%s,  mesh3d, E=sc_field(i)%E, B=sc_field(i)%B)
  else if (p%state /= alive$) then ! Lost particles
    sc_field(i)%E = 0
    sc_field(i)%B = 0
  else  ! Living particles
    if (present(bunch_params)) then
      if (out_of_sigma_cutoff(p)) then  ! Ignore particles too far off the bunch
        sc_field(i)%E = 0
        sc_field(i)%B = 0
      endif
    endif
    call interpolate_field(p%vec(1), p%vec(3), p%s,  mesh3d, E=sc_field(i)%E, B=sc_field(i)%B)
  end if
enddo

!-------------------------------------------------------------------
contains
! Check if a particle is too far from the bunch
!
function out_of_sigma_cutoff(p) result (out_of_cutoff)
  type (coord_struct) :: p
  logical :: out_of_cutoff
  real(rp) :: particle_sigma_cutoff

  out_of_cutoff = .false.
  particle_sigma_cutoff = space_charge_com%particle_sigma_cutoff
  if (particle_sigma_cutoff .le. 0) return
  out_of_cutoff = ( abs(p%vec(1) - bunch_params%centroid%vec(1)) > cutoff(1)*particle_sigma_cutoff ) .and. &
                  ( abs(p%vec(3) - bunch_params%centroid%vec(3)) > cutoff(2)*particle_sigma_cutoff ) .and. &
                  ( abs(p%s - bunch_params%centroid%vec(5)) > cutoff(3)*particle_sigma_cutoff )

end function out_of_sigma_cutoff
end subroutine sc_field_calc

!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!+
! Subroutine sc_step(bunch, ele, include_image, t_end, newborn)
!
! Subroutine to track a bunch through a given time step with space charge
!
! Input:
!   bunch         -- bunch_struct: Starting bunch position in t-based coordinates
!   ele           -- ele_struct: Element being tracked through.
!   include_image -- logical: Include image charge forces?
!   t_end         -- real(rp): Time at which the tracking ends.
!   sc_field      -- em_field_struct(:): Array to hold space charge fields. 
!                       Its length should be the number of particles.
!   newborn       -- logical(:), optional: Array of logicals the same size as bunch%particle.
!                      If true, the corresponding particle will have zero charge for sc calculation.
!
! Output:
!   bunch         -- bunch_struct: Ending bunch position in t-based coordinates after space charge kick.
!   include_image -- logical: Set False if image charge calc no longer needed (Note: never set True).
!   n_emit        -- integer, optional: The number of particles emitted in this step.
!-

subroutine sc_step(bunch, ele, include_image, t_end, sc_field, newborn, n_emit)

use beam_utils

implicit none

type (bunch_struct), target :: bunch
type (ele_struct) :: ele
type (em_field_struct) :: extra_field(size(bunch%particle))
type (coord_struct), pointer :: p
type (em_field_struct) :: sc_field(:)
type (bunch_params_struct) :: bunch_params

real(rp) t_end, sum_z
logical include_image, error
integer i, n
integer, optional :: n_emit
logical, optional :: newborn(:)

! Calculate space charge field
if (space_charge_com%particle_sigma_cutoff > 0) then
  call calc_bunch_params(bunch, bunch_params, error, is_time_coords=.true., ele=ele)
  call sc_field_calc(bunch, include_image, t_end, sc_field, newborn, bunch_params)
else
  call sc_field_calc(bunch, include_image, t_end, sc_field, newborn)
endif

! Generate particles at the cathode
do i = 1, size(bunch%particle)
  p => bunch%particle(i)
  if (p%state == pre_born$ .and. p%t <= t_end) then
    p%state = alive$
    if (present(n_emit)) n_emit = n_emit + 1
  endif
enddo 

! And track
call track_bunch_time(bunch, ele, t_end, 1e30_rp, extra_field=sc_field)
end subroutine sc_step

!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!+
! Subroutine sc_adaptive_step(bunch, ele, include_image, t_now, dt_step, dt_next)
!
! Routine to track a bunch of particles with space charge for one step using
! adaptive step size control and determine appropriate step size for the next step
!
! Input:
!   bunch         -- bunch_struct: Starting bunch position in t-based coordinates
!   ele           -- ele_struct: Nominal lattice element being tracked through.
!   include_image -- logical: Include image charge forces?
!   t_now         -- real(rp): Current time at the beginning of tracking
!   dt_step       -- real(rp): Initial SC time step to take
!   sc_field      -- em_field_struct(:): Array to hold space charge fields. 
!                       Its length should be the number of particles.
!
! Output:
!   bunch         -- bunch_struct: Ending bunch position in t-based coordinates.
!   include_image -- logical: Set False if image charge calc no longer needed (Note: never set True).
!   dt_next       -- real(rp): Next SC time step the tracker would take based on the error tolerance
!   dt_step       -- real(rp): Step done.
!-

subroutine sc_adaptive_step(bunch, ele, include_image, t_now, dt_step, dt_next, sc_field)

implicit none

type (bunch_struct) :: bunch, bunch_full, bunch_half
type (ele_struct) ele
type (coord_struct), pointer :: p
type (em_field_struct) :: sc_field(:)

real(rp) :: t_now, dt_step, dt_next, sqrt_N
real(rp) :: r_err(6), r_scale(6), rel_tol, abs_tol, err_max
real(rp), parameter :: safety = 0.9_rp, p_grow = -0.5_rp
real(rp), parameter :: p_shrink = -0.5_rp, err_con = 1.89d-4
real(rp), parameter :: tiny = 1.0e-30_rp

integer i, N, n_emit
logical :: newborn(size(bunch%particle))
logical include_image

!

sqrt_N = sqrt(abs(1/(c_light*dt_step)))  ! number of steps we would take to cover 1 meter
rel_tol = space_charge_com%rel_tol_tracking / sqrt_N
abs_tol = space_charge_com%abs_tol_tracking / sqrt_N

bunch_full = bunch
bunch_half = bunch
dt_next = dt_step

do
  n_emit = 0
  ! Full step
  call sc_step(bunch_full, ele, include_image, t_now+dt_step, sc_field)
  ! Two half steps
  call sc_step(bunch_half, ele, include_image, t_now+dt_step/2, sc_field, n_emit=n_emit)
  newborn = ( (bunch%particle%state .ne. bunch_half%particle%state) .and. (bunch%particle%state .eq. pre_born$) )
  call sc_step(bunch_half, ele, include_image, t_now+dt_step, sc_field, newborn, n_emit)

  r_scale = abs(bunch_rms_vec(bunch))+abs(bunch_rms_vec(bunch_half)) + tiny
  r_err = [0,0,0,0,0,0]
  N = 0
  ! Calculate error from the difference
  do i = 1, size(bunch%particle)
    if (bunch_half%particle(i)%state /= alive$) cycle ! Only count living particles
    r_err(:) = r_err(:) + abs(bunch_full%particle(i)%vec(:)-bunch_half%particle(i)%vec(:))
    N = N +1
  enddo
  ! If no living particle, finish step
  if (N==0) then
    bunch = bunch_half
    return
  end if
  
  ! Compare error to the tolerance
  r_err = r_err/N
  
  err_max = maxval(r_err(:)/(r_scale*rel_tol + abs_tol))
  if (space_charge_com%debug) print *, dt_step, err_max, n_emit
  ! If error is larger than tolerance, try again with a smaller step
  if (err_max <= 1.0) exit
  dt_step = safety * dt_step * (err_max**p_shrink)
  bunch%n_bad = bunch%n_bad + 1
  bunch_full = bunch
  bunch_half = bunch
enddo

bunch%n_good = bunch%n_good + 1
! Adjust next step size
! Copied from Runge-Kutta
if (err_max > err_con) then
  dt_next = safety * dt_step * (err_max**p_grow)
else
  dt_next = 5.0_rp * dt_step
endif

bunch = bunch_half

!-------------------------------------------------------------------
contains

! Use RMS of coordinates to estimate the scale of motion
! It combine the centroid position and the width of the bunch

function bunch_rms_vec(bunch) result (rms_vec)

type (bunch_struct) bunch
real(rp) rms_vec(6)
integer i, N

!

N = 0
rms_vec = [0,0,0,0,0,0]
do i = 1,size(bunch%particle)
  if (bunch%particle(i)%state /= alive$) cycle
  rms_vec(:) = rms_vec(:) + bunch%particle(i)%vec(:)**2
  N = N +1
enddo
if (N==0) return
rms_vec = sqrt(rms_vec/N)

end function bunch_rms_vec

end subroutine sc_adaptive_step

!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!+
! Subroutine track_to_s (bunch, s, branch)
!
! Drift a bunch of particles to the same s coordinate
!
! Input:
!   bunch     -- bunch_struct: Input bunch position in s-based coordinate.
!   s         -- real(rp): Target s coordinate.
!   branch    -- branch_struct: Branch being tracked through.
!
! Output:
!   bunch     -- bunch_struct: Output bunch position in s-based coordinate. Particles will be at the same s coordinate
!-

subroutine track_to_s (bunch, s, branch)

implicit none

type (bunch_struct), target :: bunch
type (coord_struct), pointer :: p
type (branch_struct) :: branch
type (coord_struct) :: position

integer i
real(rp) s, ds


do i = 1, size(bunch%particle)
  p => bunch%particle(i)
  if (p%state /= alive$) cycle
  ds = s - p%s
  call track_a_drift(p, ds)
  if (p%s > branch%ele(branch%n_ele_track)%s) then
    p%ix_ele = branch%n_ele_track
    p%location = downstream_end$
  else
    p%ix_ele = element_at_s(branch, p%s, (ds < 0), position=position)
    p%location = position%location
  endif
enddo

end subroutine track_to_s

!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!------------------------------------------------------------------------------------------
!+
! Subroutine track_to_t (bunch, t, branch)
!
! Drift a bunch of particles to the same t coordinate
!
! Input:
!   bunch     -- bunch_struct: Input bunch position in s-based coordinate.
!   t         -- real(rp): Target t coordinate.
!   branch    -- branch_struct: Lattice branch being tracked through.
!
! Output:
!   bunch     -- bunch_struct: Output bunch position in s-based coordinate. Particles will be at the same t coordinate
!-

subroutine track_to_t (bunch, t, branch)

implicit none

type (bunch_struct), target :: bunch
type (coord_struct), pointer :: p
type (branch_struct) :: branch
type (coord_struct) :: position

integer i
real(rp) t, pz0, E_tot, dt, ds

! Convert bunch to s-based coordinates

do i = 1, size(bunch%particle)
  p => bunch%particle(i)
  if (p%state /= alive$) cycle

  pz0 = sqrt((1.0_rp + p%vec(6))**2 - p%vec(2)**2 - p%vec(4)**2 ) ! * p0 
  E_tot = sqrt((1.0_rp + p%vec(6))**2 + (mass_of(p%species)/p%p0c)**2) ! * p0
  dt = t - p%t
  ds = dt*(c_light*pz0/E_tot)
  call track_a_drift(p,ds)

  if (p%s > branch%ele(branch%n_ele_track)%s) then
    p%ix_ele = branch%n_ele_track
    p%location = downstream_end$
  else
    p%ix_ele = element_at_s(branch, p%s, (ds < 0), position=position)
    p%location = position%location
  endif
enddo

end subroutine track_to_t
  
end module
