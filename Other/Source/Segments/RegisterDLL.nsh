;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; RegisterDLL.nsh
; 	This file is used to register DLL files that are configured in the Launcher.ini file.
; 

!ifdef REGISTERDLL
!define SHCHANGENOTIFY	`Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)`
!define UNLOADFREELIB	`Ole32::CoFreeUnusedLibraries()`
!define W				CabinetWClass
!ifndef REGSVR
	!define REGSVR		`$SYSDIR\regsvr32.exe`
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
; The following was written by FukenGruven
; 
!define DLL::REG `!insertmacro DLL::REG`
!macro DLL::REG _DLL _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp ${_FSR} /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s "${_DLL}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${REGSVR}" /s "${_DLL}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define DLL::UNREG `!insertmacro DLL::UNREG`
!macro DLL::UNREG _DLL _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp ${_FSR} /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s /u "${_DLL}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${REGSVR}" /s /u "${_DLL}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend

;
; The following was written by daemon.devin
; 
!define DLL::Backup "!insertmacro _DLL::Backup"
!macro _DLL::Backup _GUID _FSR _SECTION _KEY _ERR1 _ERR2
	ClearErrors
	ReadRegStr $0 HKLM "SOFTWARE\Classes\CLSID\${_GUID}\InprocServer32" ""
	${IfNot} ${Errors}
		StrCmpS $Bit 64 0 +6
		StrCmp ${_FSR} /DISABLEFSR 0 +5
		${WriteRuntimeData} ${_SECTION} ${_KEY} `$0`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s /u "$0"`
		Goto +2
		ExecDos::Exec /TOSTACK `"${REGSVR}" /s /u "$0"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	${EndIf}
!macroend
!define DLL::Restore "!insertmacro _DLL::Restore"
!macro _DLL::Restore _FSR _SECTION _KEY _ERR1 _ERR2
	ClearErrors
	${ReadRuntimeData} $0 ${_SECTION} ${_KEY}
	${IfNot} ${Errors}
		StrCmpS $Bit 64 0 +4
		StrCmp ${_FSR} /DISABLEFSR 0 +3
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s "$0"`
		Goto +2
		ExecDos::Exec /TOSTACK `"${REGSVR}" /s "$0"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	${EndIf}
!macroend
!define DLL::Register `!insertmacro _DLL::Register`
!macro _DLL::Register _DLL _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp ${_FSR} /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s "${_DLL}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${REGSVR}" /s "${_DLL}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define DLL::UnRegister `!insertmacro _DLL::UnRegister`
!macro _DLL::UnRegister _DLL _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp ${_FSR} /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s /u "${_DLL}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${REGSVR}" /s /u "${_DLL}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define DLL::GetGUID "!insertmacro _DLL::GetGUID"
!macro _DLL::GetGUID _RETURN _ProgID
	System::Call `ole32::CLSIDFromProgID(w,&g16)i("${_ProgID}",.r0).r2`
	StrCmp $2 "-2147221005" 0 +4
	SetErrors
	StrCpy ${_RETURN} ""
	Goto +2
	StrCpy ${_RETURN} $0
!macroend

${SegmentFile}
${SegmentPrePrimary}
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $1 RegisterDLL$R0 Type
		${ReadLauncherConfig} $0 RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $0
		${GetPathToLib} $0 $9 $8
		ClearErrors
		${If} $1 == REGDLL
			${DebugMsg} "Registering DLL $0."
			${RegDLL} $0
		${ElseIf} $1 == "REGTLB for user"
			${DebugMsg} "Registering TLB for user $0."
			; ${registry::RestoreKey} $0.reg $R9 ; Experimental, to register DLL for user
			; ${IfThen} $R9 = -1 ${|} ${DebugMsg} "Register file $0.reg not found" ${|}
			${RegTlbForUser} $0
			StrCpy $9 $8
		${ElseIf} $1 == REGTLB
			${DebugMsg} "Registering TLB $0."
			${RegTlb} $0
		${ElseIf} $1 == REGDLLTLB 
			${DebugMsg} "Registering DLL & TLB $0."
			${RegTlb} $0
			${RegDLL} $0
		${ElseIf} $1 == REGEXE
			;${DebugMsg} "Registering Executable $0."
			ExecWait '"$0" /regserver'
		${Else}
			${InvalidValueError} [RegisterDLL$R0]:Type $0
		${EndIf}
		${If} ${Errors}
			${WriteRuntimeData} FailedRegisterDLL $0 true
			${DebugMsg} "Failed to register DLL $0."
		${EndIf}
		${If} $9 != ''
			${WriteRuntimeData} RegisterDLLBackup $0 true
			${DebugMsg} "DLL already installed, backing-up local path $9."
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentPostPrimary}
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $1 RegisterDLL$R0 Type
		${ReadLauncherConfig} $0 RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadRuntimeData} $R9 FailedRegisterDLL $0
		${If} ${Errors} ; didn't fail
			${ParseLocations} $0
			${ReadRuntimeData} $R9 RegisterDLLBackup $0
			${If} ${Errors} ; was not installed before
				${If} $1 == REGDLL
					${DebugMsg} "Unregistering DLL $0."
					${UnRegDLL} $0
				${ElseIf} $1 == "REGTLB for user"
					${DebugMsg} "Unregistering TLB for user $0."
					${UnRegTlbForUser} $0
					; ${registry::RestoreKey} $0Un.reg $R9 ; Should really find a better way to do this...
					; ${IfThen} $R9 = -1 ${|} ${DebugMsg} "Unregister file $0Un.reg not found" ${|}
				${ElseIf} $1 == REGTLB 
					${DebugMsg} "Unregistering TLB $0."
					${UnRegTlb} $0
				${ElseIf} $1 == REGDLLTLB 
					${DebugMsg} "Unregistering DLL & TLB $0."
					${UnRegDLL} $0
					${UnRegTlb} $0
				${ElseIf} $1 == REGEXE
					${DebugMsg} "Unregistering Executable $0."
					ExecWait '"$0" /unregserver'
				${Else}
					${InvalidValueError} [RegisterDLL$R0]:Type $0
				${EndIf}
			${Else} ; re-install local
				${If} $1 == REGDLL
					${DebugMsg} "Re-registering local DLL $9."
					${RegDLL} $9
				${ElseIf} $1 == "REGTLB for user"
					${DebugMsg} "Re-registering local TLB for user $9."
					; ${registry::RestoreKey} $0Un.reg $R9 ; Should really find a better way to do this...
					; ${IfThen} $R9 = -1 ${|} ${DebugMsg} "Unregister file $0Un.reg not found" ${|}
					${RegTlbForUser} $9
				${ElseIf} $1 == REGTLB
					${DebugMsg} "Re-registering local TLB $9."
					${RegTlb} $8
				${ElseIf} $1 == REGDLLTLB 
					${DebugMsg} "Registering DLL & TLB $9."
					${RegTlb} $9
					${RegDLL} $9
				${ElseIf} $1 == REGEXE
					${DebugMsg} "Re-registering local Executable $9."
					ExecWait '"$9" /regserver'
				${Else}
					${InvalidValueError} [RegisterDLL$R0]:Type $0
				${EndIf}
			${EndIf}
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
!endif
