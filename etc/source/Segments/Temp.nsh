;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Temp.nsh
;   This file handles and configures $TEMP and %TEMP% variables for use during runtime.
; 

${SegmentFile}
Function RemoveLastDirectoryFromPath
	!macro _RemoveLastDirectoryFromPath _PATH
		Push ${_PATH}
		Call RemoveLastDirectoryFromPath
		Pop ${_PATH}
	!macroend
	!define RemoveLastDirectoryFromPath "!insertmacro _RemoveLastDirectoryFromPath"
	Exch $R0
	Push $R1
	Push $R2
	StrLen $R1 $R0
	IntOp $R1 $R1 - 1
	StrCpy $R2 $R0 1 $R1
	StrCmp $R2 ":" +4
	StrCmp $R2 "\" +2
	Goto -4
	StrCpy $R0 $R0 $R1
	Pop $R2
	Pop $R1
	Exch $R0
FunctionEnd
${Segment.onInit}
	ClearErrors
	ReadEnvStr $R0 PAC:_TEMP
	${If} ${Errors}
		!if ${RequestLevel} == ADMIN
			GetTempFileName $R0
			${RemoveLastDirectoryFromPath} $R0
			${SetEnvironmentVariable} TEMP $R0
			${SetEnvironmentVariable} TMP $R0
		!else
			!ifdef UAC
				GetTempFileName $R0
				${RemoveLastDirectoryFromPath} $R0
				${SetEnvironmentVariable} TEMP $R0
				${SetEnvironmentVariable} TMP $R0
			!else
				${SetEnvironmentVariable} TEMP $TEMP
				${SetEnvironmentVariable} TMP $TEMP
			!endif
		!endif
	${Else}
		${SetEnvironmentVariable} TEMP $R0
		${SetEnvironmentVariable} TMP $R0
	${EndIf}
!macroend
${SegmentInit}
	ClearErrors
	${ReadWrapperConfig} $R0 Launch CleanTemp
	${IfNot} ${Errors}
	${AndIf} $R0 != true
	${AndIf} $R0 != false
		${InvalidValueError} [Launch]:CleanTemp $R0
	${EndIf}
!macroend
${SegmentPre}
	${ReadWrapperConfig} $R0 Launch CleanTemp
	StrCmp $R0 false +12
	ClearErrors
	StrCmp $WaitForProgram false 0 +3
	StrCpy $R1 ${SET}\Temp
	Goto +3
	ReadEnvStr $R0 TMP
	StrCpy $R1 $R0\${APPNAME}Temp
	StrCmpS $SecondaryLaunch true +3
	IfFileExists $R1 0 +2
	RMDir /r $R1
	CreateDirectory $R1
	Goto +3
	ReadEnvStr $R0 TMP
	StrCpy $R1 $R0
	${SetEnvironmentVariablesPath} TEMP $R1
	${SetEnvironmentVariable} TMP $R1
	${SetEnvironmentVariable} PAC:_TEMP $R0
!macroend
${SegmentPostPrimary}
	!ifmacrodef TEMP
		!insertmacro TEMP
	!endif
	ReadEnvStr $R0 TMP
	${ReadWrapperConfig} $R1 Launch CleanTemp
	StrCmp $R1 false +3
	StrCmp $R0 "" +2
	RMDir /r $R0
!macroend
