module track1_photon_mod

use fringe_mod
use wall3d_mod
use photon_utils_mod
use xraylib_interface

implicit none

contains

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine track1_lens (ele, param, orbit)
!
! Routine to track through a lens.
!
! Input:
!   ele      -- ele_struct: Element tracking through.
!   param    -- lat_param_struct: lattice parameters.
!   orbit    -- Coord_struct: phase-space coords to be transformed
!
! Output:
!   orbit    -- Coord_struct: final phase-space coords
!-

subroutine track1_lens (ele, param, orbit)

type (ele_struct), target:: ele
type (coord_struct), target:: orbit
type (lat_param_struct) :: param

character(*), parameter :: r_name = 'track1_lens'

!

! Nothing implemented yet.

end subroutine track1_lens

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine track_a_patch_photon (ele, orbit, drift_to_exit, use_z_pos)
!
! Routine to track through a patch element with a photon.
! The steps for tracking are:
!   1) Transform from entrance to exit coordinates.
!   2) Drift particle from the entrance to the exit coordinants.
!
! Input:
!   ele           -- ele_struct: patch element.
!   orbit         -- coord_struct: Starting phase space coords
!   drift_to_exit -- logical, optional: If False then do not drift the particle from
!                      start to ending faces. Default is True.
!   use_z_pos     -- loigical, optional: If present and True, use orbit%vec(5) as the true
!                      z-position relative to the start of the element instead of assuming 
!                      that the particle is at the patch edge.
!
! Output:
!   orbit         -- coord_struct: Coords after applying a patch transformation.
!-

Subroutine track_a_patch_photon (ele, orbit, drift_to_exit, use_z_pos)

type (coord_struct) orbit
type (ele_struct) ele

real(rp) w(3,3)

logical, optional :: drift_to_exit, use_z_pos

!

if (orbit%direction == 1) then
  ! Translate (x, y, z) to coordinate system with respect to downstream origin.
  orbit%vec(1) = orbit%vec(1) - ele%value(x_offset$)
  orbit%vec(3) = orbit%vec(3) - ele%value(y_offset$)
  if (logic_option(.false., use_z_pos)) then
    orbit%vec(5) = orbit%vec(5) - ele%value(z_offset$)   
  else
    orbit%vec(5) = -ele%value(z_offset$)   
  endif

  if (ele%value(x_pitch$) /= 0 .or. ele%value(y_pitch$) /= 0 .or. ele%value(tilt$) /= 0) then
    call floor_angles_to_w_mat (ele%value(x_pitch$), ele%value(y_pitch$), ele%value(tilt$), w_mat_inv = w)
    orbit%vec(2:6:2) = matmul(w, orbit%vec(2:6:2))
    orbit%vec(1:5:2) = matmul(w, orbit%vec(1:5:2))
  endif

  if (logic_option(.true., drift_to_exit)) then
    call track_a_drift_photon (orbit, -orbit%vec(5), .false.)
  endif

  orbit%vec(5) = orbit%vec(5) + ele%value(l$)
  orbit%s = ele%s_start + orbit%vec(5)

else
  
  ! Shift to z being with respect to exit end coords.
  if (logic_option(.false., use_z_pos)) then
    orbit%vec(5) = orbit%vec(5) - ele%value(l$)
  else
    orbit%vec(5) = 0   ! Assume particle starts at downstream face
  endif

  if (ele%value(x_pitch$) /= 0 .or. ele%value(y_pitch$) /= 0 .or. ele%value(tilt$) /= 0) then
    call floor_angles_to_w_mat (ele%value(x_pitch$), ele%value(y_pitch$), ele%value(tilt$), w_mat = w)
    orbit%vec(2:6:2) = matmul(w, orbit%vec(2:6:2))
    orbit%vec(1:5:2) = matmul(w, orbit%vec(1:5:2))
  endif

  orbit%vec(1) = orbit%vec(1) + ele%value(x_offset$)
  orbit%vec(3) = orbit%vec(3) + ele%value(y_offset$)
  orbit%vec(5) = orbit%vec(5) + ele%value(z_offset$)

  if (logic_option(.true., drift_to_exit)) then
    call track_a_drift_photon (orbit, -orbit%vec(5), .false.)
  endif

  orbit%s = ele%s_start + orbit%vec(5)

endif

end subroutine track_a_patch_photon

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine track1_diffraction_plate_or_mask (ele, param, orbit)
!
! Routine to track through diffraction plate and mask elements.
!
! Input:
!   ele      -- ele_struct: Diffraction plate or mask element.
!   param    -- lat_param_struct: lattice parameters.
!   orbit    -- Coord_struct: phase-space coords to be transformed
!
! Output:
!   orbit    -- Coord_struct: final phase-space coords
!-

subroutine track1_diffraction_plate_or_mask (ele, param, orbit)

type (ele_struct), target:: ele
type (coord_struct), target:: orbit
type (lat_param_struct) :: param
type (wall3d_section_struct), pointer :: sec

real(rp) vz0
real(rp) wavelength, thickness, absorption, phase_shift

integer ix_sec

logical err_flag

character(60) material

! If the plate/mask is turned off then all photons are simply transmitted through.

if (.not. ele%is_on) return

! Photon is lost if in an opaque section

ix_sec = diffraction_plate_or_mask_hit_spot (ele, orbit)

if (ix_sec == 0) then
  if (ele%wall3d(1)%opaque_material == '') then
    orbit%state = lost$
    return
  endif
  material = ele%wall3d(1)%opaque_material
  thickness = ele%wall3d(1)%thickness

