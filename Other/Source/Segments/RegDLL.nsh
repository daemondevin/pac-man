;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   RegDLL.nsh
;   COM server and type library registration, journaled and user-scoped by
;   default, so a crash can never leave a portable COM registration behind.
;
; USAGE
;   [Activate]
;   RegDLLs=true
;
;   [RegisterDLL1]
;   Type=REGDLL
;   File=%PAL:AppDir%\MyProg\MyProg.dll
;   CLSID={00000000-0000-0000-0000-000000000000}
;
;   Type    REGDLL      register a COM DLL (.dll/.ocx) via DllRegisterServer
;           REGDLLTLB   register a DLL and the type library inside it
;           REGTLB      register a type library (.tlb or a DLL/EXE resource)
;           REGUSERTLB  register a type library for the current user only
;                       ("REGTLB for user" is accepted as an alias)
;           REGEXE      register an out-of-process COM server via /regserver
;   File    Path to the file. Supports environment variables.
;   Scope   user (default for 32-bit DLLs) or machine.
;           user     The DLL is registered for the current user only: the
;                    launcher calls DllRegisterServer in-process with HKCR
;                    and HKLM redirected to HKCU. No admin rights needed.
;           machine  regsvr32 registers it system-wide. Needs admin rights.
;                    64-bit DLLs and REGEXE servers are always machine scope.
;   CLSID   Optional, recommended. The class the server registers. Lets the
;           launcher protect an existing registration of the same class:
;           it is backed up and restored afterwards instead of being lost,
;           and rollback can tell when there is nothing left to undo.
;   ProgID  Optional. Used to look up the CLSID when CLSID is not given, and
;           its key is backed up and restored the same way.
;
;   Type libraries that are already registered (by anything) are left alone
;   and not registered again, so an installed copy is never overwritten.
;
; HOW IT IS UNDONE
;   COM servers   journal COMDLL: DllUnregisterServer (user scope, in-process)
;                 or regsvr32 /u, or /unregserver for EXE servers; then any
;                 backed-up CLSID/ProgID keys are re-imported.
;   Type libs     journal TYPELIB: UnRegisterTypeLib(ForUser).
;

!ifdef SEGMENTS_REGDLL

!ifndef ISFILE_NSH_INCLUDED
	!include IsFile.nsh
!endif

Var DLLType
Var DLLFile
Var DLLScope
Var DLLBits
Var DLLClsid
Var DLLProgID
Var DLLWarned

;= HELPERS
;= ################

; Backs up HKCU or HKLM (by $DLLScope) Software\Classes\$_JT3 when it exists
; and records a REGKEY entry that restores it. $_JT3 = subkey under Classes.
Function RegDLL_BackupClassesKey
	Push $0
	Push $1
	Push $2
	ClearErrors
	${If} $DLLScope == user
		StrCpy $0 HKCU
		EnumRegKey $1 HKCU `Software\Classes\$_JT3` 0
	${Else}
		StrCpy $0 HKLM
		${IfThen} $DLLBits == 64 ${|} SetRegView 64 ${|}
		EnumRegKey $1 HKLM `Software\Classes\$_JT3` 0
		SetRegView lastused
	${EndIf}
	${IfNot} ${Errors}
		; The key exists: export it before our registration can touch it.
		CreateDirectory `${JOURNAL_STORE}\RegDLL`
		System::Call `kernel32::GetTickCount()i.s`
		Pop $2
		StrCpy $2 `${JOURNAL_STORE}\RegDLL\$2.reg`
		${If} $DLLBits == 64
			nsExec::ExecToStack `"$SYSDIR\reg.exe" export "$0\Software\Classes\$_JT3" "$2" /y /reg:64`
		${Else}
			nsExec::ExecToStack `"$SYSDIR\reg.exe" export "$0\Software\Classes\$_JT3" "$2" /y /reg:32`
		${EndIf}
		Pop $1
		Pop $1
		${If} ${FileExists} $2
			${Journal::Record} RegDLL REGKEY $0 `Software\Classes\$_JT3` $2 $DLLBits
			${DebugMsg} "Backed up existing $0\Software\Classes\$_JT3 to $2."
		${EndIf}
	${EndIf}
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Resolves $DLLClsid from $DLLProgID when only a ProgID was configured.
Function RegDLL_ResolveClsid
	Push $0
	Push $1
	${If} $DLLClsid == ""
	${AndIf} $DLLProgID != ""
		System::Call `ole32::CLSIDFromProgID(w "$DLLProgID", g .r0)i .r1`
		${IfThen} $1 = 0 ${|} StrCpy $DLLClsid $0 ${|}
	${EndIf}
	Pop $1
	Pop $0
