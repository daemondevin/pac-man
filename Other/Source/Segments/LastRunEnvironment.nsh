; First, declare that this is a segment file.
${SegmentFile}


; Next, restore the saved values before [Environment] is parsed.
${SegmentPre}
	; First, load PAC's own last run environment
	${ForEachINIPairWithFile} $EXEDIR\Data\settings\$AppIDSettings.ini PortableAppsCompilerLastRunEnvironment $0 $1
		${DebugMsg} "Setting internal last run environment variable $0 to $1"
		; Treat all LREs as paths
		${SetEnvironmentVariablesPath} $0 $1
	${NextINIPairWithFile}

	; Read the keys from launcher.ini, not from $AppIDSettings.ini; this will allow the developer to update the loaded variables.
	${ForEachINIPair} LastRunEnvironment $0 $1
		; Check for a directory variable
		StrCpy $2 $0 1 -1
		${If} $2 == ~
			StrCpy $0 $0 -1 ; Strip the last character from the key
		${EndIf}

		ClearErrors
		${ReadLastRunEnvironmentVariable} $1 $0
		${IfNot} ${Errors}
			${If} $2 == ~
				${SetEnvironmentVariablesPath} $0 $1
			${Else}
				${SetEnvironmentVariable} $0 $1
			${EndIf}
		${EndIf}
	${NextINIPair}
!macroend


${SegmentPrePrimary}
	; Write some internal LREs not written anywhere else
	!insertmacro _LastRunEnvironment_WriteInternalFromEnvironmentVariable PAC:LastAppDirectory                       PAC:AppDir
	!insertmacro _LastRunEnvironment_WriteInternalFromEnvironmentVariable PAC:LastDataDirectory                      PAC:DataDir
	!insertmacro _LastRunEnvironment_WriteInternalFromEnvironmentVariable PAC:LastPortableAppsDirectory              PAC:PortableAppsDir
	!insertmacro _LastRunEnvironment_WriteInternalFromEnvironmentVariable PAC:LastPortableAppsDocumentsDirectory PortableAppsDocuments
	!insertmacro _LastRunEnvironment_WriteInternalFromEnvironmentVariable PAC:LastPortableAppsPicturesDirectory  PortableAppsPictures
	!insertmacro _LastRunEnvironment_WriteInternalFromEnvironmentVariable PAC:LastPortableAppsMusicDirectory     PortableAppsMusic
	!insertmacro _LastRunEnvironment_WriteInternalFromEnvironmentVariable PAC:LastPortableAppsVideosDirectory    PortableAppsVideos
!macroend


; And finally, save the persistent data after [Environment] is processed.
${SegmentPreExecPrimary}
	${ForEachINIPair} LastRunEnvironment $0 $1
		; Check for a directory variable
		StrCpy $2 $0 1 -1
		${If} $2 == ~
			StrCpy $0 $0 -1 ; Strip the last character from the key
		${EndIf}
		${WriteLastRunEnvironmentVariable} $0 $1
	${NextINIPair}
!macroend


; Also provide a way for custom code to get and set persistent variables
!macro ReadLastRunEnvironmentVariable out var
	${DebugMsg} "Reading last run environment variable ${var} into $${out}"
	ReadINIStr ${out} $DataDirectory\settings\$AppIDSettings.ini LastRunEnvironment `${var}`
!macroend
!define ReadLastRunEnvironmentVariable "!insertmacro ReadLastRunEnvironmentVariable"
!macro WriteLastRunEnvironmentVariable var value
	Push $R0
	ExpandEnvStrings $R0 `${value}`
	${DebugMsg} "Environment variable expansion on $$R0:$\r$\nBefore: `${value}`$\r$\nAfter: `$R0`"
	${DebugMsg} "Persisting environment variable ${var} with value `$R0`"
	WriteINIStr $DataDirectory\settings\$AppIDSettings.ini LastRunEnvironment `${var}` $R0
	Pop $R0
!macroend
!define WriteLastRunEnvironmentVariable "!insertmacro WriteLastRunEnvironmentVariable"


; And automatize the writing of internal LREs from environment variables
!macro _LastRunEnvironment_WriteInternalFromEnvironmentVariable name envvar
	ReadEnvStr $R0 `${envvar}`
	${DebugMsg} "Saving internal last run environment variable `${name}` from `${envvar}` as `$R0`"
	WriteINIStr $DataDirectory\settings\$AppIDSettings.ini PortableAppsCompilerLastRunEnvironment `${name}` $R0
!macroend
