
!+
! Fortran side of the Bmad / C++ structure interface.
!
! This file is generated by the Bmad/C++ interface code generation.
! The code generation files can be found in cpp_bmad_interface.
!
! DO NOT EDIT THIS FILE DIRECTLY! 
!-

module bmad_cpp_convert_mod

use test_mod
use fortran_cpp_utils
use, intrinsic :: iso_c_binding

!--------------------------------------------------------------------------

interface 
  subroutine my_to_f (C, Fp) bind(c)
    import c_ptr
    type(c_ptr), value :: C, Fp
  end subroutine
end interface

!--------------------------------------------------------------------------

interface 
  subroutine ttt_to_f (C, Fp) bind(c)
    import c_ptr
    type(c_ptr), value :: C, Fp
  end subroutine
end interface

contains

!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!+
! Subroutine my_to_c (Fp, C) bind(c)
!
! Routine to convert a Bmad my_struct to a C++ CPP_my structure
!
! Input:
!   Fp -- type(c_ptr), value :: Input Bmad my_struct structure.
!
! Output:
!   C -- type(c_ptr), value :: Output C++ CPP_my struct.
!-

subroutine my_to_c (Fp, C) bind(c)

implicit none

interface
  !! f_side.to_c2_f2_sub_arg
  subroutine my_to_c2 (C, z_a) bind(c)
    import c_bool, c_double, c_ptr, c_char, c_int, c_double_complex
    !! f_side.to_c2_type :: f_side.to_c2_name
    type(c_ptr), value :: C
    integer(c_int) :: z_a
  end subroutine
end interface

type(c_ptr), value :: Fp
type(c_ptr), value :: C
type(my_struct), pointer :: F
integer jd, jd1, jd2, jd3, lb1, lb2, lb3
!! f_side.to_c_var

!

call c_f_pointer (Fp, F)


!! f_side.to_c2_call
call my_to_c2 (C, F%a)

end subroutine my_to_c

!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!+
! Subroutine my_to_f2 (Fp, ...etc...) bind(c)
!
! Routine used in converting a C++ CPP_my structure to a Bmad my_struct structure.
! This routine is called by my_to_c and is not meant to be called directly.
!
! Input:
!   ...etc... -- Components of the structure. See the my_to_f2 code for more details.
!
! Output:
!   Fp -- type(c_ptr), value :: Bmad my_struct structure.
!-

!! f_side.to_c2_f2_sub_arg
subroutine my_to_f2 (Fp, z_a) bind(c)


implicit none

type(c_ptr), value :: Fp
type(my_struct), pointer :: F
integer jd, jd1, jd2, jd3, lb1, lb2, lb3
!! f_side.to_f2_var && f_side.to_f2_type :: f_side.to_f2_name
integer(c_int) :: z_a

call c_f_pointer (Fp, F)

!! f_side.to_f2_trans[integer, 0, NOT]
F%a = z_a

end subroutine my_to_f2

!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!+
! Subroutine ttt_to_c (Fp, C) bind(c)
!
! Routine to convert a Bmad ttt_struct to a C++ CPP_ttt structure
!
! Input:
!   Fp -- type(c_ptr), value :: Input Bmad ttt_struct structure.
!
! Output:
!   C -- type(c_ptr), value :: Output C++ CPP_ttt struct.
!-

subroutine ttt_to_c (Fp, C) bind(c)

implicit none

interface
  !! f_side.to_c2_f2_sub_arg
  subroutine ttt_to_c2 (C, z_i0, z_ip0, n_ip0, z_ia0, n_ia0, z_i1, z_ip1, n1_ip1, z_ia1, &
      n1_ia1, z_i2, z_ip2, n1_ip2, n2_ip2, z_ia2, n1_ia2, n2_ia2, z_i3, z_ip3, n1_ip3, n2_ip3, &
      n3_ip3, z_ia3, n1_ia3, n2_ia3, n3_ia3) bind(c)
    import c_bool, c_double, c_ptr, c_char, c_int, c_double_complex
    !! f_side.to_c2_type :: f_side.to_c2_name
    type(c_ptr), value :: C
    logical(c_bool) :: z_i0, z_ip0, z_ia0, z_i1(*), z_ip1(*), z_ia1(*), z_i2(*)
    logical(c_bool) :: z_ip2(*), z_ia2(*), z_i3(*), z_ip3(*), z_ia3(*)
    integer(c_int), value :: n_ip0, n_ia0, n1_ip1, n1_ia1, n1_ip2, n2_ip2, n1_ia2
    integer(c_int), value :: n2_ia2, n1_ip3, n2_ip3, n3_ip3, n1_ia3, n2_ia3, n3_ia3
  end subroutine
