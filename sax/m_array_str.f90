module m_array_str
!
! Utilities for character to character array
! conversions and tests of equality.
!
interface operator (.equal.)
 module procedure compare_vs_s, compare_vs_vs
end interface operator(.equal.)
interface compare_array_str
   module procedure compare_vs_s, compare_vs_vs
end interface compare_array_str
!
! Not supported by all compilers...
! interface assignment (=)
!  module procedure assign_array_to_str !!!! , assign_str_to_array
! end interface

public :: operator(.equal.), compare_array_str !!!! , assignment(=)
public :: assign_array_to_str , assign_str_to_array
private

CONTAINS
!-------------------------------------------------------------
pure subroutine assign_array_to_str(str,s)
character(len=1), dimension(:), intent(in)   :: s
character(len=*), intent(out) :: str

integer :: i, lstr

lstr = len(str)
do i = 1, min(size(s),lstr)
   str(i:i) = s(i)
enddo
do i = size(s)+1, lstr
   str(i:i) = " "
enddo
end subroutine assign_array_to_str

!-------------------------------------------------------------
! The NAG and Intel compilers cannot distinguish this from the
! intrinsic assignment... so we resort to using an explicit
! subroutine call.
!
pure subroutine assign_str_to_array(s,str)
character(len=1), dimension(:), intent(out)   :: s
character(len=*), intent(in) :: str

integer :: i, lstr

lstr = len(str)
do i = 1, min(size(s),lstr)
   s(i) = str(i:i)
enddo

end subroutine assign_str_to_array

!-------------------------------------------------------------
pure function compare_vs_s(s,str) result(equal) ! .equal. generic
character(len=1), dimension(:), intent(in)   :: s
character(len=*), intent(in) :: str
logical                      :: equal

integer :: lens, lenstr, i

equal = .false.
lens = size(s)
lenstr = len(str)
if (lens .ne. lenstr) return

do i = 1, lens
 if (s(i) .ne. str(i:i)) return
enddo
equal = .true.

end function compare_vs_s
pure function compare_vs_vs(s,str) result(equal) ! .equal. generic
character(len=1), dimension(:), intent(in)   :: s
character(len=1), dimension(:), intent(in)   :: str
logical                      :: equal

integer :: lens, lenstr, i

equal = .false.
lens = size(s)
lenstr = size(str)
if (lens .ne. lenstr) return

do i = 1, lens
 if (s(i) .ne. str(i)) return
enddo
equal = .true.

end function compare_vs_vs

end module m_array_str
