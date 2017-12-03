;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   LastRunEnvironment.nsh
;   This file provides a way for custom code to get and set persistent variables.
; 

!macro ReadLastRunEnvironmentVariable out var
	${DebugMsg} "Reading last run environment variable ${var} into $${out}"
	ReadINIStr ${out} ${CONFIGINI} LastRunEnvironment `${var}`
!macroend
!define ReadLastRunEnvironmentVariable "!insertmacro ReadLastRunEnvironmentVariable"
!macro WriteLastRunEnvironmentVariable var value
	Push $R0
	ExpandEnvStrings $R0 `${value}`
	${DebugMsg} "Environment variable expansion on $$R0:$\r$\nBefore: `${value}`$\r$\nAfter: `$R0`"
	${DebugMsg} "Persisting environment variable ${var} with value `$R0`"
	WriteINIStr ${CONFIGINI} LastRunEnvironment `${var}` $R0
	Pop $R0
!macroend
!define WriteLastRunEnvironmentVariable "!insertmacro WriteLastRunEnvironmentVariable"
!macro _LastRunEnvironment_WriteInternalFromEnvironmentVariable name envvar
	ReadEnvStr $R0 `${envvar}`
	${DebugMsg} "Saving internal last run environment variable `${name}` from `${envvar}` as `$R0`"
	WriteINIStr ${CONFIGINI} PortableAppsCompilerLastRunEnvironment `${name}` $R0
!macroend
!define LREWriteFromEV "!insertmacro _LastRunEnvironment_WriteInternalFromEnvironmentVariable"

${SegmentFile}
${SegmentPre}
	; First, load PAC's own last run environment
	${ForEachINIPairWithFile} ${CONFIGINI} PortableAppsCompilerLastRunEnvironment $0 $1
		${DebugMsg} "Setting internal last run environment variable $0 to $1"
		; Treat all LREs as paths
		${SetEnvironmentVariablesPath} $0 $1
	${NextINIPairWithFile}

	; Read the keys from CompilerWrapper.ini; this will allow the developer to update the loaded variables.
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
	${LREWriteFromEV} PAC:LastAppDirectory						PAC:AppDir
	${LREWriteFromEV} PAC:LastDataDirectory						PAC:DataDir
	${LREWriteFromEV} PAC:LastPortableAppsDirectory				PAC:PortableAppsDir
	${LREWriteFromEV} PAC:LastPortableAppsDocumentsDirectory	PortableAppsDocuments
	${LREWriteFromEV} PAC:LastPortableAppsPicturesDirectory		PortableAppsPictures
	${LREWriteFromEV} PAC:LastPortableAppsMusicDirectory		PortableAppsMusic
	${LREWriteFromEV} PAC:LastPortableAppsVideosDirectory		PortableAppsVideos
!macroend
${SegmentPreExecPrimary}
	; And finally, save the persistent data after [Environment] is processed.
	${ForEachINIPair} LastRunEnvironment $0 $1
		; Check for a directory variable
		StrCpy $2 $0 1 -1
		${If} $2 == ~
			StrCpy $0 $0 -1 ; Strip the last character from the key
		${EndIf}
		${WriteLastRunEnvironmentVariable} $0 $1
	${NextINIPair}
!macroend
