/* SWIG warning message numbers

   This file serves as the main registry of warning message numbers.  Some of these
   numbers are used internally in the C/C++ source code of SWIG.   However, some
   of the numbers are used in SWIG configuration files (swig.swg and others).

   The numbers are roughly organized into a few different classes by functionality.

   Even though symbolic constants are used in the SWIG source, this is
   not always the case in SWIG interface files.  Do not change the
   numbers in this file.

 */




#ifndef _SWIGWARN_H
#define _SWIGWARN_H 1

#define WARN_NONE                     0

/* -- Deprecated features -- */

#define WARN_DEPRECATED_EXTERN        101
#define WARN_DEPRECATED_VAL           102
#define WARN_DEPRECATED_OUT           103
#define WARN_DEPRECATED_DISABLEDOC    104
#define WARN_DEPRECATED_ENABLEDOC     105
#define WARN_DEPRECATED_DOCONLY       106
#define WARN_DEPRECATED_STYLE         107
#define WARN_DEPRECATED_LOCALSTYLE    108
#define WARN_DEPRECATED_TITLE         109
#define WARN_DEPRECATED_SECTION       110
#define WARN_DEPRECATED_SUBSECTION    111
#define WARN_DEPRECATED_SUBSUBSECTION 112
#define WARN_DEPRECATED_ADDMETHODS    113
#define WARN_DEPRECATED_READONLY      114
#define WARN_DEPRECATED_READWRITE     115
#define WARN_DEPRECATED_EXCEPT        116
#define WARN_DEPRECATED_NEW           117
#define WARN_DEPRECATED_EXCEPT_TM     118
#define WARN_DEPRECATED_IGNORE_TM     119
#define WARN_DEPRECATED_OPTC          120

/* -- Preprocessor -- */

#define WARN_PP_MISSING_FILE          201
#define WARN_PP_EVALUATION            202

/* -- C/C++ Parser -- */

#define WARN_PARSE_CLASS_KEYWORD      301
#define WARN_PARSE_REDEFINED          302
#define WARN_PARSE_EXTEND_UNDEF       303
#define WARN_PARSE_UNSUPPORTED_VALUE  304
#define WARN_PARSE_BAD_VALUE          305
#define WARN_PARSE_PRIVATE            306
#define WARN_PARSE_BAD_DEFAULT        307
#define WARN_PARSE_NAMESPACE_ALIAS    308
#define WARN_PARSE_PRIVATE_INHERIT    309
#define WARN_PARSE_TEMPLATE_REPEAT    310
#define WARN_PARSE_TEMPLATE_PARTIAL   311
#define WARN_PARSE_NESTED_CLASS       312
#define WARN_PARSE_UNDEFINED_EXTERN   313
#define WARN_PARSE_KEYWORD            314
#define WARN_PARSE_USING_UNDEF        315
#define WARN_PARSE_MODULE_REPEAT      316
#define WARN_PARSE_TEMPLATE_SP_UNDEF  317
#define WARN_PARSE_TEMPLATE_AMBIG     318
#define WARN_PARSE_NO_ACCESS          319
#define WARN_PARSE_EXPLICIT_TEMPLATE  320

