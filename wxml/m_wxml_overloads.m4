dnl
dnl First part is boilerplate to give us a foreach function
dnl
divert(-1)
# foreach(x, (item_1, item_2, ..., item_n), stmt)
define(`m4_foreach', `pushdef(`$1', `')_foreach(`$1', `$2', `$3')popdef(`$1')')
define(`_arg1', `$1')
define(`_foreach',
        `ifelse(`$2', `()', ,
                `define(`$1', _arg1$2)$3`'_foreach(`$1', (shift$2), `$3')')')
# traceon(`define', `foreach', `_foreach', `ifelse')
divert 
dnl
dnl Define a few basic bits
dnl
dnl
define(`TOHWM4_declarationtype', `dnl
ifelse(`$1', `RealDp', `real(dp)', 
       `$1', `RealSp', `real(sp)', 
       `$1', `Int', `integer', 
       `$1', `Lg', `logical', 
       `$1', `Ch', `character(len=*)') dnl
')dnl
dnl
dnl
define(`TOHWM4_subroutinename', `$1$2$3$4')dnl
dnl
dnl This is what a subroutine looks like if it is for a SCALAR quantity
dnl First arg is name of quantity (Character, Attribute, PseudoAttribute)
dnl Second arg is whether this is scalar, array, or matrix.
dnl Third arg is type of property(character/logical etc.)
define(`TOHWM4_CharacterSub',`dnl
  subroutine TOHWM4_subroutinename(`$1',`$2',`$3',`') &
    (xf, chars dnl
ifelse(substr($3,0,4),`Real',`, fmt', `$3', `Ch', `, delimiter'))

    type(xmlf_t), intent(inout) :: xf
    TOHWM4_declarationtype(`$3'), intent(in) dnl
ifelse(`$2', `Array', `, dimension(:)', `$2', `Matrix',`, dimension(:,:)') dnl
 :: chars
dnl
ifelse(substr($3,0,4),`Real',`dnl 
    character(len=*), intent(in), optional :: fmt
', `$3', `Ch', `dnl
    character(len=1), intent(in), optional :: delimiter
')
dnl
ifelse(substr($3,0,4),`Real',`dnl 
    if (present(fmt)) then
       call xml_Add$1(xf=xf, chars=str(chars, fmt))
    else
')dnl
       call xml_Add$1(xf=xf, chars=str(chars dnl
ifelse(`$3', `Ch', `, delimiter') dnl
))
ifelse(substr($3,0,4),`Real',`dnl
     endif
') dnl

  end subroutine TOHWM4_subroutinename(`$1',`$2',`$3',`')
')dnl
dnl
dnl
define(`TOHWM4_AttributeSub',`dnl
  subroutine TOHWM4_subroutinename(`$1',`$2',`$3',`') &
    (xf, name, value dnl
ifelse(substr($3,0,4),`Real',`, fmt', `$3', `Ch', `, delimiter'))

    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in) :: name
    TOHWM4_declarationtype(`$3'), intent(in) dnl
ifelse(`$2', `Array', `, dimension(:)', `$2', `Matrix',`, dimension(:,:)') dnl
 :: value
dnl
ifelse(substr($3,0,4),`Real',`dnl 
    character(len=*), intent(in), optional :: fmt
', `$3', `Ch', `dnl
    character(len=1), intent(in), optional :: delimiter
')
dnl
ifelse(substr($3,0,4),`Real',`dnl 
    if (present(fmt)) then
       call xml_Add$1(xf=xf, name=name, value=str(value, fmt))
    else
')dnl
       call xml_Add$1(xf=xf, name=name, value=str(value dnl
ifelse(`$3', `Ch', `, delimiter') dnl
))
ifelse(substr($3,0,4),`Real',`dnl
     endif
') dnl
dnl

  end subroutine TOHWM4_subroutinename(`$1',`$2',`$3',`')
')dnl
dnl
dnl
dnl
! This file is AUTOGENERATED!!!!
! Do not edit this file; edit m_wxml_overloads.m4 and regenerate.
!
!
module m_wxml_overloads

  use m_common_format, only: str
  use m_wxml_core, only: xmlf_t
  use m_wxml_core, only: xml_AddCharacters
  use m_wxml_core, only: xml_AddAttribute
  use m_wxml_core, only: xml_AddPseudoAttribute

  implicit none
  private

  integer, parameter ::  sp = selected_real_kind(6,30)
  integer, parameter ::  dp = selected_real_kind(14,100)

  interface xml_AddCharacters
m4_foreach(`x', `(RealDp, RealSp, Int, Lg)', `dnl
    module procedure TOHWM4_subroutinename(`Characters', `Scalar', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `dnl
    module procedure TOHWM4_subroutinename(`Characters', `Array', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `dnl
    module procedure TOHWM4_subroutinename(`Characters', `Matrix', x)
') dnl
 end interface xml_AddCharacters

  interface xml_AddAttribute
m4_foreach(`x', `(RealDp, RealSp, Int, Lg)', `dnl
    module procedure TOHWM4_subroutinename(`Attribute', `Scalar', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `dnl
    module procedure TOHWM4_subroutinename(`Attribute', `Array', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `dnl
    module procedure TOHWM4_subroutinename(`Attribute', `Matrix', x)
') dnl
 end interface xml_AddAttribute

  interface xml_AddPseudoAttribute
m4_foreach(`x', `(RealDp, RealSp, Int, Lg)', `dnl
    module procedure TOHWM4_subroutinename(`Attribute', `Scalar', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `dnl
    module procedure TOHWM4_subroutinename(`Attribute', `Array', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `dnl
    module procedure TOHWM4_subroutinename(`Attribute', `Matrix', x)
') dnl
 end interface xml_AddPseudoAttribute

  public :: xml_AddCharacters
  public :: xml_AddAttribute
  public :: xml_AddPseudoAttribute

contains

m4_foreach(`x', `(RealDp, RealSp, Int, Lg)', `TOHWM4_CharacterSub(`Characters', `Scalar', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `TOHWM4_CharacterSub(`Characters', `Array', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `TOHWM4_CharacterSub(`Characters', `Matrix', x)
')


m4_foreach(`x', `(RealDp, RealSp, Int, Lg)', `TOHWM4_AttributeSub(`Attribute', `Scalar', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `TOHWM4_AttributeSub(`Attribute', `Array', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `TOHWM4_AttributeSub(`Attribute', `Matrix', x)
')


m4_foreach(`x', `(RealDp, RealSp, Int, Lg)', `TOHWM4_AttributeSub(`PseudoAttribute', `Scalar', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `TOHWM4_AttributeSub(`PseudoAttribute', `Array', x)
')
m4_foreach(`x', `(RealDp, RealSp, Int, Lg, Ch)', `TOHWM4_AttributeSub(`PseudoAttribute', `Matrix', x)
')

end module m_wxml_overloads