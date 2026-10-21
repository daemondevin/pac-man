;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; Journal.nsh
;	The rollback journal and the crash-recovery dispatcher.
;
;	The journal records only what is needed to undo a change. It is a rollback
;	ledger, not a log. A segment writes an entry BEFORE it mutates the system,
;	and undoes its own work with ${Journal::Rollback} <Segment>. Crash recovery
;	runs the exact same undo code on the next launch, so the normal cleanup
;	path and the recovery path can never drift apart.
;
;	Storage
;		HKCU\Software\pac-man\Journal\<AppID>             session values
;		HKCU\Software\pac-man\Journal\<AppID>\<Segment>   one subkey per segment
;		%LOCALAPPDATA%\pac-man\Journal\<AppID>\           backup files referenced
;		                                                  by entries (host-side,
;		                                                  survives a drive change)
;
;	Session values
;		State     active | incomplete
;		PID       process id of the launcher that opened the session
;		Launcher  full path of that launcher
;		Version   PortableApps Compiler version that wrote the journal
;
;	Segment values (n = 1..Count, newest entry has the highest n)
;		Count     number of live entries
;		n.Op      undo operation (see below)
;		n.A..n.D  operation arguments
;
;	Undo operations (every one is idempotent and safe to re-run)
;		REGKEY     A=root(HKCU|HKLM) B=subkey C=.reg backup or "" D=view(32|64|"")
;		           Deletes the key, then re-imports the backup if one was taken.
;		REGEMPTY   A=root B=subkey
;		           Deletes the key only if it has no subkeys and no values.
;		           Used for parent keys created on the way to a new key.
;		REGVALUE   A=root B=subkey C=value name D=previous value or "" if absent
;		           Previous value format: STR:<data> | EXP:<data> | DWORD:<number>
;		FILE       A=path B=backup or ""
;		           Deletes the file, then moves the backup back into place.
;		DIR        A=path B=backup or "" C="recursive" to allow a recursive delete
;		           Never recurses into a reparse point (junction or symlink).
;		LINK       A=link path B=backup or "" C=link source (for hard links)
;		           Removes the link itself (never its target) only when it is
;		           provably ours, then restores the backup.
;		CMD        A=command line B=accepted exit codes (comma list, default 0)
;		           C="admin" when the command only works elevated; without
;		           admin rights the entry is then kept instead of run, so an
;		           exit code that also means "nothing to do" can't hide an
;		           access-denied failure.
;		FONT       A=font file B=AddFontResourceEx flags used (16 = private)
;		DRIVER     A=copy of the driver package's INF in the journal store
;		           Finds the driver store's oemNN.inf with the same content
;		           and removes the package with pnputil /delete-driver
;		           /uninstall /force. Needs admin rights. A missing copy
;		           means the package was already removed.
;		TASK       A=scheduled task name B=task XML backup or "" C="admin" or ""
;		           Deletes the task if it exists, then re-creates the backup
;		           with schtasks /XML. A missing backup file means the
;		           backup was already restored, so nothing is touched.
;		STRIPLINES A=text file B=marker
;		           Removes every line containing the marker.
;		SVCSTOP    A=service name B=timeout in seconds (default 30)
;		           Stops the service and waits until it reports STOPPED.
;		COMDLL     A=COM server (.dll/.ocx/.exe) B=scope(user|machine)
;		           C=bitness(32|64) D=CLSID or ""
;		           Unregisters the server. User scope calls DllUnregisterServer
;		           in-process with HKCR/HKLM redirected to HKCU. When a CLSID is
;		           given and is no longer registered, nothing is called.
;		TYPELIB    A=type library B=scope(user|machine)
;		           Unregisters the type library if it is still registered.
;
;	Rules for segment authors
;		1. Record before you mutate.
;		2. Never infer state; record exactly what to undo.
;		3. Never delete data you did not create.
;		4. Clean up with ${Journal::Rollback} <Segment>, nothing else.
;

!ifndef JOURNAL_NSH_INCLUDED
!define JOURNAL_NSH_INCLUDED

!define JOURNAL_ROOT	`Software\pac-man\Journal`
!define JOURNAL_KEY		`${JOURNAL_ROOT}\${APPNAME}`
!define JOURNAL_STORE	`$LOCALAPPDATA\pac-man\Journal\${APPNAME}`
!define /ifndef JOURNAL_WM_FONTCHANGE 0x001D
!define /ifndef JOURNAL_HWND_BROADCAST 0xFFFF
!define /ifndef JOURNAL_REPARSE_POINT 0x400

; Rollback order for recovery. This is the README apply order reversed, so no
; consumer outlives its provider. Segments not in this list are rolled back
; afterwards in registry enumeration order.
!include TypeLib.nsh

!define JOURNAL_RECOVERY_ORDER `Tasks Services Drivers Hosts Firewall Associations Symlinks Fonts RegDLL Runtime`

Var JournalActive
Var JournalIncomplete
Var JournalQuiet
Var _JSeg
Var _JOp
Var _JA
Var _JB
Var _JC
Var _JD
Var _JIdx
Var _JOk
Var _JT1
Var _JT2
Var _JT3
Var _JT4

;= PUBLIC MACROS
;= ################

; ${Journal::Begin}
; Opens (or re-opens) the session for this launcher. Called automatically by
; the first ${Journal::Record}; the lifecycle also calls it before Pre.
!define Journal::Begin `!insertmacro _Journal::Begin`
!macro _Journal::Begin
	Call Journal_Begin
!macroend