FunctionEnd

;= MACROS FOR CUSTOM.NSH
;= ################
; Kept for Custom.nsh compatibility. They do not journal anything, so use
; ${Journal::Record} before any change made with them. _FSR is ignored: the
; right regsvr32.exe is picked from the DLL's own bitness.
!define DLL::Register `!insertmacro _DLL::Register`
!macro _DLL::Register _DLL _FSR _ERR1 _ERR2
	${Journal::PEBitness} `${_DLL}` ${_ERR2}
	${Journal::RegSvr32} ${_ERR2} ${_ERR2}
	nsExec::ExecToStack `"${_ERR2}" /s "${_DLL}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define DLL::Unregister `!insertmacro _DLL::Unregister`
!macro _DLL::Unregister _DLL _FSR _ERR1 _ERR2
	${Journal::PEBitness} `${_DLL}` ${_ERR2}
	${Journal::RegSvr32} ${_ERR2} ${_ERR2}
	nsExec::ExecToStack `"${_ERR2}" /s /u "${_DLL}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define DLL::GetGUID `!insertmacro _DLL::GetGUID`
!macro _DLL::GetGUID _RETURN _ProgID _SUCCESS
	Push $0
	Push $1
	System::Call `ole32::CLSIDFromProgID(w "${_ProgID}", g .r0)i .r1`
	${If} $1 = 0
		StrCpy ${_RETURN} $0
		StrCpy ${_SUCCESS} true
	${Else}
		StrCpy ${_RETURN} ""
		StrCpy ${_SUCCESS} false
	${EndIf}
	Pop $1
	Pop $0
!macroend

${SegmentFile}

