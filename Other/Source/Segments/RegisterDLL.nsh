;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; RegisterDLL.nsh - Enhanced Edition
; 	This file handles DLL registration with error handling,
;   conflict resolution, and support for various portable scenarios.
; 
;=# NEW FEATURES (8/26/2025):
; - Rewrote the Reg/Unreg Backup/Restore macros with better error handling
; - Dependency checking before registration attempts
; - Enhanced GUID extraction with better error handling
; - Comprehensive registry backup beyond just the main InprocServer32 entry
; - Architecture-aware registration with automatic fallbacks
; - Timeout protection for executable registration
; - Better conflict resolution when DLLs are already registered

!ifdef REGISTERDLL
!define SHCHANGENOTIFY	`Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)`
!define UNLOADFREELIB	`Ole32::CoFreeUnusedLibraries()`
!define W				CabinetWClass
!ifndef REGSVR
	!define REGSVR		`$SYSDIR\regsvr32.exe`
!endif
!ifndef REGSVR_ALT
	!define REGSVR_ALT	`$WINDIR\SysWOW64\regsvr32.exe`
!endif
!ifndef SHCNE_ASSOCCHANGED
	!define SHCNE_ASSOCCHANGED 0x08000000
!endif
!ifndef SHCNF_IDLIST
	!define SHCNF_IDLIST 0x0000
!endif
!ifndef ___X64__NSH___
	!include x64.nsh
!endif
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
!ifndef ISFILE_NSH_INCLUDED
	!include IsFile.nsh
!endif
!ifndef TYPELIB_NSH_INCLUDED
	!include TypeLib.nsh
!endif

;
; Macros for handling reg/unreg and backup/restore with error handling
; 
!define DLL::Register `!insertmacro _DLL::Register`
!macro _DLL::Register _DLL _FSR _ERR1 _ERR2
	Push $R8
	Push $R9
	
	; Validate DLL exists and is accessible
	${If} ${FileExists} "${_DLL}"
		; Check if DLL is already loaded by another process
		System::Call "kernel32::GetModuleHandle(t '${_DLL}') i .R8"
		${If} $R8 != 0
			${DebugMsg} "Warning: DLL ${_DLL} is currently loaded by another process"
		${EndIf}
		
		; Determine appropriate regsvr32 based on architecture
		StrCmpS $Bit 64 0 +8
		${If} ${_FSR} == "/DISABLEFSR"
			ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s "${_DLL}"`
		${Else}
			; Try 64-bit first, then 32-bit if needed
			ExecDos::Exec /TOSTACK `"${REGSVR}" /s "${_DLL}"`
			Pop $R8
			${If} $R8 != 0
				ExecDos::Exec /TOSTACK `"${REGSVR_ALT}" /s "${_DLL}"`
				Pop $R8
			${EndIf}
			Push $R8
		${EndIf}
		Pop ${_ERR1}
		Pop ${_ERR2}
	${Else}
		StrCpy ${_ERR1} "2" ; File not found
		StrCpy ${_ERR2} "DLL file does not exist: ${_DLL}"
		${DebugMsg} "Error: ${_ERR2}"
	${EndIf}
	
	Pop $R9
	Pop $R8
!macroend
!define DLL::Unregister `!insertmacro _DLL::Unregister`
!macro _DLL::Unregister _DLL _FSR _ERR1 _ERR2
	Push $R8
	Push $R9
	
	${If} ${FileExists} "${_DLL}"
		StrCmpS $Bit 64 0 +8
		${If} ${_FSR} == "/DISABLEFSR"
			ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s /u "${_DLL}"`
		${Else}
			ExecDos::Exec /TOSTACK `"${REGSVR}" /s /u "${_DLL}"`
			Pop $R8
			${If} $R8 != 0
				ExecDos::Exec /TOSTACK `"${REGSVR_ALT}" /s /u "${_DLL}"`
				Pop $R8
			${EndIf}
			Push $R8
		${EndIf}
		Pop ${_ERR1}
		Pop ${_ERR2}
	${Else}
		StrCpy ${_ERR1} "0" ; Success - can't unregister what doesn't exist
		StrCpy ${_ERR2} "DLL file not found for unregistration: ${_DLL}"
		${DebugMsg} "Warning: ${_ERR2}"
	${EndIf}
	
	Pop $R9
	Pop $R8