; ${Journal::Record} Segment Op A B C D
; Appends an undo entry for Segment. Always call it BEFORE the mutation.
; The new entry index is left in $_JIdx.
!define Journal::Record `!insertmacro _Journal::Record`
!macro _Journal::Record _SEG _OP _A _B _C _D
	StrCpy $_JSeg `${_SEG}`
	StrCpy $_JOp `${_OP}`
	StrCpy $_JA `${_A}`
	StrCpy $_JB `${_B}`
	StrCpy $_JC `${_C}`
	StrCpy $_JD `${_D}`
	Call Journal_Record
!macroend

; ${Journal::Rollback} Segment
; Undoes every entry of Segment, newest first, removing each entry only once
; its undo succeeded. Stops at the first failure so ordering is preserved;
; whatever is left is retried on the next launch.
!define Journal::Rollback `!insertmacro _Journal::Rollback`
!macro _Journal::Rollback _SEG
	Push `${_SEG}`
	Call Journal_Rollback
!macroend

; ${Journal::Discard} Segment
; Drops the newest entry of Segment without undoing it. Only for the case
; where the mutation it was recorded for definitely did not happen.
!define Journal::Discard `!insertmacro _Journal::Discard`
!macro _Journal::Discard _SEG
	Push `${_SEG}`
	Call Journal_Discard
!macroend

; ${Journal::PEBitness} Path $var
; Sets $var to 32 or 64 from the file's PE header (0 when unknown).
!define Journal::PEBitness `!insertmacro _Journal::PEBitness`
!macro _Journal::PEBitness _PATH _VAR
	StrCpy $_JT1 `${_PATH}`
	Call Journal_PEBitness
	StrCpy ${_VAR} $_JT4
!macroend

; ${Journal::ComUserCall} Path Proc $var
; Calls DllRegisterServer or DllUnregisterServer in-process with HKCR and
; HKLM redirected to HKCU, so a 32-bit COM DLL registers for the current
; user only. $var receives the HRESULT (0 on success, negative on failure).
!define Journal::ComUserCall `!insertmacro _Journal::ComUserCall`
!macro _Journal::ComUserCall _PATH _PROC _VAR
	StrCpy $_JT1 `${_PATH}`
	StrCpy $_JT2 `${_PROC}`
	Call Journal_ComUserCall
	StrCpy ${_VAR} $_JT4
!macroend

; ${Journal::RegSvr32} Bitness $var
; Sets $var to the regsvr32.exe that matches a 32 or 64-bit server.
!define Journal::RegSvr32 `!insertmacro _Journal::RegSvr32`
!macro _Journal::RegSvr32 _BITS _VAR
	StrCpy $_JT1 `${_BITS}`
	Call Journal_RegSvr32
	StrCpy ${_VAR} $_JT4
!macroend

; ${Journal::HasEntries} Segment $var
; Sets $var to the live entry count for Segment (0 when none).
!define Journal::HasEntries `!insertmacro _Journal::HasEntries`
!macro _Journal::HasEntries _SEG _VAR
	ClearErrors
	ReadRegStr ${_VAR} HKCU `${JOURNAL_KEY}\${_SEG}` "Count"
	${IfThen} ${_VAR} == "" ${|} StrCpy ${_VAR} 0 ${|}
!macroend

; ${Journal::RegKeyExists} Root Subkey $var
; Sets $var to 1 when the key exists, else 0. Root is HKCU, HKLM or HKCR.
!define Journal::RegKeyExists `!insertmacro _Journal::RegKeyExists`
!macro _Journal::RegKeyExists _ROOT _KEY _VAR
	StrCpy $_JT1 `${_ROOT}`
	StrCpy $_JT2 `${_KEY}`
	Call Journal_RegKeyExists
	StrCpy ${_VAR} $_JT4
!macroend

; ${Journal::RegKey} Segment Root Subkey $var
; Journals a registry key the caller is about to create or replace. Root is
; HKCU or HKLM. When the key exists it is exported to the journal store and
; recorded as REGKEY with that backup; $var is set to "existed". When it does
; not, every missing parent is recorded as REGEMPTY (top-down) and the key
; itself as REGKEY with no backup; $var is set to "new". When an existing
; key cannot be backed up nothing is recorded and $var is set to "".
!define Journal::RegKey `!insertmacro _Journal::RegKey`
!macro _Journal::RegKey _SEG _ROOT _KEY _VAR
	Push `${_KEY}`
	Push `${_ROOT}`
	Push `${_SEG}`
	Call Journal_RegKey
	StrCpy ${_VAR} $_JT4
!macroend

; ${Journal::FindStagedInf} InfFile $var
; Sets $var to the oemNN.inf in %WINDIR%\INF whose content is identical to
; InfFile (the published name of that driver package), or "" when the
; package is not in the driver store.
!define Journal::FindStagedInf `!insertmacro _Journal::FindStagedInf`
!macro _Journal::FindStagedInf _INF _VAR
	StrCpy $_JT3 `${_INF}`
	Call Journal_FindStagedInf
	StrCpy ${_VAR} $_JT4
!macroend

; ${Journal::PnPUtil} $var
; Sets $var to the 64-bit pnputil.exe when the launcher runs under WOW64
; (SysWOW64 has none), else to the one in $SYSDIR.
!define Journal::PnPUtil `!insertmacro _Journal::PnPUtil`
!macro _Journal::PnPUtil _VAR
	${If} ${FileExists} `$WINDIR\Sysnative\pnputil.exe`
		StrCpy ${_VAR} `$WINDIR\Sysnative\pnputil.exe`
	${Else}
		StrCpy ${_VAR} `$SYSDIR\pnputil.exe`
	${EndIf}
