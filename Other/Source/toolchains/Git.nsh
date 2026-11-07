;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; TOOLCHAIN
;	Git.nsh
;	Puts a portable Git (PortableGit) on PATH for the app and keeps its
;	global configuration in the package.
;
;	[Git]
;		Enabled=true                  false turns it off
;		Path=%PAL:CommonFiles%\Git    the folder with cmd\git.exe
;		Redirect=true                 GIT_CONFIG_GLOBAL in Data\Toolchains\Git
;		Home=false                    true also moves HOME there (.ssh,
;		                              .bash_history, credentials files)
;

!ifdef TOOLCHAINS_GIT
Var GitDir
Var GitOn
Var GitRedirect
Var GitHome
Var GitData

${SegmentFile}

${SegmentPre}
	StrCpy $GitOn false
	${Toolchain::Enabled} Git $0
	${If} $0 == true
		${ReadCustomConfig} $GitDir Git Path `%PAL:CommonFiles%\Git`
		${If} ${FileExists} `$GitDir\cmd\git.exe`
			StrCpy $GitOn true
			${ReadCustomConfig} $GitRedirect Git Redirect true
			${ReadCustomConfig} $GitHome Git Home false
			${Toolchain::DataDir} Git $GitData
		${EndIf}
	${EndIf}
!macroend

${SegmentPrePrimary}
	${If} $GitOn == true
		; A freshly unpacked PortableGit finishes its setup once with this
		; script, which deletes itself when done.
		${If} ${FileExists} `$GitDir\post-install.bat`
			ExpandEnvStrings $0 %COMSPEC%
			nsExec::Exec `"$0" /C ""$GitDir\post-install.bat""`
			Pop $0
		${EndIf}
		${If} $GitRedirect != false
			${Toolchain::Seed} Git
			CreateDirectory $GitData
			${If} $GitHome != true
				; credential.helper=store writes passwords in plain text to HOME.
				${IfNot} ${FileExists} `$PROFILE\.git-credentials`
					${Journal::Record} Git FILE `$PROFILE\.git-credentials` "" "" ""
				${EndIf}
			${EndIf}
		${EndIf}
	${EndIf}
!macroend

${SegmentPreExec}
	${If} $GitOn == true
		${Toolchain::AddPath} `$GitDir\cmd`
		${If} $GitRedirect != false
			${SetEnvironmentVariablesPath} GIT_CONFIG_GLOBAL `$GitData\.gitconfig`
			${If} $GitHome == true
				CreateDirectory `$GitData\home`
				${SetEnvironmentVariablesPath} HOME `$GitData\home`
			${EndIf}
		${EndIf}
	${EndIf}
!macroend

${SegmentPostPrimary}
	${Journal::Rollback} Git
!macroend

!endif
