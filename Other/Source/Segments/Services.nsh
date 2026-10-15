;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Services.nsh
;   On-demand Windows services, journaled so a crash can never leave a
;   portable service installed or a local service repointed.
;
; USAGE
;   [Activate]
;   Services=true
;
;   [Service1]
;   Name=ServiceName
;   Path=%PAL:DataDir%\service.exe
;   Type=own
;   Start=demand
;   Depend=
;   IfExists=replace
;
;   Name        The service name.
;   Path        The service binary, optionally followed by arguments.
;               Supports environment variables. Quote the binary when the
;               path contains spaces and arguments follow it.
;   Type        own (default), share, interact, kernel, filesys, rec.
;   Start       demand (default), boot, system, auto, delayed-auto, disabled.
;   Depend      Dependencies separated by / (new services only).
;   DisplayName Optional display name (new services only).
;   IfExists    skip (default) or replace.
;               skip     A service with this name already exists, so the
;                        portable one is not installed and nothing changes.
;               replace  The existing service is stopped and temporarily
;                        pointed at the portable binary. Its account,
;                        dependencies, description and recovery settings are
;                        untouched, and its original binary path, start type
;                        and running state are restored afterwards.
;   Timeout     Seconds to wait for a service to start or stop (default 30).
;   Required    true to show a warning when the service cannot be started.
;
; HOW IT IS UNDONE
;   New service       journal: stop it, then sc delete
;   Replaced service  journal: stop it, sc config back to the original
;                     binary/start/type, then start it again if it was running
;
; PRIVILEGES
;   Services need administrator rights. Without them the segment changes
;   nothing and shows one warning (fail closed).
;

!ifdef SEGMENTS_SERVICES

!ifndef SC
	!define SC `$SYSDIR\sc.exe`
!endif
!define SVC_KEY `SYSTEM\CurrentControlSet\Services`

Var SvcName
Var SvcExists
Var SvcRunning
Var SvcTimeout
Var SvcText

;= HELPERS
;= ################

; Sets $SvcExists and $SvcRunning (true/false) for $SvcName.
Function Services_Query
	Push $0
	Push $1
	StrCpy $SvcExists false
	StrCpy $SvcRunning false
	ClearErrors
	ReadRegDWORD $0 HKLM `${SVC_KEY}\$SvcName` "Type"
	${IfNot} ${Errors}
		StrCpy $SvcExists true
		nsExec::ExecToStack `"${SC}" query "$SvcName"`
		Pop $0
		Pop $_JT1
		StrCpy $_JT2 RUNNING
		Call Journal_Contains
		${IfThen} $_JT4 == 1 ${|} StrCpy $SvcRunning true ${|}
	${EndIf}
	Pop $1
	Pop $0
FunctionEnd

; Waits up to $SvcTimeout seconds for $SvcName to reach state $SvcText
; (RUNNING or STOPPED). Sets $SvcText to ok or timeout.
Function Services_Wait
	Push $0
	Push $1
	StrCpy $1 0
	${Do}
		nsExec::ExecToStack `"${SC}" query "$SvcName"`
		Pop $0
		Pop $_JT1
		StrCpy $_JT2 $SvcText
		Call Journal_Contains
		${If} $_JT4 == 1
			StrCpy $SvcText ok
			${ExitDo}
		${EndIf}
		IntOp $1 $1 + 1
		${If} $1 > $SvcTimeout
			StrCpy $SvcText timeout
			${ExitDo}
		${EndIf}
		Sleep 1000
	${Loop}
	Pop $1
	Pop $0
FunctionEnd

; Escapes double quotes in $SvcText for a quoted sc.exe argument.
Function Services_Escape
	Push $0
	Push $1
	Push $2
	StrCpy $0 0
	StrCpy $2 ""
	${Do}
		StrCpy $1 $SvcText 1 $0
		${IfThen} $1 == "" ${|} ${ExitDo} ${|}
		${If} $1 == `"`
			StrCpy $2 `$2\"`
		${Else}
			StrCpy $2 `$2$1`
		${EndIf}
		IntOp $0 $0 + 1
	${Loop}
	StrCpy $SvcText $2
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Sets $SvcText to the binary part of a service command line in $SvcText.
Function Services_BinaryOf
	Push $0
	Push $1
	StrCpy $0 $SvcText 1
	${If} $0 == `"`
		StrCpy $SvcText $SvcText "" 1
		StrCpy $0 0
		${Do}
			StrCpy $1 $SvcText 1 $0
			${IfThen} $1 == "" ${|} ${ExitDo} ${|}
			${IfThen} $1 == `"` ${|} ${ExitDo} ${|}
			IntOp $0 $0 + 1
		${Loop}
		StrCpy $SvcText $SvcText $0
	${ElseIfNot} ${FileExists} $SvcText
		; Unquoted with arguments: the binary ends at the first space.
		StrCpy $0 0
		${Do}
			StrCpy $1 $SvcText 1 $0
			${IfThen} $1 == "" ${|} ${ExitDo} ${|}
			${IfThen} $1 == " " ${|} ${ExitDo} ${|}
			IntOp $0 $0 + 1
		${Loop}
		StrCpy $SvcText $SvcText $0
	${EndIf}
	Pop $1
	Pop $0
