!################################ module types_module ###############################
!####################################################################################

module types_module
use ISO_FORTRAN_ENV

  integer, parameter :: kint = 4
  integer, parameter :: kreal = kind(0.0d0)
  integer, parameter :: maxatoms = 65535 ! do not increase the limit without modifying the code that uses 2-byte integers 
  integer, parameter :: vlongmax = 51
  integer, parameter :: vbasedigits = 9
  integer(kind=kint), parameter :: vbase = 10**vbasedigits
  integer(int64), parameter :: vbase64 = vbase
  integer, parameter :: maxpolylength = 450+6+vlongmax*vbasedigits+10

  real(kreal),allocatable,dimension(:,:) :: globalgeom

  type,public :: vlonginteger
    integer,public :: leadpow
    integer(kind=4),private :: tabl(vlongmax)
  end type vlonginteger

  type,public :: structure
    integer(kint) :: nat
    integer(kint),allocatable,dimension(:) :: initiallabel
    integer(kint),allocatable,dimension(:) :: neighbornumber
    integer(kint),allocatable,dimension(:,:) :: neighborlist
    integer(kint) :: order
    type(vlonginteger),allocatable,dimension(:) :: polynomial
    integer(kint), allocatable,dimension(:,:) :: bondlist
    integer(kint) :: nbondlistentries
  end type structure

contains
  subroutine cpvli(a,b)
  type(vlonginteger),intent(in) :: a
  type(vlonginteger),intent(out) :: b
  b=a
  end subroutine cpvli
  


  function setvli(a) result(c)   
  implicit none
  integer(kint),intent(in) :: a
  integer(kint) :: i
  integer(kint) :: b
  type(vlonginteger) :: c

  c%tabl=0
  b=a
  do i=1,vlongmax
    c%tabl(i)=mod(b,vbase)
    b=(b-c%tabl(i))/vbase
    if (b == 0) then
      c%leadpow=i
      exit
    end if
  end do

  end function setvli

  function vli2real(a) result(c)   
  implicit none
  type(vlonginteger),intent(in) :: a
  integer(kint) :: i
  real(kreal) :: tmp
  real(kreal) :: c

  c=0.0_kreal
  tmp=1.0_kreal
  do i=1,a%leadpow
    c=c+a%tabl(i)*tmp
    tmp=tmp*vbase
  end do

  end function vli2real



  


  function addvli(a,b) result(c)
  implicit none
  type(vlonginteger),intent(in) :: a,b
  type(vlonginteger) :: c
  integer(kint) :: i
  integer(int64) :: val

  c%tabl=0
