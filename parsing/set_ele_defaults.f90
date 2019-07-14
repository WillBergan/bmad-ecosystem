!+
! Subroutine set_ele_defaults (ele, do_allocate)
!
! Subroutine set the defaults for an element of a given type.
! For example, the default aperture type for an ecollimator$
!   element is ele%aperture_type = elliptical$.
!
! Input:
!   ele           -- ele_struct: Element to init.
!     %key          -- Type of element.
!   do_allocate   -- logical, optional: Do default allocation of element components? Default is True.
!
! Output:
!   ele   -- ele_struct: Initialized element.
!-

subroutine set_ele_defaults (ele, do_allocate)

use bmad_interface, dummy => set_ele_defaults

implicit none

type (ele_struct) ele
integer i, j
logical, optional :: do_allocate

!

ele%component_name = ''

! Some overall defaults.

if (attribute_index(ele, 'FRINGE_AT') /= 0)            ele%value(fringe_at$) = both_ends$
if (attribute_index(ele, 'FRINGE_TYPE') /= 0)          ele%value(fringe_type$) = none$
if (attribute_index(ele, 'SPIN_FRINGE_ON') /= 0)       ele%value(spin_fringe_on$) = true$
if (attribute_index(ele, 'PTC_CANONICAL_COORDS') /= 0) ele%value(ptc_canonical_coords$) = true$
ele%taylor_map_includes_offsets = .true.

! Other inits.

select case (ele%key)

case (ac_kicker$)
  allocate (ele%ac_kick)
  ele%mat6_calc_method = tracking$
  ele%value(interpolation$) = spline$
  ele%value(ref_time_offset$) = true$

case (beambeam$)
  ele%value(charge$) = -1
  ele%value(n_slice$) = 1

case (beginning_ele$)
  ele%value(e_tot$) = -1
  ele%value(p0c$) = -1

case (fork$, photon_fork$)
  ele%value(direction$) = 1
  ele%value(particle$) = real_garbage$

case (capillary$)
  ele%offset_moves_aperture = .true.
  
case (crystal$)
  ele%value(ref_orbit_follows$) = bragg_diffracted$
  ele%aperture_at = surface$
  ele%offset_moves_aperture = .true.
  if (logic_option(.true., do_allocate)) then
    ! Avoid "ele%photon = photon_element_struct()" to get around Ifort bug. 4/10/2019
    if (associated(ele%photon)) deallocate(ele%photon)
    allocate(ele%photon)
  endif

case (custom$)  
  ele%mat6_calc_method = custom$
  ele%tracking_method  = custom$
  ele%field_calc       = custom$

case (def_particle_start$)

case (def_mad_beam$)
  ele%value(particle$) = positron$

case (def_parameter$)
  ele%value(geometry$) = real_garbage$
  ele%value(live_branch$) = real_garbage$
  ele%value(high_energy_space_charge_on$) = real_garbage$
  ele%value(particle$) = positron$
  ele%value(default_tracking_species$) = real_garbage$
  ele%value(ix_branch$) = -1

case (detector$)
  ele%aperture_type = auto_aperture$
  if (logic_option(.true., do_allocate)) then
    ! Avoid "ele%photon = photon_element_struct()" to get around ifort bug. 4/10/2019
    if (associated(ele%photon)) deallocate(ele%photon)
    allocate(ele%photon)
  endif

case (diffraction_plate$)
  ele%aperture_at = surface$
  ele%aperture_type = auto_aperture$
  ele%offset_moves_aperture = .true.
  ele%value(mode$) = transmission$
  if (logic_option(.true., do_allocate)) then
    ! Avoid "ele%photon = photon_element_struct()" to get around ifort bug. 4/10/2019
    if (associated(ele%photon)) deallocate(ele%photon)
    allocate(ele%photon)
  endif