${SegmentPrePrimary}
	StrCpy $DLLWarned ""
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $DLLType RegisterDLL$R0 Type
		${ReadLauncherConfig} $DLLFile RegisterDLL$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $DLLFile
		${ReadLauncherConfig} $DLLScope RegisterDLL$R0 Scope
		${ReadLauncherConfig} $DLLClsid RegisterDLL$R0 CLSID
		${ReadLauncherConfig} $DLLProgID RegisterDLL$R0 ProgID
		${NewStrCase} $DLLType $DLLType U
		${NewStrCase} $DLLScope $DLLScope L
		${IfThen} $DLLType == "REGTLB FOR USER" ${|} StrCpy $DLLType REGUSERTLB ${|}

		${IfNot} ${FileExists} $DLLFile
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"[RegisterDLL$R0] file not found:$\r$\n$DLLFile$\r$\n$\r$\nContinuing without registering it."
			IntOp $R0 $R0 + 1
			${Continue}
		${EndIf}

		${Journal::PEBitness} $DLLFile $DLLBits
		${IfThen} $DLLBits == 0 ${|} StrCpy $DLLBits 32 ${|}

		;= COM server part (REGDLL, REGDLLTLB, REGEXE)
		${If} $DLLType == REGDLL
		${OrIf} $DLLType == REGDLLTLB
		${OrIf} $DLLType == REGEXE
			; Pick the scope: user first, machine only when it has to be.
			${If} $DLLType == REGEXE
			${OrIf} $DLLBits == 64
				StrCpy $DLLScope machine
			${ElseIf} $DLLScope != machine
				StrCpy $DLLScope user
			${EndIf}

			${If} $DLLScope == machine
			${AndIf} $Admin != true
				${If} $DLLWarned == ""
					StrCpy $DLLWarned true
					MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
						"${PORTABLEAPPNAME} needs administrator rights to register $DLLFile system-wide.$\r$\nIt was not registered and nothing was changed."
				${EndIf}
			${Else}
				; Protect an existing registration of the same class/ProgID.
				Call RegDLL_ResolveClsid
				${If} $DLLClsid != ""
					StrCpy $_JT3 `CLSID\$DLLClsid`
					Call RegDLL_BackupClassesKey
				${EndIf}
				${If} $DLLProgID != ""
					StrCpy $_JT3 $DLLProgID
					Call RegDLL_BackupClassesKey
				${EndIf}

				; Journal before mutation, then register.
				${Journal::Record} RegDLL COMDLL $DLLFile $DLLScope $DLLBits $DLLClsid
				${If} $DLLType == REGEXE
					${DebugMsg} "Registering EXE COM server $DLLFile."
					nsExec::ExecToStack `"$DLLFile" /regserver`
					Pop $0
					Pop $1
				${ElseIf} $DLLScope == user
					${DebugMsg} "Registering $DLLFile for the current user."
					${Journal::ComUserCall} $DLLFile DllRegisterServer $0
				${Else}
					${DebugMsg} "Registering $DLLFile system-wide."
					${Journal::RegSvr32} $DLLBits $1
					nsExec::ExecToStack `"$1" /s "$DLLFile"`
					Pop $0
					Pop $1
				${EndIf}
				${If} $0 <> 0
					; The entry stays: unregistering a half-registered server
					; is the safe way back.
					MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
						"Could not register $DLLFile (error $0).$\r$\n${PORTABLEAPPNAME} may not work correctly."
				${EndIf}
			${EndIf}
		${EndIf}

		;= Type library part (REGTLB, REGUSERTLB, REGDLLTLB)
		${If} $DLLType == REGTLB
		${OrIf} $DLLType == REGUSERTLB
		${OrIf} $DLLType == REGDLLTLB
			${If} $DLLType == REGUSERTLB
				StrCpy $DLLScope user
			${ElseIf} $Admin == true
				StrCpy $DLLScope machine
			${Else}
				; User scope first: without admin rights register for the user.
				StrCpy $DLLScope user
			${EndIf}
			${GetPathToLib} $DLLFile $0 $1
			${If} $0 != ""
			${OrIf} $1 != ""
				${DebugMsg} "Type library in $DLLFile is already registered; leaving it alone."
			${Else}
				${Journal::Record} RegDLL TYPELIB $DLLFile $DLLScope "" ""
				ClearErrors
				${If} $DLLScope == user
					${RegTlbForUser} $DLLFile
				${Else}
					${RegTlb} $DLLFile
				${EndIf}
				${If} ${Errors}
					MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
						"Could not register the type library in $DLLFile.$\r$\n${PORTABLEAPPNAME} may not work correctly."
				${EndIf}
			${EndIf}
		${EndIf}

		${If} $DLLType != REGDLL
		${AndIf} $DLLType != REGDLLTLB
		${AndIf} $DLLType != REGEXE
		${AndIf} $DLLType != REGTLB
		${AndIf} $DLLType != REGUSERTLB
			${InvalidValueError} [RegisterDLL$R0]:Type $DLLType
		${EndIf}

		IntOp $R0 $R0 + 1
	${Loop}
	System::Call `shell32::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)`
!macroend

${SegmentPostPrimary}
	${Journal::HasEntries} RegDLL $R0
	${If} $R0 > 0
		${Journal::Rollback} RegDLL
		System::Call `ole32::CoFreeUnusedLibraries()`
		System::Call `shell32::SHChangeNotify(i 0x08000000, i 0, i 0, i 0)`
	${EndIf}
!macroend

!endif ; SEGMENTS_REGDLL
