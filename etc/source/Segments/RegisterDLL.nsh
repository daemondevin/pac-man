;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   RegisterDLL.nsh
;   This file is used to register DLL files that are configured in the CompilerWrapper.ini file.
; 

!define SHCHANGENOTIFY `Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)`
!define UNLOADFREELIB  `Ole32::CoFreeUnusedLibraries()`
!define W              CabinetWClass
!define REGSVR         `$SYSDIR\regsvr32.exe`
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

;=#
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

;=#
; The following was written by demon.devin
!define DLL::Backup "!insertmacro _DLL::Backup"
!macro _DLL::Backup _GUID _FSR _SECTION _KEY _ERR1 _ERR2
	ClearErrors
	ReadRegStr $0 HKLM `SOFTWARE\Classes\CLSID\${_GUID}\InprocServer32` ""
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
${SegmentPre}
	# Uninstall Local DLL
	!ifmacrodef PreDLL
		!insertmacro PreDLL
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadWrapperConfig} $1 RegisterDLL$R0 ProgID
		${ReadWrapperConfig} $0 RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${DLL::GetGUID} $2 $1
		${DLL::Backup} $2 /DISABLEFSR "RegDLLs" "$R0" $8 $9
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentPrePrimary}
	# Install Portable DLL
	!ifmacrodef PrePrimaryDLL
		!insertmacro PrePrimaryDLL
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadWrapperConfig} $1 RegisterDLL$R0 ProgID
		${ReadWrapperConfig} $0 RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $0
		${DLL::Register} "$0" /DISABLEFSR $8 $9
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentPostPrimary}
	# Uninstall Portable DLL
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadWrapperConfig} $1 RegisterDLL$R0 ProgID
		${ReadWrapperConfig} $0 RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $0
		${DLL::UnRegister} "$0" /DISABLEFSR $8 $9
		IntOp $R0 $R0 + 1
	${Loop}
	!ifmacrodef PostPrimaryDLL
		!insertmacro PostPrimaryDLL
		!ifndef SegUnloadLib
			!define SegPostLib
			System::Call `${UNLOADFREELIB}`
		!endif
	!endif
!macroend
${SegmentUnload}
	# Restore Local DLL
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadWrapperConfig} $1 RegisterDLL$R0 ProgID
		${ReadWrapperConfig} $0 RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${DLL::Restore} /DISABLEFSR "RegDLLs" "$R0" $8 $9
		IntOp $R0 $R0 + 1
	${Loop}	
	!ifmacrodef UnloadDLL
		!insertmacro UnloadDLL
		!ifndef SegPostLib
			!define SegUnloadLib
			System::Call `${UNLOADFREELIB}`
		!endif
	!endif
!macroend
