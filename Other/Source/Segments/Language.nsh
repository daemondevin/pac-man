${SegmentFile}
${Segment.onInit}
	!ifmacrodef Lang
		!insertmacro Lang
	!endif
	ReadEnvStr $0 PortableApps.comLocaleID
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
			ReadEnvStr $R0 PortableApps.comLanguageCode
			ReadEnvStr $R1 PAC:_IgnoreLanguage
			${If} $R0 == ""
			${OrIf} $R1 == true
				StrCpy $9 pap-missing
				${SetEnvironmentVariable} PAC:_IgnoreLanguage true
			${EndIf}
			${SetEnvironmentVariableDefault} PortableApps.comLanguageCode en
			${SetEnvironmentVariableDefault} PortableApps.comLocaleCode2 en
			${SetEnvironmentVariableDefault} PortableApps.comLocaleCode3 eng
			${SetEnvironmentVariableDefault} PortableApps.comLocaleglibc en_US
			${SetEnvironmentVariableDefault} PortableApps.comLocaleID 1033
			${SetEnvironmentVariableDefault} PortableApps.comLocaleWinName LANG_ENGLISH
			ReadEnvStr $R0 PortableApps.comLocaleName
			${If} $R0 == ""
				ReadEnvStr $R0 PortableApps.comLocaleWinName
				StrCpy $R0 $R0 "" 5
				${SetEnvironmentVariable} PortableApps.comLocaleName $R0
			${EndIf}
			${If} $9 == pap-missing
				ClearErrors
				${ReadLauncherConfig} $R0 LanguageFile Type
				${ReadLauncherConfig} $R1 LanguageFile File
				${ParseLocations} $R1
				${IfNot} ${Errors}
				${AndIf} ${FileExists} $R1
					StrCpy $R8 ""
					${If} $R0 == ConfigRead
						${ReadLauncherConfig} $R2 LanguageFile Entry
						${IfNot} ${Errors}
							${ReadLauncherConfig} $R4 LanguageFile CaseSensitive
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
						${ReadLauncherConfig} $R2 LanguageFile Section
						${ReadLauncherConfig} $R3 LanguageFile Key
						${IfNot} ${Errors}
							ReadINIStr $R8 $R1 $R2 $R3
						${EndIf}
		!ifdef XML_ENABLED
					${ElseIf} $R0 == "XML attribute"
						${ReadLauncherConfig} $R2 LanguageFile XPath
						${ReadLauncherConfig} $R3 LanguageFile Attribute
						${IfNot} ${Errors}
							${If} ${FileExists} $R1
								${XMLReadAttrib} $R1 $R2 $R3 $R8
							${EndIf}
						${EndIf}
					${ElseIf} $R0 == "XML text"
						${ReadLauncherConfig} $R2 LanguageFile XPath
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
						${ReadLauncherConfig} $R0 LanguageFile TrimRight
						${IfNot} ${Errors}
							; See if it ends with this string.
							StrLen $R1 $R0
							StrCpy $R2 $R8 "" -$R1
							${If} $R2 == $R0              ; yes, it does,
								StrCpy $R8 $R8 -$1       ; so cut it off
							${EndIf}
						${EndIf}
						ClearErrors
						${ReadLauncherConfig} $R0 LanguageFile TrimLeft
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
				${ReadLauncherConfig} $0 Language Base
				${If} $0 != ""
					${ParseLocations} $0
					ClearErrors
					${ReadLauncherConfig} $1 LanguageStrings $0
					${If} ${Errors}
						ClearErrors
						${ReadLauncherConfig} $1 Language Default
						${IfNot} ${Errors}
							${ParseLocations} $1
						${Else}
							StrCpy $1 $0
						${EndIf}
					${EndIf}
					${SetEnvironmentVariable} PAC:LanguageCustom $1
					${ReadLauncherConfig} $2 Language CheckIfExists
					${If} $2 != ""
						${ParseLocations} $2
						${IfNot} ${FileExists} $2
							${ReadLauncherConfig} $1 Language DefaultIfNotExists
							${ParseLocations} $1
							${SetEnvironmentVariable} PAC:LanguageCustom $1
						${EndIf}
					${EndIf}
				${EndIf}
			${EndIf}
		${EndIf}
	!endif
!macroend