!macroend

; ${Journal::BackupFile} Segment Path $outvar
; Copies Path into the journal store and returns the backup path in $outvar
; ("" when Path does not exist). Does not record an entry by itself.
!define Journal::BackupFile `!insertmacro _Journal::BackupFile`
!macro _Journal::BackupFile _SEG _PATH _OUT
	StrCpy $_JSeg `${_SEG}`
	StrCpy $_JA `${_PATH}`
	Call Journal_BackupFile
	StrCpy ${_OUT} $_JT1
!macroend

; ${Journal::Recover}
; The crash-recovery dispatcher. If a previous session left entries behind,
; roll everything back before this launch changes anything.
!define Journal::Recover `!insertmacro _Journal::Recover`
!macro _Journal::Recover
	Call Journal_Recover
!macroend

; ${Journal::End}
; Closes the session. Deletes the journal when it is empty, otherwise marks
; it incomplete so the next launch finishes the job.
!define Journal::End `!insertmacro _Journal::End`
!macro _Journal::End
	Call Journal_End
!macroend

;= FUNCTIONS
;= ################

Function Journal_Begin
	Push $0
	System::Call `kernel32::GetCurrentProcessId()i.r0`
	WriteRegStr HKCU `${JOURNAL_KEY}` "State" "active"
	WriteRegStr HKCU `${JOURNAL_KEY}` "PID" "$0"
	WriteRegStr HKCU `${JOURNAL_KEY}` "Launcher" "$EXEPATH"
	WriteRegStr HKCU `${JOURNAL_KEY}` "Version" "${PACVER}"
	StrCpy $JournalActive true
	Pop $0
FunctionEnd

Function Journal_Record
	${If} $JournalActive != true
		Call Journal_Begin
	${EndIf}
	ClearErrors
	ReadRegStr $_JIdx HKCU `${JOURNAL_KEY}\$_JSeg` "Count"
	${IfThen} $_JIdx == "" ${|} StrCpy $_JIdx 0 ${|}
	IntOp $_JIdx $_JIdx + 1
	WriteRegStr HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.Op" "$_JOp"
	WriteRegStr HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.A" "$_JA"
	WriteRegStr HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.B" "$_JB"
	WriteRegStr HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.C" "$_JC"
	WriteRegStr HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.D" "$_JD"
	; Count is written last so a half-written entry is never counted.
	WriteRegStr HKCU `${JOURNAL_KEY}\$_JSeg` "Count" "$_JIdx"
	!ifdef DEBUG_JOURNAL
		MessageBox MB_OK "Journal [$_JSeg] #$_JIdx $_JOp$\r$\nA=$_JA$\r$\nB=$_JB$\r$\nC=$_JC$\r$\nD=$_JD"
	!endif
FunctionEnd

Function Journal_BackupFile
	StrCpy $_JT1 ""
	${If} ${FileExists} `$_JA`
		CreateDirectory `${JOURNAL_STORE}\$_JSeg`
		System::Call `kernel32::GetTickCount()i.s`
		Pop $_JT2
		${GetFileName} `$_JA` $_JT3
		StrCpy $_JT1 `${JOURNAL_STORE}\$_JSeg\$_JT2.$_JT3`
		ClearErrors
		CopyFiles /SILENT `$_JA` `$_JT1`
		${If} ${Errors}
			StrCpy $_JT1 ""
		${EndIf}
	${EndIf}
FunctionEnd

; Sets $_JT4 to 1 when key $_JT2 exists under root $_JT1, else 0.
Function Journal_RegKeyExists
	ClearErrors
	${If} $_JT1 == HKLM
		EnumRegKey $_JT4 HKLM `$_JT2` 0
	${ElseIf} $_JT1 == HKCR
		EnumRegKey $_JT4 HKCR `$_JT2` 0
	${Else}
		EnumRegKey $_JT4 HKCU `$_JT2` 0
	${EndIf}
	${If} ${Errors}
		StrCpy $_JT4 0
	${Else}
		StrCpy $_JT4 1
	${EndIf}
FunctionEnd

; Stack in: segment, root, subkey. Result in $_JT4 (see ${Journal::RegKey}).
Function Journal_RegKey
	Exch $0 ; segment
	Exch
	Exch $1 ; root
	Exch 2
	Exch $2 ; subkey
	Push $3
	Push $4
	Push $5
	StrCpy $_JT1 $1
	StrCpy $_JT2 $2
	Call Journal_RegKeyExists
	${If} $_JT4 == 1
		; Export it so the undo can put it back exactly as it was.
		CreateDirectory `${JOURNAL_STORE}\$0`
		System::Call `kernel32::GetTickCount()i.r3`
		StrCpy $4 0
		${Do}
			StrCpy $5 `${JOURNAL_STORE}\$0\$3-$4.reg`
			${IfNotThen} ${FileExists} $5 ${|} ${ExitDo} ${|}
			IntOp $4 $4 + 1
		${Loop}
		nsExec::ExecToStack `"$SYSDIR\reg.exe" export "$1\$2" "$5" /y`
		Pop $3
		Pop $4
		${If} ${FileExists} $5
			${Journal::Record} $0 REGKEY $1 $2 $5 ""
			StrCpy $_JT4 existed
		${Else}
			StrCpy $_JT4 ""
		${EndIf}
	${Else}
		; Collect the missing parents, deepest first, as "|a|b|c".
		StrCpy $3 ""
		${GetParent} $2 $4
		${Do}
			${IfThen} $4 == "" ${|} ${ExitDo} ${|}
			StrCpy $_JT1 $1
			StrCpy $_JT2 $4
			Call Journal_RegKeyExists
			${IfThen} $_JT4 == 1 ${|} ${ExitDo} ${|}
			StrCpy $3 `$3|$4`
			${GetParent} $4 $4
		${Loop}
		; Record them top-down: walk the list from its end.
		${Do}
			${IfThen} $3 == "" ${|} ${ExitDo} ${|}
			StrLen $5 $3
			${Do}
				IntOp $5 $5 - 1
				StrCpy $4 $3 1 $5
				${IfThen} $4 == "|" ${|} ${ExitDo} ${|}
			${Loop}
			IntOp $4 $5 + 1
			StrCpy $4 $3 "" $4
			StrCpy $3 $3 $5
			${Journal::Record} $0 REGEMPTY $1 $4 "" ""
		${Loop}
		${Journal::Record} $0 REGKEY $1 $2 "" ""
		StrCpy $_JT4 new
	${EndIf}
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $0
	Pop $1