else
  material = ele%wall3d(1)%clear_material
  thickness = ele%wall3d(1)%thickness
  sec => ele%wall3d(1)%section(ix_sec)
  if (sec%material /= '') material = sec%material
  if (sec%thickness >= 0) thickness = sec%thickness
endif

! Transmit through material

if (material /= '') then
  call photon_absorption_and_phase_shift (material, orbit%p0c, absorption, phase_shift, err_flag)
  if (err_flag) then
    orbit%state = lost$
    return
  endif

  orbit%field = orbit%field * exp(-absorption * thickness)
  orbit%phase = orbit%phase - phase_shift * thickness
endif

! Choose outgoing direction

vz0 = orbit%vec(6)
if (ele%key == diffraction_plate$) call point_photon_emission (ele, param, orbit, +1, twopi)

! Rescale field

wavelength = c_light * h_planck / orbit%p0c
orbit%field = orbit%field * (vz0 + orbit%vec(6)) / (2 * wavelength)
orbit%phase = orbit%phase - pi / 2

if (ele%value(field_scale_factor$) /= 0) then
  orbit%field = orbit%field * ele%value(field_scale_factor$)
endif

end subroutine track1_diffraction_plate_or_mask

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine track1_sample (ele, param, orbit)
!
! Routine to track reflection from a sample element.
!
! Input:
!   ele      -- ele_struct: Element tracking through.
!   param    -- lat_param_struct: lattice parameters.
!   orbit    -- Coord_struct: phase-space coords to be transformed
!
! Output:
!   orbit    -- Coord_struct: final phase-space coords
!-

subroutine track1_sample (ele, param, orbit)

type (ele_struct), target:: ele
type (coord_struct), target:: orbit
type (lat_param_struct) :: param

real(rp) w_surface(3,3), absorption, phase_shift

logical err_flag

character(*), parameter :: r_name = 'track1_sample'

!

call track_to_surface (ele, orbit)
if (orbit%state /= alive$) return

if (ele%photon%surface%has_curvature) call rotate_for_curved_surface (ele, orbit, set$, w_surface)

! Check aperture

if (ele%aperture_at == surface$) then
  call check_aperture_limit (orbit, ele, surface$, param)
  if (orbit%state /= alive$) return
endif

! Reflect 

select case (nint(ele%value(mode$)))
case (reflection$)

  call point_photon_emission (ele, param, orbit, -1, fourpi, w_surface)

case (transmission$)
  call photon_absorption_and_phase_shift (ele%component_name, orbit%p0c, absorption, phase_shift, err_flag)
  if (err_flag) then
    orbit%state = lost$
    return
  endif

  orbit%field = orbit%field * exp(-absorption * ele%value(l$))
  orbit%phase = orbit%phase - phase_shift * ele%value(l$)

case default
  call out_io (s_error$, r_name, 'MODE NOT SET.')
  orbit%state = lost$
end select

! Rotate back to uncurved element coords

if (ele%photon%surface%has_curvature) call rotate_for_curved_surface (ele, orbit, unset$, w_surface)

end subroutine track1_sample

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine point_photon_emission (ele, param, orbit, direction, max_target_area, w_to_surface)
!
! Routine to emit a photon from a point that may be on a surface.
! If there is a downstream target, the emission calc will take this into account.
!
! Input:
!   ele                -- ele_struct: Emitting element.
!   param              -- lat_param_struct: lattice parameters.
!   orbit              -- Coord_struct: phase-space coords of photon.
!                      --   Will be in curved surface coords if there is a curved surface.
!   direction          -- Integer: +1 -> Emit in forward +z direction, -1 -> emit backwards.
!   max_target_area    -- real(rp): Area of the solid angle photons may be emitted over.
!                           max_target_area is used for normalizing the photon field.
!                           generally will be equal to twopi or fourpi.
!   w_to_surface(3,3)  -- real(rp), optional: Rotation matrix for curved surface.
!
! Output:
!   orbit    -- Coord_struct: Final phase-space coords
!-

subroutine point_photon_emission (ele, param, orbit, direction, max_target_area, w_to_surface)

type (ele_struct), target:: ele
type (coord_struct), target:: orbit
type (ele_struct), pointer :: det_ele
type (lat_param_struct) :: param
type (photon_target_struct), pointer :: target
type (target_point_struct) corner(8)
type (surface_grid_struct), pointer :: gr

real(rp), optional :: w_to_surface(3,3)
real(rp) zran(2), r_particle(3), w_to_target(3,3), w_to_ele(3,3)
real(rp) phi_min, phi_max, y_min, y_max, y, phi, rho, r(3), max_target_area, cos2_dphi
real(rp) lb(2), ub(2), r_len, dr_x(3), dr_y(3), area

integer direction
integer n, i, ix, iy

!

target => ele%photon%target

