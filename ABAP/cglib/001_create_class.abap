*&---------------------------------------------------------------------*
*& Report ZCGLIB_GENERATE_PROXY
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zcglib_generate_proxy.

TYPE-POOLS:
  seoc,
  seop.

CLASS cl_oo_include_naming DEFINITION LOAD.

DATA:
  cifkey      TYPE seoclskey,
  clstype     TYPE seoclstype,
  source      TYPE seop_source_string,
  lt_source   LIKE source,
  pool_source TYPE seop_source_string,
  source_line TYPE LINE OF seop_source_string,
  tabix       TYPE sytabix,
  includes    TYPE seop_methods_w_include,
  include     TYPE seop_method_w_include,
  cifref      TYPE REF TO if_oo_clif_incl_naming,
  clsref      TYPE REF TO if_oo_class_incl_naming,
  intref      TYPE REF TO if_oo_interface_incl_naming.

DATA: l_string TYPE string.

START-OF-SELECTION.

  cifkey-clsname = 'ZCL_JAVA_CGLIB'.
  CALL METHOD cl_oo_include_naming=>get_instance_by_cifkey
    EXPORTING
      cifkey = cifkey
    RECEIVING
      cifref = cifref
    EXCEPTIONS
      OTHERS = 1.
  ASSERT sy-subrc = 0.

  APPEND 'program.' TO lt_source.
  CHECK cifref->clstype = seoc_clstype_class.
  clsref ?= cifref.
  READ REPORT clsref->class_pool
    INTO pool_source.
*    loop at pool_source into source_line.
*      if source_line cs 'CLASS-POOL'
*        or source_line cs 'class-pool'.
*        append source_line to lt_source..
*        tabix = sy-tabix.
*        exit.
*      endif.
*    endloop.

  READ REPORT clsref->locals_old
    INTO source.
  LOOP AT source
    INTO source_line.
    IF source_line NS '*"*'.
      APPEND source_line TO lt_source..
    ENDIF.
  ENDLOOP.

  READ REPORT clsref->locals_def
    INTO source.
  LOOP AT source
    INTO source_line.
    IF source_line NS '*"*'.
      APPEND source_line TO lt_source..
    ENDIF.
  ENDLOOP.

  READ REPORT clsref->locals_imp
    INTO source.
  LOOP AT source
    INTO source_line.
    IF source_line NS '*"*'.
      APPEND source_line TO lt_source..
    ENDIF.
  ENDLOOP.

  READ REPORT clsref->macros
    INTO source.
  LOOP AT source
    INTO source_line.
    IF source_line NS '*"*'.
      APPEND source_line TO lt_source..
    ENDIF.
  ENDLOOP.

  READ REPORT clsref->public_section
    INTO source.
  LOOP AT source
    INTO source_line.
    IF source_line NS '*"*'.
      APPEND source_line TO lt_source.
    ENDIF.
  ENDLOOP.

  READ REPORT clsref->protected_section
    INTO source.
  LOOP AT source
    INTO source_line.
    IF source_line NS '*"*'.
      APPEND source_line TO lt_source..
    ENDIF.
  ENDLOOP.

  READ REPORT clsref->private_section
    INTO source.
  LOOP AT source
    INTO source_line.
    IF source_line NS '*"*'.
      APPEND source_line TO lt_source..
    ENDIF.
  ENDLOOP.
  CONCATENATE 'CLASS' cifkey 'IMPLEMENTATION' INTO l_string SEPARATED BY space.
  LOOP AT pool_source
    FROM tabix
    INTO source_line.
    IF source_line CS 'ENDCLASS'.
      APPEND source_line TO lt_source..
    ENDIF.
    IF source_line CS l_string.
      SKIP.
      APPEND source_line TO lt_source..
      tabix = sy-tabix.
      EXIT.
    ENDIF.
  ENDLOOP.
* method implementation
  includes = clsref->get_all_method_includes( ).
  LOOP AT includes
    INTO include.
    READ REPORT include-incname
      INTO source.

    LOOP AT source
      INTO source_line.
      APPEND source_line TO lt_source..
    ENDLOOP.
  ENDLOOP.
  LOOP AT pool_source
    FROM tabix
    INTO source_line.
    IF source_line CS 'ENDCLASS'.
      APPEND source_line TO lt_source..
    ENDIF.
  ENDLOOP.
  TRY.
      LOOP AT lt_source ASSIGNING FIELD-SYMBOL(<source>) WHERE table_line CS 'ZCL_JAVA_CGLIB'.
        DELETE lt_source INDEX ( sy-tabix + 1 ).
        EXIT.
      ENDLOOP.
      GENERATE SUBROUTINE POOL lt_source NAME DATA(prog).
      WRITE: / sy-subrc.

      DATA(class) = `\PROGRAM=` && prog && `\CLASS=ZCL_JAVA_CGLIB`.
      DATA oref TYPE REF TO object.
      CREATE OBJECT oref TYPE (class).

    CATCH cx_root INTO DATA(cx_root).
      WRITE: / cx_root->get_text( ).
  ENDTRY.