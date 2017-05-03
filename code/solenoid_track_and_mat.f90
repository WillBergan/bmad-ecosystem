!+
! Subroutine solenoid_track_and_mat (ele, length, param, start_orb, end_orb, mat6)
!
! Routine to track a particle through a solenoid element.
!
! Input:
!   ele          -- Ele_struct: Solenoid element.
!   length       -- real(rp): Length to track
!   param        -- lat_param_struct: Lattice parameters.
!   start_orb    -- Coord_struct: Starting position.
!   make_matrix  -- Logical: If True then make the transfer matrix.
!
! Output:
!   end_orb      -- Coord_struct: End position.
!   mat6(6,6)    -- real(rp), optional :: Transfer matrix. 
!-

subroutine solenoid_track_and_mat (ele, length, param, start_orb, end_orb, mat6)

use make_mat6_mod, except_dummy => solenoid_track_and_mat

implicit none

type (ele_struct), target :: ele
type (lat_param_struct) param
type (coord_struct) start_orb, end_orb

real(rp), optional :: mat6(:,:)
real(rp) ks, rel_p, length, kss, c, s, c2, s2, cs, c2s2, ll, kssl, kssl2, ks0, kss0
real(rp) mat4(4,4), xp, yp, pz, rel_tracking_charge, ff, e_tot, lpz
real(rp) dpz_dx, dpz_dpx, dpz_dy, dpz_dpy, vec0(6)

!

vec0 = start_orb%vec
end_orb = start_orb
rel_p = 1 + start_orb%vec(6)
rel_tracking_charge = rel_tracking_charge_to_mass(start_orb, param)

ks0 = rel_tracking_charge * ele%value(ks$)
kss0 = ks0 / 2

xp = end_orb%vec(2) + kss0 * end_orb%vec(3)
yp = end_orb%vec(4) - kss0 * end_orb%vec(1)
pz = sqrt(rel_p**2 - xp**2 - yp**2)

end_orb%vec(5) = end_orb%vec(5) + length * ((end_orb%beta * ele%value(E_tot$) / ele%value(p0c$)) - rel_p/pz)

ks = ks0 / pz
kss = ks / 2
kssl = kss * length 

if (abs(length * kss) < 1d-10) then
  ll = length
  kssl2 = kssl**2

  mat4(1,:) = [ 1.0_rp,      ll/pz,      kssl,        kssl*ll/pz]
  mat4(2,:) = [-kssl*kss0,   1.0_rp,    -kssl2*kss0,  kssl      ]
  mat4(3,:) = [-kssl,       -kssl*ll/pz, 1.0_rp,      ll/pz     ]
  mat4(4,:) = [ kssl2*kss0, -kssl,      -kssl*kss0,   1.0_rp    ]

else
  c = cos(kssl)
  s = sin(kssl)
  c2 = c*c
  s2 = s*s
  cs = c*s

  mat4(1,1) = c2
  mat4(1,2) = cs / kss0
  mat4(1,3) = cs
  mat4(1,4) = s2 / kss0

  mat4(2,1) = -kss0 * cs
  mat4(2,2) = c2
  mat4(2,3) = -kss0 * s2 
  mat4(2,4) = cs

  mat4(3,1) = -cs
  mat4(3,2) = -s2 / kss0
  mat4(3,3) = c2
  mat4(3,4) = cs / kss0

  mat4(4,1) = kss0 * s2
  mat4(4,2) = -cs
  mat4(4,3) = -kss0 * cs
  mat4(4,4) = c2
endif

! Track

end_orb%vec(1:4) = matmul (mat4, vec0(1:4))
end_orb%t = end_orb%t + length * rel_p / (pz * end_orb%beta * c_light)

if (end_orb%direction == 1) then
  end_orb%s = ele%s
else
  end_orb%s = ele%s_start
endif

! Mat6

if (.not. present(mat6)) return

if (abs(length * kss) < 1d-10) then ! must define c, s, etc.
  c = 1
  s = kssl
  c2 = 1
  s2 = kssl**2
  cs = kssl
endif

