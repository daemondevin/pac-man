;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Debug.nsh
;   This file handles the features for debugging the wrapper executable during runtime. 
; 
; USAGE
;   If you want debugging support, create the file ExtendedDebug.nsh in the package's
;   AppInfo directory. It should then have something like the following:
;
;   !define DEBUG_ALL
;     • To enable debugging of everything.
;       » This leaves out the "about to execute segment" and "finished executing segment" messages.
;
;   !define DEBUG_SEGWRAP
;     • To enable messages announcing when a segment is about to start/finish.
;
;   !define DEBUG_OUTPUT [file|messagebox]
;     • By default debugging will output it's data to a file called debug.log in the bin\Settings folder. 
;       It will also show a message box which pauses execution and allows you to terminate execution.
;       » If you want it to only log to a file, set this to 'file'.
;         · For example: !define DEBUG_OUTPUT file
;       » If you want to only show the message boxes, set this to 'messagebox'.
;         · For example: !define DEBUG_OUTPUT messagebox
;
;   !define DEBUG_GLOBAL
;     • Debug outside all segments.
;
;   !define DEBUG_SEGMENT_[SegmentName]
;     • Debug a given segment or segments
;       » To debug the PrePrimary segment use 'PrePrimary'
;         · For example: !define DEBUG_SEGMENT_PrePrimary
;       » To debug the PostExecPrimary segment use 'PostExecPrimary'
;         · For example: !define DEBUG_SEGMENT_PostExecPrimary
; 
; ATTENTION
;   Remember to remove the debug file when you're ready to release a package. 
;   You do not want the debugging features enabled for production use.
; 

; Macro: check if in debug mode for the current section {{{1
!macro !getdebug
	!ifdef DEBUG
		!undef DEBUG
	!endif
	!ifdef DEBUG_ALL
		!define DEBUG
	!else
		!ifdef Segment
			!ifdef DEBUG_SEGMENT_${Segment}
				!define DEBUG
			!endif
		!else ifdef DEBUG_GLOBAL
			!define DEBUG
		!endif
	!endif
!macroend
!define !getdebug "!insertmacro !getdebug"

; Macro: print a debug message {{{1
!macro DebugMsg _MSG
	${!getdebug}
	!ifdef DEBUG

		; Logging to file {{{2
		!ifndef DEBUG_OUTPUT
			!define _DebugMsg_OK
		!else if ${DEBUG_OUTPUT} == file
			!define _DebugMsg_OK
		!endif
		!ifdef _DebugMsg_OK
			!ifdef Segment
				!define _DebugMsg_Seg "${Segment}/${__FUNCTION__}"
			!else
				!define _DebugMsg_Seg "Global"
			!endif
			!ifndef _DebugMsg_FileOpened
				Var /GLOBAL _DebugMsg_File
				FileOpen $_DebugMsg_File $EXEDIR\bin\Settings\debug.log w
				FileWrite $_DebugMsg_File "PortableApps Compiler ${Version} debug messages for ${NamePortable} (${AppID})$\r$\n"
				; TODO: hg revision number from .hg/branch, branchheads.cache
				; My ${!ifexist} doesn't work in Wine, not sure if I can fix it
				!define _DebugMsg_FileOpened
			!else
				FileOpen  $_DebugMsg_File $EXEDIR\bin\Settings\debug.log a
				FileSeek  $_DebugMsg_File 0 END
			!endif
			FileWrite $_DebugMsg_File "${_DebugMsg_Seg} (line ${__LINE__}): ${_MSG}$\r$\n$\r$\n"
			FileClose $_DebugMsg_File
			!undef _DebugMsg_Seg
			!undef _DebugMsg_OK
		!endif ;}}}

		; Logging to display: message box {{{2
		!ifndef DEBUG_OUTPUT
			!define _DebugMsg_OK
		!else if ${DEBUG_OUTPUT} == messagebox
			!define _DebugMsg_OK
		!endif
		!ifdef _DebugMsg_OK
			!ifdef Segment
				!define _DebugMsg_Seg "$\r$\n$\r$\nSegment: ${Segment}$\r$\nHook: ${__FUNCTION__}"
			!else
				!define _DebugMsg_Seg ""
			!endif
			MessageBox MB_OKCANCEL|MB_ICONINFORMATION "Debug message at line ${__LINE__}${_DebugMsg_Seg}$\r$\n____________________$\r$\n$\r$\n${_MSG}" IDOK +2
				Abort
			!undef _DebugMsg_Seg
			!undef _DebugMsg_OK
		!endif ;}}}
	!endif
!macroend
!define DebugMsg "!insertmacro DebugMsg" ; }}}

!include /NONFATAL "${PACKAGE}\app\AppInfo\Debug.nsh"
