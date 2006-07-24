module m_wxml_core

  use FoX_common, only: FoX_version
  use m_common_attrs, only: dictionary_t, len, get_key, get_value, has_key, &
    add_item_to_dict, init_dict, reset_dict, destroy_dict
  use m_common_array_str, only: vs_str, str_vs
  use m_common_buffer
  use m_common_elstack, only: elstack_t, len, get_top_elstack, pop_elstack, is_empty, &
    init_elstack, push_elstack, destroy_elstack
  use m_common_entities, only: entity_list, init_entity_list, destroy_entity_list, &
    add_internal_entity, add_external_entity
  use m_common_error, only: FoX_warning_base, FoX_error_base, FoX_fatal_base
  use m_common_io, only: get_unit
  use m_common_namecheck, only: checkEncName, checkName, checkPITarget, &
    checkCharacterEntityReference, checkSystemId, checkPubId, &
    checkQName, prefixOfQName
  use m_common_namespaces, only: namespaceDictionary, getnamespaceURI
  use m_common_namespaces, only: initnamespaceDictionary, destroynamespaceDictionary
  use m_common_namespaces, only: addDefaultNS, addPrefixedNS, isPrefixInForce
  use m_common_namespaces, only: checkNamespacesWriting, checkEndNamespaces, dumpnsdict
  use m_common_notations, only: notation_list, init_notation_list, destroy_notation_list, &
    add_notation, notation_exists
  use m_wxml_escape, only: escape_string

  use pxf, only: pxfabort

  implicit none
  private

  integer, parameter ::  sp = selected_real_kind(6,30)
  integer, parameter ::  dp = selected_real_kind(14,100)

  !Output State Machines
  ! status wrt root element:
  integer, parameter :: WXML_STATE_1_JUST_OPENED = 0 
  !File is just opened, nothing written to it yet. 
  integer, parameter :: WXML_STATE_1_BEFORE_ROOT = 1
  !File has been opened, something has been written, but no root element yet.
  integer, parameter :: WXML_STATE_1_DURING_ROOT = 2
  !The root element has been opened but not closed
  integer, parameter :: WXML_STATE_1_AFTER_ROOT = 3
  !The root element has been opened but not closed

  ! status wrt tags:
  integer, parameter :: WXML_STATE_2_OUTSIDE_TAG= 0
  !We are not within a tag.
  integer, parameter :: WXML_STATE_2_INSIDE_PI = 1
  !We are inside a Processing Instruction tag
  integer, parameter :: WXML_STATE_2_INSIDE_ELEMENT = 2
  !We are inside an element tag.
  integer, parameter :: WXML_STATE_2_INSIDE_DOCTYPE = 3
  !We are inside the DOCTYPE declaration
  integer, parameter :: WXML_STATE_2_INSIDE_INTSUBSET = 4
  !We are inside the internal subset definition


  type xmlf_t
    character, pointer        :: filename(:)
    integer                   :: lun
    type(buffer_t)            :: buffer
    type(elstack_t)           :: stack
    type(dictionary_t)        :: dict
    integer                   :: state_1
    integer                   :: state_2
    logical                   :: indenting_requested
    character, pointer        :: name(:)
    type(namespaceDictionary) :: nsDict
    type(entity_list)         :: entityList
    type(entity_list)         :: PEList
    type(notation_list)       :: nList
  end type xmlf_t

  public :: xmlf_t

  public :: xml_OpenFile
  public :: xml_NewElement
  public :: xml_EndElement
  public :: xml_Close
  public :: xml_AddXMLDeclaration
  public :: xml_AddXMLStylesheet
  public :: xml_AddXMLPI
  public :: xml_AddComment
  public :: xml_AddCharacters
  public :: xml_AddEntityReference
  public :: xml_AddAttribute
  public :: xml_AddPseudoAttribute
  public :: xml_AddNamespace
  public :: xml_AddDOCTYPE
  public :: xml_AddParameterEntity
  public :: xml_AddInternalEntity
  public :: xml_AddExternalEntity
  public :: xml_AddNotation
 
  interface xml_AddCharacters
    module procedure xml_AddCharacters_Ch
  end interface
  interface xml_AddAttribute
    module procedure xml_AddAttribute_Ch
  end interface
  interface xml_AddPseudoAttribute
    module procedure xml_AddPseudoAttribute_Ch
  end interface
 
  !overload error handlers to allow file info
  interface wxml_warning
    module procedure wxml_warning_xf, FoX_warning_base
  end interface
  interface wxml_error
    module procedure wxml_error_xf, FoX_error_base
  end interface
  interface wxml_fatal
    module procedure wxml_fatal_xf, FoX_fatal_base
  end interface

  ! Heuristic (approximate) target for justification of output
  ! Large unbroken pcdatas will go beyond this limit
  integer, parameter  :: COLUMNS = 80

  ! TOHW - This is the longest string that may be output without
  ! a newline. The buffer must not be larger than this, but its size 
  ! can be tuned for performance.
  integer, parameter  :: xml_recl = 4096

