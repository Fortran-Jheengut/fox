undefine(`index')dnl
undefine(`len')dnl
undefine(`format')dnl
define(`TOHW_m_dom_imports',`'`divert')dnl
define(`TOHW_m_dom_publics',`divert(2)$1'`divert')dnl
define(`TOHW_m_dom_contents',`divert(3)$1'`divert')dnl
dnl
include(`m_dom_exception.m4')dnl
include(`m_dom_treewalk.m4')dnl
include(`m_dom_object.m4')dnl
dnl
include(`m_dom_configuration.m4')dnl
include(`m_dom_types.m4')dnl
include(`m_dom_node.m4')dnl
include(`m_dom_nodelist.m4')dnl
include(`m_dom_namednodemap.m4')dnl
include(`m_dom_implementation.m4')dnl
include(`m_dom_document.m4')`'dnl
include(`m_dom_document_type.m4')dnl
include(`m_dom_element.m4')dnl
include(`m_dom_attribute.m4')dnl
include(`m_dom_character_data.m4')dnl
include(`m_dom_entity.m4')dnl
include(`m_dom_processing_instruction.m4')dnl
include(`m_dom_text.m4')dnl
include(`m_dom_common.m4')dnl
include(`m_dom_namespaces.m4')dnl
dnl
! ATTENTION
! THIS FILE IS AUTOGENERATED
! DO NOT EDIT DIRECTLY
! EDIT FILES dom/m_dom_***.m4
!
module m_dom_dom
dnl

  use fox_m_fsys_array_str, only: str_vs, vs_str, vs_str_alloc
  use fox_m_fsys_format, only: operator(//)
  use fox_m_fsys_string, only: toLower
  use m_common_charset, only: checkChars, XML1_0, XML1_1
  use m_common_element, only: element_t, get_element, attribute_t, &
  attribute_has_default, get_attribute_declaration
  use m_common_namecheck, only: checkQName, prefixOfQName, localPartOfQName, &
    checkName, checkPublicId, checkNCName
  use m_common_struct, only: xml_doc_state, init_xml_doc_state, destroy_xml_doc_state

  use m_dom_error, only: DOMException, throw_exception, inException, getExceptionCode, &
    NO_MODIFICATION_ALLOWED_ERR, NOT_FOUND_ERR, HIERARCHY_REQUEST_ERR, &
    WRONG_DOCUMENT_ERR, FoX_INTERNAL_ERROR, FoX_NODE_IS_NULL, FoX_LIST_IS_NULL, &
    INUSE_ATTRIBUTE_ERR, FoX_MAP_IS_NULL, INVALID_CHARACTER_ERR, NAMESPACE_ERR, &
    FoX_INVALID_PUBLIC_ID, FoX_INVALID_SYSTEM_ID, FoX_IMPL_IS_NULL, FoX_INVALID_NODE, &
    FoX_INVALID_CHARACTER, FoX_INVALID_COMMENT, FoX_INVALID_CDATA_SECTION, &
    FoX_INVALID_PI_DATA, NOT_SUPPORTED_ERR, FoX_INVALID_ENTITY, &
    INDEX_SIZE_ERR, FoX_NO_SUCH_ENTITY, FoX_HIERARCHY_REQUEST_ERR

  implicit none
  private
dnl
undivert(2)
dnl
contains
dnl
undivert(3)
dnl
end module m_dom_dom
