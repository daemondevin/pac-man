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
; USAGE
;	Add sections [RegisterDLL1], [RegisterDLL2] etc. to Launcher.ini. 
;
;	RegisterDLL Keys:
;	Type		- Choose from one of the following:
;	    		  -	REGDLL      - register a DLL
;	    		  -	REGTLB      - register a type library
;                 - REGUSERTLB  - register a type library for the current user
;	    		  -	REGDLLTLB   - register a DLL that contains a type library
;	    		  -	REGEXE      - register an EXE COM server using /regserver
;	File		- Path to the file to be registered (supports %PAL:* variables)
;
; EXAMPLE
;	[RegisterDLL1]
;	Type=REGDLL
;	File=%PAL:AppDir%\MyProg\MyProgDLL.dll
;
;	[RegisterDLL2]
;	Type=REGEXE
;	File=%PAL:AppDir%\MyProg\MyProg.exe
;

!ifdef SEGMENTS_REGDLL

;= VARIABLES
Var DLLType
Var DLLFile

;= DEFINES
!ifndef W
	!define W CabinetWClass
!endif
!ifndef SHCHANGENOTIFY
	!define SHCHANGENOTIFY `Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)`
!endif
!ifndef UNLOADFREELIB
	!define UNLOADFREELIB `Ole32::CoFreeUnusedLibraries()`
!endif
!ifndef REGSVR
	!define REGSVR `$SYSDIR\regsvr32.exe`
!endif
!ifndef SHCNE_ASSOCCHANGED
	!define SHCNE_ASSOCCHANGED 0x08000000
!endif
!ifndef SHCNF_IDLIST
	!define SHCNF_IDLIST 0x0000
!endif

;= INCLUDES
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

;= MACROS
; The following was written by FukenGruven
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
; The following was written by daemon.devin
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

    ${DebugMsg} "RegDLL PrePrimary Segment begin..."
    
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $DLLType RegisterDLL$R0 Type
		${ReadLauncherConfig} $DLLFile RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $DLLFile
		${GetPathToLib} $DLLFile $9 $8
		ClearErrors
		${If} $DLLType == REGDLL
			${DebugMsg} "Registering DLL $DLLFile."
			${RegDLL} $DLLFile
		${ElseIf} $DLLType == "REGUSERTLB"
			${DebugMsg} "Registering TLB for user $DLLFile."
			; ${registry::RestoreKey} $DLLFile.reg $R9 ; Experimental, to register DLL for user
			; ${IfThen} $R9 = -1 ${|} ${DebugMsg} "Register file $DLLFile.reg not found" ${|}
			${RegTlbForUser} $DLLFile
			StrCpy $9 $8
		${ElseIf} $DLLType == REGTLB
			${DebugMsg} "Registering TLB $DLLFile."
			${RegTlb} $DLLFile
		${ElseIf} $DLLType == REGDLLTLB 
			${DebugMsg} "Registering DLL & TLB $DLLFile."
			${RegTlb} $DLLFile
			${RegDLL} $DLLFile
		${ElseIf} $DLLType == REGEXE
			;${DebugMsg} "Registering Executable $DLLFile."
			ExecWait '"$DLLFile" /regserver'
		${Else}
			${InvalidValueError} [RegisterDLL$R0]:Type $DLLFile
		${EndIf}
		${If} ${Errors}
			${WriteRuntimeData} FailedRegisterDLL $DLLFile true
			${DebugMsg} "Failed to register DLL $DLLFile."
		${EndIf}
		${If} $9 != ''
			${WriteRuntimeData} RegisterDLLBackup $DLLFile true
			${DebugMsg} "DLL already installed, backing-up local path $9."
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
    
    ${DebugMsg} "RegDLL PrePrimary segment complete."
    
!macroend
${SegmentPostPrimary}

    ${DebugMsg} "RegDLL PostPrimary Segment begin..."

	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $DLLType RegisterDLL$R0 Type
		${ReadLauncherConfig} $DLLFile RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadRuntimeData} $R9 FailedRegisterDLL $DLLFile
		${If} ${Errors} ; didn't fail
			${ParseLocations} $DLLFile
			${ReadRuntimeData} $R9 RegisterDLLBackup $DLLFile
			${If} ${Errors} ; was not installed before
				${If} $DLLType == REGDLL
					${DebugMsg} "Unregistering DLL $DLLFile."
					${UnRegDLL} $DLLFile
				${ElseIf} $DLLType == "REGTLB for user"
					${DebugMsg} "Unregistering TLB for user $DLLFile."
					${UnRegTlbForUser} $DLLFile
					; ${registry::RestoreKey} $DLLFileUn.reg $R9 ; Should really find a better way to do this...
					; ${IfThen} $R9 = -1 ${|} ${DebugMsg} "Unregister file $DLLFileUn.reg not found" ${|}
				${ElseIf} $DLLType == REGTLB 
					${DebugMsg} "Unregistering TLB $DLLFile."
					${UnRegTlb} $DLLFile
				${ElseIf} $DLLType == REGDLLTLB 
					${DebugMsg} "Unregistering DLL & TLB $DLLFile."
					${UnRegDLL} $DLLFile
					${UnRegTlb} $DLLFile
				${ElseIf} $DLLType == REGEXE
					${DebugMsg} "Unregistering Executable $DLLFile."
					ExecWait '"$DLLFile" /unregserver'
				${Else}
					${InvalidValueError} [RegisterDLL$R0]:Type $DLLFile
				${EndIf}
			${Else} ; re-install local
				${If} $DLLType == REGDLL
					${DebugMsg} "Re-registering local DLL $9."
					${RegDLL} $9
				${ElseIf} $DLLType == "REGTLB for user"
					${DebugMsg} "Re-registering local TLB for user $9."
					; ${registry::RestoreKey} $DLLFileUn.reg $R9 ; Should really find a better way to do this...
					; ${IfThen} $R9 = -1 ${|} ${DebugMsg} "Unregister file $DLLFileUn.reg not found" ${|}
					${RegTlbForUser} $9
				${ElseIf} $DLLType == REGTLB
					${DebugMsg} "Re-registering local TLB $9."
					${RegTlb} $8
				${ElseIf} $DLLType == REGDLLTLB 
					${DebugMsg} "Registering DLL & TLB $9."
					${RegTlb} $9
					${RegDLL} $9
				${ElseIf} $DLLType == REGEXE
					${DebugMsg} "Re-registering local Executable $9."
					ExecWait '"$9" /regserver'
				${Else}
					${InvalidValueError} [RegisterDLL$R0]:Type $DLLFile
				${EndIf}
			${EndIf}
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
    
    ${DebugMsg} "RegDLL PostPrimary segment complete."
    
!macroend
!endif
