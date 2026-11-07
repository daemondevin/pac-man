;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; TOOLCHAIN
;	Rust.nsh
;	Puts a portable Rust toolchain on PATH for the app and keeps Cargo's
;	home (installed tools, the registry, settings) in the package.
;
;	[Rust]
;		Enabled=true                  false turns it off
;		Path=%PAL:CommonFiles%\Rust   one of two layouts:
;		                              a standalone Rust, with bin\rustc.exe
;		                              a rustup install, with cargo\bin\rustup.exe
;		                              and its toolchains in rustup
;		Redirect=true                 CARGO_HOME in Data\Toolchains\Rust\.cargo
;		ClearCache=true               true deletes the downloaded crates
;		                              (registry\cache and registry\src) on exit
;
;	A rustup install is made portable by installing it with CARGO_HOME and
;	RUSTUP_HOME set to Path\cargo and Path\rustup. The launcher sets
;	RUSTUP_HOME back to Path\rustup, so its toolchains are shared by every
;	package that uses it.
;

!ifdef TOOLCHAINS_RUST
Var RustDir
Var RustOn
Var RustLayout
Var RustRedirect
Var RustData

${SegmentFile}

${SegmentPre}
	StrCpy $RustOn false
	${Toolchain::Enabled} Rust $0
	${If} $0 == true
		${ReadCustomConfig} $RustDir Rust Path `%PAL:CommonFiles%\Rust`
		${If} ${FileExists} `$RustDir\bin\rustc.exe`
			StrCpy $RustLayout standalone
			StrCpy $RustOn true
		${ElseIf} ${FileExists} `$RustDir\cargo\bin\rustup.exe`
			StrCpy $RustLayout rustup
			StrCpy $RustOn true
		${EndIf}
		${If} $RustOn == true
			${ReadCustomConfig} $RustRedirect Rust Redirect true
			${Toolchain::DataDir} Rust $RustData
		${EndIf}
	${EndIf}
!macroend

${SegmentPrePrimary}
	${If} $RustOn == true
	${AndIf} $RustRedirect != false
		${Toolchain::Seed} Rust
		${Toolchain::JournalDir} Rust `$PROFILE\.cargo`
		${Toolchain::JournalDir} Rust `$PROFILE\.rustup`
	${EndIf}
!macroend

${SegmentPreExec}
	${If} $RustOn == true
		${If} $RustLayout == rustup
			${SetEnvironmentVariablesPath} RUSTUP_HOME `$RustDir\rustup`
		${EndIf}
		${If} $RustRedirect != false
			; Tools installed with "cargo install" go first.
			${SetEnvironmentVariablesPath} CARGO_HOME `$RustData\.cargo`
			${Toolchain::AddPath} `$RustData\.cargo\bin`
		${ElseIf} $RustLayout == rustup
			${SetEnvironmentVariablesPath} CARGO_HOME `$RustDir\cargo`
		${EndIf}
		${If} $RustLayout == rustup
			${Toolchain::AddPath} `$RustDir\cargo\bin`
		${Else}
			${Toolchain::AddPath} `$RustDir\bin`
		${EndIf}
	${EndIf}
!macroend

${SegmentPostPrimary}
	${If} $RustOn == true
	${AndIf} $RustRedirect != false
		${ReadCustomConfig} $0 Rust ClearCache true
		${If} $0 == true
			RMDir /r `$RustData\.cargo\registry\cache`
			RMDir /r `$RustData\.cargo\registry\src`
		${EndIf}
	${EndIf}
	${Journal::Rollback} Rust
!macroend

!endif
