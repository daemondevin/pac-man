;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   ExecString.nsh
;   This file handles the $ExecString and prepares it before the wrapper can execute.
; 

${SegmentFile}
Var ExecString
!ifdef ExecAsUser
	Var Parameters
!endif
${SegmentPre}
	${If} $UsingJavaExecutable != true
		StrCpy $ExecString `"$AppDirectory\$ProgramExecutable"`
	${Else}
		StrCpy $ExecString `"$JavaDirectory\bin\$ProgramExecutable"`
	${EndIf}
	!ifmacrodef ExecString
		!insertmacro ExecString
	!endif
	!ifmacrodef CommandLineArguments
		!insertmacro CommandLineArguments
	!else
		ClearErrors
		ReadINIStr $0 `${WRAPPER}` Launch CommandLineArguments
		${IfNot} ${Errors}
			!ifmacrodef ParseCommandLineArguments
				!insertmacro ParseCommandLineArguments
			!endif
			ExpandEnvStrings $0 $0
			!ifdef ExecAsUser
				StrCpy $Parameters "$Parameters $0"
			!else
				StrCpy $ExecString "$ExecString $0"
			!endif
		${EndIf}
	!endif
	${GetParameters} $0
	!ifmacrodef ParseParameters
		!insertmacro ParseParameters
	!endif
	!ifdef UAC
		ClearErrors
		${GetOptions} $0 /UAC $1
		${IfNot} ${Errors}
			${WordReplace} $0 /UAC$1 "" + $0
			${Trim} $0 $0
		${EndIf}
		ClearErrors
		${GetOptions} $0 /NCRC $1
		${IfNot} ${Errors}
			${WordReplace} $0 /NCRC$1 "" + $0
			${Trim} $0 $0
		${EndIf}
	!endif
	${If} $0 != ""
		ClearErrors
		ReadINIStr $1 `${WRAPPER}` Launch WorkingDirectory
		${If} ${Errors}
			!ifdef ExecAsUser
				StrCpy $Parameters "$Parameters $0"
			!else
				StrCpy $ExecString "$ExecString $0"
			!endif
		${Else}
			ExpandEnvStrings $1 $1
			ClearErrors
			GetFullPathName $1 $0
			${If} ${Errors}
				!ifdef ExecAsUser
					StrCpy $Parameters "$Parameters $0"
				!else
					StrCpy $ExecString "$ExecString $0"
				!endif
			${Else}
				!ifdef ExecAsUser
					StrCpy $Parameters "$Parameters $1"
				!else
					StrCpy $ExecString "$ExecString $1"
				!endif
			${EndIf}
		${EndIf}
	${EndIf}
	${ConfigReads} `${CONFIG}` AdditionalParameters= $0
	${If} $0 != ""
		!ifmacrodef ParseAdditionalParameters
			!insertmacro ParseAdditionalParameters
		!endif
		ExpandEnvStrings $0 $0
		!ifdef ExecAsUser
			StrCpy $Parameters "$Parameters $0"
		!else
			StrCpy $ExecString "$ExecString $0"
		!endif
	${EndIf}
!macroend
