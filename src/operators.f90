!######################## subroutine cut_dangling_bonds #############################
!####################################################################################
recursive subroutine cut_dangling_bonds(pah)
!
! removes all dangling bonds from a given polycyclic benzenoid structure (pah)
! the dangling bond is defined via a single connected atom
! a structure without singly connected atoms does not have dangling bonds
!
  use types_module
  implicit none
  integer(kint) :: atom1,atom2, atom3, atom4,i,j,k,nelim
  integer(kint),dimension(maxatoms) :: atoms
  type(structure) :: pah,pah1
  logical :: has_dangling_bonds
  nelim=0

! ############################
! # eliminate dangling bonds #
! ############################
  has_dangling_bonds=.true.
  do while (has_dangling_bonds)
    call check_for_dangling_bonds(pah,has_dangling_bonds,atom1)
    if (has_dangling_bonds) then
      atom2=pah%neighborlist(1,atom1)
      do i=1,pah%neighbornumber(atom2)
        atom3=pah%neighborlist(i,atom2)
        if (atom3 /= atom1) then
          k=0
          do j=1,pah%neighbornumber(atom3)
            atom4=pah%neighborlist(j,atom3)
            if (atom4 /= atom2) then
              k=k+1
              pah%neighborlist(k,atom3)=atom4
            end if
          end do
          pah%neighbornumber(atom3)=k
        end if
      end do
      pah%neighbornumber(atom1)=0
      pah%neighbornumber(atom2)=0
      pah%neighborlist(1:3,atom1)=0
      pah%neighborlist(1:3,atom2)=0
      atoms(nelim+1)=atom1
      atoms(nelim+2)=atom2
      nelim=nelim+2
    end if
  end do

! ###############################
! # return if no dangling atoms #
! ###############################
  if (nelim == 0) then
    return
  end if

! ##########################################
! # otherwise create the reduced structure #
! ##########################################
  call create_noatoms_daughter(pah,pah1,nelim,atoms)
  pah=pah1
  deallocate(pah1%neighbornumber)
  deallocate(pah1%neighborlist)
  if (pah1%nbondlistentries > 0) deallocate(pah1%bondlist)
  return

end subroutine cut_dangling_bonds
!####################################################################################
!##################### end of subroutine cut_dangling_bonds #########################



!####################### subroutine check_for_dangling_bonds ########################
!####################################################################################
subroutine check_for_dangling_bonds(pah,has_dangling_bonds,atom1)
!
! check if a given polycyclic benzenoid structure
! has dangling bonds
!
  use types_module
  implicit none
  logical :: has_dangling_bonds
  integer(kint) :: atom1,i
  type(structure) :: pah

  has_dangling_bonds=.false.
  do i=1,pah%nat
    if (pah%neighbornumber(i) == 1) then
      atom1=i
      has_dangling_bonds=.true.
      exit
    end if
  end do
  return

end subroutine check_for_dangling_bonds
!####################################################################################
!#################### end of subroutine check_for_dangling_bonds ####################


!######################## subroutine find_aromatic_sextet ###########################
!####################################################################################
subroutine find_aromatic_sextet(pah,sextet,atom1,atom2,atom3,ring_exists)
!
! for a given polycyclic benzenoid structure, the routine
! finds an aromatic ring containing atoms: atom1, atom2, and atom3
!
  use types_module
  implicit none
  integer(kint) :: i,j,k,l
  integer(kint) :: atom1,atom2,atom3,atom4,atom5,atom6
  integer(kint),dimension(6) :: sextet
  type(structure) :: pah
  logical :: ring_exists

! ##################
! # initialization #
! ##################
  ring_exists=.false.
  sextet(1)=atom1
  sextet(2)=atom2
  sextet(3)=atom3

! ######################################
! # look for the remaining three atoms #
! ######################################
  do i=1,pah%neighbornumber(atom3)
    atom4=pah%neighborlist(i,atom3)
    if (atom4 /= atom1) then
      do j=1,pah%neighbornumber(atom2)
        atom5=pah%neighborlist(j,atom2)
        if (atom5 /= atom1) then
          do k=1,pah%neighbornumber(atom4)
            atom6=pah%neighborlist(k,atom4)
            do l=1,pah%neighbornumber(atom5)
              if (atom6 == pah%neighborlist(l,atom5)) then
                sextet(4)=atom4
                sextet(5)=atom5
                sextet(6)=atom6
                ring_exists=.true.
              end if
            end do
          end do
        end if
      end do
    end if
  end do
  return

