
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
!macro SC::Status _SC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${C}" /c "sc QUERY "${_SC}" | FIND /C "RUNNING""`
	Goto +2
	ExecDos::Exec /TOSTACK `"${C}" /c "sc QUERY "${_SC}" | FIND /C "RUNNING""`
	Pop ${_ERR1} ;=== 1 = success
	Pop ${_ERR2} ;=== 1 = running
	StrCmpS ${_ERR1} 1 0 +4
	StrCmpS ${_ERR2} 1 0 +3
	${WriteRuntimeData} ${PAC} ${_SC}_Status running
!macroend
; 
; The following macros were added by demon.devin using the ServiceLib.nsh
; 
!define ServiceLib::Create `!insertmacro _ServiceLib::Create`
!macro _ServiceLib::Create _RETURN _NAME _PATH _TYPE _START _DEPEND
	Push "create"
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
		ReadINIStr $0 "${LAUNCHER}" "Service$R0" "Name"
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		ReadRegStr $1 HKLM "SYSTEM\CurrentControlSet\services\$0" ImagePath
		${IfNot} ${Errors}
			StrCpy $2 $1 4
			StrCmp $2 \??\ 0 +2
			StrCpy $1 $1 "" 4
			${WriteRuntimeData} "$0_Service" LocalService true
			${WriteRuntimeData} "$0_Service" LocalPath "$1"
			${DebugMsg} "Checking and logging state of local instance of $0 service."
			ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\services\$0" Start
			${WriteRuntimeData} "$0_Service" LocalState $0
			ReadINIStr $3 "${LAUNCHER}" "Service$R0" "IfExists"
			${If} $3 == replace
				${DebugMsg} "Preparing portable service of $0; removing local instance."
				${SC::Stop} "$0" /DISABLEFSR $8 $9
				${SC::Delete} "$0" /DISABLEFSR $8 $9
			${ElseIf} $3 == skip
				${DebugMsg} "Local service of $0 already exists; not preparing for a portable instance."
			${EndIf}
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
			${If} $5 != ""
				${SC::Create} "$0" "$2" "$3" "$4" "$5" /DISABLEFSR $8 $9
			${Else}
				${SC::Create} "$0" "$2" "$3" "$4" "" /DISABLEFSR $8 $9
			${EndIf}
			${SC::Start} "$0" /DISABLEFSR $8 $9
			ReadEnvStr $R9 COMSPEC
			${If} Bit == 64
				ExecDos::Exec /TOSTACK /DISABLEFSR `"$R9" /c "sc QUERY "$0" | FIND /C "RUNNING""`
			${Else}
				ExecDos::Exec /TOSTACK `"$R9" /c "sc QUERY "$0" | FIND /C "RUNNING""`
			${EndIf}
			Pop $R7 ;=== 1 = success
			Pop $R8 ;=== 1 = running
			${If} $R7 == 1
			${OrIf} $R8 == 1
				${DebugMsg} "The portable instance of the $0 service has been started."
			${Else}
				${DebugMsg} "The portable instance of the $0 service failed to start."
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
			${ReadRuntimeData} $3 "$0_Service" LocalService
			${If} ${Errors}
				${SC::Stop} "$0" /DISABLEFSR $8 $9
				${SC::Delete} "$0" /DISABLEFSR $8 $9
			${Else}
				${SC::Stop} "$0" /DISABLEFSR $8 $9
			${EndIf}
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
			${ReadRuntimeData} $2 "$0_Service" LocalService
			${IfNot} ${Errors}
				${ReadRuntimeData} $3 "$0_Service" LocalPath
				${ReadLauncherConfig} $4 Service$R0 Type
				${ReadLauncherConfig} $5 Service$R0 Start
				${ReadLauncherConfig} $6 Service$R0 Depend
				${If} $6 != ""
					${SC::Create} "$0" "$3" "$4" "$5" "$6" /DISABLEFSR $8 $9
				${Else}
					${SC::Create} "$0" "$3" "$4" "$5" "" /DISABLEFSR $8 $9
				${EndIf}
				${ReadRuntimeData} $7 "$0_Service" LocalState
				${If} $7 != 4
					${DebugMsg} "Restarting local instance of the $0 service."
					${SC::Start} "$0" /DISABLEFSR $8 $9
				${Else}
					${DebugMsg} "Local instance of the $0 service was not running before runtime; no further action required."
				${EndIf}
			${EndIf}
		${ElseIf} $1 == skip
			${DebugMsg} "Local service of $0 was already installed; no further action taken."
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}	
!macroend