contains

  subroutine xml_OpenFile(filename, xf, indent, channel, replace, addDecl)
    character(len=*), intent(in)  :: filename
    type(xmlf_t), intent(inout)   :: xf
    logical, intent(in), optional :: indent
    integer, intent(in), optional :: channel
    logical, intent(in), optional :: replace
    logical, intent(in), optional :: addDecl
    
    integer :: iostat
    logical :: repl, decl
    
    if (present(replace)) then
      repl = replace
    else
      repl = .true.
    endif
    if (present(addDecl)) then
      decl = addDecl
    else
      decl = .true.
    endif
    
    allocate(xf%filename(len(filename)))
    xf%filename = vs_str(filename)
    allocate(xf%name(0))
    
    if (present(channel)) then
      xf%lun = channel
    else
      call get_unit(xf%lun,iostat)
      if (iostat /= 0) call wxml_fatal(xf, "cannot open file")
    endif
    
    !
    ! Use large I/O buffer in case the O.S./Compiler combination
    ! has hard-limits by default (i.e., NAGWare f95's 1024 byte limit)
    ! This is related to the maximum size of the buffer.
    ! TOHW - This is the longest string that may be output without
    ! a newline. The buffer must not be larger than this, but its size 
    ! can be tuned for performance.
    
    if(repl) then
      open(unit=xf%lun, file=filename, form="formatted", status="unknown", &
        action="write", position="rewind", recl=xml_recl)
    else 
      open(unit=xf%lun, file=filename, form="formatted", status="old", &
        action="write", position="append", recl=xml_recl)
    endif
    
    call init_elstack(xf%stack)
    
    call init_dict(xf%dict)
    call reset_buffer(xf%buffer)
    
    xf%state_1 = WXML_STATE_1_JUST_OPENED
    xf%state_2 = WXML_STATE_2_OUTSIDE_TAG
    
    xf%indenting_requested = .false.
    if (present(indent)) then
      xf%indenting_requested = indent
    endif
    
    if (decl) then
      call xml_AddXMLDeclaration(xf,encoding='UTF-8')
    endif
    
    call initNamespaceDictionary(xf%nsDict)
    call init_entity_list(xf%entityList, .false.)
    call init_entity_list(xf%PEList, .true.)
    call init_notation_list(xf%nList)
    
  end subroutine xml_OpenFile


  subroutine xml_AddXMLDeclaration(xf, encoding, standalone)
    type(xmlf_t), intent(inout)   :: xf
    character(len=*), intent(in), optional :: encoding
    logical, intent(in), optional :: standalone
    
    if (xf%state_1 /= WXML_STATE_1_JUST_OPENED) &
         call wxml_error("Tried to put XML declaration in wrong place")
    
    call xml_AddXMLPI(xf, "xml", xml=.true.)
    call xml_AddPseudoAttribute(xf, "version", "1.0")
    if (present(encoding)) then
      if (.not.checkEncName(encoding)) &
           call wxml_error("Invalid encoding name")
      call xml_AddPseudoAttribute(xf, "encoding", encoding)
    endif
    if (present(standalone)) then
      if (standalone) then
        call xml_AddPseudoAttribute(xf, "standalone", "yes")
      else
        call xml_AddPseudoAttribute(xf, "standalone", "no")
      endif
    endif
    xf%state_1 = WXML_STATE_1_BEFORE_ROOT
  end subroutine xml_AddXMLDeclaration


  subroutine xml_AddDOCTYPE(xf, name, system, public)
    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in) :: name
    character(len=*), intent(in), optional :: system, public
    
    call close_start_tag(xf)
    
    if (xf%state_1 /= WXML_STATE_1_BEFORE_ROOT) &
      call wxml_error("Tried to put XML DOCTYPE in wrong place")

    if (size(xf%name) > 0) &
      ! We must have already had a DOCTYPE declaration
      call wxml_error("Tried to output more than one DOCTYPE declaration.")

    if (.not.checkName(name)) &
         call wxml_error("Invalid Name in DTD")
    
    call add_eol(xf)
    call add_to_buffer("<!DOCTYPE "//name, xf%buffer)

    deallocate(xf%name)
    allocate(xf%name(len(name)))
    xf%name = vs_str(name)

    if (present(system)) then
      if (.not.checkSystemId(system)) &
        call wxml_error("Invalid SYSTEM ID "//system)
      if (present(public)) then
        if (.not.checkPubId(public)) &
          call wxml_error("Invalid PUBLIC ID "//public)
        if (scan(public, "'") /= 0) then
          call add_to_buffer(' PUBLIC "'//public//'"', xf%buffer)
        else
          call add_to_buffer(" PUBLIC '"//public//"'", xf%buffer)
        endif
      endif
      if (scan(system, "'") /= 0) then
        call add_to_buffer(' SYSTEM "'//system//'"', xf%buffer)
      else
        call add_to_buffer(" SYSTEM '"//system//"'", xf%buffer)
      endif
    elseif (present(public)) then
      call wxml_error("wxml:DOCTYPE: PUBLIC supplied without SYSTEM")
    endif
    
    xf%state_2 = WXML_STATE_2_INSIDE_DOCTYPE
  end subroutine xml_AddDOCTYPE


  subroutine xml_AddParameterEntity(xf, name, PEdef, system, public)
    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in) :: name
    character(len=*), intent(in), optional :: PEDef
    character(len=*), intent(in), optional :: system
    character(len=*), intent(in), optional :: public
    
    if (xf%state_2 == WXML_STATE_2_INSIDE_DOCTYPE) then
      call add_to_buffer(" [", xf%buffer)
      xf%state_2 = WXML_STATE_2_INSIDE_INTSUBSET
    endif

    if (xf%state_2 /= WXML_STATE_2_INSIDE_INTSUBSET) &
      call wxml_fatal("Cannot define Parameter Entity here.")
      

    if (present(PEdef)) then
      if (present(system) .or. present(public)) &
        call wxml_fatal("Parameter entity "//name//" cannot have both a PEdef and an External ID")
    else
      if (.not.present(system)) &
        call wxml_fatal("Parameter entity "//name//" must have either a PEdef and an External ID")
    endif
    if (present(PEdef)) then
      call add_internal_entity(xf%PEList, name, PEdef)
    else
      call add_external_entity(xf%PEList, name, system, public)
    endif

    call add_eol(xf)

    call add_to_buffer('<!ENTITY % '//name//' ', xf%buffer)
    if (present(PEdef)) then
      if (index(PEdef, '"') > 0) then
        call add_to_buffer("'"//PEdef//"'>", xf%buffer)
      else
        call add_to_buffer('"'//PEdef//'">', xf%buffer)
      endif
    else
      if (present(public)) then
        if (index(public, '"') > 0) then
          call add_to_buffer(" PUBLIC '"//public//"' ", xf%buffer)
        else
          call add_to_buffer(' PUBLIC "'//public//'" ', xf%buffer)
        endif
      else
        call add_to_buffer(' SYSTEM ', xf%buffer)
      endif
      if (index(system, '"') > 0) then
        call add_to_buffer("'"//system//'"', xf%buffer)
      else
        call add_to_buffer("'"//system//"'", xf%buffer)
      endif
    endif
  end subroutine xml_AddParameterEntity


  subroutine xml_AddInternalEntity(xf, name, value)
    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in) :: name
    character(len=*), intent(in) :: value

    if (xf%state_2 == WXML_STATE_2_INSIDE_DOCTYPE) then
      call add_to_buffer(" [", xf%buffer)
      xf%state_2 = WXML_STATE_2_INSIDE_INTSUBSET
    endif

    if (xf%state_2 /= WXML_STATE_2_INSIDE_INTSUBSET) &
      call wxml_fatal("Cannot define Entity here.")
      
    call add_internal_entity(xf%entityList, name, value)

    call add_eol(xf)
    
    call add_to_buffer('<!ENTITY '//name//' ', xf%buffer)
    if (index(value, '"') > 0) then
      call add_to_buffer("'"//value//"'>", xf%buffer)
    else
      call add_to_buffer('"'//value//'">', xf%buffer)
    endif

  end subroutine xml_AddInternalEntity


  subroutine xml_AddExternalEntity(xf, name, system, public, notation)
    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in) :: name
    character(len=*), intent(in) :: system
    character(len=*), intent(in), optional :: public
    character(len=*), intent(in), optional :: notation

    if (xf%state_2 == WXML_STATE_2_INSIDE_DOCTYPE) then
      call add_to_buffer(" [", xf%buffer)
      xf%state_2 = WXML_STATE_2_INSIDE_INTSUBSET
    endif

    if (xf%state_2 /= WXML_STATE_2_INSIDE_INTSUBSET) &
      call wxml_fatal("Cannot define Entity here.")

    !Ideally we'd check here - but perhaps the notation has been specified
    ! externally ...

    !if (present(notation)) then
    !  if (.not.notation_exists(xf%nList, notation)) &
    !    call wxml_fatal("Tried to add unregistered notation to entity: "//name)
    !endif
      
    !Name checking is done within add_external_entity
    call add_external_entity(xf%entityList, name, system, public, notation)
    
    call add_eol(xf)
    
    call add_to_buffer('<!ENTITY '//name, xf%buffer)
    if (present(public)) then
      if (index(public, '"') > 0) then
        call add_to_buffer(" PUBLIC '"//public//"' ", xf%buffer)
      else
        call add_to_buffer(' PUBLIC "'//public//'" ', xf%buffer)
      endif
    else
      call add_to_buffer(' SYSTEM ', xf%buffer)
    endif
    if (index(system, '"') > 0) then
      call add_to_buffer("'"//system//'"', xf%buffer)
    else
      call add_to_buffer("'"//system//"'", xf%buffer)
    endif
    if (present(notation)) then
      call add_to_buffer(' NDATA '//notation, xf%buffer)
    endif
    call add_to_buffer('>', xf%buffer)
      
  end subroutine xml_AddExternalEntity


  subroutine xml_AddNotation(xf, name, system, public)
    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in) :: name
    character(len=*), intent(in), optional :: system
    character(len=*), intent(in), optional :: public

    if (xf%state_2 == WXML_STATE_2_INSIDE_DOCTYPE) then
      call add_to_buffer(" [", xf%buffer)
      xf%state_2 = WXML_STATE_2_INSIDE_INTSUBSET
    endif

    if (xf%state_2 /= WXML_STATE_2_INSIDE_INTSUBSET) &
      call wxml_fatal("Cannot define Notation here: "//name)
    
    if (notation_exists(xf%nList, name)) &
      call wxml_fatal("Tried to create duplicate notation: "//name)
    
    call add_eol(xf)

    call add_notation(xf%nList, name, system, public)
    call add_to_buffer('<!NOTATION '//name, xf%buffer)
    if (present(public)) then
      if (index(public, '"') > 0) then
        call add_to_buffer(" PUBLIC '"//public//"' ", xf%buffer)
      else
        call add_to_buffer(' PUBLIC "'//public//'" ', xf%buffer)
      endif
    elseif (present(system)) then
      call add_to_buffer(' SYSTEM ', xf%buffer)
    endif
    if (present(system)) then
      if (index(system, '"') > 0) then
        call add_to_buffer("'"//system//'"', xf%buffer)
      else
        call add_to_buffer("'"//system//"'", xf%buffer)
      endif
    endif
    call add_to_buffer('>', xf%buffer)
    
  end subroutine xml_AddNotation


  subroutine xml_AddXMLStylesheet(xf, href, type, title, media, charset, alternate)
    type(xmlf_t), intent(inout)   :: xf
    character(len=*), intent(in) :: href
    character(len=*), intent(in) :: type
    character(len=*), intent(in), optional :: title
    character(len=*), intent(in), optional :: media
    character(len=*), intent(in), optional :: charset
    logical,          intent(in), optional :: alternate
    
    ! FIXME this can only appear in the prolog

    call close_start_tag(xf)
    
    call xml_AddXMLPI(xf, 'xml-stylesheet', xml=.true.)
    call xml_AddPseudoAttribute(xf, 'href', href)
    call xml_AddPseudoAttribute(xf, 'type', type)
    
    if (present(title)) call xml_AddPseudoAttribute(xf, 'title', title)
    if (present(media)) call xml_AddPseudoAttribute(xf, 'media', media)
    if (present(charset)) call xml_AddPseudoAttribute(xf, 'charset', charset)
    if (present(alternate)) then
      if (alternate) then
        call xml_AddPseudoAttribute(xf, 'alternate', 'yes')
      else
        call xml_AddPseudoAttribute(xf, 'alternate', 'no')
      endif
    endif
    if (xf%state_1 == WXML_STATE_1_JUST_OPENED) &
         xf%state_1 = WXML_STATE_1_BEFORE_ROOT 
    xf%state_2 = WXML_STATE_2_INSIDE_PI
    
  end subroutine xml_AddXMLStylesheet
  

  subroutine xml_AddXMLPI(xf, name, data, xml)
    type(xmlf_t), intent(inout)            :: xf
    character(len=*), intent(in)           :: name
    character(len=*), intent(in), optional :: data
    logical, optional :: xml
    
    call close_start_tag(xf)
    if (xf%state_1 == WXML_STATE_1_JUST_OPENED) then
      xf%state_1 = WXML_STATE_1_BEFORE_ROOT
    else
      call add_eol(xf)
    endif

    if (.not.present(xml) .and. .not.checkPITarget(name)) &
         call wxml_warning(xf, "Invalid PI Target")
    call add_to_buffer("<?" // name, xf%buffer)
    if (present(data)) then
      if (index(data, '?>') > 0) &
           call wxml_error(xf, "Tried to output invalid PI data")
      call add_to_buffer(' '//data//'?>', xf%buffer)
      ! state_2 is now OUTSIDE_TAG from close_start_tag
    else
      xf%state_2 = WXML_STATE_2_INSIDE_PI
      call reset_dict(xf%dict)
    endif

  end subroutine xml_AddXMLPI


  subroutine xml_AddComment(xf,comment)
    type(xmlf_t), intent(inout)   :: xf
    character(len=*), intent(in)  :: comment
    
    if (index(comment,'--') > 0 .or. comment(len(comment):) == '-') &
         call wxml_error("Tried to output invalid comment")
    
    call close_start_tag(xf)
    call add_eol(xf)
    call add_to_buffer("<!--", xf%buffer)
    call add_to_buffer(comment, xf%buffer)
    call add_to_buffer("-->", xf%buffer)
    if (xf%state_1 == WXML_STATE_1_JUST_OPENED) &
         xf%state_1 = WXML_STATE_1_BEFORE_ROOT
    
  end subroutine xml_AddComment


  subroutine xml_NewElement(xf, name)
    type(xmlf_t), intent(inout)   :: xf
    character(len=*), intent(in)  :: name

    select case (xf%state_1)
    case (WXML_STATE_1_JUST_OPENED, WXML_STATE_1_BEFORE_ROOT)
      xf%state_1 = WXML_STATE_1_DURING_ROOT
      if (size(xf%name) > 0) then
        if (str_vs(xf%name) /= name) & 
          call wxml_error(xf, "Root element name does not match DTD: "//name)
      endif
    case (WXML_STATE_1_DURING_ROOT)
      continue
    case (WXML_STATE_1_AFTER_ROOT)
      call wxml_error(xf, "Two root elements: "//name)
    end select
    
    if (.not.checkQName(name)) then
      call wxml_error(xf, 'attribute name '//name//' is not valid')
    endif

    call dumpnsdict(xf%nsdict)

    if (len(prefixOfQName(name)) > 0) then
      if (isPrefixInForce(xf%nsDict, prefixOfQName(name))) &
        call wxml_error(xf, "namespace prefix not registered: "//prefixOfQName(name))
    endif
    
    call close_start_tag(xf)
    call add_eol(xf)
    call push_elstack(name,xf%stack)
    call add_to_buffer("<"//name, xf%buffer)
    xf%state_2 = WXML_STATE_2_INSIDE_ELEMENT
    call reset_dict(xf%dict)
    
  end subroutine xml_NewElement
  

  subroutine xml_AddCharacters_ch(xf, chars, parsed)
    type(xmlf_t), intent(inout)   :: xf
    character(len=*), intent(in)  :: chars
    logical, intent(in), optional :: parsed

    logical :: pc

    if (xf%state_2 /= WXML_STATE_2_INSIDE_ELEMENT .and. &
         xf%state_2 /= WXML_STATE_2_OUTSIDE_TAG)         &
         call wxml_fatal("Tried to add text section in wrong place.")

    ! FIXME check for parsed inside attribute
    
    if (present(parsed)) then
      pc = parsed
    else
      pc = .true.
    endif
    
    call close_start_tag(xf)
    
    if (pc) then
      call add_to_buffer(escape_String(chars), xf%buffer)
    else
      if (index(chars,']]>') > 0) &
           call wxml_error("Tried to output invalid CDATA")
      call add_to_buffer("<![CDATA["//chars//"]]>", xf%buffer)
    endif
    
    xf%state_2 = WXML_STATE_2_OUTSIDE_TAG
  end subroutine xml_AddCharacters_Ch

  
  subroutine xml_AddEntityReference(xf, entityref)
    type(xmlf_t), intent(inout) :: xf
    character(len=*), intent(in) :: entityref

    !Where can we add this? If we allow the full gamut
    !of entities, we can no longer properly ensure
    !well-formed output, unless we tie the sax parser
    !in as well ...

    !This check is wrong. We should be able to add them before
    ! & after tags.
    if (xf%state_2 /= WXML_STATE_2_INSIDE_ELEMENT .and. &
      xf%state_2 /= WXML_STATE_2_OUTSIDE_TAG)         &
      call wxml_fatal("Tried to add entity reference in wrong place.")

    call close_start_tag(xf)

    if (.not.checkCharacterEntityReference(entityref)) then
      !it's not just a unicode entity
      call wxml_warning("Entity reference added - document may not be well-formed")
    endif
    call add_to_buffer('&'//entityref//';', xf%buffer)
  end subroutine xml_AddEntityReference


  subroutine xml_AddAttribute_Ch(xf, name, value, escape)
    type(xmlf_t), intent(inout)             :: xf
    character(len=*), intent(in)            :: name
    character(len=*), intent(in)            :: value
    logical, intent(in), optional           :: escape

    logical :: esc

    if (present(escape)) then
      esc = escape
    else
      esc = .true.
    endif

    !FIXME when escape is false we should still verify somehow.

    if (xf%state_2 /= WXML_STATE_2_INSIDE_ELEMENT) &
         call wxml_error(xf, "attributes outside element content: "//name)
    
    if (has_key(xf%dict,name)) &
         call wxml_error(xf, "duplicate att name: "//name)
    
    if (.not.checkQName(name)) &
         call wxml_error(xf, "invalid attribute name: "//name)

    if (len(prefixOfQName(name))>0) then
      if (isPrefixInForce(xf%nsDict, prefixOfQName(name))) &
        call wxml_error(xf, "namespace prefix not registered: "//prefixOfQName(name))
      if (esc) then
        call add_item_to_dict(xf%dict, name, escape_string(value), prefixOfQName(name), &
          getnamespaceURI(xf%nsDict,vs_str(prefixOfQname(name))))
      else
        call add_item_to_dict(xf%dict, name, value, prefixOfQName(name), &
          getnamespaceURI(xf%nsDict,vs_str(prefixOfQName(name))))
      endif
    else
      if (esc) then
        call add_item_to_dict(xf%dict, name, escape_string(value))
      else
        call add_item_to_dict(xf%dict, name, value)
      endif
    endif
    
  end subroutine xml_AddAttribute_Ch


  subroutine xml_AddPseudoAttribute_Ch(xf, name, value)
    type(xmlf_t), intent(inout)   :: xf
    character(len=*), intent(in)  :: name
    character(len=*), intent(in)  :: value

    !FIXME check that value doesn't contain ?>

    if (xf%state_2 /= WXML_STATE_2_INSIDE_PI) &
         call wxml_fatal("PI pseudo-attribute outside PI: "//name)

    if (has_key(xf%dict,name)) &
         call wxml_error(xf, "duplicate PI pseudo-attribute name: "//name)
    
    call add_item_to_dict(xf%dict, name, value)
    
  end subroutine xml_AddPseudoAttribute_Ch


  subroutine xml_EndElement(xf, name)
    type(xmlf_t), intent(inout)             :: xf
    character(len=*), intent(in)            :: name

    if (get_top_elstack(xf%stack) /= name) &
      call wxml_fatal(xf, 'Trying to close '//name//' but '//get_top_elstack(xf%stack)//' is open.') 
    
    select case (xf%state_2)
    case (WXML_STATE_2_INSIDE_ELEMENT)
      call checkNamespacesWriting(xf%dict, xf%nsDict, len(xf%stack))
      if (len(xf%dict) > 0) call write_attributes(xf)
      call add_to_buffer("/>",xf%buffer)
      call devnull(pop_elstack(xf%stack))
    case (WXML_STATE_2_OUTSIDE_TAG)
      call add_eol(xf)
      call add_to_buffer("</" //pop_elstack(xf%stack)// ">", xf%buffer)
    case default
      call wxml_error("Cannot close element here")
    end select
    
    call checkEndNamespaces(xf%nsDict, len(xf%stack)+1)
    
    if (is_empty(xf%stack)) then
      xf%state_1 = WXML_STATE_1_AFTER_ROOT
    endif
    xf%state_2 = WXML_STATE_2_OUTSIDE_TAG
    
  end subroutine xml_EndElement


  subroutine xml_AddNamespace(xf, nsURI, prefix)
    type(xmlf_t), intent(inout)   :: xf
    character(len=*), intent(in) :: nsURI
    character(len=*), intent(in), optional :: prefix
    
    if (xf%state_1 == WXML_STATE_1_AFTER_ROOT) &
         call wxml_error(xf, "adding namespace outside element content")
    
    if (present(prefix)) then
      call addPrefixedNS(xf%nsDict, vs_str(prefix), vs_str(nsURI), len(xf%stack)+1)
    else
      call addDefaultNS(xf%nsDict, vs_str(nsURI), len(xf%stack)+1)
    endif
    
  end subroutine xml_AddNamespace


  subroutine xml_Close(xf)
    type(xmlf_t), intent(inout)   :: xf
    
    call close_start_tag(xf)
    
    do while (xf%state_1 == WXML_STATE_1_DURING_ROOT)
      if (xf%state_1 == WXML_STATE_1_AFTER_ROOT) exit
      call xml_EndElement(xf, get_top_elstack(xf%stack))
    enddo
    
    write(unit=xf%lun,fmt="(a)") char(xf%buffer)
    close(unit=xf%lun)
    
    call destroy_dict(xf%dict)
    call destroy_elstack(xf%stack)
    
    call destroyNamespaceDictionary(xf%nsDict)
    call destroy_entity_list(xf%entityList)
    call destroy_entity_list(xf%PEList)
    call destroy_notation_list(xf%nList)
    
    deallocate(xf%name)
    deallocate(xf%filename)
    
  end subroutine xml_Close

!==================================================================
  !----------------------------------------------------------
  subroutine add_eol(xf)
    type(xmlf_t), intent(inout)   :: xf
    
    integer :: indent_level
    
    ! In case we still have a zero-length stack, we must make
    ! sure indent_level is not less than zero.
    indent_level = max(len(xf%stack) - 1, 0)
    
    !We must flush here (rather than just adding an eol character)
    !since we don't know what the eol character is on this system.
    !Flushing with a linefeed will get it automatically, though.
    write(unit=xf%lun,fmt="(a)") char(xf%buffer)
    call reset_buffer(xf%buffer)
    
    if (xf%indenting_requested) &
     call add_to_buffer(repeat(' ',indent_level),xf%buffer)
    
  end subroutine add_eol
  

  subroutine close_start_tag(xf)
    type(xmlf_t), intent(inout)   :: xf
    
    select case (xf%state_2)
    case (WXML_STATE_2_INSIDE_ELEMENT)
      call checkNamespacesWriting(xf%dict, xf%nsDict, len(xf%stack))
      if (len(xf%dict) > 0)  call write_attributes(xf)
      call add_to_buffer('>', xf%buffer)
    case (WXML_STATE_2_INSIDE_PI)
      if (len(xf%dict) > 0)  call write_attributes(xf)
      call add_to_buffer('?>', xf%buffer)
    case (WXML_STATE_2_INSIDE_DOCTYPE)
      call add_to_buffer('>', xf%buffer)
    case (WXML_STATE_2_INSIDE_INTSUBSET)
      call add_eol(xf)
      call add_to_buffer(']>', xf%buffer)
    case (WXML_STATE_2_OUTSIDE_TAG)
      continue
    case default
      call wxml_fatal("Internal library error")
    end select
    
    xf%state_2 = WXML_STATE_2_OUTSIDE_TAG
    
  end subroutine close_start_tag


  subroutine write_attributes(xf)
    type(xmlf_t), intent(inout)   :: xf

    integer  :: i, size
    
    if (xf%state_2 /= WXML_STATE_2_INSIDE_PI .and. &
      xf%state_2 /= WXML_STATE_2_INSIDE_ELEMENT) &
      call wxml_fatal("Internal library error")
    
    do i = 1, len(xf%dict)
      size = len(get_key(xf%dict, i)) + len(get_value(xf%dict, i)) + 4
      if ((len(xf%buffer) + size) > COLUMNS) call add_eol(xf)
      call add_to_buffer(" ", xf%buffer)
      call add_to_buffer(get_key(xf%dict, i), xf%buffer)
      call add_to_buffer("=", xf%buffer)
      call add_to_buffer("""",xf%buffer)
      call add_to_buffer(get_value(xf%dict, i), xf%buffer)
      call add_to_buffer("""", xf%buffer)
    enddo
    
    
  end subroutine write_attributes
  
!---------------------------------------------------------
! Error handling/trapping routines:

    subroutine wxml_warning_xf(xf, msg)
      ! Emit warning, but carry on.
      type(xmlf_t), intent(in) :: xf
      character(len=*), intent(in) :: msg

      write(6,'(a)') 'WARNING(wxml) in writing to file ', xmlf_name(xf)
      write(6,'(a)')  msg

    end subroutine wxml_warning_xf

    subroutine wxml_error_xf(xf, msg)
      ! Emit error message, clean up file and stop.
      type(xmlf_t), intent(inout) :: xf
      character(len=*), intent(in) :: msg

      write(6,'(a)') 'ERROR(wxml) in writing to file ', xmlf_name(xf)
      write(6,'(a)')  msg

      call xml_Close(xf)
      stop

    end subroutine wxml_error_xf

    subroutine wxml_fatal_xf(xf, msg)
      !Emit error message and abort with coredump. Does not try to
      !close file, so should be used from anything xml_Close might
      !itself call (to avoid infinite recursion!)

      type(xmlf_t), intent(in) :: xf
      character(len=*), intent(in) :: msg

      write(6,'(a)') 'ERROR(wxml) in writing to file ', xmlf_name(xf)
      write(6,'(a)')  msg

      call pxfabort()
      stop

    end subroutine wxml_fatal_xf

    pure function xmlf_name(xf) result(fn)
      Type (xmlf_t), intent(in) :: xf
      character(len=size(xf%filename)) :: fn
      fn = str_vs(xf%filename)
    end function xmlf_name
      

    subroutine devnull(str)
      character(len=*), intent(in) :: str
      continue
    end subroutine devnull

end module m_wxml_core