end interface

type(c_ptr), value :: Fp
type(c_ptr), value :: C
type(ttt_struct), pointer :: F
integer jd, jd1, jd2, jd3, lb1, lb2, lb3
!! f_side.to_c_var
integer(c_int) :: n_ip0
integer(c_int) :: n_ia0
integer(c_int) :: n1_ip1
integer(c_int) :: n1_ia1
integer(c_int) :: n1_ip2
integer(c_int) :: n2_ip2
integer(c_int) :: n1_ia2
integer(c_int) :: n2_ia2
integer(c_int) :: n1_ip3
integer(c_int) :: n2_ip3
integer(c_int) :: n3_ip3
integer(c_int) :: n1_ia3
integer(c_int) :: n2_ia3
integer(c_int) :: n3_ia3

!

call c_f_pointer (Fp, F)

!! f_side.to_c_trans[logical, 0, PTR]
n_ip0 = 0
if (associated(F%ip0)) n_ip0 = 1
!! f_side.to_c_trans[logical, 0, ALLOC]
n_ia0 = 0
if (allocated(F%ia0)) n_ia0 = 1
!! f_side.to_c_trans[logical, 1, PTR]
n1_ip1 = 0
if (associated(F%ip1)) then
  n1_ip1 = size(F%ip1, 1)
endif
!! f_side.to_c_trans[logical, 1, ALLOC]
n1_ia1 = 0
if (allocated(F%ia1)) then
  n1_ia1 = size(F%ia1, 1)
endif
!! f_side.to_c_trans[logical, 2, PTR]
if (associated(F%ip2)) then
  n1_ip2 = size(F%ip2, 1)
  n2_ip2 = size(F%ip2, 2)
else
  n1_ip2 = 0; n2_ip2 = 0
endif
!! f_side.to_c_trans[logical, 2, ALLOC]
if (allocated(F%ia2)) then
  n1_ia2 = size(F%ia2, 1)
  n2_ia2 = size(F%ia2, 2)
else
  n1_ia2 = 0; n2_ia2 = 0
endif
!! f_side.to_c_trans[logical, 3, PTR]
if (associated(F%ip3)) then
  n1_ip3 = size(F%ip3, 1)
  n2_ip3 = size(F%ip3, 2)
  n3_ip3 = size(F%ip3, 3)
else
  n1_ip3 = 0; n2_ip3 = 0; n3_ip3 = 0
endif
!! f_side.to_c_trans[logical, 3, ALLOC]
if (allocated(F%ia3)) then
  n1_ia3 = size(F%ia3, 1)
  n2_ia3 = size(F%ia3, 2)
  n3_ia3 = size(F%ia3, 3)
else
  n1_ia3 = 0; n2_ia3 = 0; n3_ia3 = 0
endif

!! f_side.to_c2_call
call ttt_to_c2 (C, c_logic(F%i0), fscalar2scalar(F%ip0, n_ip0), n_ip0, fscalar2scalar(F%ia0, &
    n_ia0), n_ia0, fvec2vec(F%i1, 3), fvec2vec(F%ip1, n1_ip1), n1_ip1, fvec2vec(F%ia1, n1_ia1), &
    n1_ia1, mat2vec(F%i2, 3*2), mat2vec(F%ip2, n1_ip2*n2_ip2), n1_ip2, n2_ip2, mat2vec(F%ia2, &
    n1_ia2*n2_ia2), n1_ia2, n2_ia2, tensor2vec(F%i3, 3*2*1), tensor2vec(F%ip3, &
    n1_ip3*n2_ip3*n3_ip3), n1_ip3, n2_ip3, n3_ip3, tensor2vec(F%ia3, n1_ia3*n2_ia3*n3_ia3), &
    n1_ia3, n2_ia3, n3_ia3)

