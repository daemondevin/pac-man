Function dotNETCheck
	!define CheckDOTNET "!insertmacro _CheckDOTNET"
	!macro _CheckDOTNET _RESULT _VALUE
		Push `${_VALUE}`
		Call dotNETCheck
		Pop ${_RESULT}
	!macroend
	Exch $1
	Push $0
	Push $1
	
	${If} $1 == "4.7"
		StrCpy $R1 460798
	${ElseIf} $1 == "4.6.2"
		StrCpy $R1 394802
	${ElseIf} $1 == "4.6.1"
		StrCpy $R1 394254
	${ElseIf} $1 == "4.6"
		StrCpy $R1 393295
	${ElseIf} $1 == "4.5.2"
		StrCpy $R1 379893
	${ElseIf} $1 == "4.5.1"
		StrCpy $R1 378675
	${ElseIf} $1 == "4.5"
		StrCpy $R1 378389
	${Else}
		Goto dotNET_FALSE
	${EndIf}
	
	ReadRegDWORD $R0 HKLM `SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` `Release`
	IfErrors dotNET_FALSE
	
	IntCmp $R0 $R1 dotNET_TRUE dotNET_FALSE
	
	dotNET_TRUE:
	StrCpy $0 true
	Goto dotNET_END
	
	dotNET_FALSE:
	StrCpy $0 false
	SetErrors
	
	dotNET_END:	
	Pop $1
	Exch $0
FunctionEnd

${SegmentFile}
;!include DotNet.nsh
${SegmentInit}
	; If appinfo.ini\[Dependencies]:UsesDotNetVersion is not empty, search
	; for a .NET Framework install of the specified version. Valid version
	; numbers are:
	;
	;  - (1.0|1.1|2.0|3.0|3.5)[SP<n>]
	;  - 4.0[SP<n>][C|F]
	;
	; Added by demon.devin
	;  - (4.7|4.6.2|4.6.1|4.6|4.5.2|4.5.1|4.5)
	; 
	ReadINIStr $0 $EXEDIR\App\AppInfo\appinfo.ini Dependencies UsesDotNetVersion
	${If} $0 != ""
		${CheckDOTNET} $1 "$0"
		${If} ${Errors}
			${IfThen} $0 == 4.0 ${|} StrCpy $0 4.0C ${|}
			${If} ${HasDotNetFramework} $0
				; Required .NET version found
				${DebugMsg} ".NET Framework $0 found"
			${ElseIf} ${Errors}
				; Invalid .NET version
				${InvalidValueError} [Dependencies]:UsesDotNetVersion $0
			${Else}
				; Required .NET version not found
				${DebugMsg} "Unable to find .NET Framework $0"
				MessageBox MB_OK|MB_ICONSTOP `$(LauncherNoDotNet)`
				Quit
			${EndIf}
		${EndIf}
	${EndIf}
!macroend