FunctionEnd

; Sets $_JT4 to 1 when files $_JT1 and $_JT2 have identical content, else 0.
Function Journal_SameContent
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	StrCpy $_JT4 0
	ClearErrors
	FileOpen $0 `$_JT1` r
	FileOpen $1 `$_JT2` r
	${IfNot} ${Errors}
		FileSeek $0 0 END $2
		FileSeek $1 0 END $3
		${If} $2 = $3
			FileSeek $0 0 SET
			FileSeek $1 0 SET
			System::Alloc 65536
			Pop $4
			System::Alloc 65536
			Pop $5
			StrCpy $_JT4 1
			${Do}
				System::Call `kernel32::ReadFile(p r0, p r4, i 65536, *i .r6, p 0)`
				System::Call `kernel32::ReadFile(p r1, p r5, i 65536, *i .r7, p 0)`
				${If} $6 <> $7
					StrCpy $_JT4 0
					${ExitDo}
				${EndIf}
				${IfThen} $6 = 0 ${|} ${ExitDo} ${|}
				System::Call `ntdll::RtlCompareMemory(p r4, p r5, p r6)p .r3`
				${If} $3 <> $6
					StrCpy $_JT4 0
					${ExitDo}
				${EndIf}
			${Loop}
			System::Free $4
			System::Free $5
		${EndIf}
	${EndIf}
	FileClose $0
	FileClose $1
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Sets $_JT4 to the oemNN.inf whose content equals $_JT3, or "".
Function Journal_FindStagedInf
	Push $0
	Push $1
	StrCpy $1 ""
	FindFirst $0 $_JT4 `$WINDIR\INF\oem*.inf`
	${Do}
		${IfThen} $_JT4 == "" ${|} ${ExitDo} ${|}
		Push $_JT4
		StrCpy $_JT1 `$WINDIR\INF\$_JT4`
		StrCpy $_JT2 $_JT3
		Call Journal_SameContent
		Pop $_JT1
		${If} $_JT4 == 1
			StrCpy $1 $_JT1
			${ExitDo}
		${EndIf}
		FindNext $0 $_JT4
	${Loop}
	FindClose $0
	StrCpy $_JT4 $1
	Pop $1
	Pop $0
FunctionEnd

; Sets $_JT4 to 32 or 64 from the PE header of $_JT1, 0 when unknown.
Function Journal_PEBitness
	Push $0
	Push $1
	Push $2
	Push $3
	StrCpy $_JT4 0
	ClearErrors
	FileOpen $0 `$_JT1` r
	${IfNot} ${Errors}
		FileSeek $0 0x3C SET
		FileReadByte $0 $1
		FileReadByte $0 $2
		IntOp $2 $2 << 8
		IntOp $1 $1 | $2
		FileReadByte $0 $2
		IntOp $2 $2 << 16
		IntOp $1 $1 | $2
		FileReadByte $0 $2
		IntOp $2 $2 << 24
		IntOp $1 $1 | $2
		IntOp $1 $1 + 4
		FileSeek $0 $1 SET
		FileReadByte $0 $2
		FileReadByte $0 $3
		IntOp $3 $3 << 8
		IntOp $2 $2 | $3
		${If} $2 = 0x14C
			StrCpy $_JT4 32
		${ElseIf} $2 = 0x8664
			StrCpy $_JT4 64
		${ElseIf} $2 = 0xAA64
			StrCpy $_JT4 64
		${EndIf}
		FileClose $0
	${EndIf}
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Sets $_JT4 to the regsvr32.exe matching bitness $_JT1 (32 or 64).
Function Journal_RegSvr32
	Push $0
	System::Call `kernel32::GetCurrentProcess()i.s`
	System::Call `kernel32::IsWow64Process(is,*i.r0)`
	${If} $0 <> 0
		; 32-bit launcher on 64-bit Windows: Sysnative reaches the real System32.
		${If} $_JT1 == 64
			StrCpy $_JT4 `$WINDIR\Sysnative\regsvr32.exe`
		${Else}
			StrCpy $_JT4 `$WINDIR\SysWOW64\regsvr32.exe`
		${EndIf}
	${Else}
		StrCpy $_JT4 `$SYSDIR\regsvr32.exe`
	${EndIf}
	Pop $0
FunctionEnd