! this implies that the numbers must have tabl zeroed beyond leadpow. Otherwise corruption may happen. 
  c%leadpow=max(a%leadpow,b%leadpow) 
  do i=1,c%leadpow
    c%tabl(i)=c%tabl(i)+a%tabl(i)+b%tabl(i)
  end do
  do i=1,min(vlongmax-1,c%leadpow)
    if (c%tabl(i) >= vbase) then
      val=mod(c%tabl(i),vbase)
      c%tabl(i+1)=c%tabl(i+1)+(c%tabl(i)-val)/vbase
      c%tabl(i)=val
    end if
  end do

  if (c%tabl(vlongmax) >= vbase) then
    print*,"overflow in addvli, enlarge size of tabl"
    stop
  end if
 
  if (c%leadpow < vlongmax) then  
    if (c%tabl(c%leadpow+1) /= 0) c%leadpow=c%leadpow+1
  end if

  end function addvli
 
  function multvli(a,b) result(c)
  implicit none
  type(vlonginteger),intent(in) :: a,b
  type(vlonginteger) :: c
  integer(int64) :: tmp(vlongmax)
  integer(kint) :: i,j,val

  tmp=0
  do i=1,a%leadpow
    do j=1,min(vlongmax-i,b%leadpow)
      tmp(i+j-1)=tmp(i+j-1)+int(a%tabl(i),int64)*int(b%tabl(j),int64)
    end do
  end do
  do i=1,min(vlongmax-1,a%leadpow+b%leadpow)
    if (tmp(i) >= vbase64) then
      val=mod(tmp(i),vbase64)
      tmp(i+1)=tmp(i+1)+(tmp(i)-val)/vbase
      tmp(i)=val
    end if
  end do

  if (tmp(vlongmax) >= vbase) then
    print*,"overflow in multvli, enlarge size of tabl"
    stop
  end if

  c%tabl=tmp

  c%leadpow=0
  do i=min(vlongmax,a%leadpow+b%leadpow+1),1,-1
    if (c%tabl(i) /=0) then
      c%leadpow=i
      exit
    end if
  end do
 
  end function multvli
 
  subroutine printvli(a)
  implicit none
  type(vlonginteger),intent(in) :: a
  integer(kint) :: i

  if (a%leadpow == 0) then
    write(*,*)"0"
  else
    write(*,'(1X,I4,40I4.4)')(a%tabl(i),i=a%leadpow,1,-1)
  end if

  end subroutine printvli

  subroutine printvlinoadv(a)
  implicit none
  type(vlonginteger),intent(in) :: a
  integer(kint) :: i

  if (a%leadpow == 0) then
    write(*,*)"0"
  else
    write(*,'(1X,I4,40I4.4)',advance='no')(a%tabl(i),i=a%leadpow,1,-1)
  end if

  end subroutine printvlinoadv



  subroutine print_vli_in_string(pos,string,val)
!   prints integer val in the string at position pos
    implicit none
    integer(kint) :: i
    integer(kint), intent(inout) :: pos
    type(vlonginteger) :: val
    character(len=maxpolylength) :: string

    do i=val%leadpow,val%leadpow
      select case (val%tabl(i))
        case (0:9)
          write(string(pos:),'(i1)')val%tabl(i)
          pos=pos+1
        case (10:99)
          write(string(pos:),'(i2)')val%tabl(i)
          pos=pos+2
        case (100:999)
          write(string(pos:),'(i3)')val%tabl(i)
          pos=pos+3
        case (1000:9999)
          write(string(pos:),'(i4)')val%tabl(i)
          pos=pos+4
        case (10000:99999)
          write(string(pos:),'(i5)')val%tabl(i)
          pos=pos+5
        case (100000:999999)
          write(string(pos:),'(i6)')val%tabl(i)
          pos=pos+6
        case (1000000:9999999)
          write(string(pos:),'(i7)')val%tabl(i)
          pos=pos+7
        case (10000000:99999999)
          write(string(pos:),'(i8)')val%tabl(i)
          pos=pos+8
        case default
          write(string(pos:),'(i9)')val%tabl(i)
          pos=pos+9
      end select
    end do
    do i=val%leadpow-1,1,-1
      write(string(pos:),'(i9.9)')val%tabl(i)
      pos=pos+9
    end do
    return

  end subroutine print_vli_in_string


  subroutine writetofile(iunit,a,n)
  implicit none
  integer(kint),intent(in) :: iunit,n
  type(vlonginteger) :: a(n)
  integer(kint) :: i,j
  write(iunit)(a(j)%leadpow,(a(j)%tabl(i),i=1,a(j)%leadpow),j=1,n)
  end subroutine writetofile

  subroutine readfromfile(iunit,a,n)
  implicit none
  integer(kint),intent(in) :: iunit,n
  type(vlonginteger) :: a(n)
  integer(kint) :: i,j
  do i=1,n
    a(i)%leadpow=0
    a(i)%tabl=0
  end do

  read(iunit)(a(j)%leadpow,(a(j)%tabl(i),i=1,a(j)%leadpow),j=1,n)
  do i=1,n
