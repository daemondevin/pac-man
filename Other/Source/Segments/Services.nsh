; ${SegmentFile}

; Currently services are disabled as
;   (a) they're not used yet (possibly unstable) and
;   (b) the plug-in is fairly large (at time of reporting, 122591B vs. 96901B, 25KB larger)
; TODO: switch back to NSIS code... got to sort out the null byte issue with dependencies.

; !define SERVICES_ENABLED

; !ifndef SERVICES_ENABLED
	; !echo "The Services segment is currently disabled."
; !else ifdef NSIS_UNICODE
	; !warning "The Services segment is disabled for your build as the SimpleSC plug-in is not Unicode-compatible."
	; !undef SERVICES_ENABLED
; !endif


; ${SegmentPrePrimary}
; !ifdef SERVICES_ENABLED
	; StrCpy $R0 1
	; ${Do}
		; ClearErrors
		; ${ReadLauncherConfig} $1 Service$R0 Name
		; ${ReadLauncherConfig} $4 Service$R0 Path
		; ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		; ${ParseLocations} $4
		; SimpleSC::ExistsService $1
		; Pop $2
		; ${If} $2 == 0 ; Service already exists
			; ${ReadLauncherConfig} $2 Service$R0 IfExists
			; ${If} $2 == replace
				; MessageBox MB_ICONEXCLAMATION "TODO: The backing up and replacement of services is not yet implemented. The local service will remain."
				; /*
				; SimpleSC::GetServiceDisplayName $1
				; Pop $9
				; Pop $2
				; ${DebugMsg} "Local service $1's display name is $2 (error code $9)"
				; SimpleSC::GetServiceBinaryPath $1
				; Pop $9
				; Pop $3
				; ${DebugMsg} "Local service $1's binary path is $3 (error code $9)"
				; TODO: this is going to be very messy. I'm not going to do it till later.
				; ${NewServiceLib.BackupService} $1 $DataDirectory\PortableApps.comLauncherWorkingData.ini Service$1
				; SimpleSC::RemoveService $1
				; Pop $9
				; ${DebugMsg} "Removed local service $1 (error code $9)
				; */
			; ${EndIf}
			; ${WriteRuntimeData} Service$R0 ExistedBefore true
			; StrCpy $R9 no-create
		; ${EndIf}
		; ${If} $R9 == no-create
			; ${DebugMsg} "Not creating service $1 (local service already exists)"
		; ${Else}
			; ${ReadLauncherConfigWithDefault} $2 Service$R0 Display $1
			; ${ReadLauncherConfig} $3 Service$R0 Type
			; ${If} $3 == driver-kernel
				; StrCpy $3 1
			; ${ElseIf} $3 == driver-file-system
				; StrCpy $3 2
			; ${Else}
				; StrCpy $3 16
			; ${EndIf}
			; ${ReadLauncherConfig} $5 Service$R0 Dependencies
			; ${ReadLauncherConfig} $6 Service$R0 User
			; ${If} $4 == LocalService
			; ${OrIf} $4 == NetworkService
				; StrCpy $4 "NT AUTHORITY\$4"
			; ${EndIf}
			; SimpleSC::InstallService $1 $2 $3 3 $4 $5 $6 "" ; the 3 is for manual start, "" is an empty password
			; Pop $9
			; ${DebugMsg} "Installed service $1 (error code $9)"
			; ClearErrors
			; ${ReadLauncherConfig} $7 Service$R0 Description
			; ${If} ${Errors}
				; SimpleSC::SetServiceDescription $1 $7
				; Pop $9
				; ${DebugMsg} "Set service $1's description to $7"
			; ${EndIf}
			; IntOp $R0 $R0 + 1
		; ${EndIf}
	; ${Loop}
; !endif
; !macroend

; ${SegmentPostPrimary}
; !ifdef SERVICES_ENABLED
	; StrCpy $R0 1
	; ${Do}
		; ClearErrors
		; ${ReadLauncherConfig} $1 Service$R0 Name
		; ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		; TODO: save state in the runtime data to prevent doing anything silly.
		; Possibly also check the service path to make sure it's the right one we delete.
		; SimpleSC::GetServiceStatus $1
		; Pop $9 ; error code
		; Pop $2 ; return value
		; ${DebugMsg} "Service $1's status: $2 (error code $9)"
		; ${If} $2 != 1 ; 1 = stopped
			; SimpleSC::StopService $1
			; Pop $9
			; ${DebugMsg} "Stopped service $1 (error code $9)"
		; ${EndIf}
		; SimpleSC::RemoveService $1
		; Pop $9
		; ${DebugMsg} "Removed service $1 (error code $9)"
	; ${Loop}
