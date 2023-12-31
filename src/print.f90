!######################### subroutine print_ZZ_polynomial ###########################
!####################################################################################
subroutine print_ZZ_polynomial(pah)
!
! prints the computed ZZ polynomial of a given structure pah;
! the polynomial is first printed in a formated manner to a string
! and later the chunks of the string longer than 80 characters are
! displayed at stdout
!
  use types_module
  use options_module
  implicit none
  integer(kint) :: i,cpos
  type(vlonginteger) :: total
  type(structure) :: pah
  character(len=maxpolylength) :: finalZZpolynomial

! #########################
! # initialize the string #
! #########################
  finalZZpolynomial=''
  cpos=1
  total=pah%polynomial(1)
  call print_vli_in_string(cpos,finalZZpolynomial,pah%polynomial(1))
  if (pah%order == 0) then
      write(*,'(1x,a)')finalZZpolynomial(1:cpos-1)
  else 
    if (cpos > 450) then
      write(*,'(1x,a)')finalZZpolynomial(1:cpos-1)      
      finalZZpolynomial=''
      cpos=1
    else
      write(finalZZpolynomial(cpos:),*)'+ '
    end if
    cpos=cpos+3
    call print_vli_in_string(cpos,finalZZpolynomial,pah%polynomial(2))
    write(finalZZpolynomial(cpos:),*)'x'
    cpos=cpos+2
    total=addvli(pah%polynomial(1),pah%polynomial(2))
    if (pah%order == 1) then
          write(*,'(1x,a)')finalZZpolynomial(1:cpos-1)
    else if (cpos > 450) then
          write(*,'(1x,a)')finalZZpolynomial(1:cpos-1)      
          finalZZpolynomial=''
          cpos=1
    end if
  end if
! ##############################################
! # loop over all degrees of the ZZ polynomial #
! ##############################################
  do i=2,pah%order
    total=addvli(total,pah%polynomial(i+1))
    write(finalZZpolynomial(cpos:),*)'+ '
    cpos=cpos+3
    call print_vli_in_string(cpos,finalZZpolynomial,pah%polynomial(i+1))
    write(finalZZpolynomial(cpos:),*)'x^'
    cpos=cpos+3
    call print_int_in_string(cpos,finalZZpolynomial,i)

    
!   ####################################################
!   # flush out the chunks of the polynomial to stdout #
!   ####################################################
    if (i == pah%order) then
      write(*,'(1x,a)')finalZZpolynomial(1:cpos-1)
    else if (cpos > 450) then
      write(*,'(1x,a)')finalZZpolynomial(1:cpos-1)      
      finalZZpolynomial=''
      cpos=1
    end if

  end do
  finalZZpolynomial=''
  cpos = 1
  call print_vli_in_string(cpos,finalZZpolynomial,total)
  write(*,'(1x,2a)')"total: ",trim(finalZZpolynomial)
  if (verbose) write(*,'(a,1x,i0)')'max bigint',total%leadpow
  return

end subroutine print_ZZ_polynomial
!####################################################################################
!################### end of subroutine print_ZZ_polynomial ##########################



!##################### subroutine print_int_in_string ###############################
!####################################################################################
subroutine print_int_in_string(pos,string,val)
!
! prints integer val in the string at position pos
!
  use types_module
  implicit none
  integer(kint) :: val,pos
  character(len=maxpolylength) :: string

  select case (val)
  case (0:9)
    write(string(pos:),'(i1)')val
    pos=pos+1
  case (10:99)
    write(string(pos:),'(i2)')val
    pos=pos+2
  case (100:999)
    write(string(pos:),'(i3)')val
    pos=pos+3
  case (1000:9999)
    write(string(pos:),'(i4)')val
    pos=pos+4
  case (10000:99999)
    write(string(pos:),'(i5)')val
    pos=pos+5
  case (100000:999999)
    write(string(pos:),'(i6)')val
    pos=pos+6
  case (1000000:9999999)
    write(string(pos:),'(i7)')val
    pos=pos+7
  case default
    write(string(pos:),'(i20)')val
    pos=pos+20
  end select
  return

end subroutine print_int_in_string
!####################################################################################
!################## end of subroutine print_int_in_string ###########################

subroutine print_ZZ_polynomial_XML(pah)

    use types_module
    implicit none
    type(structure), intent(in) :: pah
    integer :: i,cpos
    type(vlonginteger) :: total
    character(len=maxpolylength) :: finalZZpolynomial


! #########################
! # initialize the string #
! #########################


    total = setvli(0_kint)
    write(*, '(a)') '<zzpolynomial>'

    do i = 0, pah%order
        write(*,'(2x,a)') '<term>'
        finalZZpolynomial = ''
        cpos = 1
        call print_vli_in_string(cpos,finalZZpolynomial,pah%polynomial(i+1))
        write(*,'(4x,a,i0,a)') '<order>', i, '</order>'
        write(*,'(4x,a,a,a)')  '<coefficient>', trim(finalZZpolynomial), '</coefficient>'
        total = addvli(total,pah%polynomial(i+1))
        write(*,'(2x,a)') '</term>'
    end do

    finalZZpolynomial=''
    cpos = 1
    call print_vli_in_string(cpos,finalZZpolynomial,total)
    write(*,'(2x,a,a,a)') '<total>',trim(finalZZpolynomial), '</total>'
    write(*, '(a)') '</zzpolynomial>'
    return

end subroutine print_ZZ_polynomial_XML