; In-process COM (un)registration redirected to the current user.
; In: $_JT1 = DLL path, $_JT2 = DllRegisterServer | DllUnregisterServer
; Out: $_JT4 = HRESULT, or -1 (no entry point), -2 (load failed), -3 (no key)
Function Journal_ComUserCall
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	System::Call `advapi32::RegCreateKeyEx(p 0x80000001, t "Software\Classes", i 0, p 0, i 0, i 0x2001F, p 0, *p .r0, p 0)i .r1`
	${If} $1 = 0
		System::Call `advapi32::RegOverridePredefKey(p 0x80000000, p r0)i .r2`
		System::Call `advapi32::RegOverridePredefKey(p 0x80000002, p 0x80000001)i .r2`
		System::Call `kernel32::LoadLibraryEx(t "$_JT1", p 0, i 8)p .r4`
		${If} $4 <> 0
			System::Call `kernel32::GetProcAddress(p r4, m "$_JT2")p .r2`
			${If} $2 <> 0
				System::Call `::$2()i .r3`
				StrCpy $_JT4 $3
			${Else}
				StrCpy $_JT4 -1
			${EndIf}
			System::Call `kernel32::FreeLibrary(p r4)`
		${Else}
			StrCpy $_JT4 -2
		${EndIf}
		System::Call `advapi32::RegOverridePredefKey(p 0x80000000, p 0)`
		System::Call `advapi32::RegOverridePredefKey(p 0x80000002, p 0)`
		System::Call `advapi32::RegCloseKey(p r0)`
	${Else}
		StrCpy $_JT4 -3
	${EndIf}
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

Function Journal_Discard
	Exch $_JSeg
	Push $0
	ReadRegStr $0 HKCU `${JOURNAL_KEY}\$_JSeg` "Count"
	${If} $0 > 0
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$0.Op"
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$0.A"
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$0.B"
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$0.C"
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$0.D"
		IntOp $0 $0 - 1
		WriteRegStr HKCU `${JOURNAL_KEY}\$_JSeg` "Count" "$0"
	${EndIf}
	Pop $0
	Pop $_JSeg
FunctionEnd

; Sets $_JT4 to 1 when $_JT1 and $_JT2 are the same file on disk (same
; volume serial and file index, i.e. hard links of each other), else 0.
Function Journal_SameFile
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	StrCpy $_JT4 0
	StrCpy $5 ""
	StrCpy $4 $_JT1
	${Do}
		; FILE_SHARE_READ|WRITE|DELETE, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS
		System::Call `kernel32::CreateFile(t r4, i 0, i 7, p 0, i 3, i 0x02000000, p 0)p .r0`
		${If} $0 = -1
			${ExitDo}
		${EndIf}
		System::Call `*(&i52)p .r2`
		System::Call `kernel32::GetFileInformationByHandle(p r0, p r2)i .r3`
		System::Call `kernel32::CloseHandle(p r0)`
		${If} $3 = 0
			System::Free $2
			${ExitDo}
		${EndIf}
		; dwVolumeSerialNumber @28, nFileIndexHigh @44, nFileIndexLow @48
		System::Call `*$2(&i28, i .r0, &i12, i .r1, i .r3)`
		System::Free $2
		${If} $5 == ""
			StrCpy $5 `$0:$1:$3`
			StrCpy $4 $_JT2
		${Else}
			${IfThen} $5 == `$0:$1:$3` ${|} StrCpy $_JT4 1 ${|}
			${ExitDo}
		${EndIf}
	${Loop}
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Returns 1 in $_JT4 when $_JT1 contains $_JT2 (case-insensitive), else 0.
Function Journal_Contains
	Push $0
	Push $1
	Push $2
	StrCpy $_JT4 0
	StrLen $1 $_JT2
	${If} $1 > 0
		StrCpy $0 0
		${Do}
			StrCpy $2 $_JT1 $1 $0
			${If} $2 == ""
				${ExitDo}
			${EndIf}
			${If} $2 == $_JT2
				StrCpy $_JT4 1
				${ExitDo}
			${EndIf}
			IntOp $0 $0 + 1
		${Loop}
	${EndIf}
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Moves backup $_JT1 back to $_JT2. Sets $_JOk to false on failure.
Function Journal_RestoreBackup
	${If} $_JT1 != ""
	${AndIf} ${FileExists} `$_JT1`
		ClearErrors
		Rename `$_JT1` `$_JT2`
		${If} ${Errors}
			ClearErrors
			CopyFiles /SILENT `$_JT1` `$_JT2`
			${If} ${Errors}
				StrCpy $_JOk false
			${Else}
				Delete `$_JT1`
			${EndIf}
		${EndIf}
	${EndIf}
FunctionEnd

