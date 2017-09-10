
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
; 
; The following macros were added by FukenGruven
; 
!define SC `$SYSDIR\sc.exe`
!ifdef SSDL
	!define _SSDL `D:(A;;CCLCSWRPWPDTLOCRRC;;;SY)(A;;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;BA)(A;;CCLCSWLOCRRC;;;IU)(A;;CCLCSWLOCRRC;;;SU)`
	!define SetSSDL `!insertmacro SetSSDL`
	!macro SetSSDL _PSEXEC _COMSPEC _SERVICE _FSR _ERR1 _ERR2
		StrCmpS $Bit 64 0 +4
		StrCmp "${_FSR}" /DISABLEFSR 0 +3
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${_PSEXEC}" -accepteula -s "${_COMSPEC}" /c sc sdset ${_SERVICE} "${_SSDL}"`
		Goto +2
		ExecDos::Exec /TOSTACK `"${_PSEXEC}" -accepteula -s "${_COMSPEC}" /c sc sdset ${_SERVICE} "${_SSDL}"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	!macroend
!endif
!ifdef INF_Install
	!define rundll `$SYSDIR\rundll32.exe`
	!define rundll::CreateLocal `!insertmacro rundll::CreateLocal`
	!macro rundll::CreateLocal _SC _LOCALINF _FSR _ERR1 _ERR2
		StrCmpS $Bit 64 0 +6
		StrCmp "${_FSR}" /DISABLEFSR 0 +5
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${RunDLL}" advpack.dll,LaunchINFSection "${_LOCALINF}",DefaultInstall`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${RunDLL}" advpack.dll,LaunchINFSection "${_LOCALINF}",DefaultInstall.Services`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" start "${_SC}"`
		Goto +4
		ExecDos::Exec /TOSTACK `"${RunDLL}" advpack.dll,LaunchINFSection "${_LOCALINF}",DefaultInstall`
		ExecDos::Exec /TOSTACK `"${RunDLL}" advpack.dll,LaunchINFSection "${_LOCALINF}",DefaultInstall.Services`
		ExecDos::Exec /TOSTACK `"${SC}" start "${_SC}"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	!macroend
	!define rundll::DeleteLocal `!insertmacro rundll::DeleteLocal`
	!macro rundll::DeleteLocal _SC _LOCALINF _FSR _ERR1 _ERR2
		StrCmpS $Bit 64 0 +7
		StrCmp "${_FSR}" /DISABLEFSR 0 +6
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${RunDLL}" advpack.dll,LaunchINFSection "${_LOCALINF}",DefaultUninstall`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${RunDLL}" advpack.dll,LaunchINFSection "${_LOCALINF}",DefaultUninstall.Services`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" stop "${_SC}"`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" delete "${_SC}"`
		Goto +5
		ExecDos::Exec /TOSTACK `"${RunDLL}" advpack.dll,LaunchINFSection "${_LOCALINF}",DefaultUninstall`
		ExecDos::Exec /TOSTACK `"${RunDLL}" advpack.dll,LaunchINFSection "${_LOCALINF}",DefaultUninstall.Services`
		ExecDos::Exec /TOSTACK `"${SC}" stop "${_SC}"`
		ExecDos::Exec /TOSTACK `"${SC}" delete "${_SC}"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	!macroend
	!define rundll::DeletePortable `!insertmacro rundll::DeletePortable`
	!macro rundll::DeletePortable _SC _PORTABLEINF _FSR _ERR1 _ERR2
		StrCmpS $Bit 64 0 +7
		StrCmp "${_FSR}" /DISABLEFSR 0 +6
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${RunDLL}" advpack.dll,LaunchINFSection "${_PORTABLEINF}",DefaultUninstall`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${RunDLL}" advpack.dll,LaunchINFSection "${_PORTABLEINF}",DefaultUninstall.Services`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" stop "${_SC}"`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" delete "${_SC}"`
		Goto +5
		ExecDos::Exec /TOSTACK `"${RunDLL}" advpack.dll,LaunchINFSection "${_PORTABLEINF}",DefaultUninstall`
		ExecDos::Exec /TOSTACK `"${RunDLL}" advpack.dll,LaunchINFSection "${_PORTABLEINF}",DefaultUninstall.Services`
		ExecDos::Exec /TOSTACK `"${SC}" stop "${_SC}"`
		ExecDos::Exec /TOSTACK `"${SC}" delete "${_SC}"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	!macroend
	!define rundll::CreatePortable `!insertmacro rundll::CreatePortable`
	!macro rundll::CreatePortable _SC _PORTABLEINF _FSR _ERR1 _ERR2
		StrCmpS $Bit 64 0 +6
		StrCmp "${_FSR}" /DISABLEFSR 0 +5
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${RunDLL}" advpack.dll,LaunchINFSection "${_PORTABLEINF}",DefaultInstall`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${RunDLL}" advpack.dll,LaunchINFSection "${_PORTABLEINF}",DefaultInstall.Services`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" start "${_SC}"`
		Goto +4
		ExecDos::Exec /TOSTACK `"${RunDLL}" advpack.dll,LaunchINFSection "${_PORTABLEINF}",DefaultInstall`
		ExecDos::Exec /TOSTACK `"${RunDLL}" advpack.dll,LaunchINFSection "${_PORTABLEINF}",DefaultInstall.Services`
		ExecDos::Exec /TOSTACK `"${SC}" start "${_SC}"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	!macroend