end subroutine ttt_to_c

!--------------------------------------------------------------------------
!--------------------------------------------------------------------------
!+
! Subroutine ttt_to_f2 (Fp, ...etc...) bind(c)
!
! Routine used in converting a C++ CPP_ttt structure to a Bmad ttt_struct structure.
! This routine is called by ttt_to_c and is not meant to be called directly.
!
! Input:
!   ...etc... -- Components of the structure. See the ttt_to_f2 code for more details.
!
! Output:
!   Fp -- type(c_ptr), value :: Bmad ttt_struct structure.
!-

!! f_side.to_c2_f2_sub_arg
subroutine ttt_to_f2 (Fp, z_i0, z_ip0, n_ip0, z_ia0, n_ia0, z_i1, z_ip1, n1_ip1, z_ia1, n1_ia1, &
    z_i2, z_ip2, n1_ip2, n2_ip2, z_ia2, n1_ia2, n2_ia2, z_i3, z_ip3, n1_ip3, n2_ip3, n3_ip3, &
    z_ia3, n1_ia3, n2_ia3, n3_ia3) bind(c)


implicit none

type(c_ptr), value :: Fp
type(ttt_struct), pointer :: F
integer jd, jd1, jd2, jd3, lb1, lb2, lb3
!! f_side.to_f2_var && f_side.to_f2_type :: f_side.to_f2_name
integer(c_int), value :: n_ip0, n_ia0, n1_ip1, n1_ia1, n1_ip2, n2_ip2, n1_ia2
integer(c_int), value :: n2_ia2, n1_ip3, n2_ip3, n3_ip3, n1_ia3, n2_ia3, n3_ia3
logical(c_bool) :: z_i0, z_i1(*), z_i2(*), z_i3(*)
type(c_ptr), value :: z_ip0, z_ia0, z_ip1, z_ia1, z_ip2, z_ia2, z_ip3
type(c_ptr), value :: z_ia3
logical(c_bool), pointer :: f_ip0, f_ia0, f_ip1(:), f_ia1(:), f_ip2(:), f_ia2(:), f_ip3(:)
logical(c_bool), pointer :: f_ia3(:)

call c_f_pointer (Fp, F)

!! f_side.to_f2_trans[logical, 0, NOT]
F%i0 = f_logic(z_i0)
!! f_side.to_f2_trans[logical, 0, PTR]
if (n_ip0 == 0) then                                                                                  
  if (associated(F%ip0)) deallocate(F%ip0)                                                           
else                                                                                                   
  call c_f_pointer (z_ip0, f_ip0)                                                                    
  if (.not. associated(F%ip0)) allocate(F%ip0)                                                       
  F%ip0 = f_logic(f_ip0)
endif                                                                                                  

!! f_side.to_f2_trans[logical, 0, ALLOC]
if (n_ia0 == 0) then                                                                                  
  if (allocated(F%ia0)) deallocate(F%ia0)                                                           
else                                                                                                   
  call c_f_pointer (z_ia0, f_ia0)                                                                    
  if (.not. allocated(F%ia0)) allocate(F%ia0)                                                       
  F%ia0 = f_logic(f_ia0)
endif                                                                                                  

!! f_side.to_f2_trans[logical, 1, NOT]
call vec2fvec (z_i1, F%i1)
!! f_side.to_f2_trans[logical, 1, PTR]
if (associated(F%ip1)) then
  if (n1_ip1 == 0 .or. any(shape(F%ip1) /= [n1_ip1])) deallocate(F%ip1)
  if (any(lbound(F%ip1) /= 1)) deallocate(F%ip1)
endif
if (n1_ip1 /= 0) then
  call c_f_pointer (z_ip1, f_ip1, [n1_ip1])
  if (.not. associated(F%ip1)) allocate(F%ip1(n1_ip1))
  call vec2fvec (f_ip1, F%ip1)