; Undoes the entry loaded in $_JOp/$_JA..$_JD. Sets $_JOk to true or false.
Function Journal_UndoEntry
	Push $0
	Push $1
	Push $2
	StrCpy $_JOk true
	${Select} $_JOp

		${Case} REGKEY
			${If} $_JA == HKLM
			${AndIf} $Admin != true
				StrCpy $_JOk false
			${Else}
				${If} $_JD == 64
					SetRegView 64
				${ElseIf} $_JD == 32
					SetRegView 32
				${EndIf}
				${If} $_JA == HKLM
					DeleteRegKey HKLM `$_JB`
				${Else}
					DeleteRegKey HKCU `$_JB`
				${EndIf}
				${If} $_JD == 64
				${OrIf} $_JD == 32
					SetRegView lastused
				${EndIf}
				${If} $_JC != ""
				${AndIf} ${FileExists} `$_JC`
					${If} $_JD == 64
						nsExec::ExecToStack `"$SYSDIR\reg.exe" import "$_JC" /reg:64`
					${ElseIf} $_JD == 32
						nsExec::ExecToStack `"$SYSDIR\reg.exe" import "$_JC" /reg:32`
					${Else}
						nsExec::ExecToStack `"$SYSDIR\reg.exe" import "$_JC"`
					${EndIf}
					Pop $0
					Pop $1
					${If} $0 == 0
						Delete `$_JC`
					${Else}
						StrCpy $_JOk false
					${EndIf}
				${EndIf}
			${EndIf}

		${Case} REGEMPTY
			${If} $_JA == HKLM
			${AndIf} $Admin != true
				StrCpy $_JOk false
			${ElseIf} $_JA == HKLM
				DeleteRegKey /ifempty HKLM `$_JB`
			${Else}
				DeleteRegKey /ifempty HKCU `$_JB`
			${EndIf}

		${Case} REGVALUE
			${If} $_JA == HKLM
			${AndIf} $Admin != true
				StrCpy $_JOk false
			${Else}
				StrCpy $0 $_JD 4
				StrCpy $1 $_JD 6
				${If} $_JD == ""
					${If} $_JA == HKLM
						DeleteRegValue HKLM `$_JB` `$_JC`
					${Else}
						DeleteRegValue HKCU `$_JB` `$_JC`
					${EndIf}
				${ElseIf} $0 == "STR:"
					StrCpy $2 $_JD "" 4
					${If} $_JA == HKLM
						WriteRegStr HKLM `$_JB` `$_JC` `$2`
					${Else}
						WriteRegStr HKCU `$_JB` `$_JC` `$2`
					${EndIf}
				${ElseIf} $0 == "EXP:"
					StrCpy $2 $_JD "" 4
					${If} $_JA == HKLM
						WriteRegExpandStr HKLM `$_JB` `$_JC` `$2`
					${Else}
						WriteRegExpandStr HKCU `$_JB` `$_JC` `$2`
					${EndIf}
				${ElseIf} $1 == "DWORD:"
					StrCpy $2 $_JD "" 6
					${If} $_JA == HKLM
						WriteRegDWORD HKLM `$_JB` `$_JC` $2
					${Else}
						WriteRegDWORD HKCU `$_JB` `$_JC` $2
					${EndIf}
				${Else}
					StrCpy $_JOk false
				${EndIf}
			${EndIf}

		${Case} FILE
			Delete `$_JA`
			${If} ${FileExists} `$_JA`
				StrCpy $_JOk false
			${Else}
				StrCpy $_JT1 $_JB
				StrCpy $_JT2 $_JA
				Call Journal_RestoreBackup
			${EndIf}

		${Case} DIR
			${If} ${FileExists} `$_JA\*.*`
				System::Call `kernel32::GetFileAttributes(t "$_JA")i.r0`
				IntOp $0 $0 & ${JOURNAL_REPARSE_POINT}
				${If} $_JC == recursive
				${AndIf} $0 == 0
					RMDir /r `$_JA`
				${Else}
					RMDir `$_JA`
				${EndIf}
			${EndIf}
			${If} ${FileExists} `$_JA\*.*`
			${AndIf} $_JB != ""
				StrCpy $_JOk false
			${Else}
				StrCpy $_JT1 $_JB
				StrCpy $_JT2 $_JA
				Call Journal_RestoreBackup
			${EndIf}

		${Case} LINK
			; Only ever remove something that is provably our link: a reparse
			; point (junction or symlink) or a hard link to the source in C.
			; Anything else at A is somebody's real data and is left alone.
			System::Call `kernel32::GetFileAttributes(t "$_JA")i.r0`
			${If} $0 <> -1
				IntOp $1 $0 & ${JOURNAL_REPARSE_POINT}
				IntOp $2 $0 & 0x10
				${If} $1 <> 0
					${If} $2 <> 0
						; RMDir removes the reparse point, never the target.
						RMDir `$_JA`
					${Else}
						Delete `$_JA`
					${EndIf}
				${ElseIf} $_JC != ""
					StrCpy $_JT1 $_JA
					StrCpy $_JT2 $_JC
					Call Journal_SameFile
					${IfThen} $_JT4 == 1 ${|} Delete `$_JA` ${|}
				${EndIf}
			${EndIf}
			System::Call `kernel32::GetFileAttributes(t "$_JA")i.r0`
			${If} $0 <> -1
				; Still there. Fine if it was never ours and there is no backup
				; to put back (the crash happened before the link was made);
				; a failure if a backup is waiting for this spot.
				${If} $_JB != ""
				${AndIf} ${FileExists} `$_JB`
					StrCpy $_JOk false
				${EndIf}
			${Else}
				StrCpy $_JT1 $_JB
				StrCpy $_JT2 $_JA
				Call Journal_RestoreBackup
			${EndIf}

		${Case} CMD
			${If} $_JC == admin
			${AndIf} $Admin != true
				StrCpy $_JOk false
			${Else}
				nsExec::ExecToStack `$_JA`
				Pop $0
				Pop $1
				${IfThen} $_JB == "" ${|} StrCpy $_JB 0 ${|}
				StrCpy $_JT1 ",$_JB,"
				StrCpy $_JT2 ",$0,"
				Call Journal_Contains
				${If} $_JT4 != 1
					StrCpy $_JOk false
				${EndIf}
			${EndIf}

		${Case} DRIVER
			${If} $Admin != true
				StrCpy $_JOk false
			${ElseIf} ${FileExists} `$_JA`
				StrCpy $_JT3 $_JA
				Call Journal_FindStagedInf
				${If} $_JT4 != ""
					${Journal::PnPUtil} $2
					nsExec::ExecToStack `"$2" /delete-driver "$_JT4" /uninstall /force`
					Pop $0
					Pop $1
					${If} $0 != 0
					${AndIf} $0 != 3010
						StrCpy $_JOk false
					${EndIf}
				${EndIf}
				${If} $_JOk == true
					Delete `$_JA`
				${EndIf}
			${EndIf}

		${Case} TASK
			${If} $_JC == admin
			${AndIf} $Admin != true
				StrCpy $_JOk false
			${ElseIf} $_JB != ""
			${AndIfNot} ${FileExists} `$_JB`
				; Restored on an earlier attempt; the task there is the original.
			${Else}
				nsExec::ExecToStack `"$SYSDIR\schtasks.exe" /Query /TN "$_JA"`
				Pop $0
				Pop $1
				${If} $0 == 0
					nsExec::ExecToStack `"$SYSDIR\schtasks.exe" /Delete /TN "$_JA" /F`
					Pop $0
					Pop $1
					${IfThen} $0 != 0 ${|} StrCpy $_JOk false ${|}
				${EndIf}
				${If} $_JOk == true
				${AndIf} $_JB != ""
					nsExec::ExecToStack `"$SYSDIR\schtasks.exe" /Create /TN "$_JA" /XML "$_JB" /F`
					Pop $0
					Pop $1
					${If} $0 == 0
						Delete `$_JB`
					${Else}
						StrCpy $_JOk false
					${EndIf}
				${EndIf}
			${EndIf}

		${Case} FONT
			${IfThen} $_JB == "" ${|} StrCpy $_JB 0 ${|}
			System::Call `gdi32::RemoveFontResourceEx(t "$_JA", i $_JB, i 0)i.r0`
			SendMessage ${JOURNAL_HWND_BROADCAST} ${JOURNAL_WM_FONTCHANGE} 0 0 /TIMEOUT=2000

		${Case} STRIPLINES
			${If} ${FileExists} `$_JA`
				InitPluginsDir
				StrCpy $2 `$PLUGINSDIR\journal_strip.tmp`
				ClearErrors
				FileOpen $0 `$_JA` r
				FileOpen $1 `$2` w
				${If} ${Errors}
					StrCpy $_JOk false
				${Else}
					${Do}
						ClearErrors
						FileRead $0 $_JT1
						${IfThen} ${Errors} ${|} ${ExitDo} ${|}
						StrCpy $_JT3 $_JT1
						StrCpy $_JT2 $_JB
						Call Journal_Contains
						${If} $_JT4 != 1
							FileWrite $1 $_JT3
						${EndIf}
					${Loop}
					FileClose $0
					FileClose $1
					ClearErrors
					CopyFiles /SILENT `$2` `$_JA`
					${If} ${Errors}
						StrCpy $_JOk false
					${EndIf}
					Delete `$2`
				${EndIf}
			${EndIf}

		${Case} SVCSTOP
			${IfThen} $_JB == "" ${|} StrCpy $_JB 30 ${|}
			nsExec::ExecToStack `"$SYSDIR\sc.exe" stop "$_JA"`
			Pop $0
			Pop $1
			${If} $0 != 1060
				StrCpy $2 0
				StrCpy $_JOk false
				${Do}
					nsExec::ExecToStack `"$SYSDIR\sc.exe" query "$_JA"`
					Pop $0
					Pop $_JT1
					${If} $0 == 1060
						StrCpy $_JOk true
						${ExitDo}
					${EndIf}
					StrCpy $_JT2 STOPPED
					Call Journal_Contains
					${If} $_JT4 == 1
						StrCpy $_JOk true
						${ExitDo}
					${EndIf}
					IntOp $2 $2 + 1
					${IfThen} $2 > $_JB ${|} ${ExitDo} ${|}
					Sleep 1000
				${Loop}
			${EndIf}

		${Case} COMDLL
			; Already gone? Then there is nothing to undo.
			StrCpy $2 present
			${If} $_JD != ""
				ClearErrors
				${If} $_JB == user
					EnumRegKey $0 HKCU `Software\Classes\CLSID\$_JD` 0
				${Else}
					${If} $_JC == 64
						SetRegView 64
					${EndIf}
					EnumRegKey $0 HKLM `Software\Classes\CLSID\$_JD` 0
					SetRegView lastused
				${EndIf}
				${IfThen} ${Errors} ${|} StrCpy $2 absent ${|}
			${EndIf}
			${If} $2 == present
				${IfNot} ${FileExists} `$_JA`
					StrCpy $_JOk false
				${ElseIf} $_JB == user
					${Journal::ComUserCall} `$_JA` DllUnregisterServer $0
					${IfThen} $0 <> 0 ${|} StrCpy $_JOk false ${|}
				${ElseIf} $Admin != true
					StrCpy $_JOk false
				${Else}
					StrCpy $0 $_JA 4 -4
					${If} $0 == .exe
						nsExec::ExecToStack `"$_JA" /unregserver`
					${Else}
						${Journal::RegSvr32} $_JC $1
						nsExec::ExecToStack `"$1" /s /u "$_JA"`
					${EndIf}
					Pop $0
					Pop $1
					${IfThen} $0 != 0 ${|} StrCpy $_JOk false ${|}
				${EndIf}
			${EndIf}

		${Case} TYPELIB
			${GetPathToLib} `$_JA` $0 $1
			${If} $_JB == user
				${If} $1 != ""
					ClearErrors
					${UnRegTlbForUser} `$_JA`
					${IfThen} ${Errors} ${|} StrCpy $_JOk false ${|}
				${EndIf}
			${ElseIf} $0 != ""
				${If} $Admin != true
					StrCpy $_JOk false
				${Else}
					ClearErrors
					${UnRegTlb} `$_JA`
					${IfThen} ${Errors} ${|} StrCpy $_JOk false ${|}
				${EndIf}
			${EndIf}

		${Default}
			; Unknown operation: keep the entry and report it, never guess.
			StrCpy $_JOk false

	${EndSelect}
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

