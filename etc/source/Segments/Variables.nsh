;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Variables.nsh
;   This file configures all the applicable path variables for use during runtime.
; 

Function GetUNC
	!macro _GetUNC _PATH _RETURN
		Push `${_PATH}`
		Call GetUNC
		Pop `${_RETURN}`
	!macroend
	!define GetUNC `!insertmacro _GetUNC`
	Exch $0
	Push $1
	Push $2
	!ifdef NSIS_PTR_SIZE & NSIS_CHAR_SIZE
		System::Call `*(p,&t${NSIS_MAX_STRLEN} "")p.r2`
		!define /math BUFFER ${NSIS_CHAR_SIZE} * ${NSIS_MAX_STRLEN}
		!define /math UBUFFER ${BUFFER} + ${NSIS_PTR_SIZE}
		!undef BUFFER
		System::Call `mpr::WNetGetUniversalName(tr0,i1,p$2,*i${UBUFFER})i.r1`
	!else
		System::Call `*(i,&t${NSIS_MAX_STRLEN} "")i.r2`
		!define /math UBUFFER 4 + ${NSIS_MAX_STRLEN}
		System::Call `mpr::WNetGetUniversalNameA(tr0,i1,i$2,*i${UBUFFER})i.r1`
	!endif
	!undef UBUFFER
	IntCmpU 0 $1 0 END END
	System::Call `*$2(t.r0)`
	END:
	System::Free $2
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
;Function GetUNC
;	!define GetUNC `!insertmacro _GetUNC`
;	!macro _GetUNC _PATH _RETURN
;		Push `${_PATH}`
;		Call GetUNC
;		Pop `${_RETURN}`
;	!macroend
;	Exch $0
;	Push $1
;	Push $2
;	Push $3
;	Push $4
;	System::Call `*(&t${NSIS_MAX_STRLEN} '') i .r2`
;	System::Call `mpr::WNetGetUniversalName(t r0, i 1,i $2, *i ${NSIS_MAX_STRLEN} r3)i .r4`
;	IntCmp 0 $4 +3
;	StrCpy $1 $0
;	Goto Free
;	System::Call `*$2(t .r1)`
;	Free:
;	System::Free $2
;	Pop $4
;	Pop $3
;	Pop $2
;	Exch
;	Pop $1
;	Exch $0
;FunctionEnd
!macro _IsAdmin _a _b _t _f
	System::Call `kernel32::GetModuleHandle(t 'shell32.dll') i .s`
	System::Call `kernel32::GetProcAddress(i s, i 680) i .r0`
	System::Call `::$0() i .r0`
	!insertmacro _= $0 1 `${_t}` `${_f}`
!macroend
!define IsAdmin `"" IsAdmin ""`

${SegmentFile}

!define SetEnvironmentVariablesPath "!insertmacro SetEnvironmentVariablesPathCall"
!macro SetEnvironmentVariablesPathCall _VARIABLE_NAME _PATH
	Push "${_VARIABLE_NAME}"
	Push "${_PATH}"
	${CallArtificialFunction2} SetEnvironmentVariablesPath_
!macroend

!macro SetEnvironmentVariablesPath_
	/* This function sets environment variables with different formats for paths.
	 * For example:
	 *   ${SetEnvironmentVariablesPath} PortableAppsAppDirectory $EXEDIR\App
	 * Will produce the following environment variables:
	 *   %PAC:AppDir%                 = X:\PortableApps\AppNamePortable\App
	 *   %PAC:AppDir:Forwardslash%    = X:/PortableApps/AppNamePortable/App
	 *   %PAC:AppDir:DoubleBackslash% = X:\\PortableApps\\AppNamePortable\\App
	 *   %PAC:AppDir:java.util.prefs% = /X:///Portable/Apps///App/Name/Portable///App
	 */
	Exch $R0 ; path
	Exch
	Exch $R1 ; variable name

	Push $R2 ; forwardslash
	Push $R3 ; double backslash, java.util.prefs
	Push $R7 ; jup len
	Push $R8 ; jup pos
	Push $R9 ; jup char
	;=== Set the backslashes path as given (e.g. X:\PortableApps\AppNamePortable)
	${SetEnvironmentVariable} $R1 $R0
	;=== Make the forwardslashes path (e.g. X:/PortableApps/AppNamePortable)
	${WordReplace} $R0 \ / + $R2
	${SetEnvironmentVariable} "$R1:Forwardslash" $R2
	!ifmacrodef VariablePath
		!insertmacro VariablePath
	!endif
	;=== Make the double backslashes path (e.g. X:\\PortableApps\\AppNamePortable)
	${WordReplace} $R0 \ \\ + $R3
	${SetEnvironmentVariable} "$R1:DoubleBackslash" $R3
	!ifmacrodef CustomVariablePath
		!insertmacro CustomVariablePath
	!endif
	!ifdef JAVA
		;=== Make the java.util.prefs path
		; Based on the forwardslashes path, s/[^a-z:]/\/&/g
		StrCpy $R3 ""
		StrLen $R7 $R2
		IntOp $R7 $R7 - 1 ; base 0
		${For} $R8 0 $R7
			StrCpy $R9 $R2 1 $R8
			${If}   $R9 S== a
			${OrIf} $R9 S== b
			${OrIf} $R9 S== c
			${OrIf} $R9 S== d
			${OrIf} $R9 S== e
			${OrIf} $R9 S== f
			${OrIf} $R9 S== g
			${OrIf} $R9 S== h
			${OrIf} $R9 S== i
			${OrIf} $R9 S== j
			${OrIf} $R9 S== k
			${OrIf} $R9 S== l
			${OrIf} $R9 S== m
			${OrIf} $R9 S== n
			${OrIf} $R9 S== o
			${OrIf} $R9 S== p
			${OrIf} $R9 S== q
			${OrIf} $R9 S== r
			${OrIf} $R9 S== s
			${OrIf} $R9 S== t
			${OrIf} $R9 S== u
			${OrIf} $R9 S== v
			${OrIf} $R9 S== w
			${OrIf} $R9 S== x
			${OrIf} $R9 S== y
			${OrIf} $R9 S== z
			${OrIf} $R9 S== :
				StrCpy $R3 $R3$R9
			${Else}
				StrCpy $R3 $R3/$R9
			${EndIf}
		${Next}
		${SetEnvironmentVariable} "$R1:java.util.prefs" $R3
	!endif
	Pop $R9
	Pop $R8
	Pop $R7
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $R0
!macroend
!macro SetEnvironmentVariablesPathFromEnvironmentVariable _VARIABLE_NAME
	Push $R0
	ReadEnvStr $R0 "${_VARIABLE_NAME}"
	${SetEnvironmentVariablesPath} "${_VARIABLE_NAME}" $R0
	Pop $R0
