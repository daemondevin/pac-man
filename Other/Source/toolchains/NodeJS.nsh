;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; TOOLCHAIN
;	NodeJS.nsh
;	Puts a portable Node.js on PATH for the app and keeps npm's global
;	packages, cache and settings, and Corepack's package managers, in the
;	package.
;
;	[NodeJS]
;		Enabled=true                    false turns it off
;		Path=%PAL:CommonFiles%\NodeJS   the folder with node.exe
;		Redirect=true                   npm's prefix, cache and .npmrc,
;		                                COREPACK_HOME and the REPL history in
;		                                Data\Toolchains\NodeJS
;		ClearCache=false                true empties npm's cache on exit
;
;	npm reads npm_config_* variables like its own settings, so nothing is
;	written to %USERPROFILE%\.npmrc.
;

!ifdef TOOLCHAINS_NODEJS
Var NodeJSDir
Var NodeJSOn
Var NodeJSRedirect
Var NodeJSData

${SegmentFile}

${SegmentPre}
	StrCpy $NodeJSOn false
	${Toolchain::Enabled} NodeJS $0
	${If} $0 == true
		${ReadCustomConfig} $NodeJSDir NodeJS Path `%PAL:CommonFiles%\NodeJS`
		${If} ${FileExists} `$NodeJSDir\node.exe`
			StrCpy $NodeJSOn true
			${ReadCustomConfig} $NodeJSRedirect NodeJS Redirect true
			${Toolchain::DataDir} NodeJS $NodeJSData
		${EndIf}
	${EndIf}
!macroend

${SegmentPrePrimary}
	${If} $NodeJSOn == true
	${AndIf} $NodeJSRedirect != false
		${Toolchain::Seed} NodeJS
		; npm creates the prefix folder only when it installs something
		; global, and a missing one breaks "npm ls -g".
		CreateDirectory `$NodeJSData\npm`
		${Toolchain::JournalDir} NodeJS `$APPDATA\npm`
		${Toolchain::JournalDir} NodeJS `$APPDATA\npm-cache`
		${Toolchain::JournalDir} NodeJS `$LOCALAPPDATA\npm-cache`
		${Toolchain::JournalDir} NodeJS `$LOCALAPPDATA\node`
	${EndIf}
!macroend

${SegmentPreExec}
	${If} $NodeJSOn == true
		${If} $NodeJSRedirect != false
			${SetEnvironmentVariablesPath} npm_config_prefix `$NodeJSData\npm`
			${SetEnvironmentVariablesPath} npm_config_cache `$NodeJSData\npm-cache`
			${SetEnvironmentVariablesPath} npm_config_userconfig `$NodeJSData\.npmrc`
			${SetEnvironmentVariablesPath} COREPACK_HOME `$NodeJSData\corepack`
			${SetEnvironmentVariablesPath} NODE_REPL_HISTORY `$NodeJSData\.node_repl_history`
			; Global packages put their commands in the prefix itself on Windows.
			${Toolchain::AddPath} `$NodeJSData\npm`
		${EndIf}
		${Toolchain::AddPath} $NodeJSDir
	${EndIf}
!macroend

${SegmentPostPrimary}
	${If} $NodeJSOn == true
	${AndIf} $NodeJSRedirect != false
		${ReadCustomConfig} $0 NodeJS ClearCache false
		${If} $0 == true
			RMDir /r `$NodeJSData\npm-cache`
		${EndIf}
	${EndIf}
	${Journal::Rollback} NodeJS
!macroend

!endif