Function Journal_Rollback
	Exch $_JSeg
	Push $0
	ClearErrors
	ReadRegStr $0 HKCU `${JOURNAL_KEY}\$_JSeg` "Count"
	${IfThen} $0 == "" ${|} StrCpy $0 0 ${|}
	${DoWhile} $0 > 0
		ReadRegStr $_JOp HKCU `${JOURNAL_KEY}\$_JSeg` "$0.Op"
		ReadRegStr $_JA HKCU `${JOURNAL_KEY}\$_JSeg` "$0.A"
		ReadRegStr $_JB HKCU `${JOURNAL_KEY}\$_JSeg` "$0.B"
		ReadRegStr $_JC HKCU `${JOURNAL_KEY}\$_JSeg` "$0.C"
		ReadRegStr $_JD HKCU `${JOURNAL_KEY}\$_JSeg` "$0.D"
		Call Journal_UndoEntry
		${If} $_JOk != true
			StrCpy $JournalIncomplete true
			${ExitDo}
		${EndIf}
		IntOp $0 $0 - 1
		WriteRegStr HKCU `${JOURNAL_KEY}\$_JSeg` "Count" "$0"
		IntOp $_JIdx $0 + 1
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.Op"
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.A"
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.B"
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.C"
		DeleteRegValue HKCU `${JOURNAL_KEY}\$_JSeg` "$_JIdx.D"
	${Loop}
	${If} $0 == 0
		DeleteRegKey HKCU `${JOURNAL_KEY}\$_JSeg`
		RMDir /r `${JOURNAL_STORE}\$_JSeg`
	${EndIf}
	Pop $0
	Pop $_JSeg
