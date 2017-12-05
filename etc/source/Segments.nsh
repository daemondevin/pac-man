;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
;
; Segments.nsh
; This file is responsible for handling the execution of each segment file.
; 

!macro _CreateSegmentDef _TYPE
	!ifdef Segment${_TYPE}
		!undef Segment${_TYPE}
	!endif
	!define Segment${_TYPE} "!macro ${__FILE__}_${_TYPE}"
!macroend
!define _CreateSegmentDef "!insertmacro _CreateSegmentDef"

!macro SegmentFile
	${_CreateSegmentDef} .onInit
	${_CreateSegmentDef} Init
	${_CreateSegmentDef} Pre
	${_CreateSegmentDef} PrePrimary
	${_CreateSegmentDef} PreSecondary
	${_CreateSegmentDef} PreExec
	${_CreateSegmentDef} PreExecPrimary
	${_CreateSegmentDef} PreExecSecondary
	${_CreateSegmentDef} PostExec
	${_CreateSegmentDef} PostExecPrimary
	${_CreateSegmentDef} PostExecSecondary
	${_CreateSegmentDef} Post
	${_CreateSegmentDef} PostPrimary
	${_CreateSegmentDef} PostSecondary
	${_CreateSegmentDef} Unload
!macroend
!define SegmentFile "!insertmacro SegmentFile"

; Run an action {{{1
!macro RunSegment Segment
	!ifdef _DisableHook_${Segment}_${__FUNCTION__}
		!echo "Segment ${Segment}, hook ${__FUNCTION__} has been disabled by ExtendedWrapper.nsh."
	!else ifmacrondef ${Segment}.nsh_${__FUNCTION__}
		!if ${Segment} != Custom
			!warning "Segment ${Segment}, hook ${__FUNCTION__} was called but does not exist!"
		!endif
	!else
		${!getdebug}
		!ifdef DEBUG && DEBUG_SEGWRAP
			${DebugMsg} "About to execute segment"
		!endif
		!insertmacro ${Segment}.nsh_${__FUNCTION__}
		!ifdef DEBUG && DEBUG_SEGWRAP
			${DebugMsg} "Finished executing segment"
		!endif
	!endif
!macroend
!define RunSegment "!insertmacro RunSegment"

/* Run an action (not being used) {{{1
 * action = (.on)?Init|Unload|(Pre(Exec)?|Post)(Primary|Secondary)?
 * ${RunSegmentAction}        action
 * ${RunSegmentActionReverse} action <-- use this for Post as it does them in the reverse order (so that it's nested)
 * /
******************************************************************
* Not using these macros at the moment.                          *
* Too much like hard work maintaining a list like that just now. *
******************************************************************

!macro _RunSingleSegmentAction _SEGMENT
	!ifmacrodef ${_SEGMENT}_${_ACTION}
		!insertmacro ${_SEGMENT}_${_ACTION}
	!endif
!macroend
!define _RunSingleSegmentAction "!insertmacro _RunSingleSegment"

!macro RunSegmentAction _ACTION
	${_RunSingleSegmentAction} Mutex
	${_RunSingleSegmentAction} SplashScreen
	${_RunSingleSegmentAction} WorkingDirectory
	${_RunSingleSegmentAction} RefreshShellIcons
!macroend
!define RunSegmentAction "!insertmacro RunSegment"

!macro RunSegmentActionReverse _ACTION
	${_RunSingleSegmentAction} RefreshShellIcons
	${_RunSingleSegmentAction} WorkingDirectory
	${_RunSingleSegmentAction} SplashScreen
	${_RunSingleSegmentAction} Mutex
!macroend
!define RunSegmentActionReverse "!insertmacro RunSegment"
/* End this bit */
; Include the segments {{{1
!include Segments\*.nsh

; Customisation file {{{1
!macro DisableHook Segment Hook
	!define _DisableHook_${Segment}_${Hook}
!macroend
!define DisableHook "!insertmacro DisableHook"

!macro DisableSegment Segment
	${DisableHook} ${Segment} .onInit
	${DisableHook} ${Segment} Init
	${DisableHook} ${Segment} Pre
	${DisableHook} ${Segment} PrePrimary
	${DisableHook} ${Segment} PreSecondary
	${DisableHook} ${Segment} PreExec
	${DisableHook} ${Segment} PreExecPrimary
	${DisableHook} ${Segment} PreExecSecondary
	${DisableHook} ${Segment} PostExec
	${DisableHook} ${Segment} PostExecPrimary
	${DisableHook} ${Segment} PostExecSecondary
	${DisableHook} ${Segment} Post
	${DisableHook} ${Segment} PostPrimary
	${DisableHook} ${Segment} PostSecondary
	${DisableHook} ${Segment} Unload
!macroend
!define DisableSegment "!insertmacro DisableSegment"

!define OverrideExecute "!macro OverrideExecuteFunction"

!include /nonfatal "${PACKAGE}\app\AppInfo\ExtendWrapper.nsh"