#define WARN_IGNORE_OPERATOR_NEW        350   /* new */
#define WARN_IGNORE_OPERATOR_DELETE     351   /* delete */
#define WARN_IGNORE_OPERATOR_PLUS       352   /* + */
#define WARN_IGNORE_OPERATOR_MINUS      353   /* - */
#define WARN_IGNORE_OPERATOR_MUL        354   /* * */
#define WARN_IGNORE_OPERATOR_DIV        355   /* / */
#define WARN_IGNORE_OPERATOR_MOD        356   /* % */
#define WARN_IGNORE_OPERATOR_XOR        357   /* ^ */
#define WARN_IGNORE_OPERATOR_AND        358   /* & */
#define WARN_IGNORE_OPERATOR_OR         359   /* | */
#define WARN_IGNORE_OPERATOR_NOT        360   /* ~ */
#define WARN_IGNORE_OPERATOR_LNOT       361   /* ! */
#define WARN_IGNORE_OPERATOR_EQ         362   /* = */
#define WARN_IGNORE_OPERATOR_LT         363   /* < */
#define WARN_IGNORE_OPERATOR_GT         364   /* > */
#define WARN_IGNORE_OPERATOR_PLUSEQ     365   /* += */
#define WARN_IGNORE_OPERATOR_MINUSEQ    366   /* -= */
#define WARN_IGNORE_OPERATOR_MULEQ      367   /* *= */
#define WARN_IGNORE_OPERATOR_DIVEQ      368   /* /= */
#define WARN_IGNORE_OPERATOR_MODEQ      369   /* %= */
#define WARN_IGNORE_OPERATOR_XOREQ      370   /* ^= */
#define WARN_IGNORE_OPERATOR_ANDEQ      371   /* &= */
#define WARN_IGNORE_OPERATOR_OREQ       372   /* |= */
#define WARN_IGNORE_OPERATOR_LSHIFT     373   /* << */
#define WARN_IGNORE_OPERATOR_RSHIFT     374   /* >> */
#define WARN_IGNORE_OPERATOR_LSHIFTEQ   375   /* <<= */
#define WARN_IGNORE_OPERATOR_RSHIFTEQ   376   /* >>= */
#define WARN_IGNORE_OPERATOR_EQUALTO    377   /* == */
#define WARN_IGNORE_OPERATOR_NOTEQUAL   378   /* != */
#define WARN_IGNORE_OPERATOR_LTEQUAL    379   /* <= */
#define WARN_IGNORE_OPERATOR_GTEQUAL    380   /* >= */
#define WARN_IGNORE_OPERATOR_LAND       381   /* && */
#define WARN_IGNORE_OPERATOR_LOR        382   /* || */
#define WARN_IGNORE_OPERATOR_PLUSPLUS   383   /* ++ */
#define WARN_IGNORE_OPERATOR_MINUSMINUS 384   /* -- */
#define WARN_IGNORE_OPERATOR_COMMA      385   /* , */
#define WARN_IGNORE_OPERATOR_ARROWSTAR  386   /* ->* */
#define WARN_IGNORE_OPERATOR_ARROW      387   /* -> */
#define WARN_IGNORE_OPERATOR_CALL       388   /* () */
#define WARN_IGNORE_OPERATOR_INDEX      389   /* [] */
#define WARN_IGNORE_OPERATOR_UPLUS      390   /* + */
#define WARN_IGNORE_OPERATOR_UMINUS     391   /* - */
#define WARN_IGNORE_OPERATOR_UMUL       392   /* * */
#define WARN_IGNORE_OPERATOR_UAND       393   /* & */
#define WARN_IGNORE_OPERATOR_NEWARR     394   /* new [] */
#define WARN_IGNORE_OEPRATOR_DELARR     395   /* delete [] */

/* 394-399 are reserved */

/* -- Type system and typemaps -- */

#define WARN_TYPE_UNDEFINED_CLASS     401
#define WARN_TYPE_INCOMPLETE          402
#define WARN_TYPE_ABSTRACT            403
#define WARN_TYPE_REDEFINED           404

#define WARN_TYPEMAP_SOURCETARGET     450
#define WARN_TYPEMAP_CHARLEAK         451
#define WARN_TYPEMAP_SWIGTYPE         452
#define WARN_TYPEMAP_APPLY_UNDEF      453

#define WARN_TYPEMAP_IN_UNDEF         460
#define WARN_TYPEMAP_OUT_UNDEF        461
#define WARN_TYPEMAP_VARIN_UNDEF      462
#define WARN_TYPEMAP_VAROUT_UNDEF     463
#define WARN_TYPEMAP_CONST_UNDEF      464
#define WARN_TYPEMAP_UNDEF            465
#define WARN_TYPEMAP_VAR_UNDEF        466
#define WARN_TYPEMAP_TYPECHECK        467
#define WARN_TYPEMAP_THROW            468
#define WARN_TYPEMAP_DIRECTORIN_UNDEF 469