FunctionEnd

; Rolls back every segment: the known order first, then anything else.
Function Journal_RollbackAll
	Push $0
	Push $1
	Push $2
	StrCpy $0 `${JOURNAL_RECOVERY_ORDER} `
	${Do}
		; Pop the first space-separated name off the list.
		StrCpy $1 0
		${Do}
			StrCpy $2 $0 1 $1
			${IfThen} $2 == " " ${|} ${ExitDo} ${|}
			${IfThen} $2 == "" ${|} ${ExitDo} ${|}
			IntOp $1 $1 + 1
		${Loop}
		StrCpy $2 $0 $1
		IntOp $1 $1 + 1
		StrCpy $0 $0 "" $1
		${If} $2 != ""
			${Journal::Rollback} $2
		${EndIf}
	${LoopUntil} $0 == ""
	; Any segment not in the known order (custom segments, future segments).
	StrCpy $1 0
	${Do}
		EnumRegKey $2 HKCU `${JOURNAL_KEY}` $1
		${IfThen} $2 == "" ${|} ${ExitDo} ${|}
		${Journal::Rollback} $2
		; A fully rolled-back key is deleted, so the same index now holds the
		; next key. Only advance when this one is still there.
		EnumRegKey $0 HKCU `${JOURNAL_KEY}` $1
		${If} $0 == $2
			IntOp $1 $1 + 1
		${EndIf}
	${Loop}
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

Function Journal_End
	Push $0
	EnumRegKey $0 HKCU `${JOURNAL_KEY}` 0
	${If} $0 == ""
		DeleteRegKey HKCU `${JOURNAL_KEY}`
		DeleteRegKey /ifempty HKCU `${JOURNAL_ROOT}`
		DeleteRegKey /ifempty HKCU `Software\pac-man`
		RMDir `${JOURNAL_STORE}`
		RMDir `$LOCALAPPDATA\pac-man\Journal`
		RMDir `$LOCALAPPDATA\pac-man`
	${Else}
		WriteRegStr HKCU `${JOURNAL_KEY}` "State" "incomplete"
	${EndIf}
	StrCpy $JournalActive false
	Pop $0
FunctionEnd

Function Journal_Recover
	Push $0
	ClearErrors
	ReadRegStr $0 HKCU `${JOURNAL_KEY}` "State"
	${If} $0 == detached
		; Left open on purpose (WaitForProgram=false): undo quietly.
		StrCpy $JournalIncomplete false
		Call Journal_RollbackAll
		Call Journal_End
	${ElseIf} $0 != ""
		; Only the primary instance gets here, so no other launcher for this
		; app is alive: whatever the journal holds is left over from a crash.
		; $JournalQuiet is set when the PAL crash notice will be shown anyway.
		${If} $JournalQuiet != true
			MessageBox MB_OK|MB_ICONINFORMATION|MB_TOPMOST \
				"${PORTABLEAPPNAME} did not shut down cleanly last time.$\r$\n$\r$\nThe changes it made to this computer will now be undone before it starts again."
		${EndIf}
		StrCpy $JournalIncomplete false
		Call Journal_RollbackAll
		Call Journal_End
		${If} $JournalIncomplete == true
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"Some changes left by a previous session of ${PORTABLEAPPNAME} could not be undone (they may need administrator rights).$\r$\n$\r$\nThey will be retried on the next launch."
		${EndIf}
	${EndIf}
	Pop $0
FunctionEnd

!endif ; JOURNAL_NSH_INCLUDED