case (e_gun$)
  ele%tracking_method = time_runge_kutta$
  ele%mat6_calc_method = tracking$
  ele%value(field_autoscale$) = 1
  ele%value(fringe_at$) = exit_end$
  ele%value(fringe_type$) = full$
  ele%value(autoscale_amplitude$) = true$
  ele%value(autoscale_phase$) = true$

case (ecollimator$)
  ele%aperture_type = elliptical$
  ele%offset_moves_aperture = .true.

case (em_field$)
  ele%tracking_method = runge_kutta$
  ele%mat6_calc_method = tracking$
  ele%value(fringe_type$) = full$
  ele%value(field_autoscale$) = 1
  ele%value(constant_ref_energy$) = true$

case (fiducial$)
  ele%value(origin_ele_ref_pt$) = center_pt$

case (floor_shift$)
  ele%value(origin_ele_ref_pt$) = exit_end$
  ele%value(upstream_ele_dir$) = 1
  ele%value(downstream_ele_dir$) = 1

case (girder$)
  ele%value(origin_ele_ref_pt$) = center_pt$

case (hybrid$) 
  ! Nothing to be done.

case (lcavity$)
  ele%value(coupler_at$) = exit_end$
  ele%value(field_autoscale$) = 1
  ele%value(n_cell$) = 1
  ele%value(cavity_type$) = standing_wave$
  ele%value(fringe_type$) = full$
  ele%value(autoscale_amplitude$) = true$
  ele%value(autoscale_phase$) = true$
  ele%value(longitudinal_mode$) = 1

case (line_ele$)
  ele%value(particle$) = real_garbage$
  ele%value(geometry$) = real_garbage$
  ele%value(live_branch$) = real_garbage$
  ele%value(high_energy_space_charge_on$) = real_garbage$
  ele%value(default_tracking_species$) = real_garbage$
  ele%value(e_tot$) = -1
  ele%value(p0c$) = -1
  ele%value(ix_branch$) = -1

case (mask$)
  ele%aperture_at = surface$
  ele%aperture_type = auto_aperture$
  ele%offset_moves_aperture = .true.
  ele%value(mode$) = transmission$
  if (logic_option(.true., do_allocate)) then
    ! Avoid "ele%photon = photon_element_struct()" to get around Ifort bug. 4/10/2019
    if (associated(ele%photon)) deallocate(ele%photon)
    allocate(ele%photon)
  endif

case (mirror$)
  ele%aperture_at = surface$
  ele%offset_moves_aperture = .true.
  if (logic_option(.true., do_allocate)) then
    ! Avoid "ele%photon = photon_element_struct()" to get around Ifort bug. 4/10/2019
    if (associated(ele%photon)) deallocate(ele%photon)
    allocate(ele%photon)
  endif

case (multilayer_mirror$)
  ele%aperture_at = surface$
  ele%offset_moves_aperture = .true.
  if (logic_option(.true., do_allocate)) then
    ! Avoid "ele%photon = photon_element_struct()" to get around Ifort bug. 4/10/2019
    if (associated(ele%photon)) deallocate(ele%photon)
    allocate(ele%photon)
  endif

case (multipole$, ab_multipole$)
  if (logic_option(.true., do_allocate)) then
    call multipole_init (ele, magnetic$, .true.)
  endif
  ele%scale_multipoles = .false.

case (patch$)
  ele%value(flexible$) = false$ 
  ele%value(new_branch$) = true$
  ele%value(ref_coordinates$)= exit_end$
  ele%value(upstream_ele_dir$) = 1
  ele%value(downstream_ele_dir$) = 1

case (photon_init$)
  ele%value(ds_slice$) = 0.01
  ele%value(velocity_distribution$) = gaussian$
  ele%value(energy_distribution$) = gaussian$
  ele%value(spatial_distribution$) = gaussian$
  ele%value(transverse_sigma_cut$) = 3
  ele%value(E_center_relative_to_ref$) = true$
  if (logic_option(.true., do_allocate)) then
    ! Avoid "ele%photon = photon_element_struct()" to get around Ifort bug. 4/10/2019
    if (associated(ele%photon)) deallocate(ele%photon)
    allocate(ele%photon)
  endif