!    write(*,*)i,a(j)%leadpow
    if (a(i)%leadpow.gt. vlongmax) then
      print*,"overflow in readfromfile, enlarge size of vlongmax"
      stop
    end if
  end do
  end subroutine readfromfile

  function getmaxpow(a,n) result(maxpow)
    implicit none
    integer(kint),intent(in) :: n
    type(vlonginteger),intent(in) :: a(n)
    integer(kint) :: i,maxpow
    maxpow=0
    do i=1,n
      if (a(i)%leadpow > maxpow) maxpow = a(i)%leadpow
    end do
  end function getmaxpow      
 
  subroutine packvliarray(a,res,n,mpow)
    implicit none
    integer(kint),intent(in) :: n,mpow
    type(vlonginteger),intent(in) :: a(n)
    integer(kint),intent(out) :: res(mpow,n)
    integer(kint) :: i,j
    
    do i=1,n
      do j=1,mpow
        res(j,i)=a(i)%tabl(j)
      end do
    end do  
  end subroutine packvliarray

  subroutine unpackvliarray(res,a,n,mpow)
    implicit none
    integer(kint),intent(in) :: n,mpow
    type(vlonginteger),intent(out) :: a(n)
    integer(kint),intent(in) :: res(mpow,n)
    integer(kint) :: i,j
    
    do i=1,n
      a(i)%tabl=0 ! very important. Proper zeroing.
      a(i)%leadpow=1 ! there has to be leadpow for a(1)==0
      do j=1,mpow
        if (res(j,i) .ne. 0) then ! this assumes all vlongintegers were properly zeroed after leadpow
          a(i)%tabl(j)=res(j,i)
          a(i)%leadpow=j
        end if
      end do
    end do  
  end subroutine unpackvliarray

function getpackedsize(a,n) result(m)
    implicit none
    integer(kint),intent(in) :: n
    type(vlonginteger),intent(in) :: a(n)
    integer(kint) :: i,m
    m=0
    do i=1,n
      m=m+a(i)%leadpow+1 ! + 1 due to storing the leadpow
    end do
  end function getpackedsize      
 

  subroutine packvliarray2(a,res,n,nres)
    implicit none
    integer(kint),intent(in) :: n,nres
    type(vlonginteger),intent(in) :: a(n)
    integer(kint),intent(out) :: res(nres)
    integer(kint) :: i,j,k,npow
    
    k=0
    do i=1,n
      k=k+1
      npow=a(i)%leadpow
      res(k)=npow
      do j=1,npow
        k=k+1
        res(k)=a(i)%tabl(j)
      end do
    end do  
  end subroutine packvliarray2


  subroutine unpackvliarray2(res,a,n,nres)
    implicit none
    integer(kint),intent(in) :: n,nres
    type(vlonginteger),intent(out) :: a(n)
    integer(kint),intent(in) :: res(nres)
    integer(kint) :: i,j,k,npow
    
    do i=1,n
      a(i)%leadpow=0
      a(i)%tabl=0
    end do
    k=0
    do i=1,n
      k=k+1
      npow=res(k)
      a(i)%leadpow=npow
      do j=1,npow
        k=k+1
        a(i)%tabl(j)=res(k)
      end do
    end do
  end subroutine unpackvliarray2

    subroutine destroypah(pah)
        type(structure), intent(inout) :: pah
        if (allocated(pah%neighbornumber)) then
            deallocate(pah%neighbornumber)
        end if
        if (allocated(pah%neighborlist)) then
            deallocate(pah%neighborlist)
        end if
        if (allocated(pah%initiallabel)) then
            deallocate(pah%initiallabel)
        end if
        if (allocated(pah%polynomial)) then
            deallocate(pah%polynomial)
        end if
        if (allocated(pah%bondlist)) then
            deallocate(pah%bondlist)
        end if
    end subroutine

function clartotal(pah) result(total)
  implicit none
  type(vlonginteger) :: total
  type(structure), intent(in) :: pah
  integer(kint) :: i

  total=pah%polynomial(1)
  do i=1,pah%order
    total=addvli(total,pah%polynomial(i+1))
  end do
  return
end function clartotal



end module types_module

!####################################################################################
!############################ end of module types_module ############################
