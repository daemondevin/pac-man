;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Language.nsh
;   This file allows support for language handling and manipulates language variables.
; 

!ifndef _XML_LIB_
	!include XML.nsh
!endif

${SegmentFile}
${Segment.onInit}
	!ifmacrodef Lang
		!insertmacro Lang
	!endif
	ReadEnvStr $0 PortableAppsLocaleID
	${Switch} $0
		!insertmacro LanguageCases
			StrCpy $LANGUAGE $0
			${Break}
	${EndSwitch}
!macroend
${SegmentInit}
	!ifmacrodef LangInit
		!insertmacro LangInit
	!endif
	!ifndef DisablePAC:LanguageCustom
		ClearErrors
		ReadEnvStr $8 PAC:LanguageCustom
		${If} ${Errors}
			ReadEnvStr $R0 PortableAppsLanguageCode
			ReadEnvStr $R1 PAC:_IgnoreLanguage
			${If} $R0 == ""
			${OrIf} $R1 == true
				StrCpy $9 pap-missing
				${SetEnvironmentVariable} PAC:_IgnoreLanguage true
			${EndIf}
			${SetEnvironmentVariableDefault} PortableAppsLanguageCode en
			${SetEnvironmentVariableDefault} PortableAppsLocaleCode2 en
			${SetEnvironmentVariableDefault} PortableAppsLocaleCode3 eng
			${SetEnvironmentVariableDefault} PortableAppsLocaleglibc en_US
			${SetEnvironmentVariableDefault} PortableAppsLocaleID 1033
			${SetEnvironmentVariableDefault} PortableAppsLocaleWinName LANG_ENGLISH
			ReadEnvStr $R0 PortableAppsLocaleName
			${If} $R0 == ""
				ReadEnvStr $R0 PortableAppsLocaleWinName
				StrCpy $R0 $R0 "" 5
				${SetEnvironmentVariable} PortableAppsLocaleName $R0
			${EndIf}
			${If} $9 == pap-missing
				ClearErrors
				${ReadWrapperConfig} $R0 LanguageFile Type
				${ReadWrapperConfig} $R1 LanguageFile File
				${ParseLocations} $R1
				${IfNot} ${Errors}
				${AndIf} ${FileExists} $R1
					StrCpy $R8 ""
					${If} $R0 == ConfigRead
						${ReadWrapperConfig} $R2 LanguageFile Entry
						${IfNot} ${Errors}
							${ReadWrapperConfig} $R4 LanguageFile CaseSensitive
							${If} ${FileExists} $R1
								${If} $R4 == true
									${ConfigReadS} $R1 $R2 $R8
								${Else}
									${If} $R4 != false
									${AndIfNot} ${Errors}
										${InvalidValueError} [LanguageFile]:CaseSensitive $R4
									${EndIf}
									${ConfigRead} $R1 $R2 $R8
								${EndIf}
							${EndIf}
						${EndIf}
					${ElseIf} $R0 == INI
						${ReadWrapperConfig} $R2 LanguageFile Section
						${ReadWrapperConfig} $R3 LanguageFile Key
						${IfNot} ${Errors}
							ReadINIStr $R8 $R1 $R2 $R3
						${EndIf}
		!ifdef XML_ENABLED
					${ElseIf} $R0 == "XML attribute"
						${ReadWrapperConfig} $R2 LanguageFile XPath
						${ReadWrapperConfig} $R3 LanguageFile Attribute
						${IfNot} ${Errors}
							${If} ${FileExists} $R1
								${XMLReadAttrib} $R1 $R2 $R3 $R8
							${EndIf}
						${EndIf}
					${ElseIf} $R0 == "XML text"
						${ReadWrapperConfig} $R2 LanguageFile XPath
						${If} ${FileExists} $R1
							${XMLReadText} $R1 $R2 $R8
						${EndIf}
		!else
					${ElseIf} $R0 == "XML attribute"
					${OrIf} $R0 == "XML text"
						!insertmacro XML_WarnNotActivated [LanguageFile]
		!endif
					${Else}
						${InvalidValueError} [LanguageFile]:Type $R0
					${EndIf}
					${If} $R8 != ""
						ClearErrors
						${ReadWrapperConfig} $R0 LanguageFile TrimRight
						${IfNot} ${Errors}
							; See if it ends with this string.
							StrLen $R1 $R0
							StrCpy $R2 $R8 "" -$R1
							${If} $R2 == $R0              ; yes, it does,
								StrCpy $R8 $R8 -$1       ; so cut it off
							${EndIf}
						${EndIf}
						ClearErrors
						${ReadWrapperConfig} $R0 LanguageFile TrimLeft
						${IfNot} ${Errors}
							; See if it ends with this string.
							StrLen $R1 $R0
							StrCpy $R2 $R8 $R1
							${If} $R2 == $R0              ; yes, it does,
								StrCpy $R8 $R8 "" $R1    ; so cut it off
							${EndIf}
						${EndIf}
						${SetEnvironmentVariable} PAC:LanguageCustom $R8
					${EndIf}
				${EndIf}
			${EndIf}
			ClearErrors
			ReadEnvStr $8 PAC:LanguageCustom
			${If} ${Errors}
				${ReadWrapperConfig} $0 Language Base
				${If} $0 != ""
					${ParseLocations} $0
					ClearErrors
					${ReadWrapperConfig} $1 LanguageStrings $0
					${If} ${Errors}
						ClearErrors
						${ReadWrapperConfig} $1 Language Default
						${IfNot} ${Errors}
							${ParseLocations} $1
						${Else}
							StrCpy $1 $0
						${EndIf}
					${EndIf}
					${SetEnvironmentVariable} PAC:LanguageCustom $1
					${ReadWrapperConfig} $2 Language CheckIfExists
					${If} $2 != ""
						${ParseLocations} $2
						${IfNot} ${FileExists} $2
							${ReadWrapperConfig} $1 Language DefaultIfNotExists
							${ParseLocations} $1
							${SetEnvironmentVariable} PAC:LanguageCustom $1
						${EndIf}
					${EndIf}
				${EndIf}
			${EndIf}
		${EndIf}
	!endif
!macroend