else
  if (associated(F%ip1)) deallocate(F%ip1)
endif

!! f_side.to_f2_trans[logical, 1, ALLOC]
if (allocated(F%ia1)) then
  if (n1_ia1 == 0 .or. any(shape(F%ia1) /= [n1_ia1])) deallocate(F%ia1)
  if (any(lbound(F%ia1) /= 1)) deallocate(F%ia1)
endif
if (n1_ia1 /= 0) then
  call c_f_pointer (z_ia1, f_ia1, [n1_ia1])
  if (.not. allocated(F%ia1)) allocate(F%ia1(n1_ia1))
  call vec2fvec (f_ia1, F%ia1)
else
  if (allocated(F%ia1)) deallocate(F%ia1)
endif

!! f_side.to_f2_trans[logical, 2, NOT]
call vec2mat(z_i2, F%i2)
!! f_side.to_f2_trans[logical, 2, PTR]
if (associated(F%ip2)) then
  if (n1_ip2 == 0 .or. any(shape(F%ip2) /= [n1_ip2, n2_ip2])) deallocate(F%ip2)
  if (any(lbound(F%ip2) /= 1)) deallocate(F%ip2)
endif
if (n1_ip2 /= 0) then
  call c_f_pointer (z_ip2, f_ip2, [n1_ip2*n2_ip2])
  if (.not. associated(F%ip2)) allocate(F%ip2(n1_ip2, n2_ip2))
  call vec2mat(f_ip2, F%ip2)
else
  if (associated(F%ip2)) deallocate(F%ip2)
endif

!! f_side.to_f2_trans[logical, 2, ALLOC]
if (allocated(F%ia2)) then
  if (n1_ia2 == 0 .or. any(shape(F%ia2) /= [n1_ia2, n2_ia2])) deallocate(F%ia2)
  if (any(lbound(F%ia2) /= 1)) deallocate(F%ia2)
endif
if (n1_ia2 /= 0) then
  call c_f_pointer (z_ia2, f_ia2, [n1_ia2*n2_ia2])
  if (.not. allocated(F%ia2)) allocate(F%ia2(n1_ia2, n2_ia2))
  call vec2mat(f_ia2, F%ia2)
else
  if (allocated(F%ia2)) deallocate(F%ia2)
endif

!! f_side.to_f2_trans[logical, 3, NOT]
call vec2tensor(z_i3, F%i3)
!! f_side.to_f2_trans[logical, 3, PTR]
if (associated(F%ip3)) then
  if (n1_ip3 == 0 .or. any(shape(F%ip3) /= [n1_ip3, n2_ip3, n3_ip3])) deallocate(F%ip3)
  if (any(lbound(F%ip3) /= 1)) deallocate(F%ip3)
endif
if (n1_ip3 /= 0) then
  call c_f_pointer (z_ip3, f_ip3, [n1_ip3*n2_ip3*n3_ip3])
  if (.not. associated(F%ip3)) allocate(F%ip3(n1_ip3, n2_ip3, n3_ip3))
  call vec2tensor(f_ip3, F%ip3)
else
  if (associated(F%ip3)) deallocate(F%ip3)
endif

!! f_side.to_f2_trans[logical, 3, ALLOC]
if (allocated(F%ia3)) then
  if (n1_ia3 == 0 .or. any(shape(F%ia3) /= [n1_ia3, n2_ia3, n3_ia3])) deallocate(F%ia3)
  if (any(lbound(F%ia3) /= 1)) deallocate(F%ia3)
endif
if (n1_ia3 /= 0) then
  call c_f_pointer (z_ia3, f_ia3, [n1_ia3*n2_ia3*n3_ia3])
  if (.not. allocated(F%ia3)) allocate(F%ia3(n1_ia3, n2_ia3, n3_ia3))
  call vec2tensor(f_ia3, F%ia3)
else
  if (allocated(F%ia3)) deallocate(F%ia3)
endif


end subroutine ttt_to_f2
end module