end subroutine find_aromatic_sextet
!####################################################################################
!##################### end of subroutine find_aromatic_sextet #######################



!############################ subroutine find_pentagon ##############################
!####################################################################################
subroutine find_pentagon(pah,pentagon,atom1,atom2,atom3,ring_exists)
!
! for a given polycyclic benzenoid structure, the routine
! finds a 5 atom ring containing atoms: atom1, atom2, and atom3
!
  use types_module
  implicit none
  integer(kint) :: i,j,l
  integer(kint) :: atom1,atom2,atom3,atom4,atom5
  integer(kint),dimension(5) :: pentagon
  type(structure) :: pah
  logical :: ring_exists

! ##################
! # initialization #
! ##################
  ring_exists=.false.
  pentagon(1)=atom1
  pentagon(2)=atom2
  pentagon(3)=atom3

! ####################################
! # look for the remaining two atoms #
! ####################################
  do i=1,pah%neighbornumber(atom3)
    atom4=pah%neighborlist(i,atom3)
    if (atom4 /= atom1) then
      do j=1,pah%neighbornumber(atom2)
        atom5=pah%neighborlist(j,atom2)
        if (atom5 /= atom1) then
          do l=1,pah%neighbornumber(atom4)
            if (atom5 == pah%neighborlist(l,atom4)) then
                pentagon(4)=atom4
                pentagon(5)=atom5
                ring_exists=.true.
            end if
          end do
        end if
      end do
    end if
  end do
  return

end subroutine find_pentagon
!####################################################################################
!######################### end of subroutine find_pentagon ##########################




!########################### subroutine find_edge_ring ##############################
!####################################################################################
subroutine find_edge_ring(pah,sextet,atom1,atom2,ring_exists)
!
! for a given polycyclic benzenoid structure, the routine
! finds an aromatic ring containing atoms: atom1 and atom2
!
  use types_module
  implicit none
  integer(kint) :: i,j,k,l,m
  integer(kint) :: atom1,atom2,atom3,atom4,atom5,atom6
  integer(kint),dimension(6) :: sextet
  type(structure) :: pah
  logical :: ring_exists

! ##################
! # initialization #
! ##################
  ring_exists=.false.
  sextet(1)=atom1
  sextet(2)=atom2

! #####################################
! # look for the remaining four atoms #
! #####################################
  outer: do i=1,pah%neighbornumber(atom1)
    atom3=pah%neighborlist(i,atom1)
    if (atom3 /= atom2) then
      do j=1,pah%neighbornumber(atom2)
        atom4=pah%neighborlist(j,atom2)
        if (atom4 /= atom1) then
          do k=1,pah%neighbornumber(atom3)
            atom5=pah%neighborlist(k,atom3)
            if (atom5 /= atom1) then
              do l=1,pah%neighbornumber(atom4)
                atom6=pah%neighborlist(l,atom4)
                if (atom6 /= atom2) then
                  do m=1,pah%neighbornumber(atom5)
                    if (atom6 == pah%neighborlist(m,atom5)) then
                      sextet(3)=atom3
                      sextet(4)=atom4
                      sextet(5)=atom5
                      sextet(6)=atom6
                      ring_exists=.true.
                      exit outer
                    end if
                  end do
                end if
              end do
            end if
          end do
        end if
      end do
    end if
  end do outer
  return

end subroutine find_edge_ring
!####################################################################################
!######################## end of subroutine find_edge_ring ##########################



!######################## subroutine check_if_connected #############################
!####################################################################################
subroutine check_if_connected(pah,medat)
!
! check if the given polycyclic benzenoid structure is connected
! i.e., if there exists a bonded path between any two randomly chosen atoms
! * if pah is connected, medat is returned as 0
! * if pah is disconnected, the structure is reordered in such a way that
!   first connected substructure, containing (medat-1) atoms, is returned
!   in first (medat-1) positions of pah, and the remaining substructure (possibly
!   disconnected) in the remaining positions
!
  use types_module
  implicit none
  type(structure) :: pah,pah1
  integer(kint) :: i,j,k,medat,lnat,start
  integer(kint),dimension(maxatoms) :: map
  logical, dimension(maxatoms) :: visit_list