/* -- General code generation -- */

#define WARN_LANG_OVERLOAD_DECL       501
#define WARN_LANG_OVERLOAD_CONSTRUCT  502
#define WARN_LANG_IDENTIFIER          503
#define WARN_LANG_RETURN_TYPE         504
#define WARN_LANG_VARARGS             505 
#define WARN_LANG_VARARGS_KEYWORD     506
#define WARN_LANG_NATIVE_UNIMPL       507
#define WARN_LANG_DEREF_SHADOW        508
#define WARN_LANG_OVERLOAD_SHADOW     509
#define WARN_LANG_FRIEND_IGNORE       510
#define WARN_LANG_OVERLOAD_KEYWORD    511
#define WARN_LANG_OVERLOAD_CONST      512
#define WARN_LANG_CLASS_UNNAMED       513
#define WARN_LANG_DIRECTOR_VDESTRUCT  514
#define WARN_LANG_DISCARD_CONST       515

/* -- Reserved (600-799) -- */

/* -- Language module specific warnings (800 - 999) -- */

#define WARN_RUBY_WRONG_NAME                  801
#define WARN_RUBY_MULTIPLE_INHERITANCE        802

#define WARN_JAVA_TYPEMAP_JNI_UNDEF           810
#define WARN_JAVA_TYPEMAP_JTYPE_UNDEF         811
#define WARN_JAVA_TYPEMAP_JSTYPE_UNDEF        812
#define WARN_JAVA_MULTIPLE_INHERITANCE        813
#define WARN_JAVA_TYPEMAP_GETCPTR_UNDEF       814
#define WARN_JAVA_TYPEMAP_CLASSMOD_UNDEF      815
#define WARN_JAVA_TYPEMAP_PTRCONSTMOD_UNDEF   816
#define WARN_JAVA_TYPEMAP_JAVAOUT_UNDEF       817
#define WARN_JAVA_TYPEMAP_JAVAIN_UNDEF        818
#define WARN_JAVA_TYPEMAP_JAVADIRECTORIN_UNDEF    819
#define WARN_JAVA_TYPEMAP_JAVADIRECTOROUT_UNDEF   820
#define WARN_JAVA_TYPEMAP_NODIRECTOR_CODE     821
#define WARN_JAVA_COVARIANT_RET               822

/* please leave 810-829 free for Java */

#define WARN_CSHARP_TYPEMAP_CTYPE_UNDEF       830
#define WARN_CSHARP_TYPEMAP_CSTYPE_UNDEF      831
#define WARN_CSHARP_TYPEMAP_CSWTYPE_UNDEF     832
#define WARN_CSHARP_MULTIPLE_INHERITANCE      833
#define WARN_CSHARP_TYPEMAP_GETCPTR_UNDEF     834
#define WARN_CSHARP_TYPEMAP_CLASSMOD_UNDEF    835
#define WARN_CSHARP_TYPEMAP_PTRCONSTMOD_UNDEF 836
#define WARN_CSHARP_TYPEMAP_CSOUT_UNDEF       837
#define WARN_CSHARP_TYPEMAP_CSIN_UNDEF        838
#define WARN_CSHARP_TYPEMAP_CSDIRECTORIN_UNDEF    839
#define WARN_CSHARP_TYPEMAP_CSDIRECTOROUT_UNDEF   840
#define WARN_CSHARP_TYPEMAP_NODIRECTOR_CODE   841
#define WARN_CSHARP_COVARIANT_RET             842

/* please leave 830-849 free for C# */



/* Feel free to claim any number in this space that's not currently being used. Just make sure you
   add an entry here */

#endif