dpz_dx  =  yp * kss0 / pz
dpz_dpx = -xp / pz
dpz_dy  = -xp * kss0 / pz
dpz_dpy = -yp / pz
c2s2 = c2 - s2
lpz = length / pz

mat6 = 0

ff = -2 * kss0 * vec0(1) * cs + vec0(2) * c2s2 + kss0 * vec0(3) * c2s2 + 2 * vec0(4) * cs
mat6(1,1) = mat4(1,1) - ff * dpz_dx  * lpz / pz
mat6(1,2) = mat4(1,2) - ff * dpz_dpx * lpz / pz
mat6(1,3) = mat4(1,3) - ff * dpz_dy  * lpz / pz
mat6(1,4) = mat4(1,4) - ff * dpz_dpy * lpz / pz

ff = -vec0(1) * kss0 * c2s2 - 2 * vec0(2) * cs - 2 * vec0(3) * kss0 * cs + vec0(4) * c2s2
mat6(2,1) = mat4(2,1) - ff * dpz_dx  * kssl / pz
mat6(2,2) = mat4(2,2) - ff * dpz_dpx * kssl / pz
mat6(2,3) = mat4(2,3) - ff * dpz_dy  * kssl / pz
mat6(2,4) = mat4(2,4) - ff * dpz_dpy * kssl / pz

ff = -kss0 * vec0(1) * c2s2 - 2 * vec0(2) * cs - 2 * kss0 * vec0(3) * cs + vec0(4) * c2s2
mat6(3,1) = mat4(3,1) - ff * dpz_dx  * lpz / pz
mat6(3,2) = mat4(3,2) - ff * dpz_dpx * lpz / pz
mat6(3,3) = mat4(3,3) - ff * dpz_dy  * lpz / pz
mat6(3,4) = mat4(3,4) - ff * dpz_dpy * lpz / pz

ff = 2 * vec0(1) * kss0 * cs - vec0(2) * c2s2 - vec0(3) * kss0 * c2s2 - 2 * vec0(4) * cs
mat6(4,1) = mat4(4,1) - ff * dpz_dx  * kssl / pz
mat6(4,2) = mat4(4,2) - ff * dpz_dpx * kssl / pz
mat6(4,3) = mat4(4,3) - ff * dpz_dy  * kssl / pz
mat6(4,4) = mat4(4,4) - ff * dpz_dpy * kssl / pz


! the mat6(i,6) terms are constructed so that mat6 is sympelctic

mat6(5,1) = dpz_dx  * length * rel_p / pz**2
mat6(5,2) = dpz_dpx * length * rel_p / pz**2
mat6(5,3) = dpz_dy  * length * rel_p / pz**2
mat6(5,4) = dpz_dpy * length * rel_p / pz**2
mat6(5,5) = 1

mat6(1,6) = mat6(5,2) * mat6(1,1) - mat6(5,1) * mat6(1,2) + mat6(5,4) * mat6(1,3) - mat6(5,3) * mat6(1,4)
mat6(2,6) = mat6(5,2) * mat6(2,1) - mat6(5,1) * mat6(2,2) + mat6(5,4) * mat6(2,3) - mat6(5,3) * mat6(2,4)
mat6(3,6) = mat6(5,4) * mat6(3,3) - mat6(5,3) * mat6(3,4) + mat6(5,2) * mat6(3,1) - mat6(5,1) * mat6(3,2)
mat6(4,6) = mat6(5,4) * mat6(4,3) - mat6(5,3) * mat6(4,4) + mat6(5,2) * mat6(4,1) - mat6(5,1) * mat6(4,2)
mat6(6,6) = 1

! mat6(5,6) 

e_tot = ele%value(p0c$) * (1 + vec0(6)) / start_orb%beta
mat6(5,6) = length * (mass_of(start_orb%species)**2 * ele%value(e_tot$) / e_tot**3 - 1/pz + (rel_p/pz)**2 / pz)

if (ele%value(tilt_tot$) /= 0) then
  call tilt_mat6 (mat6, ele%value(tilt_tot$))
endif

end subroutine solenoid_track_and_mat

