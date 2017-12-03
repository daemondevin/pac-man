;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   InstanceManagement.nsh
;   This file handles the launch of a secondary instance of an application.
; 

Var SecondaryLaunch
!macro _InstanceManagement_QuitIfRunning
	${If} $SecondaryLaunch != true
	${AndIf} ${ProcessExists} $0
		MessageBox MB_ICONSTOP|MB_TOPMOST `$(LauncherAlreadyRunning)`
		Quit
	${EndIf}
!macroend
${SegmentFile}
${SegmentInit}
	System::Call 'kernel32::CreateMutex(i0,i0,t"${APPNAME}-${APPNAME}")?e'
	Pop $0
	!ifmacrodef InstanceManagement
		!insertmacro InstanceManagement
	!else
		${IfNot} $0 = 0
			ClearErrors
			${ReadWrapperConfig} $0 Launch SinglePortableAppInstance
			${If} $0 == true
				Quit
			${ElseIf} $0 != false
			${AndIfNot} ${Errors}
				${InvalidValueError} [Launch]:SinglePortableAppInstance $0
			${EndIf}
			StrCpy $SecondaryLaunch true
			StrCpy $WaitForProgram false
		${EndIf}
	!endif
	ClearErrors
	${ReadWrapperConfig} $0 Launch SingleAppInstance
	${If} $0 == true
	${OrIf} ${Errors}
		${IfNot} $UsingJavaExecutable == true
			${GetFileName} $ProgramExecutable $0
			!insertmacro _InstanceManagement_QuitIfRunning
		${EndIf}
	${ElseIf} $0 != false
		${InvalidValueError} [Launch]:SingleAppInstance $0
	${EndIf}
	ClearErrors
	${ReadWrapperConfig} $0 Launch CloseEXE
	${IfNot} ${Errors}
		!insertmacro _InstanceManagement_QuitIfRunning
	${EndIf}
	!ifmacrodef CloseEXE
		!insertmacro CloseEXE
	!endif
	${If} $WaitForProgram == ""
		ClearErrors
		${ReadWrapperConfig} $WaitForProgram Launch WaitForProgram
		${IfNot} ${Errors}
		${AndIf} $WaitForProgram != true
		${AndIf} $WaitForProgram != false
			${InvalidValueError} [Launch]:WaitForProgram $WaitForProgram
		${EndIf}
	${EndIf}
	!ifmacrodef EXE
		!insertmacro EXE
	!endif
	${IfNot} ${FileExists} `$EXEDIR\bin\$ProgramExecutable`
	${AndIfNot} $UsingJavaExecutable == true
		StrCpy $MissingFileOrPath `bin\$ProgramExecutable`
		MessageBox MB_ICONSTOP|MB_TOPMOST `$(LauncherFileNotFound)`
		Quit
	${EndIf}
!macroend