!macroend
!define DLL::Backup "!insertmacro _DLL::Backup"
!macro _DLL::Backup _DLL _GUID _FSR _SECTION _KEY _ERR1 _ERR2
	Push $R8
	Push $R9
	Push $0
	Push $1
	Push $2
	
	ClearErrors
	
	; Backup multiple registry locations that might be affected
	StrCpy $R8 0 ; Success flag
	
	; Main CLSID registration
	ReadRegStr $0 HKLM "SOFTWARE\Classes\CLSID\${_GUID}\InprocServer32" ""
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_InprocServer32" `$0`
		${DebugMsg} "Backed up InprocServer32: $0"
		StrCpy $R8 1
	${EndIf}
	
	; Backup threading model
	ReadRegStr $1 HKLM "SOFTWARE\Classes\CLSID\${_GUID}\InprocServer32" "ThreadingModel"
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_ThreadingModel" `$1`
		${DebugMsg} "Backed up ThreadingModel: $1"
	${EndIf}
	
	; Backup ProgID if exists
	ReadRegStr $2 HKLM "SOFTWARE\Classes\CLSID\${_GUID}\ProgID" ""
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_ProgID" `$2`
		${DebugMsg} "Backed up ProgID: $2"
	${EndIf}
	
	; If we found registrations to backup, unregister the existing DLL
	${If} $R8 == 1
		${If} ${FileExists} "$0"
			${DLL::Unregister} "$0" ${_FSR} ${_ERR1} ${_ERR2}
			${If} ${_ERR1} == 0
				${DebugMsg} "Successfully unregistered existing DLL: $0"
			${Else}
				${DebugMsg} "Failed to unregister existing DLL: $0 (Error: ${_ERR1})"
			${EndIf}
		${EndIf}
	${EndIf}
	
	Pop $2
	Pop $1
	Pop $0
	Pop $R9
	Pop $R8