select case (target%type)
case (rectangular$)
  r_particle = orbit%vec(1:5:2)
  r = target%center%r - r_particle
  if (ele%photon%surface%has_curvature) r = matmul(w_to_surface, r)
  call target_rot_mats (r, w_to_target, w_to_ele)

  do i = 1, target%n_corner
    r = target%corner(i)%r - r_particle
    if (direction == 1) then
      if (r(3) < 0) r(3) = 0   ! photon cannot be emitted backward
    elseif (direction == -1) then
      if (r(3) > 0) r(3) = 0   ! photon cannot be emitted forward
    else
      call err_exit
    endif
    if (ele%photon%surface%has_curvature) r = matmul(w_to_surface, r)
    r = matmul(w_to_target, r)
    corner(i)%r = r / norm2(r)
  enddo

  call target_min_max_calc (corner(4)%r, corner(1)%r, y_min, y_max, phi_min, phi_max, .true.)
  call target_min_max_calc (corner(1)%r, corner(2)%r, y_min, y_max, phi_min, phi_max)
  call target_min_max_calc (corner(2)%r, corner(3)%r, y_min, y_max, phi_min, phi_max)
  call target_min_max_calc (corner(3)%r, corner(4)%r, y_min, y_max, phi_min, phi_max)

  if (target%n_corner == 8) then
    call target_min_max_calc (corner(8)%r, corner(5)%r, y_min, y_max, phi_min, phi_max)
    call target_min_max_calc (corner(5)%r, corner(6)%r, y_min, y_max, phi_min, phi_max)
    call target_min_max_calc (corner(6)%r, corner(7)%r, y_min, y_max, phi_min, phi_max)
    call target_min_max_calc (corner(7)%r, corner(8)%r, y_min, y_max, phi_min, phi_max)
  endif

  if (y_min >= y_max .or. phi_min >= phi_max) then
    orbit%state = lost$
    return
  endif

  ! Correction for bulge in line projected onto (y, phi) sphere.

  cos2_dphi = cos((phi_max - phi_min)/2)**2

  if (y_max > 0) y_max = y_max / sqrt((1 - y_max**2) * cos2_dphi + y_max**2)
  if (y_min < 0) y_min = y_min / sqrt((1 - y_min**2) * cos2_dphi + y_min**2)

  !

  call ran_uniform(zran)
  y = y_min + (y_max-y_min) * zran(1)
  phi = phi_min + (phi_max-phi_min) * zran(2)
  rho = sqrt(1 - y*y)
  orbit%vec(2:6:2) = [rho * sin(phi), y, rho * cos(phi)]
  orbit%vec(2:6:2) = matmul(w_to_ele, orbit%vec(2:6:2))

  ! Field scaling

  if (photon_type(ele) == coherent$) then
    orbit%field = orbit%field * (y_max - y_min) * (phi_max - phi_min) / max_target_area
    ! If path_len = 0 then assume that photon is being initialized so only normalize field if path_len /= 0
    if (orbit%path_len /= 0) then
      orbit%field = orbit%field * orbit%path_len
      orbit%path_len = 0
    endif
  else
    orbit%field = orbit%field * sqrt ((y_max - y_min) * (phi_max - phi_min) / max_target_area)
  endif

! Grid target

case (grided$)
  r_particle = orbit%vec(1:5:2)
  r = target%center%r - r_particle
  if (ele%photon%surface%has_curvature) r = matmul(w_to_surface, r)
  call target_rot_mats (r, w_to_target, w_to_ele)

  det_ele => pointer_to_ele(ele%branch%lat, target%ele_loc)
  gr => det_ele%photon%surface%grid
  lb = lbound(gr%pt); ub = ubound(gr%pt)

  if (target%deterministic_grid) then
    ix = target%ix_grid
    iy = target%iy_grid
  else
    call ran_uniform(zran)
    ix = lb(1) + int((ub(1) - lb(1) + 1 - 1d-10) * zran(1))
    iy = lb(2) + int((ub(2) - lb(2) + 1 - 1d-10) * zran(2))
  endif
  
  r = target%center%r + ix * (target%corner(1)%r - target%center%r) + &
                        iy * (target%corner(2)%r - target%center%r) - r_particle
  r = matmul (w_to_target, r)
  r_len = norm2(r)
  r = r / r_len
  y = r(2)
  rho = sqrt(1 - y*y)
  r = matmul(w_to_ele, [rho * r(1), y, rho * r(3)])
  orbit%vec(2:6:2) = r

  ! Field scaling

  dr_x = matmul(w_to_ele, target%corner(1)%r - target%center%r)
  dr_y = matmul(w_to_ele, target%corner(2)%r - target%center%r)
  area = norm2(cross_product(dr_x, r)) * norm2(cross_product(dr_y, r)) / r_len**2

  if (photon_type(ele) == coherent$) then
    orbit%field = orbit%field * area / max_target_area
    if (orbit%path_len /= 0) then
      orbit%field = orbit%field * orbit%path_len
      orbit%path_len = 0
    endif
  else
    orbit%field = orbit%field * sqrt(area / max_target_area)
  endif

! No targeting

case (off$)
  call ran_uniform(zran)
  y = 2 * zran(1) - 1
  phi = pi * (zran(2) - 0.5_rp)
  rho = sqrt(1 - y**2)
  orbit%vec(2:6:2) = [rho * sin(phi), y, direction * rho * cos(phi)]
  ! Without targeting photons are emitted into twopi solid angle.
  if (photon_type(ele) == coherent$) then
    orbit%field = orbit%field * twopi / max_target_area
    ! If path_len = 0 then assume that photon is being initialized so only normalize field if path_len /= 0
    if (orbit%path_len /= 0) then
      orbit%field = orbit%field * orbit%path_len
      orbit%path_len = 0
    endif
  else
    orbit%field = orbit%field * sqrt(twopi / max_target_area)
  endif

case default
  call err_exit  ! Internal bookkeeping error
end select

end subroutine point_photon_emission 

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine track1_mirror (ele, param, orbit)
!
! Routine to track reflection from a mirror.
!
! Input:
!   ele      -- ele_struct: Element tracking through.
!   param    -- lat_param_struct: lattice parameters.
!   orbit    -- Coord_struct: phase-space coords to be transformed
!
! Output:
!   orbit    -- Coord_struct: final phase-space coords
!-

