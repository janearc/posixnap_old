/* ----------------------------------------------------------------------------- 
 * warn.c
 *
 *     SWIG warning framework.  This was added to warn developers about 
 *     deprecated APIs and other features.
 * 
 * Author(s) : David Beazley (beazley@cs.uchicago.edu)
 *
 * Copyright (C) 1999-2001.  The University of Chicago
 * See the file LICENSE for information on usage and redistribution.	
 * ----------------------------------------------------------------------------- */

char cvsroot_warn_c[] = "$Header: /home/jabba/convert/cvs/Ficl/SWIG-1.3.21/Source/Swig/warn.c,v 1.1 2004-02-01 04:05:41 alex Exp $";

#include "swig.h"

static Hash *warnings = 0;

/* -----------------------------------------------------------------------------
 * Swig_warn()
 * 
 * Issue a warning
 * ----------------------------------------------------------------------------- */

void
Swig_warn(const char *filename, int line, const char *msg) {
  String *key;
  if (!warnings) {
    warnings = NewHash();
  }
  key = NewStringf("%s:%d", filename,line);
  if (!Getattr(warnings,key)) {
    Printf(stderr,"swig-dev warning:%s:%d:%s\n", filename, line, msg);
    Setattr(warnings,key,key);
  }
  Delete(key);
}

	
		


