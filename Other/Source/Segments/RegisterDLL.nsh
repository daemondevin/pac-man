/*${SegmentFile}

${SegmentPrePrimary}
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 RegisterDLL $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $0
		${DebugMsg} "Registering DLL $0."
		;ExecWait '$SYSDIR\regsvr32.exe /s "$0"' $R9
		;${If} $R9 <> 0 ; 0 = success
		ClearErrors
		RegDLL $0
		${If} ${Errors}
			${WriteRuntimeData} FailedRegisterDLL $0 true
			${DebugMsg} "Failed to register DLL $0."
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend

${SegmentPostPrimary}
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 RegisterDLL $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ReadRuntimeData} $R9 FailedRegisterDLL $0
		${If} ${Errors} ; didn't fail
			${ParseLocations} $0
			${DebugMsg} "Unregistering DLL $0."
			;ExecWait '$SYSDIR\regsvr32.exe /s /u "$0"'
			UnRegDLL $0
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend*/

/**
 * Below added by demon.devin with original help from FukenGruven
 *
 * TODO: 
 *  Use below code and incoorperate it with above code to eliminate the
 *  need for using the custom.nsh for this functionality.
 */

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
${SegmentFile}
${SegmentPre}
	# Uninstall Local DLL
	!ifmacrodef PreDLL
		!insertmacro PreDLL
	!endif
!macroend
${SegmentPrePrimary}
	# Install Portable DLL
	!ifmacrodef PrePrimaryDLL
		!insertmacro PrePrimaryDLL
	!endif
!macroend
${SegmentPostPrimary}
	# Uninstall Portable DLL
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
	!ifmacrodef UnloadDLL
		!insertmacro UnloadDLL
		!ifndef SegPostLib
			!define SegUnloadLib
			System::Call `${UNLOADFREELIB}`
		!endif
	!endif
!macroend
