;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; TOOLCHAIN
;	Go.nsh
;	Puts a portable Go on PATH for the app and keeps GOPATH (installed
;	tools and the module cache), the build cache and go env settings in the
;	package.
;
;	[Go]
;		Enabled=true                false turns it off
;		Path=%PAL:CommonFiles%\Go   the folder with bin\go.exe (GOROOT)
;		Redirect=true               GOPATH, GOCACHE and GOENV in
;		                            Data\Toolchains\Go
;		ClearCache=false            true empties the build cache on exit
;

!ifdef TOOLCHAINS_GO
Var GoDir
Var GoOn
Var GoRedirect
Var GoData

${SegmentFile}

${SegmentPre}
	StrCpy $GoOn false
	${Toolchain::Enabled} Go $0
	${If} $0 == true
		${ReadCustomConfig} $GoDir Go Path `%PAL:CommonFiles%\Go`
		${If} ${FileExists} `$GoDir\bin\go.exe`
			StrCpy $GoOn true
			${ReadCustomConfig} $GoRedirect Go Redirect true
			${Toolchain::DataDir} Go $GoData
		${EndIf}
	${EndIf}
!macroend

${SegmentPrePrimary}
	${If} $GoOn == true
	${AndIf} $GoRedirect != false
		${Toolchain::Seed} Go
		${Toolchain::JournalDir} Go `$PROFILE\go`
		${Toolchain::JournalDir} Go `$LOCALAPPDATA\go-build`
		; Go's telemetry always writes to %APPDATA%\go\telemetry.
		${Toolchain::JournalDir} Go `$APPDATA\go`
	${EndIf}
!macroend

${SegmentPreExec}
	${If} $GoOn == true
		; A GOROOT from the computer would point this Go at another one's
		; standard library.
		${SetEnvironmentVariablesPath} GOROOT $GoDir
		${If} $GoRedirect != false
			${SetEnvironmentVariablesPath} GOPATH `$GoData\go`
			${SetEnvironmentVariablesPath} GOCACHE `$GoData\cache`
			${SetEnvironmentVariablesPath} GOENV `$GoData\env`
			; GOMODCACHE follows GOPATH unless the computer sets its own.
			System::Call `kernel32::SetEnvironmentVariable(t "GOMODCACHE", p 0)`
			${Toolchain::AddPath} `$GoData\go\bin`
		${EndIf}
		${Toolchain::AddPath} `$GoDir\bin`
	${EndIf}
!macroend

${SegmentPostPrimary}
	${If} $GoOn == true
	${AndIf} $GoRedirect != false
		${ReadCustomConfig} $0 Go ClearCache false
		${If} $0 == true
			RMDir /r `$GoData\cache`
		${EndIf}
	${EndIf}
	${Journal::Rollback} Go
!macroend

!endif
