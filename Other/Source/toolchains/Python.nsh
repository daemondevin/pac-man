;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; TOOLCHAIN
;	Python.nsh
;	Puts a portable Python on PATH for the app and keeps the packages you
;	install with pip --user, and pip's cache, in the package.
;
;	[Python]
;		Enabled=true                    false turns it off
;		Path=%PAL:CommonFiles%\Python   the folder with python.exe
;		Redirect=true                   PYTHONUSERBASE and PIP_CACHE_DIR in
;		                                Data\Toolchains\Python
;		ClearCache=false                true empties pip's cache on exit
;

!ifdef TOOLCHAINS_PYTHON
Var PythonDir
Var PythonOn
Var PythonRedirect
Var PythonData

${SegmentFile}

${SegmentPre}
	StrCpy $PythonOn false
	${Toolchain::Enabled} Python $0
	${If} $0 == true
		${ReadCustomConfig} $PythonDir Python Path `%PAL:CommonFiles%\Python`
		${If} ${FileExists} `$PythonDir\python.exe`
			StrCpy $PythonOn true
			${ReadCustomConfig} $PythonRedirect Python Redirect true
			${Toolchain::DataDir} Python $PythonData
		${EndIf}
	${EndIf}
!macroend

${SegmentPrePrimary}
	${If} $PythonOn == true
	${AndIf} $PythonRedirect != false
		${Toolchain::Seed} Python
		${Toolchain::JournalDir} Python `$APPDATA\Python`
		${Toolchain::JournalDir} Python `$LOCALAPPDATA\pip`
	${EndIf}
!macroend

${SegmentPreExec}
	${If} $PythonOn == true
		; A PYTHONHOME from the computer would point this Python at another
		; one's standard library.
		System::Call `kernel32::SetEnvironmentVariable(t "PYTHONHOME", p 0)`
		${If} $PythonRedirect != false
			${SetEnvironmentVariablesPath} PYTHONUSERBASE $PythonData
			${SetEnvironmentVariablesPath} PIP_CACHE_DIR `$PythonData\pip-cache`
			; The user scripts folder is PythonXY\Scripts (PythonXY-32 for a
			; 32-bit Python) under the user base; Python itself knows which.
			nsExec::ExecToStack `"$PythonDir\python.exe" -m site --user-site`
			Pop $0
			Pop $1
			${If} $0 == 0
				${TrimNewLines} $1 $1
				${GetParent} $1 $1
				${If} $1 != ""
					${Toolchain::AddPath} `$1\Scripts`
				${EndIf}
			${EndIf}
		${EndIf}
		${Toolchain::AddPath} `$PythonDir;$PythonDir\Scripts`
	${EndIf}
!macroend

${SegmentPostPrimary}
	${If} $PythonOn == true
	${AndIf} $PythonRedirect != false
		${ReadCustomConfig} $0 Python ClearCache false
		${If} $0 == true
			RMDir /r `$PythonData\pip-cache`
		${EndIf}
	${EndIf}
	${Journal::Rollback} Python
!macroend

!endif