FunctionEnd

; Maps a registry Start DWORD in $SvcText to its sc.exe name.
Function Services_StartName
	${Select} $SvcText
		${Case} 0
			StrCpy $SvcText boot
		${Case} 1
			StrCpy $SvcText system
		${Case} 2
			StrCpy $SvcText auto
		${Case} 3
			StrCpy $SvcText demand
		${Case} 4
			StrCpy $SvcText disabled
		${CaseElse}
			StrCpy $SvcText ""
	${EndSelect}
FunctionEnd

; Maps a registry Type DWORD in $SvcText to its sc.exe argument(s).
Function Services_TypeName
	Push $0
	Push $1
	IntOp $0 $SvcText & 0xFF
	IntOp $1 $SvcText & 0x100
	${Select} $0
		${Case} 1
			StrCpy $SvcText kernel
		${Case} 2
			StrCpy $SvcText filesys
		${Case} 16
			StrCpy $SvcText own
		${Case} 32
			StrCpy $SvcText share
		${CaseElse}
			StrCpy $SvcText ""
	${EndSelect}
	${If} $1 <> 0
	${AndIf} $SvcText != ""
		StrCpy $SvcText `$SvcText type= interact`
	${EndIf}
	Pop $1
	Pop $0
FunctionEnd

;= MACROS FOR CUSTOM.NSH
;= ################
; Kept for Custom.nsh compatibility. The _FSR argument is accepted but no
; longer needed: sc.exe talks to the service manager, which is not affected
; by WOW64 file system redirection. These do not journal anything, so use
; ${Journal::Record} before any change made with them.
!define Service::Query `!insertmacro _Service::Query`
!macro _Service::Query _SVC _FSR _ERR1 _ERR2
	nsExec::ExecToStack `"${SC}" query "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define Service::Stop `!insertmacro _Service::Stop`
!macro _Service::Stop _SVC _FSR _ERR1 _ERR2
	nsExec::ExecToStack `"${SC}" stop "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define Service::Start `!insertmacro _Service::Start`
!macro _Service::Start _SVC _FSR _ERR1 _ERR2
	nsExec::ExecToStack `"${SC}" start "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define Service::Delete `!insertmacro _Service::Delete`
!macro _Service::Delete _SVC _FSR _ERR1 _ERR2
	nsExec::ExecToStack `"${SC}" delete "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define Service::Description `!insertmacro _Service::Description`
!macro _Service::Description _SVC _DESCRIPTION _FSR _ERR1 _ERR2
	nsExec::ExecToStack `"${SC}" description "${_SVC}" "${_DESCRIPTION}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define Service::Config `!insertmacro _Service::Config`
!macro _Service::Config _SVC _CONFIG _FSR _ERR1 _ERR2
	nsExec::ExecToStack `"${SC}" config "${_SVC}" start= "${_CONFIG}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend

${SegmentFile}

