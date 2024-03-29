/*
 * Copyright (c) 2002-2003 Apple Computer, Inc. All rights reserved.
 *
 * @APPLE_LICENSE_HEADER_START@
 * 
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 * 
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 * 
 * @APPLE_LICENSE_HEADER_END@

    Change History (most recent first):

$Log: not supported by cvs2svn $
Revision 1.17  2004/01/28 21:14:23  cheshire
Reconcile debug_mode and gDebugLogging into a single flag (mDNS_DebugMode)

Revision 1.16  2003/12/09 01:30:06  rpantos
Fix usage of ARGS... macros to build properly on Windows.

Revision 1.15  2003/12/08 20:55:26  rpantos
Move some definitions here from mDNSMacOSX.h.

Revision 1.14  2003/08/12 19:56:24  cheshire
Update to APSL 2.0

Revision 1.13  2003/07/02 21:19:46  cheshire
<rdar://problem/3313413> Update copyright notices, etc., in source code comments

Revision 1.12  2003/05/26 03:01:27  cheshire
<rdar://problem/3268904> sprintf/vsprintf-style functions are unsafe; use snprintf/vsnprintf instead

Revision 1.11  2003/05/21 17:48:10  cheshire
Add macro to enable GCC's printf format string checking

Revision 1.10  2003/04/26 02:32:57  cheshire
Add extern void LogMsg(const char *format, ...);

Revision 1.9  2002/09/21 20:44:49  zarzycki
Added APSL info

Revision 1.8  2002/09/19 04:20:43  cheshire
Remove high-ascii characters that confuse some systems

Revision 1.7  2002/09/16 18:41:42  cheshire
Merge in license terms from Quinn's copy, in preparation for Darwin release

*/

#ifndef __mDNSDebug_h
#define __mDNSDebug_h

// Set MDNS_DEBUGMSGS to 0 to optimize debugf() calls out of the compiled code
// Set MDNS_DEBUGMSGS to 1 to generate normal debugging messages
// Set MDNS_DEBUGMSGS to 2 to generate verbose debugging messages
// MDNS_DEBUGMSGS is normally set in the project options (or makefile) but can also be set here if desired

//#define MDNS_DEBUGMSGS 2

// Set MDNS_CHECK_PRINTF_STYLE_FUNCTIONS to 1 to enable extra GCC compiler warnings
// Note: You don't normally want to do this, because it generates a bunch of
// spurious warnings for the following custom extensions implemented by mDNS_vsnprintf:
//    warning: `#' flag used with `%s' printf format    (for %#s              -- pascal string format)
//    warning: repeated `#' flag in format              (for %##s             -- DNS name string format)
//    warning: double format, pointer arg (arg 2)       (for %.4a, %.16a, %#a -- IP address formats)
#define MDNS_CHECK_PRINTF_STYLE_FUNCTIONS 0
#if MDNS_CHECK_PRINTF_STYLE_FUNCTIONS
#define IS_A_PRINTF_STYLE_FUNCTION(F,A) __attribute__ ((format(printf,F,A)))
#else
#define IS_A_PRINTF_STYLE_FUNCTION(F,A)
#endif

#ifdef	__cplusplus
	extern "C" {
#endif

#if MDNS_DEBUGMSGS
#define debugf debugf_
extern void debugf_(const char *format, ...) IS_A_PRINTF_STYLE_FUNCTION(1,2);
#else // If debug breaks are off, use a preprocessor trick to optimize those calls out of the code
	#if( defined( __GNUC__ ) )
		#define	debugf( ARGS... ) ((void)0)
	#elif( defined( __MWERKS__ ) )
		#define	debugf( ... )
	#else
		#define debugf 1 ? ((void)0) : (void)
	#endif
#endif

#if MDNS_DEBUGMSGS > 1
#define verbosedebugf verbosedebugf_
extern void verbosedebugf_(const char *format, ...) IS_A_PRINTF_STYLE_FUNCTION(1,2);
#else
	#if( defined( __GNUC__ ) )
		#define	verbosedebugf( ARGS... ) ((void)0)
	#elif( defined( __MWERKS__ ) )
		#define	verbosedebugf( ... )
	#else
		#define verbosedebugf 1 ? ((void)0) : (void)
	#endif
#endif

// LogMsg is used even in shipping code, to write truly serious error messages to syslog (or equivalent)
extern int	mDNS_DebugMode;	// If non-zero, LogMsg() writes to stderr instead of syslog
extern void LogMsg(const char *format, ...) IS_A_PRINTF_STYLE_FUNCTION(1,2);
extern void LogMsgIdent(const char *ident, const char *format, ...);
extern void LogMsgNoIdent(const char *format, ...);

// Set this symbol to 1 to do extra debug checks on malloc() and free()
// Set this symbol to 2 to write a log message for every malloc() and free()
#define MACOSX_MDNS_MALLOC_DEBUGGING 0

#if MACOSX_MDNS_MALLOC_DEBUGGING >= 1
extern void *mallocL(char *msg, unsigned int size);
extern void freeL(char *msg, void *x);
#else
#define mallocL(X,Y) malloc(Y)
#define freeL(X,Y) free(Y)
#endif

#if MACOSX_MDNS_MALLOC_DEBUGGING >= 2
#define LogMalloc LogMsg
#else
	#if( defined( __GNUC__ ) )
		#define	LogMalloc(ARGS...) ((void)0)
	#elif( defined( __MWERKS__ ) )
		#define	LogMalloc( ... )
	#else
		#define LogMalloc 1 ? ((void)0) : (void)
	#endif
#endif

#define LogAllOperations 0

#if LogAllOperations
#define LogOperation LogMsg
#else
#define	LogOperation debugf
#endif

#ifdef	__cplusplus
	}
#endif

#endif
