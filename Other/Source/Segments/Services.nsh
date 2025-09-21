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
;   This file enables support for handling Windows Services 
;   with error handling, conflict resolution, and dependency management.
; 
; USAGE
;	To make use of this segment, add the section [Service1] (numerical ordering) to the Launcher.ini file. 
;	Each entry supports the following keys: 
;
;	Name		-	The local/portable service name.
;	Path		-	The path to the portable service executable. Supports environment variables.
;	Type		-	Specify whether you are dealing with a service, a kernel driver or a file system driver, etc.
;					Choose from: own, share, interact, kernel, filesys, rec, adapter
;	Start		-	Specify when the service is supposed to start.
;					Choose from: boot, system, auto, demand, disabled, delayed-auto
;	Depend		-	List any dependencies here separated by / (forward slash).
;	IfExists	-	If the service already exists, you can either skip it or replace it with the portable version of the service.
;					Choose from: skip, replace, backup
;	Description	-	Optional service description
;	Account		-	Optional service account (LocalSystem, LocalService, NetworkService, or custom)
;	Password	-	Password for custom account (if Account is specified)
;	Timeout		-	Timeout in seconds for service operations (default: 30)
;	Critical	-	If true, failure to start this service will show a warning (true/false)
;
; EXAMPLE
;	[Service1]
;	Name=ServiceName
;	Path=%PAL:DataDir%\Service_driver.sys
;	Type=kernel
;	Start=system
;	Depend=
;	IfExists=replace
;	Description=My Portable Service
;	Timeout=45
;	Critical=true
; 
;=# NEW FEATURES (8/26/2025)
; - Three-tier backup strategy (skip/replace/backup)
; - Critical service protection and warning system
; - Dependency validation
; - Service account management with password support
; - Timeout-based operations with real-time monitoring
; - Enhanced configuration validation
; - Detailed error categorization and user feedback
;
!ifdef SERVICES
${IncludeIfNotDefined} LOGICLIB LogicLib.nsh
${IncludeIfNotDefined} STR_CASE_NSH_INCLUDED StrCase.nsh
${IncludeIfNotDefined} ISFILE_NSH_INCLUDED IsFile.nsh
${IncludeIfNotDefined} STR_CONTAINS_NSH_INCLUDED StrContains.nsh
${IncludeIfNotDefined} STR_LOC_NSH_INCLUDED StrLoc.nsh

${DefineIfNotDefined} SC `$SYSDIR\sc.exe`
${DefineIfNotDefined} NET `$SYSDIR\net.exe`

; Service state constants
${DefineIfNotDefined} SERVICE_STOPPED 1
${DefineIfNotDefined} SERVICE_START_PENDING 2
${DefineIfNotDefined} SERVICE_STOP_PENDING 3
${DefineIfNotDefined} SERVICE_RUNNING 4
${DefineIfNotDefined} SERVICE_CONTINUE_PENDING 5
${DefineIfNotDefined} SERVICE_PAUSE_PENDING 6
${DefineIfNotDefined} SERVICE_PAUSED 7

