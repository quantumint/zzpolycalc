subroutine makereversemap(map,reversemap,n)
  use types_module
  implicit none
  integer, intent(in) :: n
  integer, intent(in) :: map(n)
  integer, intent(out) :: reversemap(n)
  integer :: i,j
  do i=1,n
    do j=1,n
      if (map(j)==i) then
        reversemap(i)=j
        exit
      end if 
    end do
  end do
end subroutine makereversemap


! Simple insertion sort of an XYZ array
subroutine sort(a,n,initiallabel)
  use types_module
  implicit none
  
  integer, intent(in) :: n
  real(kreal), intent(inout) :: a(3,n)
  real(kreal) :: tmp(3),tmplabel
  integer :: i,j
  integer, intent(inout) :: initiallabel(n)
  integer :: tmpinitiallabel(n)
  
  do i=2,n
    tmp=a(:,i)
    tmplabel=(i)
    j=i-1
    do while (j>=1) ! equivalent to sort -k 3,3g -k 2,2g -k 1,1g
      if (a(3,j) < tmp(3) .or.(a(3,j) == tmp(3) .and. a(2,j) < tmp(2)) .or. &
             ( a(3,j) == tmp(3) .and. a(2,j) == tmp(2) .and. a(1,j) < tmp(1))) exit 
      a(:,j+1)=a(:,j)
      initiallabel(j+1)=initiallabel(j)
      j=j-1
    end do
    a(:,j+1)=tmp
    initiallabel(j+1)=tmplabel
  end do
  call makereversemap(initiallabel,tmpinitiallabel,n)
  initiallabel = tmpinitiallabel ! replace with the reverse map
end subroutine
