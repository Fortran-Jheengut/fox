define(`TOHWM4_lattice_subs', `dnl
  subroutine cmlAddCrystal$1(xf, a, b, c, alpha, beta, gamma, z,&
    id, title, dictref, convention, lenunits, angunits, spaceGroup, fmt)
    type(xmlf_t), intent(inout) :: xf
    real(kind=$1), intent(in)               :: a, b, c
    real(kind=$1), intent(in)               :: alpha
    real(kind=$1), intent(in)               :: beta
    real(kind=$1), intent(in)               :: gamma
    integer, intent(in), optional           :: z
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: dictref
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: lenunits
    character(len=*), intent(in), optional :: angunits
    character(len=*), intent(in), optional :: spaceGroup
    character(len=*), intent(in), optional :: fmt

    call xml_NewElement(xf=xf, name="crystal")
    if (present(id))      call xml_AddAttribute(xf, "id", id)
    if (present(title))   call xml_AddAttribute(xf, "title", title)
    if (present(dictref)) call xml_AddAttribute(xf, "dictRef", dictRef)
    if (present(convention)) call xml_AddAttribute(xf, "convention", convention)
    if (present(z)) call xml_AddAttribute(xf, "z", z)

    call xml_NewElement(xf=xf, name="cellParameter")
    call xml_AddAttribute(xf=xf, name="latticeType", value="real")
    call xml_AddAttribute(xf=xf, name="parameterType", value="length")
    if (present(lenunits)) then
      call xml_AddAttribute(xf=xf, name="units", value=lenunits)
    else
      call xml_AddAttribute(xf=xf, name="units", value=U_ANGSTR)
    endif
    call xml_AddCharacters(xf=xf, chars=(/a, b, c/))
    call xml_EndElement(xf=xf, name="cellParameter")

    call xml_NewElement(xf=xf, name="cellParameter")
    call xml_AddAttribute(xf=xf, name="latticeType", value="real")
    call xml_AddAttribute(xf=xf, name="parameterType", value="angle")
    if (present(angunits)) then
      call xml_AddAttribute(xf=xf, name="units", value=angunits)
    else
      call xml_AddAttribute(xf=xf, name="units", value=U_DEGREE)
    endif
    call xml_AddCharacters(xf=xf, chars=(/alpha, beta, gamma/), fmt="r3")
    call xml_EndElement(xf=xf, name="cellParameter")

    if (present(spaceGroup)) then
      call xml_NewElement(xf, "symmetry")
      call xml_AddAttribute(xf, "spaceGroup", spaceGroup)
      call xml_EndElement(xf, "symmetry")
    endif
    call xml_EndElement(xf, "crystal")

  end subroutine cmlAddCrystal$1

  subroutine cmlAddLattice$1(xf, cell, units, title, id, dictref, convention, latticeType, spaceType, fmt)
    type(xmlf_t), intent(inout) :: xf
    real(kind=$1), intent(in)              :: cell(3,3)
    character(len=*), intent(in), optional :: units       
    character(len=*), intent(in), optional :: id
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: dictref
    character(len=*), intent(in), optional :: convention
    character(len=*), intent(in), optional :: latticeType
    character(len=*), intent(in), optional :: spaceType
    character(len=*), intent(in), optional :: fmt

    integer :: i

    call xml_NewElement(xf, "lattice")
    if (present(id)) call xml_AddAttribute(xf, "id", id)
    if (present(title)) call xml_AddAttribute(xf, "title", title)
    if (present(dictref)) call xml_AddAttribute(xf, "dictRef", dictref)
    if (present(convention)) call xml_AddAttribute(xf, "convention", convention)
    if (present(latticeType)) call xml_AddAttribute(xf, "latticeType", latticeType)
    if (present(spaceType)) call xml_AddAttribute(xf, "spaceType", spaceType)

    do i = 1,3
      call xml_NewElement(xf, "latticeVector")
      if (present(units)) call xml_AddAttribute(xf, "units", units)
      call xml_AddAttribute(xf, "dictRef", "cml:latticeVector")
      call xml_AddCharacters(xf, cell(:,i), fmt)
      call xml_EndElement(xf, "latticeVector")
    enddo
    call xml_EndElement(xf, "lattice")

  end subroutine cmlAddLattice$1

')dnl
dnl
!
! This file is AUTOGENERATED
! To update, edit m_wcml_lattice.m4 and regenerate

module m_wcml_lattice

!FIXME: unimplemented bits:
! periodicity of latticevectors ...
! conversion between lattices & crystals ...

  use m_common_realtypes, only: sp, dp
  use FoX_wxml, only: xmlf_t
  use FoX_wxml, only: xml_NewElement, xml_EndElement
  use FoX_wxml, only: xml_AddAttribute, xml_AddCharacters
  use m_wcml_stml, only: stmAddValue

  implicit none
  private

  character(len=*), parameter :: U_ANGSTR = "units:angstrom"
  character(len=*), parameter :: U_DEGREE = "units:degree"

  interface cmlAddCrystal
     module procedure cmlAddCrystalSP
     module procedure cmlAddCrystalDP
  end interface

  interface cmlAddLattice
    module procedure cmlAddLatticeSP
    module procedure cmlAddLatticeDP
  end interface

  public :: cmlAddCrystal
  public :: cmlAddLattice

contains

TOHWM4_lattice_subs(`sp')

TOHWM4_lattice_subs(`dp')

end module m_wcml_lattice