! #########################################################
! # find the connected cluster of atoms containing atom 1 #
! #########################################################
  lnat=0
  start = 1
  visit_list(1:pah%nat)=.false.
  call dfs(pah,pah%nat,visit_list,lnat)

! ##########################################
! # return if all atoms are in the cluster #
! ##########################################
  if (lnat == pah%nat) then
    medat = 0
    return
  else
    medat=lnat+1
  end if

! ##################################################
! # find the mapping for the reorderred structure  #
! ##################################################
  i=0
  j=lnat
  do k=1,pah%nat
    if (visit_list(k)) then
      i=i+1
      map(k)=i
    else
      j=j+1
      map(k)=j
    end if
  end do

! ################################################
! # translate the structure into the new mapping #
! ################################################
  allocate(pah1%neighbornumber(pah%nat))
  allocate(pah1%neighborlist(3,pah%nat))
  pah1%neighbornumber=0
  pah1%neighborlist=0
  do k=1,pah%nat
    pah1%neighbornumber(map(k))=pah%neighbornumber(k)
    do i=1,pah%neighbornumber(k)
      pah1%neighborlist(i,map(k))=map(pah%neighborlist(i,k))
    end do
  end do
  pah%neighbornumber=pah1%neighbornumber
  pah%neighborlist=pah1%neighborlist

! ######################################
! # map the bond list to the new order #
! ######################################
  if (pah%nbondlistentries > 0) then
    forall (i=1:pah%nbondlistentries, j=1:2, pah%bondlist(j,i) /= 0)
      pah%bondlist(j,i)=map(pah%bondlist(j,i))
    end forall
  end if
  return

end subroutine check_if_connected
!####################################################################################
!###################### end of subroutine check_if_connected ########################



!################################# subroutine dfs ###################################
!####################################################################################
subroutine dfs(pah,nat,visit_list,lnat)
!
! find all atoms in structure pah that are connected to atom 1; if atom k is connected 
! to atom 1 via a sequence of bonds, then visit_list(k)=.true.; otherwise, visit_list(k)=.false.
!
  use types_module
  implicit none
  integer(kint) :: i
  integer(kint), intent(inout) :: lnat
  integer(kint), intent(in) :: nat
  type(structure) :: pah
  integer(kint), dimension(0:nat) :: stack
  logical, dimension(nat), intent(inout) :: visit_list
  integer(kint) :: cur_index

  stack(0) = 1
  stack(1) = 1
  do while(stack(0) > 0)
    cur_index = stack(stack(0))
    stack(0) = stack(0) - 1
    if (visit_list(cur_index) .eqv. .false.) then
      visit_list(cur_index) = .true.
      lnat = lnat + 1
      do i = 1, pah%neighbornumber(cur_index)
        if (visit_list(pah%neighborlist(i,cur_index)) .eqv. .false.) then
            stack(0) = stack(0) + 1
            stack(stack(0)) = pah%neighborlist(i,cur_index)
        end if
      end do
    end if
  end do
  return

end subroutine dfs
!####################################################################################
!############################# end of subroutine dfs ################################




!###################### subroutine split_and_decompose ##############################
!####################################################################################
recursive subroutine split_and_decompose(pah,medat,level,path)
!
! split a disconnected polycyclic benzenoid structure pah into two substructures
! * son1 which is connected and contains (medat-1) atoms
! * son2 which can be connected or disconnected and contains (pah%nat-medat+1) atoms
! decompose both structures further and multiply their resulting ZZ polynomials
!
!        ZZ(pah) = ZZ(son1) * ZZ(son2)
!
  use types_module
  implicit none
  integer(kint) :: medat,i,j,level,path
  type(structure) :: pah,son1,son2

! ###############################
! # allocate the son structures #
! ###############################
  son1%nat=medat-1
  son1%nbondlistentries=pah%nbondlistentries
  allocate(son1%neighbornumber(son1%nat))
  allocate(son1%neighborlist(3,son1%nat))
  son2%nat=pah%nat-medat+1
  son2%nbondlistentries=pah%nbondlistentries
  allocate(son2%neighbornumber(son2%nat))
  allocate(son2%neighborlist(3,son2%nat))
  if (pah%nbondlistentries > 0) then 
    allocate(son1%bondlist(2,son1%nbondlistentries))
    allocate(son2%bondlist(2,son2%nbondlistentries))
    son1%bondlist=pah%bondlist
    son2%bondlist=pah%bondlist
  end if