;= Install portable services
${SegmentPrePrimary}
	StrCpy $R0 1
	StrCpy $R9 ""
	${Do}
		ClearErrors
		${ReadLauncherConfig} $SvcName Service$R0 Name
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}

		${If} $Admin != true
			${If} $R9 == ""
				StrCpy $R9 warned
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"${PORTABLEAPPNAME} needs administrator rights to install its services.$\r$\nThe services were skipped and nothing was changed."
			${EndIf}
			IntOp $R0 $R0 + 1
			${Continue}
		${EndIf}

		${ReadLauncherConfig} $R1 Service$R0 Path
		${ParseLocations} $R1
		; Type and Start stay empty when not configured so a replaced service
		; keeps its own values; new services fall back to own and demand.
		${ReadLauncherConfig} $R2 Service$R0 Type
		${ReadLauncherConfig} $R3 Service$R0 Start
		${ReadLauncherConfig} $R4 Service$R0 Depend
		${ReadLauncherConfigWithDefault} $R5 Service$R0 IfExists skip
		${ReadLauncherConfigWithDefault} $SvcTimeout Service$R0 Timeout 30
		${ReadLauncherConfig} $R6 Service$R0 DisplayName
		${ReadLauncherConfig} $R8 Service$R0 Required
		${NewStrCase} $R5 $R5 L

		; The binary has to exist before anything is touched.
		StrCpy $SvcText $R1
		Call Services_BinaryOf
		${IfNot} ${FileExists} $SvcText
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"The binary for the $SvcName service was not found:$\r$\n$SvcText$\r$\n$\r$\nContinuing without this service."
			IntOp $R0 $R0 + 1
			${Continue}
		${EndIf}

		Call Services_Query
		StrCpy $SvcText $R1
		Call Services_Escape
		StrCpy $R7 $SvcText

		${If} $SvcExists == true
		${AndIf} $R5 != replace
			${DebugMsg} "Service $SvcName already exists and IfExists=$R5; leaving it alone."
			IntOp $R0 $R0 + 1
			${Continue}
		${EndIf}

		${If} $SvcExists == true
			; Repoint the existing service. Capture the original configuration
			; and record how to put it back, newest-undone-first:
			;   restart (if it was running) < config back < stop
			ReadRegStr $R6 HKLM `${SVC_KEY}\$SvcName` "ImagePath"
			StrCpy $SvcText $R6
			Call Services_Escape
			StrCpy $R6 `"${SC}" config "$SvcName" binpath= "$SvcText"`
			ReadRegDWORD $SvcText HKLM `${SVC_KEY}\$SvcName` "Start"
			Call Services_StartName
			${If} $SvcText == auto
				ReadRegDWORD $0 HKLM `${SVC_KEY}\$SvcName` "DelayedAutostart"
				${IfThen} $0 = 1 ${|} StrCpy $SvcText delayed-auto ${|}
			${EndIf}
			${IfThen} $SvcText != "" ${|} StrCpy $R6 `$R6 start= $SvcText` ${|}
			ReadRegDWORD $SvcText HKLM `${SVC_KEY}\$SvcName` "Type"
			Call Services_TypeName
			${IfThen} $SvcText != "" ${|} StrCpy $R6 `$R6 type= $SvcText` ${|}

			${If} $SvcRunning == true
				${Journal::Record} Services CMD `"${SC}" start "$SvcName"` "0,1056" "" ""
			${EndIf}
			${Journal::Record} Services CMD $R6 "0" "" ""
			${Journal::Record} Services SVCSTOP $SvcName $SvcTimeout "" ""

			${DebugMsg} "Repointing existing service $SvcName to the portable binary."
			nsExec::ExecToStack `"${SC}" stop "$SvcName"`
			Pop $0
			Pop $1
			StrCpy $SvcText STOPPED
			Call Services_Wait
			StrCpy $0 `"${SC}" config "$SvcName" binpath= "$R7"`
			${IfThen} $R2 != "" ${|} StrCpy $0 `$0 type= $R2` ${|}
			${IfThen} $R3 != "" ${|} StrCpy $0 `$0 start= $R3` ${|}
			nsExec::ExecToStack $0
			Pop $0
			Pop $1
			${If} $0 != 0
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"Could not point the $SvcName service at the portable binary (sc.exe error $0).$\r$\nThe original service will be restored when ${PORTABLEAPPNAME} closes."
			${EndIf}
		${Else}
			; New service. Undo: stop, then delete.
			${IfThen} $R2 == "" ${|} StrCpy $R2 own ${|}
			${IfThen} $R3 == "" ${|} StrCpy $R3 demand ${|}
			${Journal::Record} Services CMD `"${SC}" delete "$SvcName"` "0,1060,1072" "" ""
			${Journal::Record} Services SVCSTOP $SvcName $SvcTimeout "" ""

			StrCpy $0 `"${SC}" create "$SvcName" binpath= "$R7" type= $R2 start= $R3`
			${IfThen} $R4 != "" ${|} StrCpy $0 `$0 depend= "$R4"` ${|}
			${If} $R6 != ""
				StrCpy $SvcText $R6
				Call Services_Escape
				StrCpy $0 `$0 DisplayName= "$SvcText"`
			${EndIf}
			${DebugMsg} "Creating portable service $SvcName:$\r$\n$0"
			nsExec::ExecToStack $0
			Pop $0
			Pop $1
			${If} $0 != 0
				; Nothing was created, so the two entries must not run: deleting
				; would hit a service we did not create (e.g. 1073, already exists).
				${Journal::Discard} Services
				${Journal::Discard} Services
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"Could not create the $SvcName service (sc.exe error $0).$\r$\nContinuing without this service."
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
		${EndIf}

		${If} $R3 != disabled
			nsExec::ExecToStack `"${SC}" start "$SvcName"`
			Pop $0
			Pop $1
			StrCpy $SvcText RUNNING
			Call Services_Wait
			${If} $SvcText != ok
			${AndIf} $R8 == true
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"The $SvcName service did not start.$\r$\n${PORTABLEAPPNAME} may not work correctly."
			${EndIf}
		${EndIf}

		IntOp $R0 $R0 + 1
	${Loop}
!macroend

;= Remove portable services and restore local ones
${SegmentPostPrimary}
	${Journal::HasEntries} Services $R0
	${If} $R0 > 0
		${Journal::Rollback} Services
	${EndIf}
!macroend

!endif ; SEGMENTS_SERVICES
