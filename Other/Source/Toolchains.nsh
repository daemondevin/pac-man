;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; Toolchains.nsh
;	Portable toolchains (Git, Python, Node.js, Rust, Go) that any package
;	can put in front of its app.
;
;	A toolchain is written like a segment (${SegmentFile} and the same
;	hooks) and lives in Toolchains\<Name>.nsh. A package turns toolchains on
;	in its launcher INI:
;
;		[Activate]
;		Toolchains=Git,Python,Rust
;
;	which compiles in TOOLCHAINS_GIT, TOOLCHAINS_PYTHON and
;	TOOLCHAINS_RUST. Each toolchain reads its own section, first from the
;	user's <AppID>.ini, then from the launcher INI, then its built-in
;	defaults:
;
;		[Rust]
;		Enabled=true
;		Path=%PAL:CommonFiles%\Rust
;		Redirect=true
;		ClearCache=true
;
;	The hooks each toolchain uses:
;		Pre          reads its settings and finds the toolchain (every launch)
;		PrePrimary   seeds its data from DefaultData and journals the default
;		             folders its tools would create in the user profile
;		PreExec      sets its environment variables and adds to PATH
;		PostPrimary  clears caches when asked, and rolls back its journal
;
;	PATH is changed once, after every toolchain and Custom.nsh's PreExec have
;	run: the folders collected with ${Toolchain::AddPath} go in front of the
;	existing PATH, for the app only. Custom.nsh can add its own the same way.
;

;= RUNNING TOOLCHAINS
;= ################

!macro RunToolchain toolchain
	!ifdef _DisableHook_${toolchain}_${__FUNCTION__}
		!echo "Toolchain ${toolchain}, hook ${__FUNCTION__} has been disabled by Custom.nsh."
	!else ifmacrondef ${toolchain}.nsh_${__FUNCTION__}
		!if ${toolchain} != Custom
			!warning "Toolchain ${toolchain}, hook ${__FUNCTION__} was called but does not exist!"
		!endif
	!else
		${!getdebug}
		!ifdef DEBUG && DEBUG_SEGWRAP
			${DebugMsg} "About to execute toolchain"
		!endif
		!insertmacro ${toolchain}.nsh_${__FUNCTION__}
		!ifdef DEBUG && DEBUG_SEGWRAP
			${DebugMsg} "Finished executing toolchain"
		!endif
	!endif
!macroend
!define RunToolchain "!insertmacro RunToolchain"

; Runs a toolchain's hook only when the toolchain is compiled in.
; Toolchains only implement the hooks they need, so a missing one is
; skipped quietly.
!macro _RunToolchainIfEnabled _FLAG _TC
	!ifdef ${_FLAG}
		!ifmacrodef ${_TC}.nsh_${__FUNCTION__}
			${RunToolchain} ${_TC}
		!endif
	!endif
!macroend
!define RunToolchainIfEnabled "!insertmacro _RunToolchainIfEnabled"

; Apply order. A toolchain's PATH entries go in front of the next one's, so
; earlier toolchains win when two provide the same program.
!macro _PACToolchains
	${RunToolchainIfEnabled} TOOLCHAINS_GIT     Git
	${RunToolchainIfEnabled} TOOLCHAINS_PYTHON  Python
	${RunToolchainIfEnabled} TOOLCHAINS_NODEJS  NodeJS
	${RunToolchainIfEnabled} TOOLCHAINS_RUST    Rust
	${RunToolchainIfEnabled} TOOLCHAINS_GO      Go
!macroend
!define PacToolchains `!insertmacro _PACToolchains`

; Cleanup order, the exact reverse.
!macro _PACToolchainsCleanup
	${RunToolchainIfEnabled} TOOLCHAINS_GO      Go
	${RunToolchainIfEnabled} TOOLCHAINS_RUST    Rust
	${RunToolchainIfEnabled} TOOLCHAINS_NODEJS  NodeJS
	${RunToolchainIfEnabled} TOOLCHAINS_PYTHON  Python
	${RunToolchainIfEnabled} TOOLCHAINS_GIT     Git
!macroend
!define PacToolchainsCleanup `!insertmacro _PACToolchainsCleanup`

;= SHARED HELPERS
;= ################

!ifdef TOOLCHAINS_ANY

; ${Toolchain::AddPath} Folder
; Adds a folder (or several, separated by semicolons) after the ones already
; collected, so it comes before the existing PATH but after earlier toolchains.
; The list is kept in the launcher's PAC:ToolchainsPath variable rather than an
; NSIS string, so it isn't cut off at NSIS_MAX_STRLEN.
!define Toolchain::AddPath `!insertmacro _Toolchain::AddPath`
!macro _Toolchain::AddPath _DIR
	Push `${_DIR}`
	Call Toolchains_AddPath
!macroend

; ${Toolchain::ResetPath}
; Empties the list, so one inherited from another launcher is never used.
!define Toolchain::ResetPath `!insertmacro _Toolchain::ResetPath`
!macro _Toolchain::ResetPath
	System::Call `kernel32::SetEnvironmentVariableW(w "PAC:ToolchainsPath", p 0)`
