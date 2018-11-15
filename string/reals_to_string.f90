!+
! Function reals_to_string (real_arr, width, n_signif, n_decimal) result (str)
! 
! Routine to turn a n array of reals into a string for printing. 
!
! See also:
!   real_to_string
!   reals_to_table_row
!
! This routine is essentially real_to_string applied to each element of the array.
! See real_to_string for more documentation.
!
! Input:
!   real_arr(:) -- real(rp): Real array to encode.
!   width       -- integer: width of number field. The output string length will also be equal to width.
!   n_signif    -- integer, optional: Nominal number of significant digits to display. Must be non-negative. Default is 15.
!                    If n_decimal >= 0: n_signif is ignored is the number can be encoded with fixed format.
!                           n_signif only affects encoding if the number is encoded with a floating point format.
!                    If n_decimal < 0: Number of significant digits displayed will be reduced if trailing zeros are suppressed.
!                    
!   n_decimal   -- integer, optional: 
!                     n_decimal = positive or 0: Number of digits after the decimal point to display if fixed format is used. 
!                         Fixed format is preferred and floating format will only be used if necessary.
!                         Numbers are right justified. This is good for tables.
!                     n_decimal = -1 (default): Trailing zeros replaced by blanks. Numbers are left justified.
!                         The more compact fixed/floating format will be used. This is good for numbers in text.
!
! Output:
!   str         -- character(width): String representation of real_num. The length will be equal to width*size(real_arr)
!-

function reals_to_string (real_arr, width, n_signif, n_decimal) result (str)

use sim_utils, dummy => reals_to_string

implicit none

real(rp) real_arr(:)

integer width
integer, optional :: n_signif, n_decimal
integer i, n0

character(width*size(real_arr)) str

!

do i = 1, size(real_arr)
  n0 = (i-1) * width
  str(n0+1:n0+width) = real_to_string(real_arr(i), width, n_signif, n_decimal)
enddo

end function
