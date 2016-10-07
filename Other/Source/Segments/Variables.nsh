${SegmentFile}

; Macros {{{1
!define SetEnvironmentVariablesPath "!insertmacro SetEnvironmentVariablesPathCall"
!macro SetEnvironmentVariablesPathCall _VARIABLE_NAME _PATH
	Push "${_VARIABLE_NAME}"
	Push "${_PATH}"
	${CallArtificialFunction2} SetEnvironmentVariablesPath_
!macroend

!macro SetEnvironmentVariablesPath_
	/* This function sets environment variables with different formats for paths.
	 * For example:
	 *   ${SetEnvironmentVariablesPath} PortableApps.comAppDirectory $EXEDIR\App
	 * Will produce the following environment variables:
	 *   %PAL:AppDir%                      = X:\PortableApps\AppNamePortable\App
	 *   %PAL:AppDir:Forwardslash%         = X:/PortableApps/AppNamePortable/App
	 *   %PAL:AppDir:DoubleBackslash%      = X:\\PortableApps\\AppNamePortable\\App
	 *   %PAL:AppDir:QuadrupleBackslash%   = X:\\\\PortableApps\\\\AppNamePortable\\\\App
	 *   %PAL:AppDir:java.util.prefs%      = /X:///Portable/Apps///App/Name/Portable///App
	 */
	Exch $R0 ; path
	Exch
	Exch $R1 ; variable name

	Push $R2 ; forwardslash
	Push $R3 ; double backslash, quad backslash, java.util.prefs
	Push $R7 ; jup len
	Push $R8 ; jup pos
	Push $R9 ; jup char
	;=== Set the backslashes path as given (e.g. X:\PortableApps\AppNamePortable)
	${SetEnvironmentVariable} $R1 $R0
	;=== Make the forwardslashes path (e.g. X:/PortableApps/AppNamePortable)
	${WordReplace} $R0 \ / + $R2
	${SetEnvironmentVariable} "$R1:Forwardslash" $R2
	;=== Make the double backslashes path (e.g. X:\\PortableApps\\AppNamePortable)
	${WordReplace} $R0 \ \\ + $R3
	${SetEnvironmentVariable} "$R1:DoubleBackslash" $R3
	;=== Make the quadruple backslashes path (e.g. X:\\\\PortableApps\\\\AppNamePortable)
	${WordReplace} $R0 \ \\\\ + $R3
	${SetEnvironmentVariable} "$R1:QuadrupleBackslash" $R3
	;=== Make the java.util.prefs path
	; Based on the forwardslashes path, s/[^a-z:0-9]/\/&/g
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
		${OrIf} $R9 S== 0
		${OrIf} $R9 S== 1
		${OrIf} $R9 S== 2
		${OrIf} $R9 S== 3
		${OrIf} $R9 S== 4
		${OrIf} $R9 S== 5
		${OrIf} $R9 S== 6
		${OrIf} $R9 S== 7
		${OrIf} $R9 S== 8
		${OrIf} $R9 S== 9
			StrCpy $R3 $R3$R9
		${Else}
			StrCpy $R3 $R3/$R9
		${EndIf}
	${Next}
	${SetEnvironmentVariable} "$R1:java.util.prefs" $R3
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

!macro SetEnvironmentVariableFromEnvironmentVariableWithDefault _VARIABLE_NAME _ENVIRONMENT_VARIABLE _DEFAULT
	Push $R0
	ReadEnvStr $R0 "${_ENVIRONMENT_VARIABLE}"
	${IfThen} $R0 == "" ${|} StrCpy $R0 "${_DEFAULT}" ${|}
	${SetEnvironmentVariable} "${_VARIABLE_NAME}" $R0
	Pop $R0
!macroend
!define SetEnvironmentVariableFromEnvironmentVariableWithDefault "!insertmacro SetEnvironmentVariableFromEnvironmentVariableWithDefault"

!macro GetParentUNC path out ;{{{2
	; A variant of GetParent which deals appropriately with UNC paths, stopping
	; at the share level. While GetParent would turn \\server\share into
	; \\server, this leaves it as \\server\share.
	${GetRoot} `${path}` `${out}`
	${If} `${path}` != `${out}`
		${GetParent} `${path}` `${out}`
	${EndIf}
!macroend
!define GetParentUNC '!insertmacro GetParentUNC'

!macro ParseLocations VAR ;{{{2
	; Expands environment variables on a variable and provides a debug message
	; about it.

	; If we're a debug build, set up a variable for the "before" state so that
	; we can put the debug message in one message not two.
	${!getdebug}
	!ifdef DEBUG
		!ifndef _ParseLocations_Before
			Var /GLOBAL _ParseLocations_Before
			!define _ParseLocations_Before
		!endif
		StrCpy $_ParseLocations_Before ${VAR}
	!endif

	; Expand the environment variables and print the debug message
	ExpandEnvStrings ${VAR} ${VAR}
	${DebugMsg} "Environment variable expansion on $${VAR}:$\r$\nBefore: `$_ParseLocations_Before`$\r$\nAfter: `${VAR}`"
!macroend
!define ParseLocations "!insertmacro ParseLocations"

; !macro SetPortableApps.comPath {{{2
!define SetPortableApps.comPath "!insertmacro SetPortableApps.comPathCall"
!macro SetPortableApps.comPathCall _ID
	Push "${_ID}"
	${CallArtificialFunction} SetPortableApps.comPath_
!macroend

!macro SetPortableApps.comPath_
	; Set the PortableApps.com<ID> environment variable to an existing path based
	; on the following algorithm:
	;   - %PortableApps.com<ID>%
	;   - $EXEDIR\..\..\<ID>
	;   - %PAL:Drive%\<ID>
	;   - %PAL:Drive%

	Exch $R1
	Push $R0

	ClearErrors
	ReadEnvStr $R0 PortableApps.com$R1
	${IfNot} ${Errors}
	${AndIf} ${FileExists} $R0\*.*
		Nop
	${ElseIf} ${FileExists} $PortableAppsBaseDirectory\$R1
		StrCpy $R0 $PortableAppsBaseDirectory\$R1
	${ElseIf} ${FileExists} $CurrentDrive\$R1
		StrCpy $R0 $CurrentDrive\$R1
	${Else}
		StrCpy $R0 $CurrentDrive
	${EndIf}

	${SetEnvironmentVariablesPath} PortableApps.com$R1 $R0
	Pop $R0
	Exch $R1
!macroend

; Variables {{{1
Var AppDirectory
Var DataDirectory
Var PortableAppsDirectory

Var PortableAppsBaseDirectory
Var LastPortableAppsBaseDirectory

; Segments {{{1
${SegmentInit}
	;=== Initialise variables
	StrCpy $AppDirectory  $EXEDIR\App
	StrCpy $DataDirectory $EXEDIR\Data
	${SetEnvironmentVariablesPath} PAL:AppDir  $AppDirectory
	${SetEnvironmentVariablesPath} PAL:DataDir $DataDirectory
	; These may be changed in the RunLocally segment's Pre hook.

	${GetParentUNC} $EXEDIR $PortableAppsDirectory
	${SetEnvironmentVariablesPath} PAL:PortableAppsDir $PortableAppsDirectory

	${GetParentUNC} $PortableAppsDirectory $PortableAppsBaseDirectory
	${SetEnvironmentVariablesPath} PAL:PortableAppsBaseDir $PortableAppsBaseDirectory
	ClearErrors
	ReadINIStr $LastPortableAppsBaseDirectory $DataDirectory\settings\$AppIDSettings.ini PortableApps.comLauncherLastRunEnvironment PAL:LastPortableAppsBaseDir
	${IfNot} ${Errors}
		${SetEnvironmentVariablesPath} PAL:LastPortableAppsBaseDir $LastPortableAppsBaseDirectory
	${EndIf}

	${SetPortableApps.comPath} Documents
	${SetPortableApps.comPath} Pictures
	${SetPortableApps.comPath} Music
	${SetPortableApps.comPath} Videos

	; Language variables are in the Language segment

	SetShellVarContext all
	${SetEnvironmentVariablesPath} ALLUSERSAPPDATA $APPDATA
	SetShellVarContext current
	${SetEnvironmentVariablesPathFromEnvironmentVariable} ALLUSERSPROFILE
	${SetEnvironmentVariablesPathFromEnvironmentVariable} USERPROFILE
	${SetEnvironmentVariablesPath} LOCALAPPDATA $LOCALAPPDATA
	${SetEnvironmentVariablesPath} APPDATA $APPDATA
	${SetEnvironmentVariablesPath} DOCUMENTS $DOCUMENTS
!macroend

${SegmentPrePrimary}
	WriteINIStr $DataDirectory\settings\$AppIDSettings.ini PortableApps.comLauncherLastRunEnvironment PAL:LastPortableAppsBaseDir $PortableAppsBaseDirectory
!macroend