! #################################
! # initialize the son structures #
! #################################
  son1%neighbornumber=pah%neighbornumber(1:medat-1)
  son1%neighborlist=pah%neighborlist(1:3,1:medat-1)
  son2%neighbornumber=pah%neighbornumber(medat:pah%nat)
  son2%neighborlist=pah%neighborlist(1:3,medat:pah%nat)
  forall (i=1:son2%nat, j=1:3, son2%neighborlist(j,i) /= 0)
    son2%neighborlist(j,i)=son2%neighborlist(j,i)-son1%nat
  end forall
  forall (i=1:son1%nbondlistentries, j=1:2, son1%bondlist(j,i) > son1%nat)
    son1%bondlist(j,i)=0
  end forall
  forall (i=1:son2%nbondlistentries, j=1:2, son2%bondlist(j,i) <= son1%nat)
    son2%bondlist(j,i)=0
  end forall
  forall (i=1:son2%nbondlistentries, j=1:2, son2%bondlist(j,i) /= 0)
    son2%bondlist(j,i)=son2%bondlist(j,i)-son1%nat
  end forall
  call clean_bond_list(son1)
  call clean_bond_list(son2)

! ###################################################
! # find the ZZ polynomials for both son structures #
! ###################################################
  call find_ZZ_polynomial(son1,level+1,path)
  call find_ZZ_polynomial(son2,level+1,path)

! ######################################################
! # multiply the ZZ polynomials of both son structures #
! ######################################################
  call multiply_polynomials(pah,son1,son2)

! #################################
! # deallocate the son structures #
! #################################
  deallocate(son1%neighbornumber)
  deallocate(son1%neighborlist)
  deallocate(son1%polynomial)
  deallocate(son2%neighbornumber)
  deallocate(son2%neighborlist)
  deallocate(son2%polynomial)
  if (son1%nbondlistentries > 0) deallocate(son1%bondlist)
  if (son2%nbondlistentries > 0) deallocate(son2%bondlist)
  return

end subroutine split_and_decompose
!####################################################################################
!################### end of subroutine split_and_decompose ##########################







!######################### subroutine select_edge_bond ##############################
!####################################################################################
subroutine select_edge_bond(pah,atom1,atom2)
!
! selects two atoms (atom1 & atom2) located on the edge of a given
! polycyclic benzenoid structure pah; it uses the fact that the edge
! carbon atoms are surounded maximally by 2 hexagons
!
  use types_module
  implicit none
  integer(kint) :: i,j,atom1,atom2,atom3,sextet(6)
  type(structure) :: pah
  logical :: ring_exists,selected
  atom2=0
  selected=.false.

! #################################################
! # try to select the bond from the provided list #
! #################################################
  outer1: do i=1,pah%nbondlistentries
    atom1=pah%bondlist(1,i)
    atom2=pah%bondlist(2,i)
    if (pah%neighbornumber(atom1) == 2 .or. pah%neighbornumber(atom2) == 2) then
      selected=.true.
      exit outer1
    end if
    do  j=1,pah%neighbornumber(atom1)
      if (pah%neighborlist(j,atom1) == atom2) cycle
      atom3=pah%neighborlist(j,atom1)
      call find_aromatic_sextet(pah,sextet,atom1,atom2,atom3,ring_exists)
      if (.not. ring_exists) then
        selected=.true.
        exit outer1
      end if
    end do
  end do outer1

! #############################################################
! # otherwise choose an edge bond from the topological matrix #
! #############################################################
  if (.not. selected) then
    atom2=0
    outer: do i=1,pah%nat
      if (pah%neighbornumber(i) == 2) then
        atom1=i
        atom2=pah%neighborlist(1,i)
        exit outer
      else if (pah%neighbornumber(i) == 3) then
        atom1=i
        do j=1,3
          atom2=pah%neighborlist(min(j,mod(j,3)+1),atom1)
          atom3=pah%neighborlist(max(j,mod(j,3)+1),atom1)
          call find_aromatic_sextet(pah,sextet,atom1,atom2,atom3,ring_exists)
          if (.not. ring_exists) then
            exit outer
          end if
        end do
        atom2=0
      end if
    end do outer
  end if

  if (atom2 == 0) then
    write(*,*)"No atom is located on the edge"
    write(*,*)"despite of non-zero number of atoms:",pah%nat
    write(*,*)"Logical error - program is terminated in select_edge_bond"
    stop
  end if
  return