!macroend
!define DLL::Restore "!insertmacro _DLL::Restore"
!macro _DLL::Restore _GUID _FSR _SECTION _KEY _ERR1 _ERR2
	Push $0
	Push $1
	Push $2
	Push $R8
	
	ClearErrors
	StrCpy ${_ERR1} "0"
	StrCpy ${_ERR2} "Success"
	StrCpy $R8 0 ; Restoration success flag
	
	; Restore InprocServer32 registry entry
	${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_InprocServer32"
	${IfNot} ${Errors}
		WriteRegStr HKLM "SOFTWARE\Classes\CLSID\${_GUID}\InprocServer32" "" "$0"
		${If} ${Errors}
			StrCpy ${_ERR1} "1"
			StrCpy ${_ERR2} "Failed to restore InprocServer32 registry entry"
		${Else}
			${DebugMsg} "Restored InprocServer32: $0"
			StrCpy $R8 1
		${EndIf}
	${EndIf}
	
	; Restore ThreadingModel if it was backed up
	${ReadRuntimeData} $1 ${_SECTION} "${_KEY}_ThreadingModel"
	${IfNot} ${Errors}
		WriteRegStr HKLM "SOFTWARE\Classes\CLSID\${_GUID}\InprocServer32" "ThreadingModel" "$1"
		${If} ${Errors}
			${DebugMsg} "Warning: Failed to restore ThreadingModel: $1"
		${Else}
			${DebugMsg} "Restored ThreadingModel: $1"
		${EndIf}
	${EndIf}
	
	; Restore ProgID if it was backed up
	${ReadRuntimeData} $2 ${_SECTION} "${_KEY}_ProgID"
	${IfNot} ${Errors}
		WriteRegStr HKLM "SOFTWARE\Classes\CLSID\${_GUID}\ProgID" "" "$2"
		${If} ${Errors}
			${DebugMsg} "Warning: Failed to restore ProgID: $2"
		${Else}
			${DebugMsg} "Restored ProgID: $2"
		${EndIf}
	${EndIf}
	
	; If we restored registry entries but the original DLL file doesn't exist, warn about it
	${If} $R8 == 1
		${If} ${FileExists} "$0"
			${DebugMsg} "Successfully restored registry entries for DLL: $0"
		${Else}
			${DebugMsg} "Warning: Restored registry entries but original DLL no longer exists: $0"
			StrCpy ${_ERR1} "2"
			StrCpy ${_ERR2} "Registry restored but original DLL file missing"
		${EndIf}
	${EndIf}
	
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend
!define DLL::GetGUID "!insertmacro _DLL::GetGUID"
!macro _DLL::GetGUID _RETURN _ProgID _SUCCESS
	Push $0
	Push $1
	Push $2
	
	System::Call `ole32::CLSIDFromProgID(w,&g16)i("${_ProgID}",.r0).r2`
	${Switch} $2
		${Case} "0" ; S_OK
			StrCpy ${_RETURN} $0
			StrCpy ${_SUCCESS} "true"
			${Break}
		${Case} "-2147221005" ; REGDB_E_CLASSNOTREG
			StrCpy ${_RETURN} ""
			StrCpy ${_SUCCESS} "false"
			${DebugMsg} "ProgID not found in registry: ${_ProgID}"
			${Break}
		${Default}
			StrCpy ${_RETURN} ""
			StrCpy ${_SUCCESS} "false"
			${DebugMsg} "Error getting GUID for ProgID ${_ProgID}: $2"
			${Break}
	${EndSwitch}
	
	Pop $2
	Pop $1
	Pop $0
!macroend
!define DLL::CheckDependencies "!insertmacro _DLL::CheckDependencies"
!macro _DLL::CheckDependencies _DLL _RESULT
	Push $0
	Push $1
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "true"
	
	; Try to load the DLL temporarily to check dependencies
	System::Call "kernel32::LoadLibrary(t '${_DLL}') i .R8"
	${If} $R8 == 0
		System::Call "kernel32::GetLastError() i .R9"
		${Switch} $R9
			${Case} "126" ; ERROR_MOD_NOT_FOUND
				${DebugMsg} "Missing dependencies for DLL: ${_DLL}"
				StrCpy ${_RESULT} "false"
				${Break}
			${Case} "193" ; ERROR_BAD_EXE_FORMAT
				${DebugMsg} "Architecture mismatch for DLL: ${_DLL}"
				StrCpy ${_RESULT} "false"
				${Break}
			${Default}
				${DebugMsg} "Cannot load DLL ${_DLL}, error: $R9"
				StrCpy ${_RESULT} "false"
				${Break}
		${EndSwitch}
	${Else}
		; Successfully loaded, free it
		System::Call "kernel32::FreeLibrary(i R8)"
	${EndIf}
	
	Pop $R9
	Pop $R8
	Pop $1
	Pop $0
!macroend

${SegmentFile}
${SegmentPrePrimary}
	${DebugMsg} "Starting DLL registration process..."
	
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $1 RegisterDLL$R0 Type
		${ReadLauncherConfig} $0 RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		
		${DebugMsg} "Processing RegisterDLL$R0: Type=$1, File=$0"
		${ParseLocations} $0
		
		; Path resolution and validation
		${If} ${FileExists} "$0"
			${GetPathToLib} $0 $9 $8
			
			; Check dependencies before registration
			${DLL::CheckDependencies} "$0" $R8
			${If} $R8 == "false"
				${WriteRuntimeData} FailedRegisterDLL $0 "dependency_error"
				${DebugMsg} "Skipping registration due to dependency issues: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Process based on type with error handling
			${Switch} $1
				${Case} "REGDLL"
					${DebugMsg} "Registering DLL: $0"
					${If} $9 != ""
						${DebugMsg} "Existing DLL found at: $9, creating backup..."
						${DLL::GetGUID} $R8 "DLL.From.File.$0" $R9
						${If} $R9 == "true"
							${DLL::Backup} "$0" "$R8" "" "RegisterDLLBackup" "$0" $2 $3
							${WriteRuntimeData} RegisterDLLBackup "$0_HasBackup" "true"
						${EndIf}
					${EndIf}
					${DLL::Register} "$0" "" $2 $3
					${Break}
					
				${Case} "REGTLB for user"
					${DebugMsg} "Registering TLB for user: $0"
					${RegTlbForUser} $0
					${If} $9 != ""
						StrCpy $8 $9
						${WriteRuntimeData} RegisterDLLBackup "$0_LocalPath" "$9"
					${EndIf}
					${Break}
					
				${Case} "REGTLB"
					${DebugMsg} "Registering TLB: $0"
					${RegTlb} $0
					${Break}
					
				${Case} "REGDLLTLB"
					${DebugMsg} "Registering DLL & TLB: $0"
					${If} $9 != ""
						${DLL::GetGUID} $R8 "DLL.From.File.$0" $R9
						${If} $R9 == "true"
							${DLL::Backup} "$0" "$R8" "" "RegisterDLLBackup" "$0" $2 $3
							${WriteRuntimeData} RegisterDLLBackup "$0_HasBackup" "true"
						${EndIf}
					${EndIf}
					${RegTlb} $0
					${DLL::Register} "$0" "" $2 $3
					${Break}
					
				${Case} "REGEXE"
					${DebugMsg} "Registering Executable: $0"
					; Enhanced executable registration with timeout
					ExecWait '"$0" /regserver' $2 30000 ; 30 second timeout
					${If} $2 != 0
						${DebugMsg} "Executable registration returned code: $2"
						StrCpy $3 "regserver_failed"
					${EndIf}
					${Break}
					
				${CaseElse}
					${InvalidValueError} [RegisterDLL$R0]:Type $1
					StrCpy $2 "1"
					StrCpy $3 "invalid_type"
					${Break}
			${EndSwitch}
			
			; Enhanced error tracking
			${If} $2 != 0
			${OrIf} ${Errors}
				${WriteRuntimeData} FailedRegisterDLL $0 $3
				${DebugMsg} "Failed to register: $0 (Error: $2 - $3)"
			${Else}
				${WriteRuntimeData} SuccessfulRegisterDLL $0 "true"
				${DebugMsg} "Successfully registered: $0"
			${EndIf}
			
			; Track backup status
			${If} $9 != ""
				${WriteRuntimeData} RegisterDLLBackup $0 "true"
				${WriteRuntimeData} RegisterDLLBackup "$0_LocalPath" "$9"
				${DebugMsg} "DLL backup created for local path: $9"
			${EndIf}
		${Else}
			${DebugMsg} "File not found, skipping: $0"
			${WriteRuntimeData} FailedRegisterDLL $0 "file_not_found"
		${EndIf}
		
		IntOp $R0 $R0 + 1
	${Loop}
	
	; Notify system of association changes
	${SHCHANGENOTIFY}
	${DebugMsg} "DLL registration process completed."
!macroend

${SegmentPostPrimary}
	${DebugMsg} "Starting DLL cleanup process..."
	
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $1 RegisterDLL$R0 Type
		${ReadLauncherConfig} $0 RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		
		${DebugMsg} "Processing cleanup for RegisterDLL$R0: $0"
		${ParseLocations} $0
		
		; Check if registration was successful initially
		${ReadRuntimeData} $R8 SuccessfulRegisterDLL $0
		${If} ${Errors}
			${DebugMsg} "Skipping cleanup - registration was not successful: $0"
			IntOp $R0 $R0 + 1
			${Continue}
		${EndIf}
		
		; Check if we have a backup to restore
		${ReadRuntimeData} $R9 RegisterDLLBackup "$0_HasBackup"
		${IfNot} ${Errors}
			; Get the GUID for proper restoration
			${DLL::GetGUID} $R8 "DLL.From.File.$0" $R7
			${If} $R7 == "true"
				${DebugMsg} "Restoring backed up DLL registration: $0"
				${DLL::Restore} "$R8" "" "RegisterDLLBackup" "$0" $2 $3
				${If} $2 != 0
					${DebugMsg} "Warning during restore: $3"
				${EndIf}
			${Else}
				${DebugMsg} "Cannot restore - unable to get GUID for: $0"
			${EndIf}
		${Else}
			; No backup, just unregister
			${Switch} $1
				${Case} "REGDLL"
					${DebugMsg} "Unregistering DLL: $0"
					${DLL::Unregister} "$0" "" $2 $3
					${Break}
					
				${Case} "REGTLB for user"
					${DebugMsg} "Unregistering TLB for user: $0"
					${UnRegTlbForUser} $0
					; Restore local path if it existed
					${ReadRuntimeData} $9 RegisterDLLBackup "$0_LocalPath"
					${IfNot} ${Errors}
						${RegTlbForUser} $9
						${DebugMsg} "Restored local TLB: $9"
					${EndIf}
					${Break}
					
				${Case} "REGTLB"
					${DebugMsg} "Unregistering TLB: $0"
					${UnRegTlb} $0
					${Break}
					
				${Case} "REGDLLTLB"
					${DebugMsg} "Unregistering DLL & TLB: $0"
					${DLL::Unregister} "$0" "" $2 $3
					${UnRegTlb} $0
					${Break}
					
				${Case} "REGEXE"
					${DebugMsg} "Unregistering Executable: $0"
					ExecWait '"$0" /unregserver' $2 30000
					${If} $2 != 0
						${DebugMsg} "Executable unregistration returned code: $2"
					${EndIf}
					${Break}
					
				${CaseElse}
					${InvalidValueError} [RegisterDLL$R0]:Type $1
					${Break}
			${EndSwitch}
		${EndIf}
		
		IntOp $R0 $R0 + 1
	${Loop}
	
	; Final cleanup - unload any unused libraries
	${UNLOADFREELIB}
	${SHCHANGENOTIFY}
	${DebugMsg} "DLL cleanup process completed."
!macroend
!endif