!macroend

; ${Toolchain::Enabled} Toolchain $var
; true unless the user (or the package) set Enabled=false in [Toolchain].
!define Toolchain::Enabled `!insertmacro _Toolchain::Enabled`
!macro _Toolchain::Enabled _TC _VAR
	${ReadCustomConfig} ${_VAR} `${_TC}` Enabled true
	${IfThen} ${_VAR} != false ${|} StrCpy ${_VAR} true ${|}
!macroend

; ${Toolchain::DataDir} Toolchain $var
; The toolchain's own folder in the package's Data.
!define Toolchain::DataDir `!insertmacro _Toolchain::DataDir`
!macro _Toolchain::DataDir _TC _VAR
	StrCpy ${_VAR} `$DataDirectory\Toolchains\${_TC}`
!macroend

; ${Toolchain::Seed} Toolchain
; Copies App\DefaultData\Toolchains\<Name> to Data\Toolchains\<Name> the first
; time, so a package can ship a starting .gitconfig, .npmrc and so on.
!define Toolchain::Seed `!insertmacro _Toolchain::Seed`
!macro _Toolchain::Seed _TC
	${IfNot} ${FileExists} `$DataDirectory\Toolchains\${_TC}\*.*`
	${AndIf} ${FileExists} `${DEFDATA}\Toolchains\${_TC}\*.*`
		CreateDirectory `$DataDirectory\Toolchains\${_TC}`
		CopyFiles /SILENT `${DEFDATA}\Toolchains\${_TC}\*.*` `$DataDirectory\Toolchains\${_TC}`
	${EndIf}
!macroend

; ${Toolchain::JournalDir} Toolchain Folder
; A folder in the user profile that a tool creates when it doesn't honor the
; toolchain's variables. Journaled only when it isn't there yet, so it is
; removed again with what the session put in it, and a folder that was
; already there is never touched.
!define Toolchain::JournalDir `!insertmacro _Toolchain::JournalDir`
!macro _Toolchain::JournalDir _TC _DIR
	${IfNot} ${FileExists} `${_DIR}\*.*`
		${Journal::Record} `${_TC}` DIR `${_DIR}` "" recursive ""
	${EndIf}
!macroend

; The buffers below are sized from the variables themselves, so PATH may be
; longer than NSIS strings can hold. Strings are passed in registers (w r0)
; rather than inline, so the call itself can't be cut off either. The wide
; (W) functions are named, so the buffers are always UTF-16.
Function Toolchains_AddPath
	Exch $0
	Push $1
	Push $2
	Push $3
	StrLen $1 $0
	; The size of the list with its terminating null, or 0 when it's empty.
	System::Call `kernel32::GetEnvironmentVariableW(w "PAC:ToolchainsPath", p 0, i 0)i.r2`
	IntOp $3 $1 + $2
	IntOp $3 $3 + 1
	IntOp $3 $3 * 2
	; Zero-filled, so it starts as an empty string.
	System::Alloc $3
	Pop $3
	${If} $3 <> 0
		${If} $2 > 1
			System::Call `kernel32::GetEnvironmentVariableW(w "PAC:ToolchainsPath", p r3, i r2)`
			System::Call `kernel32::lstrcatW(p r3, w ";")`
		${EndIf}
		System::Call `kernel32::lstrcatW(p r3, w r0)`
		System::Call `kernel32::SetEnvironmentVariableW(w "PAC:ToolchainsPath", p r3)`
		System::Free $3
	${EndIf}
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Puts the collected folders in front of PATH for the app, then empties the
; list, so a launcher the app starts doesn't add them a second time.
Function Toolchains_ApplyPath
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	System::Call `kernel32::GetEnvironmentVariableW(w "PAC:ToolchainsPath", p 0, i 0)i.r0`
	${If} $0 > 1
		System::Call `kernel32::GetEnvironmentVariableW(w "PATH", p 0, i 0)i.r1`
		; Both sizes count a terminating null: one makes room for the
		; semicolon, the other for the null at the end.
		IntOp $2 $0 + $1
		IntOp $2 $2 * 2
		System::Alloc $2
		Pop $3
		${If} $3 <> 0
			System::Call `kernel32::GetEnvironmentVariableW(w "PAC:ToolchainsPath", p r3, i r0)i.r4`
			${If} $1 > 1
				System::Call `kernel32::lstrcatW(p r3, w ";")`
				IntOp $4 $4 + 1
				IntOp $4 $4 * 2
				IntPtrOp $4 $3 + $4
				System::Call `kernel32::GetEnvironmentVariableW(w "PATH", p r4, i r1)`
			${EndIf}
			System::Call `kernel32::SetEnvironmentVariableW(w "PATH", p r3)`
			System::Free $3
		${EndIf}
		!ifdef DEBUG
			ReadEnvStr $0 PATH
			${DebugMsg} "PATH with the toolchains' folders: $0"
		!endif
	${EndIf}
	${Toolchain::ResetPath}
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

!endif ; TOOLCHAINS_ANY

; Include the toolchains
!include Toolchains\*.nsh
