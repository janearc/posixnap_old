/* -----------------------------------------------------------------------------
 * python.cxx
 *
 *     Python module.
 *
 * Author(s) : David Beazley (beazley@cs.uchicago.edu)
 *
 * Copyright (C) 1999-2000.  The University of Chicago
 * See the file LICENSE for information on usage and redistribution.
 * ----------------------------------------------------------------------------- */

char cvsroot_python_cxx[] = "$Header: /home/jabba/convert/cvs/Ficl/SWIG-1.3.21/Source/Modules/python.cxx,v 1.1 2004-02-01 04:05:28 alex Exp $";

#include "swigmod.h"

#ifndef MACSWIG
#include "swigconfig.h"
#endif

#include <ctype.h>

#define PYSHADOW_MEMBER  0x2

static  String       *const_code = 0;
static  String       *shadow_methods = 0;
static  String       *module = 0;
static  String       *mainmodule = 0;
static  String       *interface = 0;
static  String       *global_name = 0;
static  int           shadow = 1;
static  int           use_kw = 0;

static  File         *f_runtime = 0;
static  File         *f_runtime_h = 0;
static  File         *f_header = 0;
static  File         *f_wrappers = 0;
static  File         *f_directors = 0;
static  File         *f_directors_h = 0;
static  File         *f_init = 0;
static  File         *f_shadow = 0;
static  File         *f_shadow_stubs = 0;

static  String       *methods;
static  String       *class_name;
static  String       *shadow_indent = 0;
static  int           in_class = 0;
static  int           classic = 0;
static  int           modern = 0;
static  int           apply = 0;
static  int           new_repr = 0;

/* C++ Support + Shadow Classes */

static  int       have_constructor;
static  int       have_repr;
static  String   *real_classname;

static const char *usage = (char *)"\
Python Options (available with -python)\n\
     -ldflags        - Print runtime libraries to link with\n\
     -globals <name> - Set <name> used to access C global variable [default: 'cvar']\n\
     -interface <lib>- Set the lib name to <lib>\n\
     -keyword        - Use keyword arguments\n\
     -classic        - Use classic classes only\n\
     -modern         - Use modern python features only, without compatibility code\n\
     -apply          - Use apply() in proxy classes\n\
     -new_repr       - Use more informative version of __repr__ in proxy classes\n\
     -noexcept       - No automatic exception handling\n\
     -noproxy        - Don't generate proxy classes \n\n";

class PYTHON : public Language {
public:

  /* ------------------------------------------------------------
   * main()
   * ------------------------------------------------------------ */
  
  virtual void main(int argc, char *argv[]) {

    SWIG_library_directory("python");
  
    for (int i = 1; i < argc; i++) {
      if (argv[i]) {
	if(strcmp(argv[i],"-interface") == 0) {
	  if (argv[i+1]) {
	    interface = NewString(argv[i+1]);
	    Swig_mark_arg(i);
	    Swig_mark_arg(i+1);
	    i++;
	  } else {
	    Swig_arg_error();
	  }
	  /* end added */
	} else if (strcmp(argv[i],"-globals") == 0) {
	  if (argv[i+1]) {
	    global_name = NewString(argv[i+1]);
	    Swig_mark_arg(i);
	    Swig_mark_arg(i+1);
	    i++;
	  } else {
	    Swig_arg_error();
	  }
	} else if ((strcmp(argv[i],"-shadow") == 0) || ((strcmp(argv[i],"-proxy") == 0))) {
	  shadow = 1;
	  Swig_mark_arg(i);
        } else if (strcmp(argv[i],"-apply") == 0) {
          apply = 1;
          Swig_mark_arg(i);
        } else if (strcmp(argv[i],"-new_repr") == 0) {
          new_repr = 1;
          Swig_mark_arg(i);
	} else if ((strcmp(argv[i],"-noproxy") == 0)) {
	  shadow = 0;
	  Swig_mark_arg(i);
	} else if (strcmp(argv[i],"-keyword") == 0) {
	  use_kw = 1;
	  Swig_mark_arg(i);
	} else if (strcmp(argv[i],"-classic") == 0) {
	  classic = 1;
	  Swig_mark_arg(i);
	} else if (strcmp(argv[i],"-modern") == 0) {
	  classic = 0;
          modern = 1;
	  Swig_mark_arg(i);
	} else if (strcmp(argv[i],"-help") == 0) {
	  fputs(usage,stderr);
	} else if (strcmp (argv[i], "-ldflags") == 0) {
	  printf("%s\n", SWIG_PYTHON_RUNTIME);
	  SWIG_exit (EXIT_SUCCESS);
	}
      }
    }
    if (!global_name) global_name = NewString("cvar");
    Preprocessor_define("SWIGPYTHON 1", 0);
    SWIG_typemap_lang("python");
    SWIG_config_file("python.swg");
    allow_overloading();
  }


  /* ------------------------------------------------------------
   * top()
   * ------------------------------------------------------------ */

