/******************************************************************************
 * Simplified Wrapper and Interface Generator  (SWIG)
 *
 * Author : David Beazley
 *
 * Department of Computer Science
 * University of Chicago
 * 1100 E 58th Street
 * Chicago, IL  60637
 * beazley@cs.uchicago.edu
 *
 * Please read the file LICENSE for the copyright and terms by which SWIG
 * can be used and distributed.
 *****************************************************************************/

char cvsroot_mzscheme_cxx[] = "$Header: /home/jabba/convert/cvs/Ficl/SWIG-1.3.21/Source/Modules/mzscheme.cxx,v 1.1 2004-02-01 04:05:27 alex Exp $";

/***********************************************************************
 * $Header: /home/jabba/convert/cvs/Ficl/SWIG-1.3.21/Source/Modules/mzscheme.cxx,v 1.1 2004-02-01 04:05:27 alex Exp $
 *
 * mzscheme.cxx
 *
 * Definitions for adding functions to Mzscheme 101
 ***********************************************************************/

#include "swigmod.h"

#ifndef MACSWIG
#include "swigconfig.h"
#endif

#include <ctype.h>

static const char *usage = (char*)"\
Mzscheme Options (available with -mzscheme)\n\
     -ldflags        - Print runtime libraries to link with\n\
     -prefix <name>  - Set a prefix <name> to be prepended to all names\n\
     -declaremodule  - Create extension that declares a module\n\
\n";

static char *prefix=0;
static bool declaremodule = false;
static String *module=0;
static char *mzscheme_path=(char*)"mzscheme";
static String *init_func_def = 0;

static  File         *f_runtime = 0;
static  File         *f_header = 0;
static  File         *f_wrappers = 0;
static  File         *f_init = 0;

// Used for garbage collection
static int     exporting_destructor = 0;
static String *swigtype_ptr = 0;

class MZSCHEME : public Language {
public:

  /* ------------------------------------------------------------
   * main()
   * ------------------------------------------------------------ */

  virtual void main (int argc, char *argv[]) {

    int i;
    
    SWIG_library_directory(mzscheme_path);
    
    // Look for certain command line options
    for (i = 1; i < argc; i++) {
      if (argv[i]) {
	if (strcmp (argv[i], "-help") == 0) {
	  fputs (usage, stderr);
	  SWIG_exit (0);
	} else if (strcmp (argv[i], "-prefix") == 0) {
	  if (argv[i + 1]) {
	    prefix = new char[strlen(argv[i + 1]) + 2];
	    strcpy(prefix, argv[i + 1]);
	    Swig_mark_arg (i);
	    Swig_mark_arg (i + 1);
	    i++;
	  } else {
	    Swig_arg_error();
	  }
	} else if (strcmp (argv[i], "-declaremodule") == 0) {
		declaremodule = true;
		Swig_mark_arg (i);
	} else if (strcmp (argv[i], "-ldflags") == 0) {
	  printf("%s\n", SWIG_MZSCHEME_RUNTIME);
	  SWIG_exit (EXIT_SUCCESS);
	}
      }
    }
    
    // If a prefix has been specified make sure it ends in a '_'
    
    if (prefix) {
      if (prefix[strlen (prefix)] != '_') {
	prefix[strlen (prefix) + 1] = 0;
	prefix[strlen (prefix)] = '_';
      }
    } else
      prefix = (char*)"swig_";
    
    // Add a symbol for this module
    
    Preprocessor_define ("SWIGMZSCHEME 1",0);
    
    // Set name of typemaps
    
    SWIG_typemap_lang("mzscheme");

    // Read in default typemaps */
    SWIG_config_file("mzscheme.swg");
    allow_overloading();

  }
  
  /* ------------------------------------------------------------
   * top()
   * ------------------------------------------------------------ */

