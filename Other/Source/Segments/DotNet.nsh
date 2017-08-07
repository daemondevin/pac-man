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
Function HasDotNETFramework
	!macro _HasDotNETFramework _a _b _t _f
		!insertmacro _LOGICLIB_TEMP
		Call HasDotNETFramework
		Pop $_LOGICLIB_TEMP
		!insertmacro _= $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
	!macroend
	!define HasDotNETFramework `"" HasDotNETFramework ""`
	!define NET `SOFTWARE\Microsoft\.NETFramework`
	!define POL `SOFTWARE\Microsoft\.NETFramework\policy`
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	ReadRegStr $4 HKLM `${NET}` InstallRoot
	Push $4
	Exch $EXEDIR
	Exch $EXEDIR
	Pop $4
	IfFileExists $4 0 +10
	StrCpy $0 0
	EnumRegKey $2 HKLM `${POL}` $0
	IntOp $0 $0 + 1
	StrCmpS $2 "" +6
	StrCpy $1 0
	EnumRegValue $3 HKLM `${POL}\$2` $1
	IntOp $1 $1 + 1
	StrCmpS $3 "" -6
	IfFileExists `$4\$2.$3` +3 -3
	StrCpy $0 0
	Goto +2
	StrCpy $0 1
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd

${SegmentFile}
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
/*	ReadINIStr $0 $EXEDIR\App\AppInfo\appinfo.ini Dependencies UsesDotNetVersion
	!define dotNETVersion "$0"
	${If} $0 != ""
		${CheckDOTNET} $1 "$0"
		${If} ${Errors}
			; ${IfNot} ${HasDotNet${dotNETVersion}}
				; MessageBox MB_ICONSTOP|MB_TOPMOST `${PORTABLEAPPNAME} requires Microsoft .NET Framework 2.0 or newer`
				; Call Unload
				; Quit
			; ${EndIf}
			; ${If} ${HasDotNetFramework} $0
			${If} ${HasDotNetFramework}
				MessageBox MB_OK|MB_ICONSTOP `$0`
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
		${Else}
			; Required .NET version found. Has 4.5 or above.
			${DebugMsg} "The required .NET Framework was found."
		${EndIf}
	${EndIf}
!macroend */

	ReadINIStr $0 $EXEDIR\App\AppInfo\appinfo.ini Dependencies UsesDotNetVersion
	${If} $0 <= "4.0"
		!define dotNETVersion "$0"
		${IfNot} ${HasDotNet${dotNETVersion}}
			${DebugMsg} "Unable to find .NET Framework ${dotNETVersion}." ; Required .NET version not found
			MessageBox MB_OK|MB_ICONSTOP `$(LauncherNoDotNet)`
			Quit
		${Else}
			${DebugMsg} ".NET Framework ${dotNETVersion} found." ; Required .NET version found. 4.0 or below.
		${EndIf}
	${ElseIf} $0 >= "4.5"
		${CheckDOTNET} $R0 $0
		IfErrors 0 +4
		${DebugMsg} "Unable to find .NET Framework $0" ; Required .NET version not found
		MessageBox MB_OK|MB_ICONSTOP `$(LauncherNoDotNet)`
		Quit
		${DebugMsg} "The required .NET Framework was found." ; Required .NET version found. Has 4.5 or above.
	${Else}
		; Invalid .NET version
		${InvalidValueError} [Dependencies]:UsesDotNetVersion $0
	${EndIf}
!macroend