!macroend
!define SetEnvironmentVariablesPathFromEnvironmentVariable "!insertmacro SetEnvironmentVariablesPathFromEnvironmentVariable"
!macro GetParentUNC path out
	${GetRoot} `${path}` `${out}`
	${If} `${path}` != `${out}`
		${GetParent} `${path}` `${out}`
	${EndIf}
!macroend
!define GetParentUNC '!insertmacro GetParentUNC'
!macro ParseLocations VAR
	ExpandEnvStrings ${VAR} ${VAR}
!macroend
!define ParseLocations "!insertmacro ParseLocations"
Var AppDirectory
Var DataDirectory
Var PortableAppsDirectory
Var PortableAppsCommonFiles
Var PortableAppsBaseDirectory
Var LastPortableAppsBaseDirectory

${SegmentInit}
	!ifmacrodef EnvironmentVariables
		!insertmacro EnvironmentVariables
	!endif
	StrCpy $AppDirectory `$EXEDIR\bin`
	StrCpy $DataDirectory `$EXEDIR\bin\Settings`
	${SetEnvironmentVariablesPath} PAC:AppDir  $AppDirectory
	${SetEnvironmentVariablesPath} PAC:DataDir $DataDirectory
	${GetParentUNC} $EXEDIR $PortableAppsDirectory
	StrCpy $PortableAppsCommonFiles $PortableAppsDirectory\CommonFiles
	${SetEnvironmentVariablesPath} PAC:PortableAppsDir $PortableAppsDirectory
	${SetEnvironmentVariablesPath} PAC:CommonFiles $PortableAppsDirectory\CommonFiles
	${GetParentUNC} $PortableAppsDirectory $PortableAppsBaseDirectory
	${SetEnvironmentVariablesPath} PAC:PortableAppsBaseDir $PortableAppsBaseDirectory
	ClearErrors
	ReadINIStr `$LastPortableAppsBaseDirectory` `${CONFIGINI}` PortableAppsCompilerLastRunEnvironment PAC:LastPortableAppsBaseDir
	${IfNot} ${Errors}
		${SetEnvironmentVariablesPath} PAC:LastPortableAppsBaseDir $LastPortableAppsBaseDirectory
	${EndIf}
	ReadEnvStr $0 PortableAppsDocuments
	${If} $0 == ""
	${OrIfNot} ${FileExists} $0
		${GetRoot} $EXEDIR $1
		StrCpy $0 `$1\Documents`
	${EndIf}
	${SetEnvironmentVariablesPath} PortableAppsDocuments $0
	ReadEnvStr $1 PortableAppsPictures
	${If} $1 == ""
	${OrIfNot} ${FileExists} $1
		StrCpy $1 `$0\Pictures`
	${EndIf}
	${SetEnvironmentVariablesPath} PortableAppsPictures $1
	ReadEnvStr $1 PortableAppsMusic
	${If} $1 == ""
	${OrIfNot} ${FileExists} $1
		StrCpy $1 `$0\Music`
	${EndIf}
	${SetEnvironmentVariablesPath} PortableAppsMusic $1
	ReadEnvStr $1 PortableAppsVideos
	${If} $1 == ""
	${OrIfNot} ${FileExists} $1
		StrCpy $1 `$0\Videos`
	${EndIf}
	${SetEnvironmentVariablesPath} PortableAppsVideos $1
	${SetEnvironmentVariablesPathFromEnvironmentVariable} ALLUSERSPROFILE
	${SetEnvironmentVariablesPathFromEnvironmentVariable} USERPROFILE
	${SetEnvironmentVariablesPath} LOCALAPPDATA $LOCALAPPDATA
	${SetEnvironmentVariablesPath} APPDATA $APPDATA
	${SetEnvironmentVariablesPath} DOCUMENTS $DOCUMENTS
	SetShellVarContext all
	${SetEnvironmentVariablesPath} ALLUSERSAPPDATA $APPDATA
	${SetEnvironmentVariablesPath} PROGRAMDATA $APPDATA
	SetShellVarContext current
	!ifmacrodef PostEnvironmentVariables
		!insertmacro PostEnvironmentVariables
	!endif
!macroend
${SegmentPrePrimary}
	WriteINIStr `${CONFIGINI}` ${PAC}LastRunEnvironment PAC:LastPortableAppsBaseDir `$PortableAppsBaseDirectory`
!macroend