  virtual int top(Node *n) {

    /* Initialize all of the output files */
    String *outfile = Getattr(n,"outfile");
    
    f_runtime = NewFile(outfile,"w");
    if (!f_runtime) {
      Printf(stderr,"*** Can't open '%s'\n", outfile);
      SWIG_exit(EXIT_FAILURE);
    }
    f_init = NewString("");
    f_header = NewString("");
    f_wrappers = NewString("");
    
    /* Register file targets with the SWIG file handler */
    Swig_register_filebyname("header",f_header);
    Swig_register_filebyname("wrapper",f_wrappers);
    Swig_register_filebyname("runtime",f_runtime);
    
    init_func_def = NewString("");
    Swig_register_filebyname("init",init_func_def);
    
    Printf(f_runtime, "/* -*- buffer-read-only: t -*- vi: set ro: */\n");
    Swig_banner (f_runtime);
    
    if (NoInclude) {
      Printf(f_runtime, "#define SWIG_NOINCLUDE\n");
    }
    
    module = Getattr(n,"name");
    
    Language::top(n);
    
    SwigType_emit_type_table (f_runtime, f_wrappers);
    Printf(f_init, "Scheme_Object *scheme_reload(Scheme_Env *env) {\n");
	Printf(f_init, "\tScheme_Env *menv = env;\n");
	if (declaremodule) {
		Printf(f_init, "\tmenv = scheme_primitive_module(scheme_intern_symbol(\"%s\"), env);\n", module);
	}
    Printf(f_init, "%s\n", Char(init_func_def));
	if (declaremodule) {
		Printf(f_init, "\tscheme_finish_primitive_module(menv);\n");
	}
    Printf (f_init, "\treturn scheme_void;\n}\n");
    Printf(f_init, "Scheme_Object *scheme_initialize(Scheme_Env *env) {\n");
    Printf(f_init, "\treturn scheme_reload(env);\n");
    Printf (f_init, "}\n");
    
    Printf(f_init,"Scheme_Object *scheme_module_name(void) {\n");
	if (declaremodule) {
		Printf(f_init, "   return scheme_intern_symbol((char*)\"%s\");\n", module);
	}
	else {
		Printf(f_init,"   return scheme_make_symbol((char*)\"%s\");\n", module);
	}
    Printf(f_init,"}\n");

    /* Close all of the files */
    Dump(f_header,f_runtime);
    Dump(f_wrappers,f_runtime);
    Wrapper_pretty_print(f_init,f_runtime);
    Delete(f_header);
    Delete(f_wrappers);
    Delete(f_init);
    Close(f_runtime);
    Delete(f_runtime);
    return SWIG_OK;
  }
  
  /* ------------------------------------------------------------
   * functionWrapper()
   * Create a function declaration and register it with the interpreter.
   * ------------------------------------------------------------ */

  void throw_unhandled_mzscheme_type_error (SwigType *d)
  {
    Swig_warning(WARN_TYPEMAP_UNDEF, input_file, line_number,
		 "Unable to handle type %s.\n", SwigType_str(d,0));
  }

  /* Return true iff T is a pointer type */

  int
  is_a_pointer (SwigType *t)
  {
    return SwigType_ispointer(SwigType_typedef_resolve_all(t));
  }

