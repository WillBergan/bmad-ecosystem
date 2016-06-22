!+
! Subroutine string_to_real (line, default, value, err_flag)
!
! Subroutine to convert a string to an real.
!
! Input:
!   line    -- Character*(*): String to decode
!   default -- Real: Default value to use for a blank string
!
! Output:
!   value    -- Real: Variable to hold value
!   err_flag -- Logical: Set .true. if there is a decoding error
!-

subroutine string_to_real (line, default, value, err_flag)

use precision_def

implicit none

real(rp) default, value
integer ix, ios
character(*) line
logical err_flag

!

err_flag = .false.

call string_trim (line, line, ix)
if (ix .eq. 0) then 
  value = default
else
  read (line, *, iostat = ios) value
  if (ios /= 0) then
    err_flag = .true.
    print *, 'ERROR DECODING NUMBER: ', trim(line)
  endif
endif

end subroutine
