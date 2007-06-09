TOHW_m_dom_imports(`

  use m_common_array_str, only: str_vs, vs_str_alloc
  use m_common_namecheck, only: checkQName, prefixOfQName, localPartOfQName
  use m_dom_error, only : NOT_FOUND_ERR, INVALID_CHARACTER_ERR, FoX_INVALID_NODE, &
    FoX_INVALID_XML_NAME, WRONG_DOCUMENT_ERR, FoX_INVALID_TEXT, & 
    FoX_INVALID_CHARACTER, FoX_INVALID_COMMENT, FoX_INVALID_CDATA_SECTION, &
    FoX_INVALID_PI_DATA, NOT_SUPPORTED_ERR

')`'dnl
dnl
TOHW_m_dom_publics(`

  public :: getDocumentType
  public :: getImplementation
  public :: getDocumentElement
  public :: setDocumentElement
  
  public :: createElement
  public :: createDocumentFragment
  public :: createTextNode
  public :: createComment
  public :: createCdataSection
  public :: createProcessingInstruction
  public :: createAttribute
  public :: createEntityReference
  public :: getElementsByTagName
  public :: importNode
  public :: createElementNS
  public :: createAttributeNS
  public :: getElementsByTagNameNS
  public :: getElementById

  public :: createEntity
  public :: createNotation

')`'dnl
dnl
TOHW_m_dom_contents(`

  ! Getters and setters:

  TOHW_function(getDocumentType, (doc), np)
    type(Node), intent(in) :: doc
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    endif
    
    np => doc%docType

  end function getDocumentType

  TOHW_function(getImplementation, (doc), imp)
    type(Node), intent(in) :: doc
    type(DOMImplementation), pointer :: imp

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    endif
    
    imp => doc%implementation
    
  end function getImplementation

  TOHW_function(getDocumentElement, (doc), np)
    type(Node), intent(in) :: doc
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    endif
    
    np => doc%documentElement

  end function getDocumentElement

  TOHW_subroutine(setDocumentElement, (doc, np))
  ! Only for use by FoX, not exported through FoX_DOM interface
    type(Node), pointer :: doc
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (np%nodeType/=ELEMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.associated(np%ownerDocument, doc)) then
      TOHW_m_dom_throw_error(WRONG_DOCUMENT_ERR)
    endif
    
    doc%documentElement => np

  end subroutine setDocumentElement

  ! Methods

  TOHW_function(createElement, (doc, tagName), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: tagName
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    else if (.not.checkChars(tagName, doc%docType%xds%xml_version)) then
      TOHW_m_dom_throw_error(INVALID_CHARACTER_ERR)
    endif  
    if (.not.checkName(tagName, doc%docType%xds)) then
      TOHW_m_dom_throw_error(FoX_INVALID_XML_NAME)
    endif
    
    np => createElementNS(doc, "", tagName)
  
  end function createElement
    
  TOHW_function(createDocumentFragment, (doc), np)
    type(Node), pointer :: doc
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    endif
    
    np => createNode(doc, DOCUMENT_FRAGMENT_NODE, "", "")
    
  end function createDocumentFragment

  TOHW_function(createTextNode, (doc, data), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: data
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.checkChars(data, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(FoX_INVALID_CHARACTER)
    elseif (scan(data,"&<")>0) then   
      TOHW_m_dom_throw_error(FoX_INVALID_TEXT)
    endif

    np => createNode(doc, TEXT_NODE, "#text", data)
   
  end function createTextNode

  TOHW_function(createComment, (doc, data), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: data
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.checkChars(data, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(FoX_INVALID_CHARACTER)
    elseif (index(data,"--")>0) then   
      TOHW_m_dom_throw_error(FoX_INVALID_COMMENT)
    endif
  
    np => createNode(doc, COMMENT_NODE, "#comment", data)

  end function createComment

  TOHW_function(createCdataSection, (doc, data), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: data
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.checkChars(data, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(FoX_INVALID_CHARACTER)
    elseif (index(data,"]]>")>0) then   
      TOHW_m_dom_throw_error(FoX_INVALID_CDATA_SECTION)
    endif
  
    np => createNode(doc, CDATA_SECTION_NODE, "#text", data)
  
  end function createCdataSection

  TOHW_function(createProcessingInstruction, (doc, target, data), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: target
    character(len=*), intent(in) :: data
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.checkChars(target, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(INVALID_CHARACTER_ERR)
    elseif (.not.checkChars(data, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(FoX_INVALID_CHARACTER)
    elseif (.not.checkName(data, doc%xds)) then
      TOHW_m_dom_throw_error(FoX_INVALID_XML_NAME)
    elseif (index(data,"?>")>0) then   
      TOHW_m_dom_throw_error(FoX_INVALID_PI_DATA)
    endif

    np => createNode(doc, PROCESSING_INSTRUCTION_NODE, target, data)

  end function createProcessingInstruction

  TOHW_function(createAttribute, (doc, name), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: name
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.checkChars(name, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(INVALID_CHARACTER_ERR)
    elseif (.not.checkName(name, doc%xds)) then
      TOHW_m_dom_throw_error(FoX_INVALID_XML_NAME)
    endif
  
    np => createAttributeNS(doc, name, "")
  
  end function createAttribute

  TOHW_function(createEntityReference, (doc, name), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: name
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.checkChars(name, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(INVALID_CHARACTER_ERR)
    elseif (.not.checkName(name, doc%xds)) then
      TOHW_m_dom_throw_error(FoX_INVALID_XML_NAME)
    endif

    ! FIXME check existence of entities + namespace handling,
    ! see spec

    np => createNode(doc, ENTITY_REFERENCE_NODE, name, "")

  end function createEntityReference

  TOHW_function(getElementsByTagName, (doc, tagName), list)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: tagName
    type(NodeList) :: list

    type(Node), pointer :: np
    logical :: noChild, allElements

    if (doc%nodeType/=DOCUMENT_NODE.and.doc%nodeType/=ELEMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    endif

    if (tagName=="*") &
      allElements = .true.

    if (doc%nodeType==DOCUMENT_NODE) then
      np => doc%documentElement
    else
      np => doc
    endif

    if (.not.associated(np)) then
      ! FIXME internal error
      continue
    endif

    noChild = .false.
    do
      if (noChild) then
        if (associated(np, doc).or.associated(np, doc%documentElement)) then
          exit
        else
          np => np%parentNode
          noChild=  .false.
        endif
      endif
      if ((np%nodeType==ELEMENT_NODE) .and. &
        (allElements .or. str_vs(np%nodeName)==tagName)) then
        call append(list, np)
      endif
      if (associated(np%firstChild)) then
        np => np%firstChild
      elseif (associated(np%nextSibling)) then
        np => np%nextSibling
      else
        noChild = .true.
      endif
    enddo

  end function getElementsByTagName

  TOHW_function(importNode, (doc, arg, deep) , np)
    type(Node), pointer :: doc
    type(Node), pointer :: arg
    logical, intent(in) :: deep
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    endif

    select case(arg%nodeType)
    case (ATTRIBUTE_NODE)
      np => cloneNode(arg, deep, ex)
      np%ownerElement => null()
      np%specified = .true.
    case (DOCUMENT_NODE)
      TOHW_m_dom_throw_error(NOT_SUPPORTED_ERR)
    case (DOCUMENT_TYPE_NODE)
      TOHW_m_dom_throw_error(NOT_SUPPORTED_ERR)
    case (ELEMENT_NODE)
      np => cloneNode(arg, deep, ex)
! FIXME strip out unspecified attributes unless they are also default in this doc ...
    case (ENTITY_REFERENCE_NODE)
      np => cloneNode(arg, .false., ex)
! FIXME if entity is defined in this doc then add appropriate children
    case default
      np => cloneNode(arg, deep, ex)
    end select

    np%ownerDocument => doc
    np%parentNode => null()

  end function importNode

  TOHW_function(createElementNS, (doc, namespaceURI, qualifiedName), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: namespaceURI, qualifiedName
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.checkChars(qualifiedName, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(INVALID_CHARACTER_ERR)
    elseif (.not.checkQName(qualifiedName, doc%xds)) then
      TOHW_m_dom_throw_error(NAMESPACE_ERR)
    elseif (prefixOfQName(qualifiedName)/="" &
     .and. namespaceURI=="") then
      TOHW_m_dom_throw_error(NAMESPACE_ERR)
    elseif (prefixOfQName(qualifiedName)=="xml" .and. &
      namespaceURI/="http://www.w3.org/XML/1998/namespace") then
      TOHW_m_dom_throw_error(NAMESPACE_ERR)
    ! FIXME is this all possible errors?
      ! what if prefix = "xmlns"? or other "xml"
    endif

    ! FIXME create a namespace node for XPath?

    np => createNode(doc, ELEMENT_NODE, qualifiedName, "")
    np%namespaceURI => vs_str_alloc(namespaceURI)
    np%prefix => vs_str_alloc(prefixOfQName(qualifiedname))
    np%localName => vs_str_alloc(localpartOfQName(qualifiedname))

  end function createElementNS
  
  TOHW_function(createAttributeNS, (doc, namespaceURI,  qualifiedname), np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: namespaceURI, qualifiedName
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    elseif (.not.checkChars(qualifiedName, doc%xds%xml_version)) then
      TOHW_m_dom_throw_error(INVALID_CHARACTER_ERR)
    elseif (.not.checkQName(qualifiedName, doc%xds)) then
      TOHW_m_dom_throw_error(NAMESPACE_ERR)
    elseif (prefixOfQName(qualifiedName)/="" &
     .and. namespaceURI=="") then
      TOHW_m_dom_throw_error(NAMESPACE_ERR)
    elseif (prefixOfQName(qualifiedName)=="xml" .and. &
      namespaceURI/="http://www.w3.org/XML/1998/namespace") then
      TOHW_m_dom_throw_error(NAMESPACE_ERR)
    ! FIXME is this all possible errors?
      ! what if prefix = "xmlns"? or other "xml"
    endif
  
    np => createNode(doc, ATTRIBUTE_NODE, qualifiedName, "")
    np%namespaceURI => vs_str_alloc(namespaceURI)
    np%localname => vs_str_alloc(localPartofQName(qualifiedname))
    np%prefix => vs_str_alloc(PrefixofQName(qualifiedname))
    
  end function createAttributeNS

  TOHW_function(getElementsByTagNameNS, (doc, namespaceURI, localName), list)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: namespaceURI, localName
    type(NodeList) :: list

    type(Node), pointer :: np
    logical :: noChild, allLocalNames, allNameSpaces

    if (doc%nodeType/=DOCUMENT_NODE.and.doc%nodeType/=ELEMENT_NODE) then
      TOHW_m_dom_throw_error(FoX_INVALID_NODE)
    endif

    if (namespaceURI=="*") &
      allNameSpaces = .true.
    if (localName=="*") &
      allLocalNames = .true.

    if (doc%nodeType==DOCUMENT_NODE) then
      np => doc%documentElement
    else
      np => doc
    endif

    if (.not.associated(np)) then
      ! FIXME internal error
      continue
    endif

    noChild = .false.
    do
      if (noChild) then
        if (associated(np, doc).or.associated(np, doc%documentElement)) then
          exit
        else
          np => np%parentNode
          noChild=  .false.
        endif
      endif
      if ((np%nodeType==ELEMENT_NODE) &
        .and. (allNameSpaces .or. str_vs(np%namespaceURI)==namespaceURI) &
        .and. (allLocalNames .or. str_vs(np%localName)==localName)) then
        call append(list, np)
      endif
      if (associated(np%firstChild)) then
        np => np%firstChild
      elseif (associated(np%nextSibling)) then
        np => np%nextSibling
      else
        noChild = .true.
      endif
    enddo

  end function getElementsByTagNameNS


  function getElementById(doc, elementId) result(np)
    type(Node), intent(in) :: doc
    character(len=*), intent(in) :: elementId
    type(NodeList), pointer :: np
    if (doc%nodeType/=DOCUMENT_NODE) then
      ! FIXME throw an error
      continue
    endif

    continue

    ! FIXME logic
    ! cannot fix until IDs implemented
  end function getElementById

  ! Internal function, not part of API

  function createEntity(doc, name, publicId, systemId, notationName) result(np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: name
    character(len=*), intent(in) :: publicId
    character(len=*), intent(in) :: systemId
    character(len=*), intent(in) :: notationName
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      print*,"internal error in createEntity"
      stop
    endif

    np => createNode(doc, ENTITY_NODE, name, "")
    np%publicId => vs_str_alloc(publicId)
    np%systemId => vs_str_alloc(systemId)
    np%notationName => vs_str_alloc(notationName)

  end function createEntity

  function createNotation(doc, name, publicId, systemId) result(np)
    type(Node), pointer :: doc
    character(len=*), intent(in) :: name
    character(len=*), intent(in), optional :: publicId
    character(len=*), intent(in), optional :: systemId
    type(Node), pointer :: np

    if (doc%nodeType/=DOCUMENT_NODE) then
      print*,"internal error in createEntity"
      stop
    endif

    np => createNode(doc, NOTATION_NODE, name, "")
    if (present(publicId)) np%publicId => vs_str_alloc(publicId)
    if (present(systemId)) np%systemId => vs_str_alloc(systemId)
    
  end function createNotation

')`'dnl