  virtual int functionWrapper(Node *n) {
    char *iname = GetChar(n,"sym:name");
    SwigType *d = Getattr(n,"type");
    ParmList *l = Getattr(n,"parms");
    Parm *p;
    
    Wrapper *f = NewWrapper();
    String *proc_name = NewString("");
    String *source = NewString("");
    String *target = NewString("");
    String *arg = NewString("");
    String *cleanup = NewString("");
    String *outarg = NewString("");
    String *build = NewString("");
    String   *tm;
    int argout_set = 0;
    int i = 0;
    int numargs;
    int numreq;
    String *overname = 0;

    // Make a wrapper name for this
    String *wname = Swig_name_wrapper(iname);
    if (Getattr(n,"sym:overloaded")) {
      overname = Getattr(n,"sym:overname");
    } else {
      if (!addSymbol(iname,n)) return SWIG_ERROR;
    }
    if (overname) {
      Append(wname, overname);
    }
    Setattr(n,"wrap:name",wname);
    
    // Build the name for Scheme.
    Printv(proc_name, iname,NIL);
    Replaceall(proc_name, "_", "-");
    
    // writing the function wrapper function
    Printv(f->def, "static Scheme_Object *",  wname, " (", NIL);
    Printv(f->def, "int argc, Scheme_Object **argv", NIL);
    Printv(f->def, ")\n{", NIL);
    
    /* Define the scheme name in C. This define is used by several
       macros. */
    Printv(f->def, "#define FUNC_NAME \"", proc_name, "\"", NIL);
    
    // Declare return variable and arguments
    // number of parameters
    // they are called arg0, arg1, ...
    // the return value is called result
    
    emit_args(d, l, f);
    
    /* Attach the standard typemaps */
    emit_attach_parmmaps(l,f);
    Setattr(n,"wrap:parms",l);
    
    numargs = emit_num_arguments(l);
    numreq  = emit_num_required(l);
    
    // adds local variables
    Wrapper_add_local(f, "_len", "int _len");
    Wrapper_add_local(f, "lenv", "int lenv = 1");
    Wrapper_add_local(f, "values", "Scheme_Object *values[MAXVALUES]");
    
    // Now write code to extract the parameters (this is super ugly)
    
    for (i = 0, p = l; i < numargs; i++) {
      /* Skip ignored arguments */

      while (checkAttribute(p,"tmap:in:numinputs","0")) {
	p = Getattr(p,"tmap:in:next");
      }
      
      SwigType *pt = Getattr(p,"type");
      String   *ln = Getattr(p,"lname");
      
      // Produce names of source and target
      Clear(source);
      Clear(target);
      Clear(arg);
      Printf(source, "argv[%d]", i);
      Printf(target, "%s",ln);
      Printv(arg, Getattr(p,"name"),NIL);
      
      if (i >= numreq) {
	Printf(f->code,"if (argc > %d) {\n",i);
      }
      // Handle parameter types.
      if ((tm = Getattr(p,"tmap:in"))) {
	Replaceall(tm,"$source",source);
	Replaceall(tm,"$target",target);
	Replaceall(tm,"$input",source);
	Setattr(p,"emit:input",source);
	Printv(f->code, tm, "\n", NIL);
	p = Getattr(p,"tmap:in:next");
      } else {
	// no typemap found
	// check if typedef and resolve
	throw_unhandled_mzscheme_type_error (pt);
	p = nextSibling(p);
      }
      if (i >= numreq) {
	Printf(f->code,"}\n");
      }
    }
    
    /* Insert constraint checking code */
    for (p = l; p;) {
      if ((tm = Getattr(p,"tmap:check"))) {
	Replaceall(tm,"$target",Getattr(p,"lname"));
	Printv(f->code,tm,"\n",NIL);
	p = Getattr(p,"tmap:check:next");
      } else {
	p = nextSibling(p);
      }
    }
    
    // Pass output arguments back to the caller.
    
    for (p = l; p;) {
      if ((tm = Getattr(p,"tmap:argout"))) {
	Replaceall(tm,"$source",Getattr(p,"emit:input"));   /* Deprecated */
	Replaceall(tm,"$target",Getattr(p,"lname"));   /* Deprecated */
	Replaceall(tm,"$arg",Getattr(p,"emit:input"));
	Replaceall(tm,"$input",Getattr(p,"emit:input"));
	Printv(outarg,tm,"\n",NIL);
	p = Getattr(p,"tmap:argout:next");
	argout_set = 1;
      } else {
	p = nextSibling(p);
      }
    }
    
    // Free up any memory allocated for the arguments.
    
    /* Insert cleanup code */
    for (p = l; p;) {
      if ((tm = Getattr(p,"tmap:freearg"))) {
	Replaceall(tm,"$target",Getattr(p,"lname"));
	Printv(cleanup,tm,"\n",NIL);
	p = Getattr(p,"tmap:freearg:next");
      } else {
	p = nextSibling(p);
      }
    }
    
    // Now write code to make the function call
    
    emit_action(n,f);
    
    // Now have return value, figure out what to do with it.
    
    if ((tm = Swig_typemap_lookup_new("out",n,"result",0))) {
      Replaceall(tm,"$source","result");
      Replaceall(tm,"$target","values[0]");
      Replaceall(tm,"$result","values[0]");
      if (Getattr(n, "feature:new"))
        Replaceall(tm, "$owner", "1");
      else
        Replaceall(tm, "$owner", "0");
      Printv(f->code, tm, "\n",NIL);
    } else {
      throw_unhandled_mzscheme_type_error (d);
    }
    
    // Dump the argument output code
    Printv(f->code, Char(outarg),NIL);
    
    // Dump the argument cleanup code
    Printv(f->code, Char(cleanup),NIL);
    
    // Look for any remaining cleanup
    
    if (Getattr(n,"feature:new")) {
      if ((tm = Swig_typemap_lookup_new("newfree",n,"result",0))) {
	Replaceall(tm,"$source","result");
	Printv(f->code, tm, "\n",NIL);
      }
    }
    
    // Free any memory allocated by the function being wrapped..
    
    if ((tm = Swig_typemap_lookup_new("ret",n,"result",0))) {
      Replaceall(tm,"$source","result");
      Printv(f->code, tm, "\n",NIL);
    }
    
    // Wrap things up (in a manner of speaking)
    
    Printv(f->code, tab4, "return SWIG_MzScheme_PackageValues(lenv, values);\n", NIL);
    Printf(f->code, "#undef FUNC_NAME\n");
    Printv(f->code, "}\n",NIL);
    
    Wrapper_print(f, f_wrappers);
   
    if (!Getattr(n,"sym:overloaded")) {
 
      // Now register the function
      char temp[256];
      sprintf(temp, "%d", numargs);
      if (exporting_destructor) {
        Printf(init_func_def, "SWIG_TypeClientData(SWIGTYPE%s, (void *) %s);\n", swigtype_ptr, wname);
      } else {
        Printf(init_func_def, "scheme_add_global(\"%s\", scheme_make_prim_w_arity(%s,\"%s\",%d,%d),menv);\n",
	       proc_name, wname, proc_name, numreq, numargs);
      }
    } else {
      if (!Getattr(n,"sym:nextSibling")) {
	/* Emit overloading dispatch function */

	int maxargs;
	String *dispatch = Swig_overload_dispatch(n,"return %s(argc,argv);",&maxargs);
	
	/* Generate a dispatch wrapper for all overloaded functions */

	Wrapper *df      = NewWrapper();
	String  *dname   = Swig_name_wrapper(iname);

	Printv(df->def,	
	       "static Scheme_Object *\n", dname,
	       "(int argc, Scheme_Object **argv) {",
	       NIL);
	Printv(df->code,dispatch,"\n",NIL);
	Printf(df->code,"scheme_signal_error(\"No matching function for overloaded '%s'\");\n", iname);
	Printv(df->code,"}\n",NIL);
	Wrapper_print(df,f_wrappers);
	Printf(init_func_def, "scheme_add_global(\"%s\", scheme_make_prim_w_arity(%s,\"%s\",%d,%d),menv);\n",
	     proc_name, dname, proc_name, 0, maxargs);
	DelWrapper(df);
	Delete(dispatch);
	Delete(dname);
      }
    }
    
    Delete(proc_name);
    Delete(source);
    Delete(target);
    Delete(arg);
    Delete(outarg);
    Delete(cleanup);
    Delete(build);
    DelWrapper(f);
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * variableWrapper()
   *
   * Create a link to a C variable.
   * This creates a single function _wrap_swig_var_varname().
   * This function takes a single optional argument.   If supplied, it means
   * we are setting this variable to some value.  If omitted, it means we are
   * simply evaluating this variable.  Either way, we return the variables
   * value.
   * ------------------------------------------------------------ */

  virtual int variableWrapper(Node *n)  {

    char *name  = GetChar(n,"name");
    char *iname = GetChar(n,"sym:name");
    SwigType *t = Getattr(n,"type");
    
    String *proc_name = NewString("");
    char  var_name[256];
    String *tm;
    String *tm2 = NewString("");;
    String *argnum = NewString("0");
    String *arg = NewString("argv[0]");
    Wrapper *f;
    
    if (!addSymbol(iname,n)) return SWIG_ERROR;
    
    f = NewWrapper();
    
    // evaluation function names
    
    strcpy(var_name, Char(Swig_name_wrapper(iname)));
    
    // Build the name for scheme.
    Printv(proc_name, iname,NIL);
    Replaceall(proc_name, "_", "-");
    
    if ((SwigType_type(t) != T_USER) || (is_a_pointer(t))) {
      
      Printf (f->def, "static Scheme_Object *%s(int argc, Scheme_Object** argv) {\n", var_name);
      Printv(f->def, "#define FUNC_NAME \"", proc_name, "\"", NIL);
      
      Wrapper_add_local (f, "swig_result", "Scheme_Object *swig_result");
      
      if (!Getattr(n,"feature:immutable")) {
	/* Check for a setting of the variable value */
	Printf (f->code, "if (argc) {\n");
	if ((tm = Swig_typemap_lookup_new("varin",n,name,0))) {
	  Replaceall(tm,"$source","argv[0]");
	  Replaceall(tm,"$target",name);
	  Replaceall(tm,"$input","argv[0]");
	  Printv(f->code, tm, "\n",NIL);
	}
	else {
	  throw_unhandled_mzscheme_type_error (t);
	}
	Printf (f->code, "}\n");
      }
      
      // Now return the value of the variable (regardless
      // of evaluating or setting)
      
      if ((tm = Swig_typemap_lookup_new("varout",n,name,0))) {
	Replaceall(tm,"$source",name);
	Replaceall(tm,"$target","swig_result");
	Replaceall(tm,"$result","swig_result");
	Printf (f->code, "%s\n", tm);
      }
      else {
	throw_unhandled_mzscheme_type_error (t);
      }
      Printf (f->code, "\nreturn swig_result;\n");
      Printf (f->code, "#undef FUNC_NAME\n");
      Printf (f->code, "}\n");
      
      Wrapper_print (f, f_wrappers);
      
      // Now add symbol to the MzScheme interpreter
      
      Printv(init_func_def,
	     "scheme_add_global(\"",
	     proc_name,
	     "\", scheme_make_prim_w_arity(",
	     var_name,
	     ", \"",
	     proc_name,
	     "\", ",
	     "0",
	     ", ",
	     "1",
	     "), menv);\n",NIL);
      
    } else {
      Swig_warning(WARN_TYPEMAP_VAR_UNDEF, input_file, line_number,
		   "Unsupported variable type %s (ignored).\n", SwigType_str(t,0));
    }
    Delete(proc_name);
    Delete(argnum);
    Delete(arg);
    Delete(tm2);
    DelWrapper(f);
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * constantWrapper()
   * ------------------------------------------------------------ */

  virtual int constantWrapper(Node *n) {
    char *name      = GetChar(n,"name");
    char *iname     = GetChar(n,"sym:name");
    SwigType *type  = Getattr(n,"type");
    String   *value = Getattr(n,"value");
    
    String *var_name = NewString("");
    String *proc_name = NewString("");
    String *rvalue = NewString("");
    String *temp = NewString("");
    String *tm;
    
    // Make a static variable;
    
    Printf (var_name, "_wrap_const_%s", Swig_name_mangle(iname));
    
    // Build the name for scheme.
    Printv(proc_name, iname,NIL);
    Replaceall(proc_name, "_", "-");
    
    if ((SwigType_type(type) == T_USER) && (!is_a_pointer(type))) {
      Swig_warning(WARN_TYPEMAP_CONST_UNDEF, input_file, line_number,
		   "Unsupported constant value.\n");
      return SWIG_NOWRAP;
    }
    
    // See if there's a typemap
    
    Printv(rvalue, value,NIL);
    if ((SwigType_type(type) == T_CHAR) && (is_a_pointer(type) == 1)) {
      temp = Copy(rvalue);
      Clear(rvalue);
      Printv(rvalue, "\"", temp, "\"",NIL);
    }
    if ((SwigType_type(type) == T_CHAR) && (is_a_pointer(type) == 0)) {
      Delete(temp);
      temp = Copy(rvalue);
      Clear(rvalue);
      Printv(rvalue, "'", temp, "'",NIL);
    }
    if ((tm = Swig_typemap_lookup_new("constant",n,name,0))) {
      Replaceall(tm,"$source",rvalue);
      Replaceall(tm,"$value",rvalue);
      Replaceall(tm,"$target",name);
      Printf (f_init, "%s\n", tm);
    } else {
      // Create variable and assign it a value
      
      Printf (f_header, "static %s = ", SwigType_lstr(type,var_name));
      if ((SwigType_type(type) == T_STRING)) {
	Printf (f_header, "\"%s\";\n", value);
      } else if (SwigType_type(type) == T_CHAR) {
	Printf (f_header, "\'%s\';\n", value);
      } else {
	Printf (f_header, "%s;\n", value);
      }
      
      // Now create a variable declaration
      
      {
	/* Hack alert: will cleanup later -- Dave */
	Node *n = NewHash();
	Setattr(n,"name",var_name);
	Setattr(n,"sym:name",iname);
	Setattr(n,"type", type);
	variableWrapper(n);
	Delete(n);
      }
    }
    Delete(proc_name);
    Delete(rvalue);
    Delete(temp);
    return SWIG_OK;
  }

  virtual int destructorHandler(Node *n) {
    exporting_destructor = true;
    Language::destructorHandler(n);
    exporting_destructor = false;
    return SWIG_OK;
  }

  virtual int classHandler(Node *n) {
    SwigType *t = NewStringf("p.%s", Getattr(n, "name"));
    swigtype_ptr = SwigType_manglestr(t);
    Delete(t);
    Language::classHandler(n);
    Delete(swigtype_ptr);
    swigtype_ptr = 0;
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * validIdentifer()
   * ------------------------------------------------------------ */
  
  virtual int validIdentifier(String *s) {
    char *c = Char(s);
    /* Check whether we have an R5RS identifier.*/
    /* <identifier> --> <initial> <subsequent>* | <peculiar identifier> */
    /* <initial> --> <letter> | <special initial> */
    if (!(isalpha(*c) || (*c == '!') || (*c == '$') || (*c == '%')
	  || (*c == '&') || (*c == '*') || (*c == '/') || (*c == ':')
	  || (*c == '<') || (*c == '=') || (*c == '>') || (*c == '?')
	  || (*c == '^') || (*c == '_') || (*c == '~'))) {
      /* <peculiar identifier> --> + | - | ... */
      if ((strcmp(c, "+") == 0)
	  || strcmp(c, "-") == 0
	  || strcmp(c, "...") == 0) return 1;
      else return 0;
    }
    /* <subsequent> --> <initial> | <digit> | <special subsequent> */
    while (*c) {
      if (!(isalnum(*c) || (*c == '!') || (*c == '$') || (*c == '%')
	    || (*c == '&') || (*c == '*') || (*c == '/') || (*c == ':')
	    || (*c == '<') || (*c == '=') || (*c == '>') || (*c == '?')
	    || (*c == '^') || (*c == '_') || (*c == '~') || (*c == '+')
	    || (*c == '-') || (*c == '.') || (*c == '@'))) return 0;
      c++;
    }
    return 1;
  }
};
  
/* -----------------------------------------------------------------------------
 * swig_mzscheme()    - Instantiate module
 * ----------------------------------------------------------------------------- */

extern "C" Language *
swig_mzscheme(void) {
  return new MZSCHEME();
}