subroutine track1_mirror (ele, param, orbit)

type (ele_struct), target:: ele
type (coord_struct), target:: orbit
type (lat_param_struct) :: param

real(rp) wavelength, w_surface(3,3)
real(rp), pointer :: val(:)

character(*), parameter :: r_name = 'track1_mirror'

!

val => ele%value
wavelength = c_light * h_planck / orbit%p0c

call track_to_surface (ele, orbit)
if (orbit%state /= alive$) return

if (ele%photon%surface%has_curvature) call rotate_for_curved_surface (ele, orbit, set$, w_surface)

! Check aperture

if (ele%aperture_at == surface$) then
  call check_aperture_limit (orbit, ele, surface$, param)
  if (orbit%state /= alive$) return
endif

! Reflect momentum vector

orbit%vec(6) = -orbit%vec(6)

! Rotate back to uncurved element coords

if (ele%photon%surface%has_curvature) call rotate_for_curved_surface (ele, orbit, unset$, w_surface)

end subroutine track1_mirror

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine track1_multilayer_mirror (ele, param, orbit)
!
! Routine to track reflection from a multilayer_mirror.
! Basic equations are from Kohn, "On the Theory of Reflectivity of an X-Ray Multilayer Mirror".
!
! Input:
!   ele    -- ele_struct: Element tracking through.
!   param  -- lat_param_struct: lattice parameters.
!   orbit    -- Coord_struct: phase-space coords to be transformed
!
! Output:
!   orbit    -- Coord_struct: final phase-space coords
!-

subroutine track1_multilayer_mirror (ele, param, orbit)

type (ele_struct), target:: ele
type (coord_struct), target:: orbit
type (lat_param_struct) :: param

real(rp) wavelength, kz_air, w_surface(3,3)
real(rp), pointer :: val(:)

complex(rp) zero, xi_1, xi_2, kz1, kz2, c1, c2

character(*), parameter :: r_name = 'track1_multilayer_mirror'

!

val => ele%value
wavelength = c_light * h_planck / orbit%p0c

call track_to_surface (ele, orbit)
if (orbit%state /= alive$) return

if (ele%photon%surface%has_curvature) call rotate_for_curved_surface (ele, orbit, set$, w_surface)

! Check aperture

if (ele%aperture_at == surface$) then
  call check_aperture_limit (orbit, ele, surface$, param)
  if (orbit%state /= alive$) return
endif

! Note: Koln z-axis = Bmad x-axis.
! Note: f0_re and f0_im are both positive.

xi_1 = -conjg(ele%photon%material%f0_m1) * r_e * wavelength**2 / (pi * val(v1_unitcell$)) 
xi_2 = -conjg(ele%photon%material%f0_m2) * r_e * wavelength**2 / (pi * val(v2_unitcell$)) 

kz1 = twopi * sqrt(orbit%vec(6)**2 + xi_1) / wavelength
kz2 = twopi * sqrt(orbit%vec(6)**2 + xi_2) / wavelength
kz_air = twopi * orbit%vec(6) / wavelength

c1 = exp(I_imaginary * kz1 * val(d1_thickness$) / 2)
c2 = exp(I_imaginary * kz2 * val(d2_thickness$) / 2)

zero = cmplx(0.0_rp, 0.0_rp, rp)

call multilayer_track (xi_1, xi_2, orbit%field(1), orbit%phase(1))     ! pi polarization
call multilayer_track (zero, zero, orbit%field(2), orbit%phase(2))     ! sigma polarization

! Reflect momentum vector

orbit%vec(6) = -orbit%vec(6)

! Rotate back to uncurved element coords

if (ele%photon%surface%has_curvature) call rotate_for_curved_surface (ele, orbit, unset$, w_surface)

!-----------------------------------------------------------------------------------------------
contains

subroutine multilayer_track (xi1_coef, xi2_coef, e_field, e_phase)

real(rp) e_field, e_phase

complex(rp) xi1_coef, xi2_coef, r_11, r_22, tt, denom, k1, k2
complex(rp) a, v, f_minus, f_plus, r_ratio, f, r, ttbar, nu, exp_half, exp_n
complex(rp) Rc_n_top, R_tot, k_a, r_aa, Rc_1_bot, Rc_1_top

integer i, n1

! Rc_n_top is the field ratio for the top layer of cell n.
! Rc_n_bot is the field ratio for the bottom layer of cell n.
! Rc_1_bot for the bottom layer just above the substrate is assumed to be zero.
! Upgrade: If we knew the substrate material we would not have to make this assumption.

Rc_1_bot = 0

! Compute Rc_1_top.
! The top layer of a cell is labeled "2" and the bottom "1". See Kohn Eq 6.

k1 = (1 + xi2_coef) * kz1
k2 = (1 + xi1_coef) * kz2
denom = k1 + k2

r_11 = c1**2 * (k1 - k2) / denom
r_22 = c2**2 * (k2 - k1) / denom

tt = 4 * k1 * k2 * (c1 * c2 / denom)**2    ! = t_12 * t_21

Rc_1_top = r_22 + tt * Rc_1_bot / (1 - r_11 * Rc_1_bot)

! Now compute the single cell factors. See Kohn Eq. 12.
! Note: If you go through the math you will find r = r_bar.

f = tt / (1 - r_11**2)
r = r_22 + r_11 * f
ttbar = f**2