  virtual int top(Node *n) {
    /* check if directors are enabled for this module.  note: this 
     * is a "master" switch, without which no director code will be
     * emitted.  %feature("director") statements are also required
     * to enable directors for individual classes or methods.
     *
     * use %module(directors="1") modulename at the start of the 
     * interface file to enable director generation.
     */
    {
      Node *module = Getattr(n, "module");
      if (module) {
        Node *options = Getattr(module, "options");
        if (options) {
          if (Getattr(options, "directors")) {
            allow_directors();
          }
          if (Getattr(options, "dirprot")) {
	    allow_dirprot();
          }
        }
      }
    }

    /* Set comparison with none for ConstructorToFunction */
    setSubclassInstanceCheck(NewString("$arg != Py_None"));

    /* Initialize all of the output files */
    String *outfile = Getattr(n,"outfile");
    String *outfile_h = Getattr(n, "outfile_h");

    f_runtime = NewFile(outfile,"w");
    if (!f_runtime) {
      Printf(stderr,"*** Can't open '%s'\n", outfile);
      SWIG_exit(EXIT_FAILURE);
    }
    
    if (directorsEnabled()) {
      f_runtime_h = NewFile(outfile_h,"w");
      if (!f_runtime_h) {
        Printf(stderr,"*** Can't open '%s'\n", outfile_h);
        SWIG_exit(EXIT_FAILURE);
      }
    }

    f_init = NewString("");
    f_header = NewString("");
    f_wrappers = NewString("");
    f_directors_h = NewString("");
    f_directors = NewString("");

    /* Register file targets with the SWIG file handler */
    Swig_register_filebyname("header",f_header);
    Swig_register_filebyname("wrapper",f_wrappers);
    Swig_register_filebyname("runtime",f_runtime);
    Swig_register_filebyname("init",f_init);
    Swig_register_filebyname("director",f_directors);
    Swig_register_filebyname("director_h",f_directors_h);

    const_code     = NewString("");
    shadow_methods = NewString("");
    methods        = NewString("");

    Swig_banner(f_runtime);

    Printf(f_runtime,"#define SWIGPYTHON\n");
    if (NoInclude)
      Printf(f_runtime,"#define SWIG_NOINCLUDE\n");

    if (directorsEnabled()) {
      Printf(f_runtime,"#define SWIG_DIRECTORS\n");
    }

    /* Set module name */
    module = Copy(Getattr(n,"name"));
    mainmodule = Getattr(n,"name");

    if (directorsEnabled()) {
      Swig_banner(f_directors_h);
      Printf(f_directors_h, "#ifndef SWIG_%s_WRAP_H_\n", module);
      Printf(f_directors_h, "#define SWIG_%s_WRAP_H_\n\n", module);
      Printf(f_directors_h, "class Swig::Director;\n\n");
      Swig_insert_file("director.swg", f_directors);
      Printf(f_directors, "\n\n");
      Printf(f_directors, "/* ---------------------------------------------------\n");
      Printf(f_directors, " * C++ director class methods\n");
      Printf(f_directors, " * --------------------------------------------------- */\n\n");
      Printf(f_directors, "#include \"%s\"\n\n", Swig_file_filename(outfile_h));
    }

    /* If shadow classing is enabled, we're going to change the module name to "_module" */
    if (shadow) {
      String *filen = NewStringf("%s%s.py", SWIG_output_directory(), Char(module));
      // If we don't have an interface then change the module name X to _X
      if (interface) module = interface;
      else Insert(module,0,"_");
      if ((f_shadow = NewFile(filen,"w")) == 0) {
	Printf(stderr,"Unable to open %s\n", filen);
	SWIG_exit (EXIT_FAILURE);
      }
      Delete(filen); filen = NULL;

      f_shadow_stubs = NewString("");

      Swig_register_filebyname("shadow",f_shadow);
      Swig_register_filebyname("python",f_shadow);

      Printv(f_shadow,
	     "# This file was created automatically by SWIG.\n",
	     "# Don't modify this file, modify the SWIG interface instead.\n",
	     NIL);

      if (! modern) {
          Printv(f_shadow,
                 "# This file is compatible with both classic and new-style classes.\n",
                 NIL);
      }
      
      Printf(f_shadow,"\nimport %s\n\n", module);

      if (! modern) {
        // Python-2.2 object hack
        Printv(f_shadow,
               "def _swig_setattr(self,class_type,name,value):\n",
               tab4, "if (name == \"this\"):\n",
               tab4, tab4, "if isinstance(value, class_type):\n",
               tab4, tab8, "self.__dict__[name] = value.this\n",
               tab4, tab8, "if hasattr(value,\"thisown\"): self.__dict__[\"thisown\"] = value.thisown\n",
               tab4, tab8, "del value.thisown\n",
               tab4, tab8, "return\n",
               //	   tab8, "if (name == \"this\") or (name == \"thisown\"): self.__dict__[name] = value; return\n",
               tab4, "method = class_type.__swig_setmethods__.get(name,None)\n",
               tab4, "if method: return method(self,value)\n",
               tab4, "self.__dict__[name] = value\n\n",
               NIL);

        Printv(f_shadow,
               "def _swig_getattr(self,class_type,name):\n",
               tab4, "method = class_type.__swig_getmethods__.get(name,None)\n",
               tab4, "if method: return method(self)\n",
               tab4, "raise AttributeError,name\n\n",
               NIL);

        if (!classic) {
          Printv(f_shadow,
                 "import types\n",
                 "try:\n",
                 "    _object = types.ObjectType\n",
                 "    _newclass = 1\n",
                 "except AttributeError:\n",
                 "    class _object : pass\n",
                 "    _newclass = 0\n",
                 "del types\n",
                 "\n\n",
                 NIL);
        }
      }
      
      if (directorsEnabled()) {
        // Try loading weakref.proxy, which is only available in Python 2.1 and higher
        Printv(f_shadow,
               "try:\n",
	       tab4, "from weakref import proxy as weakref_proxy\n",
	       "except:\n",
	       tab4, "weakref_proxy = lambda x: x\n",
	       "\n\n",
	       NIL);
      }

      // Include some information in the code
      Printf(f_header,"\n/*-----------------------------------------------\n              @(target):= %s.so\n\
  ------------------------------------------------*/\n", module);

    }

    Printf(f_header,"#define SWIG_init    init%s\n\n", module);
    Printf(f_header,"#define SWIG_name    \"%s\"\n", module);

    Printf(f_wrappers,"#ifdef __cplusplus\n");
    Printf(f_wrappers,"extern \"C\" {\n");
    Printf(f_wrappers,"#endif\n");
    Printf(const_code,"static swig_const_info swig_const_table[] = {\n");
    Printf(methods,"static PyMethodDef SwigMethods[] = {\n");

    /* emit code */
    Language::top(n);

    /* Close language module */
    Printf(methods,"\t { NULL, NULL }\n");
    Printf(methods,"};\n");
    Printf(f_wrappers,"%s\n",methods);

    SwigType_emit_type_table(f_runtime,f_wrappers);

    Printf(const_code, "{0}};\n");
    Printf(f_wrappers,"%s\n",const_code);
    Printf(f_init,"}\n");

    Printf(f_wrappers,"#ifdef __cplusplus\n");
    Printf(f_wrappers,"}\n");
    Printf(f_wrappers,"#endif\n");

    if (shadow) {
      Printv(f_shadow, f_shadow_stubs, "\n",NIL);
      Close(f_shadow);
      Delete(f_shadow);
    }

    /* Close all of the files */
    Dump(f_header,f_runtime);

    if (directorsEnabled()) {
      Dump(f_directors, f_runtime);
      Dump(f_directors_h, f_runtime_h);
      Printf(f_runtime_h, "\n");
      Printf(f_runtime_h, "#endif\n");
      Close(f_runtime_h);
    }

    Dump(f_wrappers,f_runtime);
    Wrapper_pretty_print(f_init,f_runtime);

    Delete(f_header);
    Delete(f_wrappers);
    Delete(f_init);
    Delete(f_directors);
    Delete(f_directors_h);

    Close(f_runtime);

    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * importDirective()
   * ------------------------------------------------------------ */

  virtual int importDirective(Node *n) {
    if (shadow) {
      String *modname = Getattr(n,"module");
      if (modname) {
	Printf(f_shadow,"import %s\n", modname);
      }
    }
    return Language::importDirective(n);
  }


  /* ------------------------------------------------------------
   * emitFuncCallHelper()
   *    Write the shadow code to call a function in the extension
   *    module.  Takes into account the -apply flag and whether
   *    to use keyword args or not.
   * ------------------------------------------------------------ */

  String *funcCallHelper(String *name, int kw) {
    String *str;
    
    str = NewString("");
    if (apply) {
      Printv(str, "apply(", module, ".", name, ", args", (kw ? ", kwargs" : ""), ")", NIL);
    } else {
      Printv(str, module, ".", name, "(*args", (kw ? ", **kwargs" : ""), ")", NIL);
    }
    return str;
  }


  /* ------------------------------------------------------------
   * emitFunctionShadowHelper()
   *    Refactoring some common code out of functionWrapper and
   *    dispatchFunction that writes the proxy code for non-member
   *    functions.
   * ------------------------------------------------------------ */

  void emitFunctionShadowHelper(Node *n, File *f_dest, String *name, int kw) {
    if ( ! have_addtofunc(n) ) {
      /* If there is no addtofunc directive then just assign from the extension module */
      Printv(f_dest, "\n", name, " = ", module, ".", name, "\n", NIL);
    } else {
      /* Otherwise make a wrapper function to insert the code into */
      Printv(f_dest, "\ndef ", name, "(*args", (kw ? ", **kwargs" : ""), "):\n", NIL);
      Printv(f_dest, tab4, "val = ", funcCallHelper(name, kw), "\n", NIL);
      Printv(f_dest, tab4, addtofunc(n), "\n", NIL);
      Printv(f_dest, tab4, "return val\n", NIL);
    }
  }


  /* ------------------------------------------------------------
   * check_kwargs()
   *    check if using kwargs is allowed for this Node
   * ------------------------------------------------------------ */

  int check_kwargs(Node *n) {
    return ((use_kw || Getattr(n,"feature:kwargs")) && !Getattr(n, "feature:nokwargs")) ? 1 : 0;
  }


  /* ------------------------------------------------------------
   * have_addtofunc()
   *    Check if there is a %addtofunc directive and it has text
   * ------------------------------------------------------------ */

  bool have_addtofunc(Node *n) {
    String* str = Getattr(n, "feature:addtofunc");
    return (str != NULL && Len(str) > 0);
  }
  
  /* ------------------------------------------------------------
   * addtofunc()
   *    Get the %addtofunc code, stripping off {} if neccessary
   * ------------------------------------------------------------ */

  String *addtofunc(Node *n) {
    String* str = Getattr(n, "feature:addtofunc");
    char* t = Char(str);
    if (*t == '{') {
      Delitem(str ,0);
      Delitem(str,DOH_END);
    }
    return str;
  }
    
  /* ------------------------------------------------------------
   * add_method()
   * ------------------------------------------------------------ */

  void add_method(String *name, String *function, int kw) {
    if (!kw)
      Printf(methods,"\t { (char *)\"%s\", %s, METH_VARARGS },\n", name, function);
    else
      Printf(methods,"\t { (char *)\"%s\", (PyCFunction) %s, METH_VARARGS | METH_KEYWORDS },\n", name, function);
  }
  
  /* ------------------------------------------------------------
   * functionWrapper()
   * ------------------------------------------------------------ */

  virtual int functionWrapper(Node *n) {
  
    String  *name  = Getattr(n,"name");
    String  *iname = Getattr(n,"sym:name");
    SwigType *d    = Getattr(n,"type");
    ParmList *l    = Getattr(n,"parms");
    Node *parent   = Getattr(n,"parentNode");

    Parm    *p;
    int     i;
    char    wname[256];
    char    source[64];
    Wrapper *f;
    String *parse_args;
    String *arglist;
    String *get_pointers;
    String *cleanup;
    String *outarg;
    String *kwargs;
    String *tm;
    String *overname = 0;

    int     num_required;
    int     num_arguments;
    int     varargs = 0;
    int     allow_kwargs = check_kwargs(n);

    /* member of a director class? */
    String *nodeType = Getattr(n, "nodeType");
    int constructor = (!Cmp(nodeType, "constructor")); 
    int destructor = (!Cmp(nodeType, "destructor")); 
    String *storage   = Getattr(n,"storage");
    int isVirtual = (Cmp(storage,"virtual") == 0);

    if (Getattr(n,"sym:overloaded")) {
      overname = Getattr(n,"sym:overname");
    } else {
      if (!addSymbol(iname,n)) return SWIG_ERROR;
    }

    f = NewWrapper();
    parse_args   = NewString("");
    arglist      = NewString("");
    get_pointers = NewString("");
    cleanup      = NewString("");
    outarg       = NewString("");
    kwargs       = NewString("");
    
    Wrapper_add_local(f,"resultobj", "PyObject *resultobj");

  /* Write code to extract function parameters. */
    emit_args(d, l, f);

    /* Attach the standard typemaps */
    emit_attach_parmmaps(l,f);
    Setattr(n,"wrap:parms",l);
    /* Get number of required and total arguments */
    num_arguments = emit_num_arguments(l);
    num_required  = emit_num_required(l);
    varargs = emit_isvarargs(l);

    strcpy(wname,Char(Swig_name_wrapper(iname)));
    if (overname) {
      strcat(wname,Char(overname));
    }

    if (!allow_kwargs || Getattr(n,"sym:overloaded")) {
      if (!varargs) {
	Printv(f->def,
	       "static PyObject *", wname,
	       "(PyObject *self, PyObject *args) {",
	       NIL);
      } else {
	Printv(f->def,
	       "static PyObject *", wname, "__varargs__", 
	       "(PyObject *self, PyObject *args, PyObject *varargs) {",
	       NIL);
      }
      if (allow_kwargs) {
	Swig_warning(WARN_LANG_OVERLOAD_KEYWORD, input_file, line_number,
		     "Can't use keyword arguments with overloaded functions.\n");
	allow_kwargs = 0;
      }
    } else {
      if (varargs) {
	Swig_warning(WARN_LANG_VARARGS_KEYWORD, input_file, line_number,
		     "Can't wrap varargs with keyword arguments enabled\n");
	varargs = 0;
      }
      Printv(f->def,
	     "static PyObject *", wname,
	     "(PyObject *self, PyObject *args, PyObject *kwargs) {",
	     NIL);
    }
    if (!allow_kwargs) {
      Printf(parse_args,"    if(!PyArg_ParseTuple(args,(char *)\"");
    } else {
      Printf(parse_args,"    if(!PyArg_ParseTupleAndKeywords(args,kwargs,(char *)\"");
      Printf(arglist,",kwnames");
    }

    /* Generate code for argument marshalling */

    Printf(kwargs,"{ ");  
    for (i = 0, p=l; i < num_arguments; i++) {
    
      while (checkAttribute(p,"tmap:in:numinputs","0")) {
	p = Getattr(p,"tmap:in:next");
      }

      SwigType *pt = Getattr(p,"type");
      String   *pn = Getattr(p,"name");
      String   *ln = Getattr(p,"lname");

      sprintf(source,"obj%d",i);

      Putc(',',arglist);
      if (i == num_required) Putc('|', parse_args);    /* Optional argument separator */

      /* Keyword argument handling */
      if (Len(pn)) {
	Printf(kwargs,"(char *) \"%s\",", pn);
      } else {
	Printf(kwargs,"\"arg%d\",", i+1);
      }

      /* Look for an input typemap */
      if ((tm = Getattr(p,"tmap:in"))) {
	String *parse = Getattr(p,"tmap:in:parse");
	if (!parse) {
	  Replaceall(tm,"$source",source);
	  Replaceall(tm,"$target",ln);
	  Replaceall(tm,"$input", source);
	  Setattr(p,"emit:input", source);   /* Save the location of the object */
	  
	  if (Getattr(p,"wrap:disown") || (Getattr(p,"tmap:in:disown"))) {
	    Replaceall(tm,"$disown","SWIG_POINTER_DISOWN");
	  } else {
	    Replaceall(tm,"$disown","0");
	  }

	  Putc('O',parse_args);
	  Wrapper_add_localv(f, source, "PyObject *",source, "= 0", NIL);
	  Printf(arglist,"&%s",source);
	  if (i >= num_required)
	    Printv(get_pointers, "if (", source, ") {\n", NIL);
	  Printv(get_pointers,tm,"\n", NIL);
	  if (i >= num_required)
	    Printv(get_pointers, "}\n", NIL);

	} else {
	  Printf(parse_args,"%s",parse);
	  Printf(arglist,"&%s", ln);
	}
	p = Getattr(p,"tmap:in:next");
	continue;
      } else {
	Swig_warning(WARN_TYPEMAP_IN_UNDEF, input_file, line_number, 
		     "Unable to use type %s as a function argument.\n",SwigType_str(pt,0));
	break;
      }
      p = nextSibling(p);
    }

    /* finish argument marshalling */
    Printf(kwargs," NULL }");
    if (allow_kwargs) {
      Printv(f->locals,tab4, "char *kwnames[] = ", kwargs, ";\n", NIL);
    }

    Printf(parse_args,":%s\"", iname);
    Printv(parse_args,
	   arglist, ")) goto fail;\n",
	   NIL);

    /* Now piece together the first part of the wrapper function */
    Printv(f->code, parse_args, get_pointers, NIL);

    /* Check for trailing varargs */
    if (varargs) {
      if (p && (tm = Getattr(p,"tmap:in"))) {
	Replaceall(tm,"$input", "varargs");
	Printv(f->code,tm,"\n",NIL);
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
  
    /* Insert cleanup code */
    for (p = l; p;) {
      if ((tm = Getattr(p,"tmap:freearg"))) {
	Replaceall(tm,"$source",Getattr(p,"lname"));
	Printv(cleanup,tm,"\n",NIL);
	p = Getattr(p,"tmap:freearg:next");
      } else {
	p = nextSibling(p);
      }
    }

    /* Insert argument output code */
    for (p = l; p;) {
      if ((tm = Getattr(p,"tmap:argout"))) {
	Replaceall(tm,"$source",Getattr(p,"lname"));
	Replaceall(tm,"$target","resultobj");
	Replaceall(tm,"$arg",Getattr(p,"emit:input"));
	Replaceall(tm,"$input",Getattr(p,"emit:input"));
	Printv(outarg,tm,"\n",NIL);
	p = Getattr(p,"tmap:argout:next");
      } else {
	p = nextSibling(p);
      }
    }
      
    /* if the object is a director, and the method call originated from its
     * underlying python object, resolve the call by going up the c++ 
     * inheritance chain.  otherwise try to resolve the method in python.  
     * without this check an infinite loop is set up between the director and 
     * shadow class method calls.
     */

    // NOTE: this code should only be inserted if this class is the
    // base class of a director class.  however, in general we haven't
    // yet analyzed all classes derived from this one to see if they are
    // directors.  furthermore, this class may be used as the base of
    // a director class defined in a completely different module at a
    // later time, so this test must be included whether or not directorbase
    // is true.  we do skip this code if directors have not been enabled
    // at the command line to preserve source-level compatibility with
    // non-polymorphic swig.  also, if this wrapper is for a smart-pointer
    // method, there is no need to perform the test since the calling object
    // (the smart-pointer) and the director object (the "pointee") are
    // distinct.

    if (directorsEnabled()) {
      if (!is_smart_pointer()) {
        if (/*directorbase &&*/ !constructor && !destructor && isVirtual) {
          Wrapper_add_local(f, "director", "Swig::Director *director = 0");
          Printf(f->code, "director = dynamic_cast<Swig::Director *>(arg1);\n");
	  if (dirprot_mode() && is_protected(n)) {
            Printf(f->code, "if (!director || !(director->swig_get_inner(\"%s\"))) ", name);
	    Printf(f->code, "SWIG_exception(SWIG_RuntimeError,\"accessing protected member %s\");\n", name);
	  }
          Printf(f->code, "if (director && (director->swig_get_self()==obj0)) director->swig_set_up();\n");
	}
      }
    }

    /* for constructor, determine if Python class has been subclassed.
     * if so, create a director instance.  otherwise, just create a normal instance.
     */
    /* MOVED TO Swig_ConstructorToFunction() */
    /*
    if (constructor && (Getattr(n, "wrap:self") != 0)) {
      Wrapper_add_local(f, "subclassed", "int subclassed = 0");
      Printf(f->code, "subclassed = (arg1 != Py_None);\n");
    }
    */
     
    /* Emit the function call */
    emit_action(n,f);

    /* This part below still needs cleanup */

  /* Return the function value */
    if ((tm = Swig_typemap_lookup_new("out",n,"result",0))) {
      Replaceall(tm,"$source", "result");
      Replaceall(tm,"$target", "resultobj");
      Replaceall(tm,"$result", "resultobj");
      if (Getattr(n,"feature:new")) {
	Replaceall(tm,"$owner","1");
      } else {
	Replaceall(tm,"$owner","0");
      }

      // FIXME: this will not try to unwrap directors returned as non-director
      //        base class pointers!

      /* New addition to unwrap director return values so that the original
       * python object is returned instead. 
       */
      int unwrap = 0;
      String *decl = Getattr(n, "decl");
      int is_pointer = SwigType_ispointer_return(decl);
      int is_reference = SwigType_isreference_return(decl);
      if (is_pointer || is_reference) {
        String *type = Getattr(n, "type");
  	//Node *classNode = Swig_methodclass(n);
        //Node *module = Getattr(classNode, "module");
        Node *module = Getattr(parent, "module");
        Node *target = Swig_directormap(module, type);
	if (target) unwrap = 1;
      }
      if (unwrap) {
      	Wrapper_add_local(f, "resultdirector", "Swig::Director *resultdirector = 0");
	Printf(f->code, "resultdirector = dynamic_cast<Swig::Director *>(result);\n");
	Printf(f->code, "if (resultdirector) {\n");
	Printf(f->code, "  resultobj = resultdirector->swig_get_self();\n");
	Printf(f->code, "  Py_INCREF(resultobj);\n");
	Printf(f->code, "} else {\n"); 
        Printf(f->code,"%s\n", tm);
        Printf(f->code, "}\n");
      } else {
        Printf(f->code,"%s\n", tm);
      }
    } else {
      Swig_warning(WARN_TYPEMAP_OUT_UNDEF, input_file, line_number,
		   "Unable to use return type %s in function %s.\n", SwigType_str(d,0), name);
    }

    /* Output argument output code */
    Printv(f->code,outarg,NIL);

    /* Output cleanup code */
    Printv(f->code,cleanup,NIL);

    /* Look to see if there is any newfree cleanup code */
    if (Getattr(n,"feature:new")) {
      if ((tm = Swig_typemap_lookup_new("newfree",n,"result",0))) {
	Replaceall(tm,"$source","result");
	Printf(f->code,"%s\n",tm);
      }
    }

    /* See if there is any return cleanup code */
    if ((tm = Swig_typemap_lookup_new("ret", n, "result", 0))) {
      Replaceall(tm,"$source","result");
      Printf(f->code,"%s\n",tm);
    }

    Printf(f->code,"    return resultobj;\n");

    /* Error handling code */

    Printf(f->code,"fail:\n");
    Printv(f->code,cleanup,NIL);
    Printf(f->code,"return NULL;\n");
    Printf(f->code,"}\n");

    /* Substitute the cleanup code */
    Replaceall(f->code,"$cleanup",cleanup);

    /* Substitute the function name */
    Replaceall(f->code,"$symname",iname);
    Replaceall(f->code,"$result","resultobj");

    /* Dump the function out */
    Wrapper_print(f,f_wrappers);

    /* If varargs.  Need to emit a varargs stub */
    if (varargs) {
      DelWrapper(f);
      f = NewWrapper();
      Printv(f->def,
	     "static PyObject *", wname,
	     "(PyObject *self, PyObject *args) {",
	     NIL);
      Wrapper_add_local(f,"resultobj", "PyObject *resultobj");
      Wrapper_add_local(f,"varargs", "PyObject *varargs");
      Wrapper_add_local(f,"newargs", "PyObject *newargs");
      Printf(f->code,"newargs = PyTuple_GetSlice(args,0,%d);\n", num_arguments);
      Printf(f->code,"varargs = PyTuple_GetSlice(args,%d,PyTuple_Size(args)+1);\n", num_arguments);
      Printf(f->code,"resultobj = %s__varargs__(self,newargs,varargs);\n", wname);
      Printf(f->code,"Py_XDECREF(newargs);\n");
      Printf(f->code,"Py_XDECREF(varargs);\n");
      Printf(f->code,"return resultobj;\n");
      Printf(f->code,"}\n");
      Wrapper_print(f,f_wrappers);
    }

    Setattr(n,"wrap:name", wname);

    /* Now register the function with the interpreter.   */
    if (!Getattr(n,"sym:overloaded")) {
      add_method(iname, wname, allow_kwargs);

      /* Create a shadow for this function (if enabled and not in a member function) */
      if ((shadow) && (!(shadow & PYSHADOW_MEMBER))) {
        emitFunctionShadowHelper(n, in_class ? f_shadow_stubs : f_shadow, iname, allow_kwargs);
      }
    } else {
      if (!Getattr(n,"sym:nextSibling")) {
	dispatchFunction(n);
      }
    }
    Delete(parse_args);
    Delete(arglist);
    Delete(get_pointers);
    Delete(cleanup);
    Delete(outarg);
    Delete(kwargs);
    DelWrapper(f);
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * dispatchFunction()
   * ------------------------------------------------------------ */
  void dispatchFunction(Node *n) {
    /* Last node in overloaded chain */

    int maxargs;
    String *tmp = NewString("");
    String *dispatch = Swig_overload_dispatch(n,"return %s(self,args);",&maxargs);
	
    /* Generate a dispatch wrapper for all overloaded functions */

    Wrapper *f       = NewWrapper();
    String  *symname = Getattr(n,"sym:name");
    String  *wname   = Swig_name_wrapper(symname);

    Printv(f->def,	
	   "static PyObject *", wname,
	   "(PyObject *self, PyObject *args) {",
	   NIL);
    
    Wrapper_add_local(f,"argc","int argc");
    Printf(tmp,"PyObject *argv[%d]", maxargs+1);
    Wrapper_add_local(f,"argv",tmp);
    Wrapper_add_local(f,"ii","int ii");
    Printf(f->code,"argc = PyObject_Length(args);\n");
    Printf(f->code,"for (ii = 0; (ii < argc) && (ii < %d); ii++) {\n",maxargs);
    Printf(f->code,"argv[ii] = PyTuple_GetItem(args,ii);\n");
    Printf(f->code,"}\n");
    
    Replaceall(dispatch,"$args","self,args");
    Printv(f->code,dispatch,"\n",NIL);
    Printf(f->code,"PyErr_SetString(PyExc_TypeError,\"No matching function for overloaded '%s'\");\n", symname);
    Printf(f->code,"return NULL;\n");
    Printv(f->code,"}\n",NIL);
    Wrapper_print(f,f_wrappers);
    add_method(symname,wname,0);

    /* Create a shadow for this function (if enabled and not in a member function) */
    if ((shadow) && (!(shadow & PYSHADOW_MEMBER))) {
      emitFunctionShadowHelper(n, f_shadow_stubs, symname, 0);
    }
    DelWrapper(f);
    Delete(dispatch);
    Delete(tmp);
    Delete(wname);
  }

  /* ------------------------------------------------------------
   * variableWrapper()
   * ------------------------------------------------------------ */

  virtual int variableWrapper(Node *n) {
    String *name  = Getattr(n,"name");
    String *iname = Getattr(n,"sym:name");
    SwigType *t = Getattr(n,"type");
    
    String *wname;
    static int have_globals = 0;
    String  *tm;
    Wrapper *getf, *setf;

    if (!addSymbol(iname,n)) return SWIG_ERROR;

    getf = NewWrapper();
    setf = NewWrapper();

   /* If this is our first call, add the globals variable to the
      Python dictionary. */

    if (!have_globals) {
      Printf(f_init,"\t PyDict_SetItemString(d,(char*)\"%s\", SWIG_globals);\n",global_name);
      have_globals=1;
      if ((shadow) && (!(shadow & PYSHADOW_MEMBER))) {
	Printf(f_shadow_stubs,"%s = %s.%s\n", global_name, module, global_name);
      }
    }

    if ((shadow) && (SwigType_isconst(t))) {
	if (!in_class) {
	  Printf(f_shadow_stubs,"%s = %s.%s\n", iname, global_name, iname);
	}
    }

    wname = Swig_name_wrapper(iname);

    /* Create a function for setting the value of the variable */

    Printf(setf->def,"static int %s_set(PyObject *_val) {", wname);
    if (!Getattr(n,"feature:immutable")) {
      if ((tm = Swig_typemap_lookup_new("varin",n,name,0))) {
	Replaceall(tm,"$source","_val");
	Replaceall(tm,"$target",name);
	Replaceall(tm,"$input","_val");
	Printf(setf->code,"%s\n",tm);
	Delete(tm);
      } else {
	Swig_warning(WARN_TYPEMAP_VARIN_UNDEF, input_file, line_number, 
		     "Unable to set variable of type %s.\n", SwigType_str(t,0));
      }
      Printf(setf->code,"    return 0;\n");
    } else {
      /* Is a readonly variable.  Issue an error */
      Printv(setf->code,
	     tab4, "PyErr_SetString(PyExc_TypeError,\"Variable ", iname,
	     " is read-only.\");\n",
	     tab4, "return 1;\n",
	     NIL);
    }

    Printf(setf->code,"}\n");
    Wrapper_print(setf,f_wrappers);

    /* Create a function for getting the value of a variable */
    Printf(getf->def,"static PyObject *%s_get() {", wname);
    Wrapper_add_local(getf,"pyobj", "PyObject *pyobj");
    if ((tm = Swig_typemap_lookup_new("varout",n,name,0))) {
      Replaceall(tm,"$source",name);
      Replaceall(tm,"$target","pyobj");
      Replaceall(tm,"$result","pyobj");
      Printf(getf->code,"%s\n", tm);
    } else {
      Swig_warning(WARN_TYPEMAP_VAROUT_UNDEF, input_file, line_number,
		   "Unable to read variable of type %s\n", SwigType_str(t,0));
    }
    
    Printf(getf->code,"    return pyobj;\n}\n");
    Wrapper_print(getf,f_wrappers);

    /* Now add this to the variable linking mechanism */
    Printf(f_init,"\t SWIG_addvarlink(SWIG_globals,(char*)\"%s\",%s_get, %s_set);\n", iname, wname, wname);

    DelWrapper(setf);
    DelWrapper(getf);
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * constantWrapper()
   * ------------------------------------------------------------ */

  virtual int constantWrapper(Node *n) {
    String *name    = Getattr(n,"name");
    String *iname   = Getattr(n,"sym:name");
    SwigType *type  = Getattr(n,"type");
    String   *value = Getattr(n,"value");
    String  *tm;
    int     have_tm = 0;

    if (!addSymbol(iname,n)) return SWIG_ERROR;

  /* Special hook for member pointer */
    if (SwigType_type(type) == T_MPOINTER) {
      String *wname = Swig_name_wrapper(iname);
      Printf(f_header, "static %s = %s;\n", SwigType_str(type,wname), value);
      value = wname;
    }
    if ((tm = Swig_typemap_lookup_new("consttab",n,name,0))) {
      Replaceall(tm,"$source",value);
      Replaceall(tm,"$target",name);
      Replaceall(tm,"$value", value);
      Printf(const_code,"%s,\n", tm);
      have_tm = 1;
    }
    if ((tm = Swig_typemap_lookup_new("constcode", n, name, 0))) {
      Replaceall(tm,"$source",value);
      Replaceall(tm,"$target",name);
      Replaceall(tm,"$value",value);
      Printf(f_init, "%s\n", tm);
      have_tm = 1;
    }
    if (!have_tm) {
      Swig_warning(WARN_TYPEMAP_CONST_UNDEF, input_file, line_number,
		   "Unsupported constant value.\n");
      return SWIG_NOWRAP;
    }
    if ((shadow) && (!(shadow & PYSHADOW_MEMBER))) {
      if (!in_class) {
	Printv(f_shadow,iname, " = ", module, ".", iname, "\n", NIL);
      } else {
	Printv(f_shadow_stubs,iname, " = ", module, ".", iname, "\n", NIL);      
      }
    }
    return SWIG_OK;
  }

  /* ------------------------------------------------------------ 
   * nativeWrapper()
   * ------------------------------------------------------------ */

  virtual int nativeWrapper(Node *n) {
    String *name     = Getattr(n,"sym:name");
    String *wrapname = Getattr(n,"wrap:name");

    if (!addSymbol(wrapname,n)) return SWIG_ERROR;

    add_method(name, wrapname,0);
    if (shadow) {
      Printv(f_shadow_stubs, name, " = ", module, ".", name, "\n\n", NIL);
    }
    return SWIG_OK;
  }


/*************************************************************************************
 * BEGIN C++ Director Class modifications
 ************************************************************************************/

/* C++/Python polymorphism demo code, copyright (C) 2002 Mark Rose <mrose@stm.lbl.gov>
 *
 * TODO
 *
 * Move some boilerplate code generation to Swig_...() functions.
 *
 */

  /* ---------------------------------------------------------------
   * classDirectorMethod()
   *
   * Emit a virtual director method to pass a method call on to the 
   * underlying Python object.
   *
   * --------------------------------------------------------------- */

  int classDirectorMethod(Node *n, Node *parent, String *super) {
    int is_void = 0;
    int is_pointer = 0;
    String *decl;
    String *type;
    String *name;
    String *classname;
    String *declaration;
    ParmList *l;
    Wrapper *w;
    String *tm;
    String *wrap_args;
    String *return_type;
    String *value = Getattr(n, "value");
    String *storage = Getattr(n,"storage");
    bool pure_virtual = false;
    int status = SWIG_OK;
    int idx;

    if (Cmp(storage,"virtual") == 0) {
      if (Cmp(value,"0") == 0) {
        pure_virtual = true;
      }
    }

    classname = Getattr(parent, "sym:name");
    type = Getattr(n, "type");
    name = Getattr(n, "name");

    w = NewWrapper();
    declaration = NewString("");
	
    /* determine if the method returns a pointer */
    decl = Getattr(n, "decl");
    is_pointer = SwigType_ispointer_return(decl);
    is_void = (!Cmp(type, "void") && !is_pointer);

    /* form complete return type */
    return_type = Copy(type);
    {
    	SwigType *t = Copy(decl);
	SwigType *f = 0;
	f = SwigType_pop_function(t);
	SwigType_push(return_type, t);
	Delete(f);
	Delete(t);
    }

    /* virtual method definition */
    l = Getattr(n, "parms");
    String *target;
    String *pclassname = NewStringf("SwigDirector_%s", classname);
    String *qualified_name = NewStringf("%s::%s", pclassname, name);
    target = Swig_method_decl(decl, qualified_name, l, 0, 0);
    String *rtype = SwigType_str(type, 0);
    Printf(w->def, "%s %s {", rtype, target);
    Delete(qualified_name);
    Delete(target);
    /* header declaration */
    target = Swig_method_decl(decl, name, l, 0, 1);
    Printf(declaration, "    virtual %s %s;\n", rtype, target);
    Delete(target);
    
    /* attach typemaps to arguments (C/C++ -> Python) */
    String *arglist = NewString("");
    String* parse_args = NewString("");

    Swig_typemap_attach_parms("in", l, w);
    Swig_typemap_attach_parms("directorin", l, w);
    Swig_typemap_attach_parms("directorout", l, w);
    Swig_typemap_attach_parms("directorargout", l, w);

    Parm* p;
    int num_arguments = emit_num_arguments(l);
    int i;
    char source[256];

    wrap_args = NewString("");
    int outputs = 0;
    if (!is_void) outputs++;
	
    /* build argument list and type conversion string */
    for (i=0, idx=0, p = l; i < num_arguments && p != 0; i++) {

      if (checkAttribute(p,"tmap:in:numinputs","0")) {
	p = Getattr(p,"tmap:in:next");
	continue;
      }

      /* old style?  caused segfaults without the p!=0 check
         in the for() condition, and seems dangerous in the
	 while loop as well.
      while (Getattr(p, "tmap:ignore")) {
	p = Getattr(p, "tmap:ignore:next");
      }
      */

      if (Getattr(p, "tmap:directorargout") != 0) outputs++;
      
      String* pname = Getattr(p, "name");
      String* ptype = Getattr(p, "type");
      
      Putc(',',arglist);
      if ((tm = Getattr(p, "tmap:directorin")) != 0) {
	String* parse = Getattr(p, "tmap:directorin:parse");
	if (!parse) {
	  sprintf(source, "obj%d", idx++);
	  Replaceall(tm, "$input", source);
	  Replaceall(tm, "$owner", "0");
	  Printv(wrap_args, tm, "\n", NIL);
	  Wrapper_add_localv(w, source, "PyObject *", source, "= 0", NIL);
	  Printv(arglist, source, NIL);
	  Putc('O', parse_args);
	} else {
	  Printf(parse_args, "%s", parse);
	  Replaceall(tm, "$input", pname);
	  Replaceall(tm, "$owner", "0");
	  if (Len(tm) == 0) Append(tm, pname);
	  Printf(arglist, "%s", tm);
	}
	p = Getattr(p, "tmap:directorin:next");
	continue;
      } else
      if (Cmp(ptype, "void")) {
	/* special handling for pointers to other C++ director classes.
	 * ideally this would be left to a typemap, but there is currently no
	 * way to selectively apply the dynamic_cast<> to classes that have
	 * directors.  in other words, the type "SwigDirector_$1_lname" only exists
	 * for classes with directors.  we avoid the problem here by checking
	 * module.wrap::directormap, but it's not clear how to get a typemap to
	 * do something similar.  perhaps a new default typemap (in addition
	 * to SWIGTYPE) called DIRECTORTYPE?
	 */
	if (SwigType_ispointer(ptype) || SwigType_isreference(ptype)) {
	  Node *module = Getattr(parent, "module");
	  Node *target = Swig_directormap(module, ptype);
	  sprintf(source, "obj%d", idx++);
	  String *nonconst = 0;
	  /* strip pointer/reference --- should move to Swig/stype.c */
	  String *nptype = NewString(Char(ptype)+2);
	  /* name as pointer */
	  String *ppname = Copy(pname);
	  if (SwigType_isreference(ptype)) {
      	     Insert(ppname,0,"&");
	  }
	  /* if necessary, cast away const since Python doesn't support it! */
	  if (SwigType_isconst(nptype)) {
	    nonconst = NewStringf("nc_tmp_%s", pname);
	    String *nonconst_i = NewStringf("= const_cast<%s>(%s)", SwigType_lstr(ptype, 0), ppname);
	    Wrapper_add_localv(w, nonconst, SwigType_lstr(ptype, 0), nonconst, nonconst_i, NIL);
	    Delete(nonconst_i);
	    Swig_warning(WARN_LANG_DISCARD_CONST, input_file, line_number,
		         "Target language argument '%s' discards const in director method %s::%s.\n", SwigType_str(ptype, pname), classname, name);
	  } else {
	    nonconst = Copy(ppname);
	  }
	  Delete(nptype);
	  Delete(ppname);
	  String *mangle = SwigType_manglestr(ptype);
	  if (target) {
	    String *director = NewStringf("director_%s", mangle);
	    Wrapper_add_localv(w, director, "Swig::Director *", director, "= 0", NIL);
	    Wrapper_add_localv(w, source, "PyObject *", source, "= 0", NIL);
	    Printf(wrap_args, "%s = dynamic_cast<Swig::Director *>(%s);\n", director, nonconst);
	    Printf(wrap_args, "if (!%s) {\n", director);
	    Printf(wrap_args,   "%s = SWIG_NewPointerObj(%s, SWIGTYPE%s, 0);\n", source, nonconst, mangle);
	    Printf(wrap_args, "} else {\n");
	    Printf(wrap_args,   "%s = %s->swig_get_self();\n", source, director);
	    Printf(wrap_args,   "Py_INCREF(%s);\n", source);
	    Printf(wrap_args, "}\n");
	    Delete(director);
	    Printv(arglist, source, NIL);
	  } else {
	    Wrapper_add_localv(w, source, "PyObject *", source, "= 0", NIL);
	    Printf(wrap_args, "%s = SWIG_NewPointerObj(%s, SWIGTYPE%s, 0);\n", 
	           source, nonconst, mangle); 
	    //Printf(wrap_args, "%s = SWIG_NewPointerObj(%s, SWIGTYPE_p_%s, 0);\n", 
	    //       source, nonconst, base);
	    Printv(arglist, source, NIL);
	  }
	  Putc('O', parse_args);
	  Delete(mangle);
	  Delete(nonconst);
	} else {
	  Swig_warning(WARN_TYPEMAP_DIRECTORIN_UNDEF, input_file, line_number,
		       "Unable to use type %s as a function argument in director method %s::%s (skipping method).\n", SwigType_str(ptype, 0), classname, name);
          status = SWIG_NOWRAP;
	  break;
	}
      }
      p = nextSibling(p);
    }

    /* declare method return value 
     * if the return value is a reference or const reference, a specialized typemap must
     * handle it, including declaration of c_result ($result).
     */
    if (!is_void) {
      Wrapper_add_localv(w, "c_result", SwigType_lstr(return_type, "c_result"), NIL);
    }
    /* declare Python return value */
    Wrapper_add_local(w, "result", "PyObject *result");

    /* direct call to superclass if _up is set */
    Printf(w->code, "if (swig_get_up()) {\n");
    if (pure_virtual) {
    	Printf(w->code, "throw Swig::DirectorPureVirtualException();\n");
    } else {
    	if (is_void) {
    	  Printf(w->code, "%s;\n", Swig_method_call(super,l));
    	  Printf(w->code, "return;\n");
	} else {
    	  Printf(w->code, "return %s;\n", Swig_method_call(super,l));
	}
    }
    Printf(w->code, "}\n");
    
    /* wrap complex arguments to PyObjects */
    Printv(w->code, wrap_args, NIL);

    String  *pyname = Getattr(n,"sym:name");

    /* pass the method call on to the Python object */
    if (dirprot_mode() && is_protected(n))
      Printf(w->code, "swig_set_inner(\"%s\", true);\n", name);

    if (Len(parse_args) > 0) {
      Printf(w->code, "result = PyObject_CallMethod(swig_get_self(), \"%s\", \"%s\" %s);\n", pyname, parse_args, arglist);
    } else {
      Printf(w->code, "result = PyObject_CallMethod(swig_get_self(), \"%s\", NULL);\n", pyname);
    }
    if (dirprot_mode() && is_protected(n))
      Printf(w->code, "swig_set_inner(\"%s\", false);\n", name);

    /* exception handling */
    tm = Swig_typemap_lookup_new("director:except", n, "result", 0);
    if (!tm) {
      tm = Getattr(n, "feature:director:except");
    }
    if ((tm) && Len(tm) && (Strcmp(tm, "1") != 0)) {
      Printf(w->code, "if (result == NULL) {\n");
      Printf(w->code, "  PyObject *error = PyErr_Occurred();\n");
      Replaceall(tm, "$error", "error");
      Printv(w->code, Str(tm), "\n", NIL);
      Printf(w->code, "}\n");
    }

    /*
    * Python method may return a simple object, or a tuple.
    * for in/out aruments, we have to extract the appropriate PyObjects from the tuple,
    * then marshal everything back to C/C++ (return value and output arguments).
    *
    */

    /* marshal return value and other outputs (if any) from PyObject to C/C++ type */

    String* cleanup = NewString("");
    String* outarg = NewString("");

    if (outputs > 1) {
      Wrapper_add_local(w, "output", "PyObject *output");
      Printf(w->code, "if (!PyTuple_Check(result)) {\n");
      Printf(w->code, "throw Swig::DirectorTypeMismatchException(\"Python method failed to return a tuple.\");\n");
      Printf(w->code, "}\n");
    }

    idx = 0;

    /* marshal return value */
    if (!is_void) {
      /* this seems really silly.  the node's type excludes qualifier/pointer/reference markers,
       * which have to be retrieved from the decl field to construct return_type.  but the typemap
       * lookup routine uses the node's type, so we have to swap in and out the correct type.
       * it's not just me, similar silliness also occurs in Language::cDeclaration().
       */
      Setattr(n, "type", return_type);
      tm = Swig_typemap_lookup_new("directorout", n, "result", w);
      Setattr(n, "type", type);
      if (tm == 0) {
        String *name = NewString("result");
        tm = Swig_typemap_search("directorout", return_type, name, NULL);
	Delete(name);
      }
      if (tm != 0) {
	if (outputs > 1) {
	  Printf(w->code, "output = PyTuple_GetItem(result, %d);\n", idx++);
	  Replaceall(tm, "$input", "output");
	} else {
	  Replaceall(tm, "$input", "result");
	}
	/* TODO check this */
	if (Getattr(n,"wrap:disown")) {
	  Replaceall(tm,"$disown","SWIG_POINTER_DISOWN");
	} else {
	  Replaceall(tm,"$disown","0");
	}
	Replaceall(tm, "$result", "c_result");
	Printv(w->code, tm, "\n", NIL);
      } else {
	Swig_warning(WARN_TYPEMAP_OUT_UNDEF, input_file, line_number,
		     "Unable to return type %s in director method %s::%s (skipping method).\n", SwigType_str(return_type, 0), classname, name);
        status = SWIG_ERROR;
      }
    }
	  
    /* marshal outputs */
    for (p = l; p; ) {
      if ((tm = Getattr(p, "tmap:directorargout")) != 0) {
	if (outputs > 1) {
	  Printf(w->code, "output = PyTuple_GetItem(result, %d);\n", idx++);
	  Replaceall(tm, "$input", "output");
	} else {
	  Replaceall(tm, "$input", "result");
	}
	Replaceall(tm, "$result", Getattr(p, "name"));
	Printv(w->code, tm, "\n", NIL);
	p = Getattr(p, "tmap:directorargout:next");
      } else {
	p = nextSibling(p);
      }
    }

    Printf(w->code, "Py_XDECREF(result);\n");

    /* any existing helper functions to handle this? */
    if (!is_void) {
      if (!SwigType_isreference(return_type)) {
        Printf(w->code, "return c_result;\n");
      } else {
        Printf(w->code, "return *c_result;\n");
      }
    }

    Printf(w->code, "}\n");

    /* emit the director method */
    if (status == SWIG_OK) {
      Wrapper_print(w, f_directors);
      Printv(f_directors_h, declaration, NIL);
    }

    /* clean up */
    Delete(wrap_args);
    Delete(parse_args);
    Delete(arglist);
    Delete(rtype);
    Delete(return_type);
    Delete(pclassname);
    Delete(cleanup);
    Delete(outarg);
    DelWrapper(w);
    return status;
  }

  /* ------------------------------------------------------------
   * classDirectorConstructor()
   * ------------------------------------------------------------ */

  int classDirectorConstructor(Node *n) {
    Node *parent = Getattr(n, "parentNode");
    String *sub = NewString("");
    String *decl = Getattr(n, "decl");
    String *supername = Swig_class_name(parent);
    String *classname = NewString("");
    Printf(classname, "SwigDirector_%s", supername);

    /* insert self and disown parameters */
    Parm *p, *ip;
    ParmList *superparms = Getattr(n, "parms");
    ParmList *parms = CopyParmList(superparms);
    String *type = NewString("PyObject");
    SwigType_add_pointer(type);
    p = NewParm(type, NewString("self"));
    set_nextSibling(p, parms);
    parms = p;
    for (ip = parms; nextSibling(ip); ) ip = nextSibling(ip);
    p = NewParm(NewString("bool"), NewString("disown"));
    Setattr(p, "arg:byname", "1");
    Setattr(n, "director:postfix_args", p);
    Setattr(p, "value", "false");
    set_nextSibling(ip, p);
    
    /* constructor */
    {
      Wrapper *w = NewWrapper();
      String *call;
      String *basetype = Getattr(parent, "classtype");
      String *target = Swig_method_decl(decl, classname, parms, 0, 0);
      call = Swig_csuperclass_call(0, basetype, superparms);
      Printf(w->def, "%s::%s: %s, Swig::Director(self, disown) { }", classname, target, call);
      Delete(target);
      Wrapper_print(w, f_directors);
      Delete(call);
      DelWrapper(w);
    }
    
    /* constructor header */
    {
      String *target = Swig_method_decl(decl, classname, parms, 0, 1);
      Printf(f_directors_h, "    %s;\n", target);
      Delete(target);
    }

    Delete(sub);
    Delete(classname);
    Delete(supername);
    Delete(parms);
    return Language::classDirectorConstructor(n);
  }

  /* ------------------------------------------------------------
   * classDirectorDefaultConstructor()
   * ------------------------------------------------------------ */
   
  int classDirectorDefaultConstructor(Node *n) {
    String *classname;
    classname = Swig_class_name(n);
    {
      Wrapper *w = NewWrapper();
      Printf(w->def, "SwigDirector_%s::SwigDirector_%s(PyObject* self, bool disown) : Swig::Director(self, disown) { }", classname, classname);
      Wrapper_print(w, f_directors);
      DelWrapper(w);
    }
    Printf(f_directors_h, "    SwigDirector_%s(PyObject* self, bool disown = false);\n", classname);
    Delete(classname);
    return Language::classDirectorDefaultConstructor(n);
  }


  /* ------------------------------------------------------------
   * classDirectorInit()
   * ------------------------------------------------------------ */

  int classDirectorInit(Node *n) {
    if (dirprot_mode()) {
      Printf(f_directors_h, "#include <map>\n");
      Printf(f_directors_h, "#include <string>\n\n");
    }    

    String *declaration = Swig_director_declaration(n);
    Printf(f_directors_h, "\n");
    Printf(f_directors_h, "%s\n", declaration);
    Printf(f_directors_h, "public:\n");
    Delete(declaration);
    return Language::classDirectorInit(n);
  }

  /* ------------------------------------------------------------
   * classDirectorEnd()
   * ------------------------------------------------------------ */

  int classDirectorEnd(Node *n) {
    if (dirprot_mode()) {
      /*
	This implementation uses a std::map<std::string,int>.

	It should be possible to rewrite it using a more elegant way,
	like copying the Java approach for the 'override' array.

	But for know, this seems to be the least intrusive way.
      */
      Printf(f_directors_h,"\n\n");
      Printf(f_directors_h,"/* Internal Director utilities */\n");
      Printf(f_directors_h,"public:\n");
      Printf(f_directors_h,"    bool swig_get_inner(const char* name) const {\n");
      Printf(f_directors_h,"      std::map<std::string, bool>::const_iterator iv = inner.find(name);\n");
      Printf(f_directors_h,"      return (iv != inner.end() ? iv->second : false);\n");
      Printf(f_directors_h,"    }\n\n");
      
      Printf(f_directors_h,"    void swig_set_inner(const char* name, bool val) const\n");
      Printf(f_directors_h,"    { inner[name] = val;}\n\n");
      Printf(f_directors_h,"private:\n");
      Printf(f_directors_h,"    mutable std::map<std::string, bool> inner;\n");

    }
    Printf(f_directors_h, "};\n\n");
    return Language::classDirectorEnd(n);
  }

  /* ------------------------------------------------------------
   * classDirectorDisown()
   * ------------------------------------------------------------ */

  int classDirectorDisown(Node *n) {
    int result;
    int oldshadow = shadow;
    /* disable shadowing */
    if (shadow) shadow = shadow | PYSHADOW_MEMBER;
    result = Language::classDirectorDisown(n);
    shadow = oldshadow;
    if (shadow) {
      String *symname = Getattr(n,"sym:name");
      String *mrename = Swig_name_disown(symname); //Getattr(n, "name"));
      Printv(f_shadow, tab4, "def __disown__(self):\n", NIL);
      Printv(f_shadow, tab8, "self.thisown = 0\n", NIL);
      Printv(f_shadow, tab8, module, ".", mrename,"(self)\n", NIL);
      Printv(f_shadow, tab8, "return weakref_proxy(self)\n", NIL);
      Delete(mrename);
    }
    return result;
  }

/*************************************************************************************
 * END of C++ Director Class modifications
 ************************************************************************************/
 

  /* ------------------------------------------------------------
   * classDeclaration()
   * ------------------------------------------------------------ */

  virtual int classDeclaration(Node *n) {
    String *importname;
    Node   *mod;
    if (shadow) {
      mod = Getattr(n,"module");
      if (mod) {
	String *modname = Getattr(mod,"name");
	if (Strcmp(modname,mainmodule) != 0) {
	  importname = NewStringf("%s.%s", modname, Getattr(n,"sym:name"));
	} else {
	  importname = NewString(Getattr(n,"sym:name"));
	}
	Setattr(n,"python:proxy",importname);
      }
    }
    return Language::classDeclaration(n);
  }

  /* ------------------------------------------------------------
   * classHandler()
   * ------------------------------------------------------------ */

  virtual int classHandler(Node *n) {
    int oldclassic = classic;
    int oldmodern  = modern;
    File   *f_shadow_file = f_shadow;

    if (shadow) {

      /* Create new strings for building up a wrapper function */
      have_constructor = 0;
      have_repr = 0;
      
      if (Getattr(n,"cplus:exceptionclass")) {
	classic = 1;
        modern  = 0;
      }
      if (Getattr(n,"feature:classic")) {
        classic = 1;
        modern  = 0;
      }
      if (Getattr(n,"feature:modern")) {
        classic = 0;
        modern = 1;
      }

      shadow_indent = (String *) tab4;
      
      class_name = Getattr(n,"sym:name");
      real_classname = Getattr(n,"name");
      
      if (!addSymbol(class_name,n)) return SWIG_ERROR;
      
      /* Handle inheritance */
      String *base_class = NewString("");
      List *baselist = Getattr(n,"bases");
      if (baselist && Len(baselist)) {
	Iterator b;
	b = First(baselist);
	while (b.item) {
	  String *bname = Getattr(b.item, "python:proxy");
	  if (!bname) {
	    b = Next(b);
	    continue;
	  }
	  Printv(base_class,bname,NIL);
	  b = Next(b);
	  if (b.item) {
	    Putc(',',base_class);
	  }
	}
      }
      Printv(f_shadow,"class ", class_name, NIL);

      if (Len(base_class)) {
	Printf(f_shadow,"(%s)", base_class);
      } else {
	if (!classic) {
	  Printf(f_shadow, modern ? "(object)" : "(_object)");
	}
      }
      Printf(f_shadow,":\n");

      if (!modern) {
        Printv(f_shadow,tab4,"__swig_setmethods__ = {}\n",NIL);
        if (Len(base_class)) {
          Printf(f_shadow,"%sfor _s in [%s]: __swig_setmethods__.update(_s.__swig_setmethods__)\n",tab4,base_class);
        }
      
        Printv(f_shadow,
               tab4, "__setattr__ = lambda self, name, value: _swig_setattr(self, ", class_name, ", name, value)\n",
               NIL);

        Printv(f_shadow,tab4,"__swig_getmethods__ = {}\n",NIL);
        if (Len(base_class)) {
          Printf(f_shadow,"%sfor _s in [%s]: __swig_getmethods__.update(_s.__swig_getmethods__)\n",tab4,base_class);
        }
      
        Printv(f_shadow,
               tab4, "__getattr__ = lambda self, name: _swig_getattr(self, ", class_name, ", name)\n",
               NIL);
      }
    }
    
    /* Emit all of the members */

    in_class = 1;

    /* Overide the shadow file so we can capture its methods */
    f_shadow = NewString(""); 

    Language::classHandler(n);
    in_class = 0;

    /* Complete the class */
    if (shadow) {
      /* Generate a class registration function */
      {
	SwigType  *ct = NewStringf("p.%s", real_classname);
	SwigType_remember(ct);
	Printv(f_wrappers,
	       "static PyObject * ", class_name, "_swigregister(PyObject *self, PyObject *args) {\n",
	       tab4, "PyObject *obj;\n",
	       tab4, "if (!PyArg_ParseTuple(args,(char*)\"O\", &obj)) return NULL;\n",
	       tab4, "SWIG_TypeClientData(SWIGTYPE", SwigType_manglestr(ct),", obj);\n",
	       tab4, "Py_INCREF(obj);\n",
	       tab4, "return Py_BuildValue((char *)\"\");\n",
	       "}\n",NIL);
	String *cname = NewStringf("%s_swigregister", class_name);
	add_method(cname, cname, 0);
	Delete(cname);
	Delete(ct);
      }
      if (!have_constructor) {
	Printv(f_shadow_file,tab4,"def __init__(self): raise RuntimeError, \"No constructor defined\"\n",NIL);
      }

      if (!have_repr) {
	/* Supply a repr method for this class  */
          if (new_repr) {
              Printv(f_shadow_file,
                 tab4, "def __repr__(self):\n",
                 tab8, "return \"<%s.%s; proxy of ", CPlusPlus ? "C++ " : "C ", real_classname," instance at %s>\" % (self.__class__.__module__, self.__class__.__name__, self.this,)\n",
                 NIL);
          }
          else {
              Printv(f_shadow_file,
	         tab4, "def __repr__(self):\n",
  	         tab8, "return \"<C ", real_classname," instance at %s>\" % (self.this,)\n",
	         NIL);
          }
      }
      
      /* Now emit methods */
      Printv(f_shadow_file, f_shadow, NIL);

      /* Now the Ptr class */
      Printv(f_shadow_file,
  	     "\nclass ", class_name, "Ptr(", class_name, "):\n",
             tab4, "def __init__(self, this):\n", NIL);
      if (!modern) {
        Printv(f_shadow_file,
               tab8, "_swig_setattr(self, ", class_name, ", 'this', this)\n",
               tab8, "if not hasattr(self,\"thisown\"): _swig_setattr(self, ", class_name, ", 'thisown', 0)\n",
               tab8, "_swig_setattr(self, ", class_name, ",self.__class__,", class_name, ")\n",
               NIL);
      } else {
        Printv(f_shadow_file,
               tab8, "self.this = this\n",
               tab8, "if not hasattr(self,\"thisown\"): self.thisown = 0\n",
               tab8, "self.__class__ = ", class_name, "\n", NIL);
  	     //	   tab8,"try: self.this = this.this; self.thisown = getattr(this,'thisown',0); this.thisown=0\n",
  	     //	   tab8,"except AttributeError: self.this = this\n"
      }

      Printf(f_shadow_file,"%s.%s_swigregister(%sPtr)\n", module, class_name, class_name,0);
      shadow_indent = 0;
      Printf(f_shadow_file,"%s\n", f_shadow_stubs);
      Clear(f_shadow_stubs);
    }
    classic = oldclassic;
    modern  = oldmodern;

    /* Restore shadow file back to original version */
    f_shadow = f_shadow_file;

    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * memberfunctionHandler()
   * ------------------------------------------------------------ */

  virtual int memberfunctionHandler(Node *n) {
    String *symname = Getattr(n,"sym:name");
    int   oldshadow;

    /* Create the default member function */
    oldshadow = shadow;    /* Disable shadowing when wrapping member functions */
    if (shadow) shadow = shadow | PYSHADOW_MEMBER;
    Language::memberfunctionHandler(n);
    shadow = oldshadow;

    if (!Getattr(n,"sym:nextSibling")) {
      if (shadow) {
	int allow_kwargs = (check_kwargs(n) && !Getattr(n,"sym:overloaded")) ? 1 : 0;
	if (Strcmp(symname,"__repr__") == 0)
	  have_repr = 1;
	
	if (Getattr(n,"feature:shadow")) {
	  String *pycode = pythoncode(Getattr(n,"feature:shadow"),tab4);
	  String *pyaction = NewStringf("%s.%s", module, Swig_name_member(class_name,symname));
	  Replaceall(pycode,"$action", pyaction);
	  Delete(pyaction);
	  Printv(f_shadow,pycode,"\n",NIL);
	} else {

          Printv(f_shadow, tab4, "def ", symname, "(*args", (allow_kwargs ? ", **kwargs" : ""), "): ", NIL);
          if ( have_addtofunc(n) ) {
            Printv(f_shadow, "\n", NIL);
            Printv(f_shadow, tab8, "val = ", funcCallHelper(Swig_name_member(class_name,symname), allow_kwargs), "\n", NIL);
            Printv(f_shadow, tab8, addtofunc(n), "\n", NIL);
            Printv(f_shadow, tab8, "return val\n", NIL);
          } else {
            Printv(f_shadow, "return ", funcCallHelper(Swig_name_member(class_name,symname), allow_kwargs), "\n", NIL);
          }
        }

      }
    }
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * staticmemberfunctionHandler()
   * ------------------------------------------------------------ */
  
  virtual int staticmemberfunctionHandler(Node *n) {
    String *symname = Getattr(n,"sym:name");
    Language::staticmemberfunctionHandler(n);
    if (shadow) {
      if ( !classic && have_addtofunc(n) ) {
        int kw = (check_kwargs(n) && !Getattr(n,"sym:overloaded")) ? 1 : 0;
        Printv(f_shadow, tab4, "def ", symname, "(*args", (kw ? ", **kwargs" : ""), "):\n", NIL);
        Printv(f_shadow, tab8, "val = ", funcCallHelper(Swig_name_member(class_name, symname), kw), "\n", NIL);
        Printv(f_shadow, tab8, addtofunc(n), "\n", NIL);
        Printv(f_shadow, tab8, "return val\n", NIL);
        Printv(f_shadow, tab4, modern ? "" : "if _newclass:",  symname,
               " = staticmethod(", symname, ")\n", NIL);

        if (!modern) {
          Printv(f_shadow, tab4, "__swig_getmethods__[\"", symname, "\"] = lambda x: ", symname, "\n",  NIL);
        }
       
      } else {
        if (!modern) {
          Printv(f_shadow, tab4, "__swig_getmethods__[\"", symname, "\"] = lambda x: ", module, ".", Swig_name_member(class_name, symname), "\n",  NIL);
        }
        if (!classic) {
          Printv(f_shadow, tab4, modern ? "" : "if _newclass:",  symname,
                 " = staticmethod(", module, ".",
                 Swig_name_member(class_name, symname), ")\n", NIL);
        }
      }
    }
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * constructorDeclaration()
   * ------------------------------------------------------------ */

  virtual int constructorHandler(Node *n) {
    String *symname = Getattr(n,"sym:name");
    int   oldshadow = shadow;
    int   use_director = Swig_directorclass(n);

    /* 
     * If we're wrapping the constructor of a C++ director class, prepend a new parameter
     * to receive the scripting language object (e.g. 'self')
     *
     */
    Swig_save("python:constructorHandler",n,"parms",NIL);
    if (use_director) {
          Parm *parms = Getattr(n, "parms");
	  Parm *self;
	  String *name = NewString("self");
          String *type = NewString("PyObject");
          SwigType_add_pointer(type);
	  self = NewParm(type, name);
	  Delete(type);
	  Delete(name);
	  Setattr(self, "lname", "O");
	  if (parms) set_nextSibling(self, parms);
	  Setattr(n, "parms", self);
	  Setattr(n, "wrap:self", "1");
	  Delete(self);
    }
  
    if (shadow) shadow = shadow | PYSHADOW_MEMBER;
    Language::constructorHandler(n);
    shadow = oldshadow;

    Delattr(n, "wrap:self");
    Swig_restore(n);

    if (!Getattr(n,"sym:nextSibling")) {
      if (shadow) {
	int allow_kwargs = (check_kwargs(n) && (!Getattr(n,"sym:overloaded"))) ? 1 : 0;
	if (!have_constructor) {
	  if (Getattr(n,"feature:shadow")) {
	    String *pycode = pythoncode(Getattr(n,"feature:shadow"),tab4);
	    String *pyaction = NewStringf("%s.%s",module, Swig_name_construct(symname));
	    Replaceall(pycode,"$action", pyaction);
	    Delete(pyaction);
	    Printv(f_shadow,pycode,"\n",NIL);
	  } else {
	    String *pass_self = NewString("");
	    Node *parent = Swig_methodclass(n);
	    String *classname = Swig_class_name(parent);
	    String *rclassname = Swig_class_name(getCurrentClass());
	    assert(rclassname);
	    if (use_director) {
 	      Printv(pass_self, tab8, NIL);
	      Printf(pass_self, "if self.__class__ == %s:\n", classname);
	      Printv(pass_self, tab8, tab4, "args = (None,) + args\n",
	                        tab8, "else:\n",
		                tab8, tab4, "args = (self,) + args\n",
                                NIL);
 	    }

            Printv(f_shadow, tab4, "def __init__(self, *args",
                   (allow_kwargs ? ", **kwargs" : ""), "):\n", NIL);
            Printv(f_shadow, pass_self, NIL);
            if (!modern) {
              Printv(f_shadow, tab8, "_swig_setattr(self, ", rclassname, ", 'this', ", 
                     funcCallHelper(Swig_name_construct(symname), allow_kwargs), ")\n", NIL);
              Printv(f_shadow, 
                     tab8, "_swig_setattr(self, ", rclassname, ", 'thisown', 1)\n",
                     NIL);
            } else {
              Printv(f_shadow, tab8, "newobj = ",
                     funcCallHelper(Swig_name_construct(symname), allow_kwargs), "\n", NIL);
              Printv(f_shadow, tab8, "self.this = newobj.this\n", NIL);
              Printv(f_shadow, tab8, "self.thisown = 1\n", NIL);
              Printv(f_shadow, tab8, "del newobj.thisown\n", NIL);
            }
            if ( have_addtofunc(n) )
              Printv(f_shadow, tab8, addtofunc(n), "\n", NIL);
  	    Delete(pass_self);
  	  }
	  have_constructor = 1;
	} else {
	  /* Hmmm. We seem to be creating a different constructor.  We're just going to create a
	     function for it. */

	  if (Getattr(n,"feature:shadow")) {
	    String *pycode = pythoncode(Getattr(n,"feature:shadow"),"");
	    String *pyaction = NewStringf("%s.%s", module, Swig_name_construct(symname));
	    Replaceall(pycode,"$action", pyaction);
	    Delete(pyaction);
	    Printv(f_shadow_stubs,pycode,"\n",NIL);
	  } else {

            Printv(f_shadow_stubs, "\ndef ", symname, "(*args",
                   (allow_kwargs ? ", **kwargs" : ""), "):\n", NIL);
            Printv(f_shadow_stubs, tab4, "val = ",
                   funcCallHelper(Swig_name_construct(symname), allow_kwargs), "\n", NIL);
	    Printv(f_shadow_stubs, tab4, "val.thisown = 1\n", NIL);
            if ( have_addtofunc(n) )
              Printv(f_shadow_stubs, tab4, addtofunc(n), "\n", NIL);
            Printv(f_shadow_stubs, tab4, "return val\n", NIL);
  	  }
	}
      }
    }
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * destructorHandler()
   * ------------------------------------------------------------ */

  virtual int destructorHandler(Node *n) {
    String *symname = Getattr(n,"sym:name");
    int oldshadow = shadow;
    
    if (shadow) shadow = shadow | PYSHADOW_MEMBER;
    Language::destructorHandler(n);
    shadow = oldshadow;
    if (shadow) {
      if (Getattr(n,"feature:shadow")) {
	String *pycode = pythoncode(Getattr(n,"feature:shadow"), tab4);
	String *pyaction = NewStringf("%s.%s", module, Swig_name_destroy(symname));
	Replaceall(pycode, "$action", pyaction);
	Delete(pyaction);
	Printv(f_shadow,pycode,"\n", NIL);
      } else {
	Printv(f_shadow, tab4, "def __del__(self, destroy=", module, ".", Swig_name_destroy(symname), "):\n", NIL);
	if ( have_addtofunc(n) )
	  Printv(f_shadow, tab8, addtofunc(n), "\n", NIL);
	Printv(f_shadow, tab8, "try:\n", NIL);
	Printv(f_shadow, tab4, tab8, "if self.thisown: destroy(self)\n", NIL);
	Printv(f_shadow, tab8, "except: pass\n", NIL);
      }
    }
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * membervariableHandler()
   * ------------------------------------------------------------ */

  virtual int membervariableHandler(Node *n) {
    String *symname = Getattr(n,"sym:name");

    int   oldshadow = shadow;
    if (shadow) shadow = shadow | PYSHADOW_MEMBER;
    Language::membervariableHandler(n);
    shadow = oldshadow;

    if (shadow) {
      int immutable = (Getattr(n,"feature:immutable") != NULL);
      if (!modern) {
        if (!immutable) {
          Printv(f_shadow, tab4, "__swig_setmethods__[\"", symname, "\"] = ", module, ".", Swig_name_set(Swig_name_member(class_name,symname)), "\n", NIL);
        } 
        Printv(f_shadow, tab4, "__swig_getmethods__[\"", symname, "\"] = ", module, ".", Swig_name_get(Swig_name_member(class_name,symname)),"\n", NIL);
      }
      if (!classic) {
	if (immutable) {
	  Printv(f_shadow,tab4, modern ? "" : "if _newclass:",
                 symname," = property(", module, ".", 
		 Swig_name_get(Swig_name_member(class_name,symname)),")\n", NIL);
	} else {
	  Printv(f_shadow,tab4, modern ? "" : "if _newclass:",
                 symname," = property(", 
		 module, ".", Swig_name_get(Swig_name_member(class_name,symname)),", ",
		 module, ".", Swig_name_set(Swig_name_member(class_name,symname)),")\n", NIL);
	}
      }
    }
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * staticmembervariableHandler()
   * ------------------------------------------------------------ */

  virtual int staticmembervariableHandler(Node *n) {
    String *symname;
    SwigType *t;
    
    Language::staticmembervariableHandler(n);
    if (shadow) {
      t = Getattr(n,"type");
      symname = Getattr(n,"sym:name");
      if (SwigType_isconst(t) && !Getattr(n, "value")) {
	Printf(f_shadow,"%s%s = %s.%s.%s\n", tab4, symname, module, global_name, Swig_name_member(class_name,symname));      
      }
    }
    return SWIG_OK;

  }

  /* ------------------------------------------------------------
   * memberconstantHandler()
   * ------------------------------------------------------------ */

  virtual int memberconstantHandler(Node *n) {
    String *symname = Getattr(n,"sym:name");
    int   oldshadow = shadow;
    if (shadow) shadow = shadow | PYSHADOW_MEMBER;
    Language::memberconstantHandler(n);
    shadow = oldshadow;

    if (shadow) {
      Printv(f_shadow, tab4, symname, " = ", module, ".", Swig_name_member(class_name,symname), "\n", NIL);
    }
    return SWIG_OK;
  }

  /* ------------------------------------------------------------
   * pythoncode()     - Output python code into the shadow file
   * ------------------------------------------------------------ */

  String *pythoncode(String *code, const String *indent) {
    String *out = NewString("");
    String *temp;
    char   *t;
    if (!indent) indent = "";

    temp = NewString(code);

    t = Char(temp);
    if (*t == '{') {
      Delitem(temp,0);
      Delitem(temp,DOH_END);
    }

    /* Split the input text into lines */
    List *clist = DohSplitLines(temp);
    Delete(temp);
    int   initial = 0;
    String *s = 0;
    Iterator si;
    /* Get the initial indentation */
    
    for (si = First(clist); si.item; si = Next(si)) {
      s = si.item;
      if (Len(s)) {
	char *c = Char(s);
	while (*c) {
	  if (!isspace(*c)) break;
	  initial++;
	  c++;
	}
	if (*c && !isspace(*c)) break;
	else {
	  initial = 0;
	}
      }
    }
    while (si.item) {
      s = si.item;
      if (Len(s) > initial) {
	char *c = Char(s);
	c += initial;
	Printv(out,indent,c,"\n",NIL);
      } else {
	Printv(out,"\n",NIL);
      }
      si = Next(si);
    }
    Delete(clist);
    return out;
  }

  /* ------------------------------------------------------------
   * insertDirective()
   * 
   * Hook for %insert directive.   We're going to look for special %shadow inserts
   * as a special case so we can do indenting correctly
   * ------------------------------------------------------------ */

  virtual int insertDirective(Node *n) {
    String *code = Getattr(n,"code");
    String *section = Getattr(n,"section");

    if ((!ImportMode) && ((Cmp(section,"python") == 0) || (Cmp(section,"shadow") == 0))) {
      if (shadow) {
	String *pycode = pythoncode(code,shadow_indent);
	Printv(f_shadow, pycode, NIL);
	Delete(pycode);
      }
    } else {
      Language::insertDirective(n);
    }
    return SWIG_OK;
  }
};

/* -----------------------------------------------------------------------------
 * swig_python()    - Instantiate module
 * ----------------------------------------------------------------------------- */

extern "C" Language *
swig_python(void) {
  return new PYTHON();
}