case (rbend$, sbend$)
  ele%value(fintx$) = real_garbage$
  ele%value(hgapx$) = real_garbage$
  ele%value(fringe_type$) = basic_bend$
  ele%value(higher_order_fringe_type$) = none$
  ele%value(ptc_field_geometry$) = sector$
  ele%value(ptc_fringe_geometry$) = x_invariant$
  ele%value(exact_multipoles$) = off$

case (rcollimator$)
  ele%offset_moves_aperture = .true.

case (rfcavity$)
  ele%value(coupler_at$) = exit_end$
  ele%value(field_autoscale$) = 1
  ele%value(n_cell$) = 1
  ele%value(cavity_type$) = standing_wave$
  ele%value(fringe_type$) = full$
  ele%value(autoscale_amplitude$) = true$
  ele%value(autoscale_phase$) = true$
  ele%value(longitudinal_mode$) = 1

case (sad_mult$)
  ele%value(eps_step_scale$) = 1
  ele%scale_multipoles = .false.
  if (logic_option(.true., do_allocate)) then
    call multipole_init (ele, magnetic$, .true.)
  endif

case (sample$)
  ele%aperture_at = surface$
  ele%value(mode$) = reflection$
  if (logic_option(.true., do_allocate)) then
    ! Avoid "ele%photon = photon_element_struct()" to get around Ifort bug. 4/10/2019
    if (associated(ele%photon)) deallocate(ele%photon)
    allocate(ele%photon)
  endif

case (taylor$)   ! start with unit matrix
  ele%tracking_method = taylor$  
  ele%mat6_calc_method = taylor$ 
  ele%taylor_map_includes_offsets = .false.
  if (logic_option(.true., do_allocate)) then
    call taylor_make_unit (ele%taylor)
  
    do i = 0, 3
      ele%spin_taylor(i)%ref = 0
      call init_taylor_series (ele%spin_taylor(i), 0)
    enddo
  endif

case (wiggler$, undulator$) 
  ele%field_calc = int_garbage$
  ele%value(polarity$) = 1.0

end select

! %bookkeeping_state inits
! Note: Groups, for example, do not have a reference energy, etc. so set the bookkeeping
! state to OK$ for these categories.

call set_status_flags (ele%bookkeeping_state, stale$)

select case (ele%key)

case (group$)
  ele%bookkeeping_state%attributes     = ok$
  ele%bookkeeping_state%s_position     = ok$
  ele%bookkeeping_state%floor_position = ok$
  ele%bookkeeping_state%ref_energy     = ok$
  ele%bookkeeping_state%mat6           = ok$
  ele%bookkeeping_state%rad_int        = ok$
  ele%bookkeeping_state%ptc            = ok$
  ele%field_calc = no_field$
  ele%value(gang$) = true$

case (overlay$)
  ele%bookkeeping_state%attributes     = ok$
  ele%bookkeeping_state%mat6           = ok$
  ele%bookkeeping_state%rad_int        = ok$
  ele%bookkeeping_state%ptc            = ok$
  ele%field_calc = no_field$
  ele%value(gang$) = true$

case (girder$)
  ele%bookkeeping_state%attributes     = ok$
  ele%bookkeeping_state%ref_energy     = ok$
  ele%bookkeeping_state%mat6           = ok$
  ele%bookkeeping_state%rad_int        = ok$
  ele%bookkeeping_state%ptc            = ok$
  ele%field_calc = no_field$

case (beginning_ele$)
  ele%bookkeeping_state%rad_int        = ok$
  ele%bookkeeping_state%control        = ok$
  ele%field_calc = no_field$

case default
  ele%bookkeeping_state%control        = ok$

end select

end subroutine set_ele_defaults