! Calc Rc_n_top. See Kohn Eq. 21. Note that there are n-1 cells in between. 

a = (1 - ttbar + r**2) / 2
nu = (1 + ttbar - r**2) / (2 * sqrt(ttbar))
n1 = nint(val(n_cell$)) - 1

exp_half = nu + I_imaginary * sqrt(1 - nu**2)
exp_n = exp_half ** (2 * n1)
f_plus  = a - I_imaginary * sqrt(ttbar) * sqrt(1 - nu**2)
f_minus = a + I_imaginary * sqrt(ttbar) * sqrt(1 - nu**2)
Rc_n_top = r * (r - Rc_1_top * f_minus - (r - Rc_1_top * f_plus) * exp_n) / &
               (f_plus * (r - Rc_1_top * f_minus) - f_minus * (r - Rc_1_top * f_plus) * exp_n)

! Now factor in the air interface

k_a = kz_air
denom = k_a + k2

tt = 4 * k_a * k2 * (c2 / denom)**2
r_aa = (k_a - k2) / denom
r_22 = c2**2 * (k2 - k_a) / denom

R_tot = r_aa + tt * Rc_n_top / (1 - r_22 * Rc_n_top)

e_field = e_field * abs(R_tot)
e_phase = e_phase + atan2(aimag(R_tot), real(R_tot))

end subroutine multilayer_track 

end subroutine track1_multilayer_mirror

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine track1_crystal (ele, param, orbit)
!
! Routine to track reflection from a crystal.
!
! Input:
!   ele      -- ele_struct: Element tracking through.
!   param    -- lat_param_struct: lattice parameters.
!   orbit    -- Coord_struct: phase-space coords to be transformed
!
! Output:
!   orbit    -- Coord_struct: final phase-space coords
!-

subroutine track1_crystal (ele, param, orbit)

type (ele_struct), target:: ele
type (coord_struct), target:: orbit
type (lat_param_struct) :: param
type (crystal_param_struct) cp

real(rp) h_bar(3), e_tot, pc, p_factor, field1, field2, w_surface(3,3)
real(rp) gamma_0, gamma_h, dr1(3), dr2(3)

character(*), parameter :: r_name = 'track1_cyrstal'

! A graze angle of zero means the wavelength of the reference photon was too large
! for the bragg condition. 

if (orbit_too_large(orbit, param)) return

if (ele%value(bragg_angle_in$) == 0) then
  call out_io (s_fatal$, r_name, 'REFERENCE ENERGY TOO SMALL TO SATISFY BRAGG CONDITION!')
  orbit%state = lost_pz_aperture$
  if (global_com%exit_on_error) call err_exit
  return
endif