; !endif
; !macroend


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
	ReadEnvStr $R0 COMSPEC
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"$R0" /c "${SC} qc "${_SVC}" | FIND "BINARY_PATH_NAME""`
	Goto +2
	ExecDos::Exec /TOSTACK `"$R0" /c "${SC} qc "${_SVC}" | FIND "BINARY_PATH_NAME""`
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
    ReadEnvStr $R0 COMSPEC
    StrCmpS $Bit 64 0 +4
    StrCmp "${_FSR}" /DISABLEFSR 0 +3
    ExecDos::Exec /TOSTACK /DISABLEFSR `"$R0" /c "${SC} query "${_SVC}" | find /C "RUNNING""`
    Goto +2
    ExecDos::Exec /TOSTACK `"$R0" /c "${SC} query "${_SVC}" | find /C "RUNNING""`
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
			ReadINIStr $2 `${LAUNCHER}` `Service$R0` `IfExists`
			${If} $2 == replace
				ReadEnvStr $R0 COMSPEC
				StrCmpS $Bit 64 0 +3
				ExecDos::Exec /TOSTACK /DISABLEFSR `"$R0" /c "${SC} query "${_SVC}" | find /C "RUNNING""`
				Goto +2
				ExecDos::Exec /TOSTACK `"$R0" /c "${SC} query "${_SVC}" | find /C "RUNNING""`
				Pop $8
				Pop $9
				StrCmpS $8 1 0 +4
				StrCmpS $9 1 0 +3
				${WriteRuntimeData} "$0Service" LocalState Running
				StrCmpS $Bit 64 0 +3
				ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" stop "${_SVC}"`
				Goto +2
				ExecDos::Exec /TOSTACK `"${SC}" stop "${_SVC}"`
				Pop $8
				Pop $9
				StrCmpS $Bit 64 0 +3
				ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" delete "${_SVC}"`
				Goto +2
				ExecDos::Exec /TOSTACK `"${SC}" delete "${_SVC}"`
				Pop $8
				Pop $9
			${EndIf}
		${EndIf}
		ClearErrors
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
		${ReadLauncherConfig} $1 Service$R0 Name
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadLauncherConfig} $0 Service$R0 IfExists
		${If} $0 == replace
			${ReadLauncherConfig} $2 Service$R0 Path
			${ReadLauncherConfig} $3 Service$R0 Type
			${ReadLauncherConfig} $4 Service$R0 Start
			${ReadLauncherConfig} $5 Service$R0 Depend
			${ParseLocations} $2
			${Service::Create} "$1" "$2" "$3" "$4" "$5" /DISABLEFSR $8 $9
			${Registry::CopyKey} "${PAFKEYS}\HKLM\SYSTEM\CurrentControlSet\services\$1" "HKLM\SYSTEM\CurrentControlSet\services\$1" $9
			WriteRegStr HKLM "SYSTEM\CurrentControlSet\services\$1" "ImagePath" "$2"
			Sleep 50
			${Service::Start} "$1" /DISABLEFSR $8 $9
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
		${ReadLauncherConfig} $1 Service$R0 Name
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadLauncherConfig} $0 Service$R0 IfExists
		${If} $0 == replace
			${Service::Stop} "$1" /DISABLEFSR $8 $9
			Sleep 50
			${Service::Remove} "$1" /DISABLEFSR $8 $9
			DeleteRegKey HKLM "SYSTEM\CurrentControlSet\services\$1"
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
		${ReadLauncherConfig} $1 Service$R0 Name
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadLauncherConfig} $0 Service$R0 IfExists
		${If} $0 == replace
			${ReadRuntimeData} $7 "$1Service" LocalService
			${IfNot} ${Errors}
			${AndIf} $7 == true
				${Registry::RestoreBackupKey} "HKLM\SYSTEM\CurrentControlSet\services\$1" $9
				${ReadRuntimeData} $5 "$1Service" LocalState
				${If} $5 == "Running"
					${ReadRuntimeData} $6 "$1Service" LocalPath
					${IfNot} ${Errors}
						${ReadLauncherConfig} $2 Service$R0 Type
						${ReadLauncherConfig} $3 Service$R0 Start
						${ReadLauncherConfig} $4 Service$R0 Depend
						${Service::Create} "$1" "$6" "$2" "$3" "$4" /DISABLEFSR $8 $9
						Sleep 50
						${Service::Start} "$1" /DISABLEFSR $8 $9
					${EndIf}
				${EndIf}
			${EndIf}
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}	
!macroend
