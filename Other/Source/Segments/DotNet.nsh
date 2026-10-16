;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
;   DotNet.nsh
;   This file provides support for checking if the system has the required .NET Framework.
; 

!ifdef DOTNET
Var DotNETVersion
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
	
	${If} $1 == "4.8.1"
		StrCpy $R1 533320
	${ElseIf} $1 == "4.8"
		StrCpy $R1 528040
	${ElseIf} $1 == "4.7.2"
		StrCpy $R1 461808
	${ElseIf} $1 == "4.7.1"
		StrCpy $R1 461308
	${ElseIf} $1 == "4.7"
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

${IncludeIfNotDefined} ___DOTNETVER__NSH___ DotNetVer.nsh

${SegmentFile}
${SegmentInit}
	; If appinfo.ini\[Dependencies]:UsesDotNetVersion is not empty, search
	; for a .NET Framework install of the specified version. Valid version
	; numbers are:
	;
	;  - (1.0|1.1|2.0|3.0|3.5)[SP<n>]
	;  - 4.0[SP<n>][C|F]
	;
	; Added by daemon.devin
	;  - (4.8.1|4.8|4.7.2|4.7.1|4.7|4.6.2|4.6.1|4.6|4.5.2|4.5.1|4.5)
	; 
	ReadINIStr $DotNETVersion "${INFOINI}" Dependencies UsesDotNetVersion
	; Versions are compared as versions, not integers ("4.5" is not 4).
	StrCpy $1 $DotNETVersion 3
	StrCpy $2 0
	${If} $DotNETVersion != ""
		${VersionCompare} $1 4.5 $2
	${EndIf}
	${If} $DotNETVersion == ""
		; Nothing to check.
	${ElseIf} $2 == 2
		StrCpy $0 false
		${Select} $1
			${Case} 1.0
				${IfThen} ${HasDotNet1.0} ${|} StrCpy $0 true ${|}
			${Case} 1.1
				${IfThen} ${HasDotNet1.1} ${|} StrCpy $0 true ${|}
			${Case} 2.0
				${IfThen} ${HasDotNet2.0} ${|} StrCpy $0 true ${|}
			${Case} 3.0
				${IfThen} ${HasDotNet3.0} ${|} StrCpy $0 true ${|}
			${Case} 3.5
				${IfThen} ${HasDotNet3.5} ${|} StrCpy $0 true ${|}
			${CaseElse}
				${IfThen} ${HasDotNet4.0} ${|} StrCpy $0 true ${|}
		${EndSelect}
		${If} $0 != true
			${DebugMsg} "Unable to find .NET Framework $DotNETVersion." ; Required .NET version not found
			MessageBox MB_OK|MB_ICONSTOP `$(LauncherNoDotNet)`
			Quit
		${Else}
			${DebugMsg} ".NET Framework $DotNETVersion found." ; Required .NET version found. 4.0 or below.
		${EndIf}
	${Else}
		Push $DotNETVersion
		Call dotNETCheck
		Pop $0
		${If} $0 == false
		${OrIf} ${Errors}
			${DebugMsg} "Unable to find .NET Framework $DotNETVersion" ; Required .NET version not found
			MessageBox MB_OK|MB_ICONSTOP `$(LauncherNoDotNet)`
			Quit
		${Else}
			${DebugMsg} "The required .NET Framework was found." ; Required .NET version found. Has 4.5 or above.
		${EndIf}
	${EndIf}
!macroend
!endif
