!+
! Subroutine tao_get_vars (s, var_value, var_del, var_weight, var_data_value)
!
! Subroutine to get the values of the variables used in optimization and put them
! in an array. It is important that the variables in different universes be the same.
!
! Input:
!   s    -- Tao_super_universe_struct: 
! 
! Output:
!   var_value(:)       -- Real, allocatable: Variable values
!   var_del(:)         -- Real, allocatable, optional: Variable step sizes.
!   var_weight(:)      -- Real, allocatable, optional: Variable weights in the merit function.
!   var_data_value(:)  -- Real, allocatable, optional: Variable values when the data was taken.
!-

subroutine tao_get_vars (s, var_value, var_del, var_weight, var_data_value)

use tao_mod

implicit none

type (tao_super_universe_struct), target :: s
type (tao_var_struct), pointer :: var(:)

real(rp), allocatable :: var_value(:)
real(rp), allocatable, optional :: var_del(:), var_weight(:), var_data_value(:)

integer i, j, k
integer n_var, n_data

! 

  n_var  = count(s%var(:)%useit_opt)
  call reallocate_real (var_value, n_var)
  if (present(var_del))        call reallocate_real (var_del, n_var)
  if (present(var_data_value)) call reallocate_real (var_data_value, n_var)
  if (present(var_weight))     call reallocate_real (var_weight, n_var)

  j = 0
  do i = 1, size(s%var)
    if (.not. s%var(i)%useit_opt) cycle
    j = j + 1
    var_value(j) = s%var(i)%model_value
    if (present(var_del))    var_del(j) = s%var(i)%step
    if (present(var_weight)) var_weight(j) = s%var(i)%weight
    if (present(var_data_value))   var_data_value(j) = s%var(i)%data_value
  enddo


end subroutine