end subroutine select_edge_bond
!####################################################################################
!###################### end of subroutine select_edge_bond ##########################




!########################## subroutine clean_bond_list ##############################
!####################################################################################
subroutine clean_bond_list(pah)
!
! clean the list of bonds by removing not longer
! valid entries, i.e. not existing atoms & not existing bonds
!
  use types_module
  implicit none
  integer(kint) :: i,j
  type(structure) :: pah,pah1
  logical :: are_neighbors

  if (pah%nbondlistentries > 0) then
    allocate(pah1%bondlist(2,pah%nbondlistentries))
    pah1%bondlist=0
    j=0
    do i=1,pah%nbondlistentries
      if (pah%bondlist(1,i) /= 0) then
        if (pah%bondlist(2,i) /= 0) then
          if (are_neighbors(pah,pah%bondlist(1,i),pah%bondlist(2,i))) then
            j=j+1
            pah1%bondlist(1,j)=pah%bondlist(1,i)
            pah1%bondlist(2,j)=pah%bondlist(2,i)
          end if
        end if
      end if
    end do
    pah%nbondlistentries=j

    if (pah%nbondlistentries == 0) then
      deallocate(pah%bondlist)
    else
      deallocate(pah%bondlist)
      allocate(pah%bondlist(2,pah%nbondlistentries))
      pah%bondlist=pah1%bondlist(:,1:pah%nbondlistentries)
      deallocate(pah1%bondlist)
    end if
  end if
  return

! #################################################
! # try to select the bond from the provided list #
! #################################################


end subroutine clean_bond_list
!####################################################################################
!####################### end of subroutine clean_bond_list ##########################


!########################## function are_neighbors ##################################
!####################################################################################
logical function are_neighbors(pah,atom1,atom2)
!
! return .true. if atoms atom1 and atom2 are neighbors in structure pah;
! otherwise, return .false.
!
  use types_module
  implicit none
  integer(kint) :: i,atom1,atom2
  type(structure) :: pah
  
  are_neighbors=.false.
  do i=1,pah%neighbornumber(atom1)
    if (pah%neighborlist(i,atom1) == atom2) then
      are_neighbors=.true.
      exit
    end if
  end do
  return

end function are_neighbors
!####################################################################################
!###################### end of function are_neighbors ###############################


!######################### subroutine select_edge_bond ##############################
!####################################################################################
subroutine select_edge(pah,atom1,atom2)
!
! selects two atoms (atom1 & atom2) that are connected in pah by a bond
!
  use types_module
  implicit none
  integer(kint) :: i,j,atom1,atom2,atom3,sextet(6)
  type(structure) :: pah
  logical :: ring_exists,selected
  atom2=0
  selected=.false.

  atom1=1
  atom2=pah%neighborlist(1,1)

! #############################################################
! # otherwise choose an edge bond from the topological matrix #
! #############################################################
  if (.not. selected) then
    atom2=0
    outer: do i=1,pah%nat
      if (pah%neighbornumber(i) == 2) then
        atom1=i
        atom2=pah%neighborlist(1,i)
        exit outer
      else if (pah%neighbornumber(i) == 3) then
        atom1=i
        do j=1,3
          atom2=pah%neighborlist(min(j,mod(j,3)+1),atom1)
          atom3=pah%neighborlist(max(j,mod(j,3)+1),atom1)
          call find_aromatic_sextet(pah,sextet,atom1,atom2,atom3,ring_exists)
          if (.not. ring_exists) then
            exit outer
          end if
        end do
        atom2=0
      end if
    end do outer
  end if

  if (atom2 == 0) then
    write(*,*)"No atom is located on the edge"
    write(*,*)"despite of non-zero number of atoms:",pah%nat
    write(*,*)"Logical error - program is terminated in select_edge_bond"
    stop
  end if
  return

end subroutine select_edge
!####################################################################################
!###################### end of subroutine select_edge_bond ##########################