if (ele%value(b_param$) > 0 .and. ele%value(thickness$) == 0) then 
  call out_io (s_error$, r_name, 'LAUE CRYSTAL WITH ZERO THICKNESS WILL HAVE NO DIFFRACTION: ' // ele%name)
endif

!

cp%wavelength = c_light * h_planck / orbit%p0c
cp%cap_gamma = r_e * cp%wavelength**2 / (pi * ele%value(v_unitcell$)) 

! (px, py, pz) coords are with respect to laboratory reference trajectory.
! Convert this vector to k0_outside_norm which are coords with respect to crystal surface.
! k0_outside_norm is normalized to 1.

call track_to_surface (ele, orbit)
if (orbit%state /= alive$) return

if (ele%photon%surface%has_curvature) call rotate_for_curved_surface (ele, orbit, set$, w_surface)

cp%old_vvec = orbit%vec(2:6:2)

! Check aperture

if (ele%aperture_at == surface$) then
  call check_aperture_limit (orbit, ele, surface$, param)
  if (orbit%state /= alive$) return
endif

! Construct h_bar = H * wavelength.

h_bar = ele%photon%material%h_norm
if (ele%photon%surface%grid%type == h_misalign$) call crystal_h_misalign (ele, orbit, h_bar) 
h_bar = h_bar * cp%wavelength / ele%value(d_spacing$)

! cp%new_vvec is the normalized outgoing wavevector outside the crystal

cp%new_vvec = orbit%vec(2:6:2) + h_bar

if (ele%value(b_param$) < 0) then ! Bragg
  cp%new_vvec(3) = -sqrt(1 - cp%new_vvec(1)**2 - cp%new_vvec(2)**2)
else
  cp%new_vvec(3) = sqrt(1 - cp%new_vvec(1)**2 - cp%new_vvec(2)**2)
endif

! Calculate some parameters

gamma_0 = cp%old_vvec(3)
gamma_h = cp%new_vvec(3)

cp%b_eff = gamma_0 / gamma_h
cp%dtheta_sin_2theta = -dot_product(h_bar + 2 * cp%old_vvec, h_bar) / 2

! E field calc

p_factor = cos(ele%value(bragg_angle_in$) + ele%value(bragg_angle_out$))
call crystal_diffraction_field_calc (cp, orbit, ele, param, p_factor, .true.,  field1, orbit%phase(1), dr1)
call crystal_diffraction_field_calc (cp, orbit, ele, param, 1.0_rp,   .false., field2, orbit%phase(2), dr2)   ! Sigma pol

orbit%field(1) = orbit%field(1) * field1
orbit%field(2) = orbit%field(2) * field2

! For Laue: Average trajectories for the two polarizations weighted by the fields.
! This approximation is valid as long as the two trajectories are "close" enough.

if (ele%value(b_param$) > 0 .and. (field1 /= 0 .or. field2 /= 0)) then ! Laue
  orbit%vec(1:5:2) = orbit%vec(1:5:2) + (dr1 * field1 + dr2 * field2) / (field1 + field2)
endif

! Rotate back from curved body coords to element coords

if (ele%value(b_param$) < 0) then ! Bragg
  orbit%vec(2:6:2) = cp%new_vvec
else
  ! forward_diffracted and undiffracted beams do not have an orientation change.
  if (nint(ele%value(ref_orbit_follows$)) == bragg_diffracted$) orbit%vec(2:6:2) = cp%new_vvec
endif

if (ele%photon%surface%has_curvature) call rotate_for_curved_surface (ele, orbit, unset$, w_surface)

end subroutine track1_crystal

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine track_to_surface (ele, orbit)
!
! Routine to track a photon to the surface of the element.
!
! After calling this routine, if the surface is curved, the routine rotate_for_curved_surface should
! be called to rotate the photon's velocity coordinates to the local surface coordinate system.
!
! Input:
!   ele                 -- ele_struct: Element
!   orbit               -- coord_struct: Coordinates in the element coordinate frame
!   curved_surface_rot  -- Logical, optional, If present and False then do not rotate velocity coords.
!
! Output:
!   orbit      -- coord_struct: At surface in local surface coordinate frame
!     %state     -- set to lost$ if the photon does not intersect the surface (can happen when surface is curved).
!   err        -- logical: Set true if surface intersection cannot be found. 
!-

subroutine track_to_surface (ele, orbit, curved_surface_rot)

use super_recipes_mod

type (ele_struct) ele
type (coord_struct) orbit
type (segmented_surface_struct), pointer :: segment

real(rp) :: s_len, s1, s2, s_center, x0, y0, z
integer status 

character(*), parameter :: r_name = 'track_to_surface'
logical, optional :: curved_surface_rot

! If there is curvature, compute the reflection point which is where 
! the photon intersects the surface.

if (ele%photon%surface%has_curvature) then

  ele%photon%surface%segment%ix = int_garbage$; ele%photon%surface%segment%iy = int_garbage$

  ! Assume flat crystal, compute s required to hit the intersection

  s_center = orbit%vec(5) / orbit%vec(6)

  s1 = s_center
  s2 = s_center
  z = photon_depth_in_element(s_center, status); if (status /= 0) return
  if (z > 0) then
    do
      s1 = s1 - 0.1
      z = photon_depth_in_element(s1, status); if (status /= 0) return
      if (z < 0) exit
      if (s1 < -10) then
        !! call out_io (s_warn$, r_name, &
        !!      'PHOTON INTERSECTION WITH SURFACE NOT FOUND FOR ELEMENT: ' // ele%name)
        orbit%state = lost$
        return
      endif
    enddo
  else
    do
      s2 = s2 + 0.1
      z = photon_depth_in_element(s2, status); if (status /= 0) return
      if (z > 0) exit
      if (s1 > 10) then
        !! call out_io (s_warn$, r_name, &
        !!      'PHOTON INTERSECTION WITH SURFACE NOT FOUND FOR ELEMENT: ' // ele%name)
        orbit%state = lost$
        return
      endif
    enddo
  endif

  s_len = super_zbrent (photon_depth_in_element, s1, s2, 0.0_rp, 1d-10, status)
  if (orbit%state == lost$) return

  ! Compute the intersection point

  orbit%vec(1:5:2) = s_len * orbit%vec(2:6:2) + orbit%vec(1:5:2)
  orbit%t = orbit%t + s_len / c_light

else
  s_len = -orbit%vec(5) / orbit%vec(6)
  orbit%vec(1:5:2) = orbit%vec(1:5:2) + s_len * orbit%vec(2:6:2) ! Surface is at z = 0
  orbit%t = orbit%t + s_len / c_light
endif

contains

!-----------------------------------------------------------------------------------------------
!+
! Function photon_depth_in_element (s_len, status) result (delta_h)
! 
! Private routine to be used as an argument in zbrent. Propagates
! photon forward by a distance s_len. Returns delta_h = z-z0
! where z0 is the height of the element surface. 
! Since positive z points inward, positive delta_h => inside element.
!
! Input:
!   s_len   -- real(rp): Place to position the photon.
!
! Output:
!   delta_h -- real(rp): Depth of photon below surface in crystal coordinates.
!   status  -- integer: 0 -> Calculation OK.
!                       1 -> Calculation not OK.
!-

function photon_depth_in_element (s_len, status) result (delta_h)

real(rp), intent(in) :: s_len
real(rp) :: delta_h
real(rp) :: point(3)

integer status

!

point = s_len * orbit%vec(2:6:2) + orbit%vec(1:5:2)
delta_h = point(3) - z_at_surface(ele, point(1), point(2), status)
if (status /= 0) orbit%state = lost$

end function photon_depth_in_element

end subroutine track_to_surface

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine rotate_for_curved_surface (ele, orbit, set, rot_mat)
!
! Routine to rotate just the velocity coords between element body coords and effective 
! body coords ("curved body coords") with respect to the surface at the point of photon impact.
!
! To rotate the photon coords back to the the element body coords, the inverse of the rotation 
! matrix usedto transform from element body coords is needed. Thus rot_mat must be saved between 
! calls to this routine with set = True and set = False.
!
! Input:
!   ele          -- ele_struct: reflecting element
!   orbit        -- coord_struct: Photon position.
!   set          -- Logical: True -> Transform body coords to local curved body coords. 
!                            False -> Transform local curved body to body coords.
!   rot_mat(3,3) -- real(rp): When set = False, rotation matrix calculated from previous call with set = True.
!
! Output:
!   orbit        -- coord_struct: Photon position.
!   rot_mat(3,3) -- real(rp): When set = True, calculated rotation matrix.
!-

subroutine rotate_for_curved_surface (ele, orbit, set, rot_mat)

type (ele_struct), target :: ele
type (coord_struct) orbit
type (photon_surface_struct), pointer :: s

real(rp) rot_mat(3,3)
real(rp) rot(3,3), angle
real(rp) slope_y, slope_x, x, y, zt, g(3)
integer ix, iy

logical set

! Transform from local curved to body coords.

if (.not. set) then
  rot = transpose(rot_mat)
  orbit%vec(2:6:2) = matmul(rot, orbit%vec(2:6:2))
  return
endif

! Compute the slope of the surface at that the point of impact.
! curve_rot transforms from standard body element coords to body element coords at point of impact.

s => ele%photon%surface
x = orbit%vec(1)
y = orbit%vec(3)

if (s%grid%type == segmented$) then
  call init_surface_segment (x, y, ele)
  slope_x = s%segment%slope_x; slope_y = s%segment%slope_y

else

  slope_x = 0
  slope_y = 0

  do ix = 0, ubound(s%curvature_xy, 1)
  do iy = 0, ubound(s%curvature_xy, 2) - ix
    if (s%curvature_xy(ix, iy) == 0) cycle
    if (ix > 0) slope_x = slope_x - ix * s%curvature_xy(ix, iy) * x**(ix-1) * y**iy
    if (iy > 0) slope_y = slope_y - iy * s%curvature_xy(ix, iy) * x**ix * y**(iy-1)
  enddo
  enddo

  g = s%spherical_curvature + s%elliptical_curvature
  if (g(3) /= 0) then
    zt = sqrt(1 - sign_of(g(1)) * (x * g(1))**2 - sign_of(g(2)) * (y * g(2))**2)
    slope_x = slope_x - x * sign_of(g(1)) * g(1)**2 / (g(3) * zt)
    slope_y = slope_y - y * sign_of(g(2)) * g(2)**2 / (g(3) * zt)
  endif
endif

if (slope_x == 0 .and. slope_y == 0) then
  call mat_make_unit(rot_mat)
  return
endif

! Compute rotation matrix and goto body element coords at point of photon impact

angle = -atan2(sqrt(slope_x**2 + slope_y**2), 1.0_rp)
call axis_angle_to_w_mat ([slope_y, -slope_x, 0.0_rp], angle, rot_mat)

orbit%vec(2:6:2) = matmul(rot_mat, orbit%vec(2:6:2))

end subroutine rotate_for_curved_surface

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine crystal_h_misalign (ele, orbit, h_vec)
!
! Routine reorient the crystal H vector due to local imperfections in the crystal lattice.
!
! Input:
!   ele      -- ele_struct: Crystal element
!   orbit    -- coord_struct: Photon position at crystal surface.
!   h_vec(3) -- real(rp): H vector before misalignment.
!
! Output:
!   h_vec(3) -- real(rp): H vector after misalignment.
!-

subroutine crystal_h_misalign (ele, orbit, h_vec)

type (ele_struct), target :: ele
type (coord_struct) orbit
type (photon_surface_struct), pointer :: s
type (surface_orientation_struct), pointer :: orient

real(rp) h_vec(3), r(2)
integer ij(2)
character(*), parameter :: r_name = 'crystal_h_misalign'

!

s => ele%photon%surface

ij = nint((orbit%vec(1:3:2) + s%grid%r0) / s%grid%dr)

if (any(ij < lbound(s%grid%pt)) .or. any(ij > ubound(s%grid%pt))) then
  call out_io (s_error$, r_name, &
              'Photon position on crystal surface outside of grid bounds for element: ' // ele%name)
  return
endif

! Make small angle approximation

orient => s%grid%pt(ij(1), ij(2))%orientation

h_vec(1:2) = h_vec(1:2) + [orient%dz_dx, orient%dz_dy]
if (orient%dz_dx_rms /= 0 .or. orient%dz_dy /= 0) then
  call ran_gauss (r)
  h_vec(1:2) = h_vec(1:2) + [orient%dz_dx_rms, orient%dz_dy_rms] * r
endif

h_vec(3) = sqrt(1 - h_vec(1)**2 - h_vec(2)**2)

end subroutine crystal_h_misalign

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine target_rot_mats (r_center, w_to_target, w_to_ele)
!
! Routine to calculate the rotation matrices between ele coords and "target" coords.
! By definition, in target coords r_center = [0, 0, 1].
!
! Input:
!   r_center(3)   -- real(rp): In lab coords: Center of target relative to phton emission point.
!
! Output:
!   w_to_target(3,3) -- real(rp): Rotation matrix from ele to target coords.
!   w_to_ele(3,3)    -- real(rp): Rotation matrix from target to ele coords.
!-

subroutine target_rot_mats (r_center, w_to_target, w_to_ele)

real(rp) r_center(3), w_to_target(3,3), w_to_ele(3,3)
real(rp) r(3), cos_theta, sin_theta, cos_phi, sin_phi

!

r = r_center / norm2(r_center)
sin_phi = r(2)
cos_phi = sqrt(r(1)**2 + r(3)**2)
if (cos_phi == 0) then
  sin_theta = 0  ! Arbitrary
  cos_theta = 1
else
  sin_theta = r(1) / cos_phi
  cos_theta = r(3) / cos_phi
endif

w_to_ele(1,:) = [ cos_theta, -sin_theta * sin_phi, sin_theta * cos_phi]
w_to_ele(2,:) = [ 0.0_rp,     cos_phi,             sin_phi]
w_to_ele(3,:) = [-sin_theta, -cos_theta * sin_phi, cos_theta * cos_phi]

w_to_target(1,:) = [ cos_theta,           0.0_rp,  -sin_theta]
w_to_target(2,:) = [-sin_theta * sin_phi, cos_phi, -cos_theta * sin_phi]
w_to_target(3,:) = [ sin_theta * cos_phi, sin_phi,  cos_theta * cos_phi]

end subroutine target_rot_mats

!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!-----------------------------------------------------------------------------------------------
!+
! Subroutine target_min_max_calc (r_corner1, r_corner2, y_min, y_max, phi_min, phi_max, initial)
!
! Routine to calculate the min/max values for (y, phi).
! min/max values are cumulative.
!
! Input:
!   r_corner1(3)     -- real(rp): In target coords: A corner of the target. Must be normalized to 1.
!   r_corner2(3)     -- real(rp): In target coords: Adjacent corner of the target. Must be normalized to 1.
!   y_min, y_max     -- real(rp): min/max values. Only needed if initial = False.
!   phi_min, phi_max -- real(rp): min/max values. Only needed if initial = False.
!   initial          -- logical, optional: If present and True then this is the first edge for computation.
!
! Output:
!   y_min, y_max     -- real(rp): min/max values. 
!   phi_min, phi_max -- real(rp): min/max values. 
!-

subroutine target_min_max_calc (r_corner1, r_corner2, y_min, y_max, phi_min, phi_max, initial)

real(rp)  r_corner1(3), r_corner2(3), y_min, y_max, phi_min, phi_max
real(rp) phi1, phi2, k, t, alpha, beta, y

logical, optional :: initial

!

phi1 = atan2(r_corner1(1), r_corner1(3))
phi2 = atan2(r_corner2(1), r_corner2(3))

if (logic_option(.false., initial)) then
  y_max = max(r_corner1(2), r_corner2(2))
  y_min = min(r_corner1(2), r_corner2(2))
  phi_max = max(phi1, phi2)
  phi_min = min(phi1, phi2)
else
  y_max = max(y_max, r_corner1(2), r_corner2(2))
  y_min = min(y_min, r_corner1(2), r_corner2(2))
  phi_max = max(phi_max, phi1, phi2)
  phi_min = min(phi_min, phi1, phi2)
endif

k = dot_product(r_corner1, r_corner2)
t = abs(k * r_corner1(2) - r_corner2(2)) 
alpha = t / sqrt((1-k**2)*(1-k**2 + t**2))

if (alpha < 1) then
  beta = sqrt((alpha * k)**2 + 1 - alpha**2) - alpha * k
  y = r_corner1(2) * alpha + r_corner2(2) * beta
  y_max = max(y_max, y)
  y_min = min(y_min, y)
endif

end subroutine target_min_max_calc

!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!---------------------------------------------------------------------------
!+
! Subroutine track_a_bend_photon (orb, ele, length)
!
! Routine to track a photon through a dipole bend.
! The photon is traveling in a straight line but the reference frame
! is curved in a circular shape.
!
! Input:
!   orb        -- Coord_struct: Starting position.
!   ele        -- Ele_struct: Bend element.
!   length     -- real(rp): length to track.
!
! Output:
!   orb         -- Coord_struct: End position.
!-

subroutine track_a_bend_photon (orb, ele, length)

type (coord_struct) orb
type (ele_struct) ele

real(rp) length
real(rp) g, radius, theta, tan_t, dl, st, ct, denom, sin_t, cos_t
real(rp) v_x, v_s

!

g = ele%value(g$)

! g = 0 case

if (g == 0) then
  call track_a_drift_photon (orb, length, .true.)
  return
endif

! Normal case

if (ele%value(ref_tilt_tot$) /= 0) call tilt_coords_photon (ele%value(ref_tilt_tot$), orb%vec)

radius = 1 / g
theta = length * g
tan_t = tan(theta)
dl = tan_t * (radius + orb%vec(1)) / (orb%vec(6) - tan_t * orb%vec(2))

! Move to the stop point. 
! Need to remember that radius can be negative.

st = dl * orb%vec(6)
ct = radius + orb%vec(1) + dl * orb%vec(2)
if (abs(st) < 1d-3 * ct) then
  denom = sign (ct * (1 + (st/ct)**2/2 + (st/ct)**4/8), radius)
else
  denom = sign (sqrt((radius + orb%vec(1) + dl * orb%vec(2))**2 + (dl * orb%vec(6))**2), radius)
endif
sin_t = st / denom
cos_t = ct / denom
v_x = orb%vec(2); v_s = orb%vec(6)

orb%vec(1) = denom - radius
orb%vec(2) = v_s * sin_t + v_x * cos_t
orb%vec(3) = orb%vec(3) + dl * orb%vec(4)
orb%vec(5) = orb%vec(5) + length
orb%vec(6) = v_s * cos_t - v_x * sin_t
orb%s      = orb%s + length
orb%t      = orb%t + length * orb%vec(6) / c_light

if (ele%value(ref_tilt_tot$) /= 0) call tilt_coords_photon (-ele%value(ref_tilt_tot$), orb%vec)

end subroutine track_a_bend_photon

end module