!endif
!define SC::Query `!insertmacro SC::Query`
!macro SC::Query _SC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" query "${_SC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" query "${_SC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define SC::Stop `!insertmacro SC::Stop`
!macro SC::Stop _SC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" stop "${_SC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" stop "${_SC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define SC::Start `!insertmacro SC::Start`
!macro SC::Start _SC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" start "${_SC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" start "${_SC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define SC::Delete `!insertmacro SC::Delete`
!macro SC::Delete _SC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" delete "${_SC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" delete "${_SC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define SC::Create `!insertmacro SC::Create`
!macro SC::Create _SC _PATH _TYPE _START _DEPEND _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +7
	StrCmp "${_FSR}" /DISABLEFSR 0 +6
		StrCmp "${_DEPEND}" "" 0 +3
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" create "${_SC}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}"`
		Goto +7
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" create "${_SC}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}" depend= ""${_DEPEND}""`
		Goto +5
	StrCmp "${_DEPEND}" "" 0 +3
	ExecDos::Exec /TOSTACK `"${SC}" create "${_SC}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" create "${_SC}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}" depend= ""${_DEPEND}""`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define SC::Description `!insertmacro SC::Description`
!macro SC::Description _SC _DESCRIPTION _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" description "${_SC}" "${_DESCRIPTION}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" description "${_SC}" "${_DESCRIPTION}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define SC::Config `!insertmacro SC::Config`
!macro SC::Config _SC _CONFIG _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	; disabled, demand, auto
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" config "${_SC}" start= "${_CONFIG}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" config "${_SC}" start= "${_CONFIG}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define SC::Status `!insertmacro SC::Status`
!macro SC::Status _SC _CONFIG _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${C}" /c "sc QUERY "${_SC}" | FIND /C "RUNNING""`
	Goto +2
	ExecDos::Exec /TOSTACK `"${C}" /c "sc QUERY "${_SC}" | FIND /C "RUNNING""`
	Pop ${_ERR1} ;=== 1 = success
	Pop ${_ERR2} ;=== 1 = running
	StrCmpS ${_ERR1} 1 0 +4
	StrCmpS ${_ERR2} 1 0 +3
	${WriteRuntimeData} ${PAL} ${_SC}_Status running
!macroend
; 
; The following macros were added by demon.devin
; 
Var $CMD
!define Service::Query `!insertmacro _Service::Query`
!macro _Service::Query _SVC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" query "${_SVC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" query "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
	StrCmp ${_ERR1} "1060" 0 +3
	SetErrors
	Goto +3
	${WriteRuntimeData} "${_SVC}Service" LocalService true
!macroend
!define Service::QueryConfig `!insertmacro _Service::QueryConfig`
!macro _Service::QueryConfig _SVC _FSR _ERR1 _ERR2
	ReadEnvStr $CMD COMSPEC
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"$CMD" /c "${SC} qc "${_SVC}" | FIND "BINARY_PATH_NAME""`
	Goto +2
	ExecDos::Exec /TOSTACK `"$CMD" /c "${SC} qc "${_SVC}" | FIND "BINARY_PATH_NAME""`
	Pop ${_ERR1}
	Pop ${_ERR2}
	StrCmpS ${_ERR1} 0 0 +4
	StrCpy $R1 ${_ERR2} "" 29
	${WriteRuntimeData} "${_SVC}Service" LocalPath "$R1"
	ReadRegStr $R1 HKLM `SYSTEM\CurrentControlSet\services\${_SVC}` ImagePath
	${WriteRuntimeData} "${_SVC}Service" LocalPath "$R1"
!macroend
!define Service::State `!insertmacro _Service::State`
!macro _Service::State _SVC _FSR _ERR1 _ERR2
    ReadEnvStr $CMD COMSPEC
    StrCmpS $Bit 64 0 +4
    StrCmp "${_FSR}" /DISABLEFSR 0 +3
    ExecDos::Exec /TOSTACK /DISABLEFSR `"$CMD" /c "${SC} query "${_SVC}" | find /C "RUNNING""`
    Goto +2
    ExecDos::Exec /TOSTACK `"$CMD" /c "${SC} query "${_SVC}" | find /C "RUNNING""`
    Pop ${_ERR1}
    Pop ${_ERR2}
	StrCmpS ${_ERR1} 1 0 +4
	StrCmpS ${_ERR2} 1 0 +3
	${WriteRuntimeData} "${_SVC}Service" LocalState Running
!macroend
!define Service::Start `!insertmacro _Service::Start`
!macro _Service::Start _SVC _FSR _ERR1 _ERR2
    StrCmpS $Bit 64 0 +4
    StrCmp "${_FSR}" /DISABLEFSR 0 +3
    ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" start "${_SVC}"`
    Goto +2
    ExecDos::Exec /TOSTACK `"${SC}" start "${_SVC}"`
    Pop ${_ERR1}
    Pop ${_ERR2}
!macroend
!define Service::Stop `!insertmacro _Service::Stop`
!macro _Service::Stop _SVC _FSR _ERR1 _ERR2
    StrCmpS $Bit 64 0 +4
    StrCmp "${_FSR}" /DISABLEFSR 0 +3
    ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" stop "${_SVC}"`
    Goto +2
    ExecDos::Exec /TOSTACK `"${SC}" stop "${_SVC}"`
    Pop ${_ERR1}
    Pop ${_ERR2}
!macroend
!define Service::Remove `!insertmacro _Service::Remove`
!macro _Service::Remove _SVC _FSR _ERR1 _ERR2
    StrCmpS $Bit 64 0 +4
    StrCmp "${_FSR}" /DISABLEFSR 0 +3
    ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" delete "${_SVC}"`
    Goto +2
    ExecDos::Exec /TOSTACK `"${SC}" delete "${_SVC}"`
    Pop ${_ERR1}
    Pop ${_ERR2}
!macroend
!define Service::Create `!insertmacro _Service::Create`
!macro _Service::Create _SVC _PATH _TYPE _START _DEPEND _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +7
	StrCmp "${_FSR}" /DISABLEFSR 0 +6
	StrCmp "${_DEPEND}" "" 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" create "${_SVC}" DisplayName= "${FULLNAME}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}"`
	Goto +7
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" create "${_SVC}" DisplayName= "${FULLNAME}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}" depend= ""${_DEPEND}""`
	Goto +5
	StrCmp "${_DEPEND}" "" 0 +3
	ExecDos::Exec /TOSTACK `"${SC}" create "${_SVC}" DisplayName= "${FULLNAME}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" create "${_SVC}" DisplayName= "${FULLNAME}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}" depend= ""${_DEPEND}""`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define ServiceLib::Create `!insertmacro _ServiceLib::Create`
!macro _ServiceLib::Create _RETURN _NAME _PATH _TYPE _START _DEPEND
	Push "start"
	Push "${_NAME}"
	StrCmp "${_DEPEND}" "" 0 +3
	Push "path=${_PATH};servicetype=${_TYPE};starttype=${_START};"
	Goto +2
	Push "path=${_PATH};servicetype=${_TYPE};starttype=${_START};depend=${_DEPEND};"
	Call Service
	Pop ${_RETURN}
!macroend
!define ServiceLib::Start `!insertmacro _ServiceLib::Start`
!macro _ServiceLib::Start _RETURN _NAME
	Push "start"
	Push "${_NAME}"
	Push ""
	Call Service
	Pop ${_RETURN} ;= Returns true/false
!macroend
!define ServiceLib::Remove `!insertmacro _ServiceLib::Remove`
!macro _ServiceLib::Remove _RETURN _NAME
	Push "delete"
	Push "${_NAME}"
	Push ""
	Call Service
	Pop ${_RETURN} ;= Returns true/false
!macroend
!define ServiceLib::Stop `!insertmacro _ServiceLib::Stop`
!macro _ServiceLib::Stop _RETURN _NAME
	Push "stop"
	Push "${_NAME}"
	Push ""
	Call Service
	Pop ${_RETURN} ;= Returns true/false
!macroend
!define ServiceLib::Pause `!insertmacro _ServiceLib::Pause`
!macro _ServiceLib::Pause _RETURN _NAME
	Push "pause"
	Push "${_NAME}"
	Push ""
	Call Service
	Pop ${_RETURN} ;= Returns true/false
!macroend
!define ServiceLib::Continue `!insertmacro _ServiceLib::Continue`
!macro _ServiceLib::Continue _RETURN _NAME
	Push "continue"
	Push "${_NAME}"
	Push ""
	Call Service
	Pop ${_RETURN} ;= Returns true/false
!macroend
!define ServiceLib::Status `!insertmacro _ServiceLib::Status`
!macro _ServiceLib::Status _RETURN _NAME
	Push "status"
	Push "${_NAME}"
	Push ""
	Call Service
	Pop ${_RETURN} ;= Returns stopped/running/start_pending/stop_pending/continue_pending/pause_pending/pause/unknown
!macroend
${SegmentFile}
${SegmentPre}
	# Uninstall Local Services
	!ifmacrodef PreServices
		!insertmacro PreServices
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		ReadINIStr $0 `${LAUNCHER}` `Service$R0` `Name`
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		ReadRegStr $1 HKLM `SYSTEM\CurrentControlSet\services\$0` ImagePath
		${IfNot} ${Errors}
			${WriteRuntimeData} "$0Service" LocalService true
			${ParseLocations} $1
			${WriteRuntimeData} "$0Service" LocalPath "$1"
		${Else}
			${WriteRuntimeData} "$0Service" LocalService false
		${EndIf}
		${DebugMsg} "Checking and logging state of local instance of $0 service."
		${ServiceLib::Status} $9 "$0"
		Pop $9
		${If} $9 == running
			${WriteRuntimeData} "$0Service" LocalState running
		${ElseIf} $9 == stopped
			${WriteRuntimeData} "$0Service" LocalState stopped
		${Else}
			${WriteRuntimeData} "$0Service" LocalState "$9"
		${EndIf}
		ClearErrors
		ReadINIStr $2 `${LAUNCHER}` `Service$R0` `IfExists`
		${If} $2 == replace
			${DebugMsg} "Preparing portable service of $0; removing local instance."
			PRE_SERVICE_STOP_LOOP:
			${ServiceLib::Stop} $9 "$0"
			Pop $9
			${If} $9 == true
				${ServiceLib::Remove} $8 "$0"
			${Else}
				Goto PRE_SERVICE_STOP_LOOP
			${EndIf}
			${Registry::CopyKey} "${PAFKEYS}\HKLM\SYSTEM\CurrentControlSet\services\$0" "HKLM\SYSTEM\CurrentControlSet\services\$0" $9
		${ElseIf} $2 == skip
			${DebugMsg} "Local service of $0 already exists; not preparing for a portable instance."
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentPrePrimary}
	# Install Portable Services
	!ifmacrodef PrePrimaryServices
		!insertmacro PrePrimaryServices
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 Service$R0 Name
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadLauncherConfig} $1 Service$R0 IfExists
		${If} $1 == replace
			${DebugMsg} "Creating a portable instance of the $0 service."
			${ReadLauncherConfig} $2 Service$R0 Path
			${ParseLocations} $2
			${ReadLauncherConfig} $3 Service$R0 Type
			${ReadLauncherConfig} $4 Service$R0 Start
			${ReadLauncherConfig} $5 Service$R0 Depend
			${IfNot} ${Errors}
			${OrIf} $5 != ""
				${ServiceLib::Create} $6 "$0" "$2" "$3" "$4" "$5"
			${Else}
				${ServiceLib::Create} $6 "$0" "$2" "$3" "$4" ""
			${EndIf}
			WriteRegStr HKLM "SYSTEM\CurrentControlSet\services\$0" "ImagePath" "$2"
			Sleep 1500
			${ServiceLib::Start} $9 "$0"
			Pop $9
			${If} $9 == true
				${DebugMsg} "The portable instance of the $0 service has been started."
			${ElseIf} $9 == false
				MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST "The portable instance of the $0 service failed to start.${NewLine}Continuing anyway!"
			${EndIf}
		${ElseIf} $1 == skip
			${DebugMsg} "Local service of $0 already exists; not creating a portable instance."
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentPostPrimary}
	# Uninstall Portable Services
	!ifmacrodef PostPrimaryServices
		!insertmacro PostPrimaryServices
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 Service$R0 Name
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadLauncherConfig} $1 Service$R0 IfExists
		${If} $1 == replace
			${DebugMsg} "Removing portable service of $0 to prepare for reinstallation of the local instance."
			POST_SERVICE_STOP_LOOP:
			${ServiceLib::Stop} $9 "$0"
			Pop $9
			${If} $9 == true
				${ServiceLib::Remove} $9 "$0"
			${Else}
				Goto POST_SERVICE_STOP_LOOP
			${EndIf}
			DeleteRegKey HKLM "SYSTEM\CurrentControlSet\services\$0"
		${ElseIf} $1 == skip 
			${DebugMsg} "Local service of $0 was already installed; no further action taken."
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentUnload}
	# Restore Local Services
	!ifmacrodef UnloadServices
		!insertmacro UnloadServices
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 Service$R0 Name
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadLauncherConfig} $1 Service$R0 IfExists
		${If} $1 == replace
			${DebugMsg} "Reinstalling the local instance of the $0 service."
			${ReadRuntimeData} $7 "$0Service" LocalService
			${If} $7 == true
				${Registry::RestoreBackupKey} "HKLM\SYSTEM\CurrentControlSet\services\$0" $9
				${ReadRuntimeData} $5 "$0Service" LocalPath
				${ReadLauncherConfig} $2 Service$R0 Type
				${ReadLauncherConfig} $3 Service$R0 Start
				${ReadLauncherConfig} $4 Service$R0 Depend
				${IfNot} ${Errors}
				${OrIf} $4 != ""
					${ServiceLib::Create} $8 "$0" "$5" "$2" "$3" "$4"
				${Else}
					${ServiceLib::Create} $8 "$0" "$5" "$2" "$3" ""
				${EndIf}
				${ReadRuntimeData} $6 "$0Service" LocalState
				${If} $6 == running
					${DebugMsg} "Restarting local instance of the $0 service."
					Sleep 1000
					${ServiceLib::Start} $9 "$0"
					Pop $9
				${ElseIf} $6 == stopped
					${DebugMsg} "Local instance of the $0 service was not running before runtime; no further action required."
				${EndIf}
			${EndIf}
		${ElseIf} $1 == skip
			${DebugMsg} "Local service of $0 was already installed; no further action taken."
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}	
!macroend