; Service macros with timeout and error handling
!define Service::Query `!insertmacro _Service::Query`
!macro _Service::Query _SVC _FSR _EXIST _STATE _ERR1 _ERR2
	Push $R8
	Push $R9
	
	StrCmpS $Bits 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" query "${_SVC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" query "${_SVC}"`
	Pop ${_ERR1}
	Pop $R8 ; Output text
	
	; Check if service exists
	${If} ${_ERR1} == 0
		StrCpy ${_EXIST} "true"
		
		; Parse state from output
		StrCpy ${_STATE} "unknown"
		${If} $R8 != ""
			; Look for state in the output
			StrCpy $R9 $R8
			${If} ${StrContains} $R9 "STOPPED"
				StrCpy ${_STATE} "stopped"
			${ElseIf} ${StrContains} $R9 "RUNNING"
				StrCpy ${_STATE} "running"
			${ElseIf} ${StrContains} $R9 "PAUSED"
				StrCpy ${_STATE} "paused"
			${ElseIf} ${StrContains} $R9 "START_PENDING"
				StrCpy ${_STATE} "start_pending"
			${ElseIf} ${StrContains} $R9 "STOP_PENDING"
				StrCpy ${_STATE} "stop_pending"
			${EndIf}
		${EndIf}
		StrCpy ${_ERR2} "Service exists"
	${ElseIf} ${_ERR1} == 1060
		StrCpy ${_EXIST} "false"
		StrCpy ${_STATE} "not_found"
		StrCpy ${_ERR2} "Service not found"
	${Else}
		StrCpy ${_EXIST} "false"
		StrCpy ${_STATE} "error"
		StrCpy ${_ERR2} "Query failed with error ${_ERR1}"
	${EndIf}
	
	Pop $R9
	Pop $R8
!macroend

!define Service::Stop `!insertmacro _Service::Stop`
!macro _Service::Stop _SVC _TIMEOUT _FSR _ERR1 _ERR2
	Push $R8
	Push $R9
	Push $0
	
	; First check if service is running
	${Service::Query} "${_SVC}" "${_FSR}" $R8 $R9 $0 ${_ERR2}
	${If} $R9 == "running"
	${OrIf} $R9 == "start_pending"
		${DebugMsg} "Stopping service: ${_SVC}"
		
		StrCmpS $Bits 64 0 +4
		StrCmp "${_FSR}" /DISABLEFSR 0 +3
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" stop "${_SVC}"`
		Goto +2
		ExecDos::Exec /TOSTACK `"${SC}" stop "${_SVC}"`
		Pop ${_ERR1}
		Pop ${_ERR2}
		
		; Wait for service to stop with timeout
		${If} ${_ERR1} == 0
			StrCpy $R8 0 ; Counter
			${Do}
				Sleep 1000
				IntOp $R8 $R8 + 1
				${Service::Query} "${_SVC}" "${_FSR}" $R9 $0 $R9 ${_ERR2}
				${If} $0 == "stopped"
					${DebugMsg} "Service ${_SVC} stopped successfully"
					${ExitDo}
				${ElseIf} $R8 >= ${_TIMEOUT}
					StrCpy ${_ERR1} "1460" ; ERROR_TIMEOUT
					StrCpy ${_ERR2} "Timeout waiting for service to stop"
					${DebugMsg} "Timeout stopping service: ${_SVC}"
					${ExitDo}
				${EndIf}
			${Loop}
		${EndIf}
	${ElseIf} $R9 == "stopped"
		StrCpy ${_ERR1} "0"
		StrCpy ${_ERR2} "Service already stopped"
		${DebugMsg} "Service ${_SVC} already stopped"
	${Else}
		StrCpy ${_ERR1} "1062" ; SERVICE_NOT_ACTIVE
		StrCpy ${_ERR2} "Service not in stoppable state: $R9"
	${EndIf}
	
	Pop $0
	Pop $R9
	Pop $R8
!macroend

!define Service::Start `!insertmacro _Service::Start`
!macro _Service::Start _SVC _TIMEOUT _FSR _ERR1 _ERR2
	Push $R8
	Push $R9
	Push $0
	
	; Check current state
	${Service::Query} "${_SVC}" "${_FSR}" $R8 $R9 $0 ${_ERR2}
	${If} $R9 == "stopped"
	${OrIf} $R9 == "stop_pending"
		${DebugMsg} "Starting service: ${_SVC}"
		
		StrCmpS $Bits 64 0 +4
		StrCmp "${_FSR}" /DISABLEFSR 0 +3
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" start "${_SVC}"`
		Goto +2
		ExecDos::Exec /TOSTACK `"${SC}" start "${_SVC}"`
		Pop ${_ERR1}
		Pop ${_ERR2}
		
		; Wait for service to start with timeout
		${If} ${_ERR1} == 0
			StrCpy $R8 0 ; Counter
			${Do}
				Sleep 1000
				IntOp $R8 $R8 + 1
				${Service::Query} "${_SVC}" "${_FSR}" $R9 $0 $R9 ${_ERR2}
				${If} $0 == "running"
					${DebugMsg} "Service ${_SVC} started successfully"
					${ExitDo}
				${ElseIf} $0 == "stopped"
					StrCpy ${_ERR1} "1067" ; ERROR_PROCESS_ABORTED
					StrCpy ${_ERR2} "Service failed to start"
					${DebugMsg} "Service ${_SVC} failed to start"
					${ExitDo}
				${ElseIf} $R8 >= ${_TIMEOUT}
					StrCpy ${_ERR1} "1460" ; ERROR_TIMEOUT
					StrCpy ${_ERR2} "Timeout waiting for service to start"
					${DebugMsg} "Timeout starting service: ${_SVC}"
					${ExitDo}
				${EndIf}
			${Loop}
		${EndIf}
	${ElseIf} $R9 == "running"
		StrCpy ${_ERR1} "0"
		StrCpy ${_ERR2} "Service already running"
		${DebugMsg} "Service ${_SVC} already running"
	${Else}
		StrCpy ${_ERR1} "1056" ; SERVICE_ALREADY_RUNNING or invalid state
		StrCpy ${_ERR2} "Service not in startable state: $R9"
	${EndIf}
	
	Pop $0
	Pop $R9
	Pop $R8
!macroend

!define Service::Delete `!insertmacro _Service::Delete`
!macro _Service::Delete _SVC _FSR _ERR1 _ERR2
	Push $R8
	Push $R9
	
	; First ensure service is stopped
	${Service::Stop} "${_SVC}" 30 "${_FSR}" $R8 $R9
	
	; Now delete the service
	StrCmpS $Bits 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" delete "${_SVC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" delete "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
	
	; Wait a moment for deletion to complete
	${If} ${_ERR1} == 0
		Sleep 2000
		${DebugMsg} "Service ${_SVC} deleted successfully"
	${Else}
		${DebugMsg} "Failed to delete service ${_SVC}: ${_ERR2}"
	${EndIf}
	
	Pop $R9
	Pop $R8
!macroend

!define Service::Create `!insertmacro _Service::Create`
!macro _Service::Create _SVC _PATH _TYPE _START _DEPEND _ACCOUNT _PASSWORD _DESCRIPTION _FSR _ERR1 _ERR2
	Push $R8
	Push $R9
	Push $0
	
	; Build the create command
	StrCpy $R8 `"${SC}" create "${_SVC}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}"`
	
	; Add dependencies if specified
	${If} "${_DEPEND}" != ""
		StrCpy $R8 `$R8 depend= "${_DEPEND}"`
	${EndIf}
	
	; Add account if specified
	${If} "${_ACCOUNT}" != ""
		${If} "${_ACCOUNT}" == "LocalSystem"
		${OrIf} "${_ACCOUNT}" == "LocalService"
		${OrIf} "${_ACCOUNT}" == "NetworkService"
			StrCpy $R8 `$R8 obj= "${_ACCOUNT}"`
		${Else}
			; Custom account
			${If} "${_PASSWORD}" != ""
				StrCpy $R8 `$R8 obj= "${_ACCOUNT}" password= "${_PASSWORD}"`
			${Else}
				StrCpy $R8 `$R8 obj= "${_ACCOUNT}"`
			${EndIf}
		${EndIf}
	${EndIf}
	
	; Execute the create command
	StrCmpS $Bits 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `$R8`
	Goto +2
	ExecDos::Exec /TOSTACK `$R8`
	Pop ${_ERR1}
	Pop ${_ERR2}
	
	; Set description if specified and creation was successful
	${If} ${_ERR1} == 0
	${AndIf} "${_DESCRIPTION}" != ""
		StrCmpS $Bits 64 0 +4
		StrCmp "${_FSR}" /DISABLEFSR 0 +3
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" description "${_SVC}" "${_DESCRIPTION}"`
		Goto +2
		ExecDos::Exec /TOSTACK `"${SC}" description "${_SVC}" "${_DESCRIPTION}"`
		Pop $R9 ; Ignore description errors
		Pop $0
		${DebugMsg} "Service ${_SVC} created successfully"
	${ElseIf} ${_ERR1} == 1073
		; Service already exists
		StrCpy ${_ERR2} "Service already exists"
	${Else}
		${DebugMsg} "Failed to create service ${_SVC}: ${_ERR2}"
	${EndIf}
	
	Pop $0
	Pop $R9
	Pop $R8
!macroend

!define Service::Backup `!insertmacro _Service::Backup`
!macro _Service::Backup _SVC _SECTION _KEY
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	
	; Backup comprehensive service information
	ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Services\${_SVC}" "ImagePath"
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_ImagePath" "$0"
	${EndIf}
	
	ReadRegDWORD $1 HKLM "SYSTEM\CurrentControlSet\Services\${_SVC}" "Start"
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Start" "$1"
	${EndIf}
	
	ReadRegDWORD $2 HKLM "SYSTEM\CurrentControlSet\Services\${_SVC}" "Type"
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Type" "$2"
	${EndIf}
	
	ReadRegStr $3 HKLM "SYSTEM\CurrentControlSet\Services\${_SVC}" "Description"
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Description" "$3"
	${EndIf}
	
	ReadRegStr $4 HKLM "SYSTEM\CurrentControlSet\Services\${_SVC}" "ObjectName"
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_ObjectName" "$4"
	${EndIf}
	
	ReadRegStr $5 HKLM "SYSTEM\CurrentControlSet\Services\${_SVC}" "DependOnService"
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_DependOnService" "$5"
	${EndIf}
	
	${WriteRuntimeData} ${_SECTION} "${_KEY}_BackupComplete" "true"
	${DebugMsg} "Service backup completed for: ${_SVC}"
	
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

!define Service::Restore `!insertmacro _Service::Restore`
!macro _Service::Restore _SVC _SECTION _KEY _FSR _ERR1 _ERR2
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	
	; Check if we have a backup
	${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_BackupComplete"
	${If} ${Errors}
		StrCpy ${_ERR1} "1"
		StrCpy ${_ERR2} "No backup found for service ${_SVC}"
		${DebugMsg} "No backup found for service: ${_SVC}"
		Goto RestoreEnd
	${EndIf}
	
	; Read backed up values
	${ReadRuntimeData} $1 ${_SECTION} "${_KEY}_ImagePath"
	${ReadRuntimeData} $2 ${_SECTION} "${_KEY}_Start"
	${ReadRuntimeData} $3 ${_SECTION} "${_KEY}_Type"
	${ReadRuntimeData} $4 ${_SECTION} "${_KEY}_Description"
	${ReadRuntimeData} $5 ${_SECTION} "${_KEY}_ObjectName"
	
	; Convert numeric values to SC command format
	${Switch} $2
		${Case} "0"
			StrCpy $2 "boot"
			${Break}
		${Case} "1"
			StrCpy $2 "system"
			${Break}
		${Case} "2"
			StrCpy $2 "auto"
			${Break}
		${Case} "3"
			StrCpy $2 "demand"
			${Break}
		${Case} "4"
			StrCpy $2 "disabled"
			${Break}
		${Default}
			StrCpy $2 "demand"
			${Break}
	${EndSwitch}
	
	${Switch} $3
		${Case} "1"
			StrCpy $3 "kernel"
			${Break}
		${Case} "2"
			StrCpy $3 "filesys"
			${Break}
		${Case} "16"
			StrCpy $3 "own"
			${Break}
		${Case} "32"
			StrCpy $3 "share"
			${Break}
		${Default}
			StrCpy $3 "own"
			${Break}
	${EndSwitch}
	
	; Restore the service
	${Service::Create} "${_SVC}" "$1" "$3" "$2" "" "$5" "" "$4" "${_FSR}" ${_ERR1} ${_ERR2}
	
	${If} ${_ERR1} == 0
		${DebugMsg} "Service ${_SVC} restored successfully"
	${Else}
		${DebugMsg} "Failed to restore service ${_SVC}: ${_ERR2}"
	${EndIf}
	
	RestoreEnd:
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

;
; Utility macros for advanced service scenarios
;

; Check if service is critical system service
!define Service::IsCriticalSystem `!insertmacro _Service::IsCriticalSystem`
!macro _Service::IsCriticalSystem _SVC _RESULT
	Push $0
	StrCpy ${_RESULT} "false"
	
	; List of critical system services that should never be replaced
	${Switch} "${_SVC}"
		${Case} "winmgmt"
		${Case} "rpcss"
		${Case} "eventlog"
		${Case} "lsass"
		${Case} "csrss"
		${Case} "services"
		${Case} "smss"
		${Case} "wininit"
		${Case} "winlogon"
			StrCpy ${_RESULT} "true"
			${Break}
	${EndSwitch}
	
	Pop $0
!macroend

; Validate service configuration
!define Service::ValidateConfig `!insertmacro _Service::ValidateConfig`
!macro _Service::ValidateConfig _TYPE _START _RESULT _ERROR
	Push $0
	StrCpy ${_RESULT} "true"
	StrCpy ${_ERROR} ""
	
	; Validate service type
	${Switch} "${_TYPE}"
		${Case} "own"
		${Case} "share"
		${Case} "interact"
		${Case} "kernel"
		${Case} "filesys"
		${Case} "rec"
		${Case} "adapter"
			; Valid types
			${Break}
		${Default}
			StrCpy ${_RESULT} "false"
			StrCpy ${_ERROR} "Invalid service type: ${_TYPE}"
			${Break}
	${EndSwitch}
	
	; Validate start type
	${If} ${_RESULT} == "true"
		${Switch} "${_START}"
			${Case} "boot"
			${Case} "system"
			${Case} "auto"
			${Case} "demand"
			${Case} "disabled"
			${Case} "delayed-auto"
				; Valid start types
				${Break}
			${Default}
				StrCpy ${_RESULT} "false"
				StrCpy ${_ERROR} "Invalid start type: ${_START}"
				${Break}
		${EndSwitch}
	${EndIf}
	
	Pop $0
!macroend

; Wait for service state change
!define Service::WaitForState `!insertmacro _Service::WaitForState`
!macro _Service::WaitForState _SVC _EXPECTEDSTATE _TIMEOUT _FSR _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy $R8 0 ; Counter
	
	${Do}
		${Service::Query} "${_SVC}" "${_FSR}" $0 $1 $2 $3
		${If} $1 == "${_EXPECTEDSTATE}"
			StrCpy ${_RESULT} "true"
			${ExitDo}
		${EndIf}
		
		Sleep 1000
		IntOp $R8 $R8 + 1
		${If} $R8 >= ${_TIMEOUT}
			${ExitDo}
		${EndIf}
	${Loop}
	
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Get service startup type as string
!define Service::GetStartTypeString `!insertmacro _Service::GetStartTypeString`
!macro _Service::GetStartTypeString _STARTVALUE _RESULT
	${Switch} "${_STARTVALUE}"
		${Case} "0"
			StrCpy ${_RESULT} "boot"
			${Break}
		${Case} "1"
			StrCpy ${_RESULT} "system"
			${Break}
		${Case} "2"
			StrCpy ${_RESULT} "auto"
			${Break}
		${Case} "3"
			StrCpy ${_RESULT} "demand"
			${Break}
		${Case} "4"
			StrCpy ${_RESULT} "disabled"
			${Break}
		${Default}
			StrCpy ${_RESULT} "unknown"
			${Break}
	${EndSwitch}
!macroend

; Error handling for service operations
!define Service::HandleError `!insertmacro _Service::HandleError`
!macro _Service::HandleError _OPERATION _SERVICE _ERRORCODE _ERRORMSG _CRITICAL
	${Switch} "${_ERRORCODE}"
		${Case} "0"
			${DebugMsg} "Service ${_OPERATION} successful for ${_SERVICE}"
			${Break}
		${Case} "1056"
			${DebugMsg} "Service ${_SERVICE} already in requested state"
			${Break}
		${Case} "1060"
			${DebugMsg} "Service ${_SERVICE} not found"
			${If} "${_CRITICAL}" == "true"
				MessageBox MB_OK|MB_ICONEXCLAMATION "Critical service '${_SERVICE}' not found."
			${EndIf}
			${Break}
		${Case} "1062"
			${DebugMsg} "Service ${_SERVICE} not started"
			${Break}
		${Case} "1067"
			${DebugMsg} "Service ${_SERVICE} terminated unexpectedly"
			${If} "${_CRITICAL}" == "true"
				MessageBox MB_OK|MB_ICONEXCLAMATION "Critical service '${_SERVICE}' terminated unexpectedly."
			${EndIf}
			${Break}
		${Case} "1073"
			${DebugMsg} "Service ${_SERVICE} already exists"
			${Break}
		${Case} "1460"
			${DebugMsg} "Timeout during ${_OPERATION} for service ${_SERVICE}"
			${If} "${_CRITICAL}" == "true"
				MessageBox MB_OK|MB_ICONEXCLAMATION "Timeout during ${_OPERATION} for critical service '${_SERVICE}'."
			${EndIf}
			${Break}
		${Default}
			${DebugMsg} "Service ${_OPERATION} failed for ${_SERVICE}: ${_ERRORMSG} (Code: ${_ERRORCODE})"
			${If} "${_CRITICAL}" == "true"
				MessageBox MB_OK|MB_ICONEXCLAMATION "Critical service operation failed:$\nService: ${_SERVICE}$\nOperation: ${_OPERATION}$\nError: ${_ERRORMSG}"
			${EndIf}
			${Break}
	${EndSwitch}
!macroend
; Check service dependencies
!define Service::CheckDependencies `!insertmacro _Service::CheckDependencies`
!macro _Service::CheckDependencies _DEPENDENCIES _RESULT
	Push $0
	Push $1
	Push $2
	Push $R8
	
	StrCpy ${_RESULT} "true"
	StrCpy $0 "${_DEPENDENCIES}"
	
	; Check each dependency separated by /
	${Do}
		${StrLoc} $1 "$0" "/" ">"
		${If} $1 == ""
			; Last or only dependency
			StrCpy $2 $0
			StrCpy $0 ""
		${Else}
			; Get next dependency
			StrCpy $2 $0 $1
			IntOp $1 $1 + 1
			StrCpy $0 $0 "" $1
		${EndIf}
		
		${If} $2 != ""
			${Service::Query} "$2" "" $R8 $1 $R8 $1
			${If} $R8 != "true"
				${DebugMsg} "Dependency not found: $2"
				StrCpy ${_RESULT} "false"
				${ExitDo}
			${EndIf}
		${EndIf}
	${LoopUntil} $0 == ""
	
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

!define SERVICES_ENABLED
${SegmentFile}
${SegmentPre}
	!ifdef SERVICES_ENABLED
		${DebugMsg} "Starting service backup and preparation..."
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Service$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${DebugMsg} "Processing service: $0"
			
			; Enhanced service existence check
			${Service::Query} "$0" /DISABLEFSR $R8 $R9 $1 $2
			${If} $R8 == "true"
				${DebugMsg} "Found existing service: $0 (State: $R9)"
				
				; Backup comprehensive service information
				${Service::Backup} "$0" "ServiceBackup" "$0"
				
				; Check IfExists setting
				${ReadLauncherConfig} $3 Service$R0 IfExists
				${StrCase} $3 $3 "L"
				
				${Switch} $3
					${Case} "replace"
						${DebugMsg} "Preparing to replace service: $0"
						${WriteRuntimeData} ServiceState "$0_Action" "replace"
						
						; Stop and delete existing service
						${Service::Delete} "$0" /DISABLEFSR $1 $2
						${If} $1 != 0
							${DebugMsg} "Warning: Failed to remove existing service $0: $2"
							${WriteRuntimeData} ServiceState "$0_Failed" "delete_failed"
						${EndIf}
						${Break}
						
					${Case} "backup"
						${DebugMsg} "Backing up service without replacement: $0"
						${WriteRuntimeData} ServiceState "$0_Action" "backup"
						${Service::Stop} "$0" 30 /DISABLEFSR $1 $2
						${Break}
						
					${CaseElse} ; skip
						${DebugMsg} "Skipping existing service: $0"
						${WriteRuntimeData} ServiceState "$0_Action" "skip"
						${Break}
				${EndSwitch}
			${Else}
				${DebugMsg} "Service $0 does not exist - will be created"
				${WriteRuntimeData} ServiceState "$0_Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		${DebugMsg} "Portable service cleanup completed."
	!endif
!macroend

;= Install/Start Portable Services
${SegmentPrePrimary}
	!ifdef SERVICES_ENABLED
		${DebugMsg} "Starting portable service installation..."
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Service$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we should process this service
			${ReadRuntimeData} $1 ServiceState "$0_Action"
			${If} $1 == "skip"
				${DebugMsg} "Skipping service (already exists): $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Get service configuration
			${ReadLauncherConfig} $2 Service$R0 Path
			${ParseLocations} $2
			
			${If} ${IsFile} "$2"
				${ReadLauncherConfig} $3 Service$R0 Type
				${ReadLauncherConfig} $4 Service$R0 Start
				${ReadLauncherConfig} $5 Service$R0 Depend
				${ReadLauncherConfig} $6 Service$R0 Description
				${ReadLauncherConfig} $7 Service$R0 Account
				${ReadLauncherConfig} $8 Service$R0 Password
				${ReadLauncherConfig} $9 Service$R0 Timeout
				${ReadLauncherConfig} $R8 Service$R0 Critical
				
				; Set defaults
				${If} $9 == ""
					StrCpy $9 "30"
				${EndIf}
				
				; Check dependencies if specified
				${If} $5 != ""
					${Service::CheckDependencies} "$5" $R9
					${If} $R9 == "false"
						${DebugMsg} "Warning: Dependencies not met for service $0"
						${If} $R8 == "true"
							MessageBox MB_OK|MB_ICONEXCLAMATION "Warning: Service '$0' has unmet dependencies and may not function properly."
						${EndIf}
					${EndIf}
				${EndIf}
				
				; Create the service
				${DebugMsg} "Creating portable service: $0"
				${Service::Create} "$0" "$2" "$3" "$4" "$5" "$7" "$8" "$6" /DISABLEFSR $R7 $R6
				
				${If} $R7 == 0
					${DebugMsg} "Successfully created service: $0"
					${WriteRuntimeData} ServiceState "$0_Created" "true"
					
					; Start the service if it should be started
					${If} $4 == "auto"
					${OrIf} $4 == "delayed-auto"
						${Service::Start} "$0" $9 /DISABLEFSR $R7 $R6
						${If} $R7 == 0
							${DebugMsg} "Successfully started service: $0"
							${WriteRuntimeData} ServiceState "$0_Started" "true"
						${Else}
							${DebugMsg} "Failed to start service $0: $R6"
							${WriteRuntimeData} ServiceState "$0_StartFailed" "true"
							${If} $R8 == "true"
								MessageBox MB_OK|MB_ICONEXCLAMATION "Warning: Critical service '$0' failed to start: $R6"
							${EndIf}
						${EndIf}
					${EndIf}
				${Else}
					${DebugMsg} "Failed to create service $0: $R6"
					${WriteRuntimeData} ServiceState "$0_CreateFailed" "true"
					${If} $R8 == "true"
						MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Critical service '$0' failed to install: $R6"
					${EndIf}
				${EndIf}
			${Else}
				${DebugMsg} "Service executable not found: $2"
				${WriteRuntimeData} ServiceState "$0_FileNotFound" "true"
				MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Service executable not found for '$0'$\nPath: $2$\n$\nContinuing without this service."
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		${DebugMsg} "Portable service installation completed."
	!endif
!macroend

;= Stop/Remove Portable Services
${SegmentPostPrimary}
	!ifdef SERVICES_ENABLED
		${DebugMsg} "Starting portable service cleanup..."
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Service$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we created this service
			${ReadRuntimeData} $1 ServiceState "$0_Created"
			${If} ${Errors}
				${DebugMsg} "Service was not created by us, skipping: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${DebugMsg} "Stopping and removing portable service: $0"
			
			; Get timeout setting
			${ReadLauncherConfig} $2 Service$R0 Timeout
			${If} $2 == ""
				StrCpy $2 "30"
			${EndIf}
			
			; Stop and delete the service
			${Service::Delete} "$0" /DISABLEFSR $R7 $R6
			${If} $R7 == 0
				${DebugMsg} "Successfully removed service: $0"
			${Else}
				${DebugMsg} "Warning: Failed to remove service $0: $R6"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		${DebugMsg} "Service backup and preparation completed."
	!endif
!macroend

;= Restore Original Services
${SegmentUnload}
	!ifdef SERVICES_ENABLED
		${DebugMsg} "Starting service restoration..."
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Service$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check what action we took originally
			${ReadRuntimeData} $1 ServiceState "$0_Action"
			${If} ${Errors}
				${DebugMsg} "No action recorded for service: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${Switch} $1
				${Case} "replace"
					${DebugMsg} "Restoring replaced service: $0"
					${Service::Restore} "$0" "ServiceBackup" "$0" /DISABLEFSR $R7 $R6
					${If} $R7 == 0
						${DebugMsg} "Successfully restored service: $0"
						
						; Check if it was originally running and start it
						${ReadRuntimeData} $2 ServiceBackup "$0_Start"
						${If} $2 == "2" ; AUTO_START
						${OrIf} $2 == "3" ; DEMAND_START with original running state
							${ReadLauncherConfig} $3 Service$R0 Timeout
							${If} $3 == ""
								StrCpy $3 "30"
							${EndIf}
							${Service::Start} "$0" $3 /DISABLEFSR $R8 $R9
							${If} $R8 == 0
								${DebugMsg} "Successfully restarted restored service: $0"
							${Else}
								${DebugMsg} "Warning: Failed to restart restored service $0: $R9"
							${EndIf}
						${EndIf}
					${Else}
						${DebugMsg} "Failed to restore service $0: $R6"
					${EndIf}
					${Break}
					
				${Case} "backup"
					${DebugMsg} "Restarting backed up service: $0"
					${ReadLauncherConfig} $2 Service$R0 Timeout
					${If} $2 == ""
						StrCpy $2 "30"
					${EndIf}
					${Service::Start} "$0" $2 /DISABLEFSR $R7 $R6
					${If} $R7 == 0
						${DebugMsg} "Successfully restarted service: $0"
					${Else}
						${DebugMsg} "Warning: Failed to restart service $0: $R6"
					${EndIf}
					${Break}
					
				${Case} "skip"
				${Case} "create"
					${DebugMsg} "No restoration needed for service: $0 (action: $1)"
					${Break}
					
				${Default}
					${DebugMsg} "Unknown action for service $0: $1"
					${Break}
			${EndSwitch}
			
			IntOp $R0 $R0 + 1
		${Loop}
		${DebugMsg} "Service restoration completed."
	!endif
!macroend
!endif
