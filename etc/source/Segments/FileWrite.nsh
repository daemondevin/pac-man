;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   FileWrite.nsh
;   This file handles file writes and text replacements that are declared in the CompilerWrapper.ini file.
; 

${SegmentFile}
${SegmentPrePrimary}
	!ifmacrodef FileWrite
		!insertmacro FileWrite
	!endif
	StrCpy $R0 0
	${Do}
		IntOp $R0 $R0 + 1
		ClearErrors
		ReadINIStr $0 `${WRAPPER}` FileWrite$R0 Type
		ReadINIStr $7 `${WRAPPER}` FileWrite$R0 File
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		ExpandEnvStrings $0 $0
		ExpandEnvStrings $7 $7
		${If} $0 == ConfigWrite
			ReadINIStr $2 `${WRAPPER}` FileWrite$R0 Entry
			ReadINIStr $3 `${WRAPPER}` FileWrite$R0 Value
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			ExpandEnvStrings $2 $2
			ExpandEnvStrings $3 $3
			ClearErrors
			ReadINIStr $4 `${WRAPPER}` FileWrite$R0 CaseSensitive
			${If} $4 != true
			${AndIf} $4 != false
			${AndIfNot} ${Errors}
				MessageBox MB_OK|MB_ICONSTOP `ERROR: Invalid value '$4' for [FileWrite$R0]:CaseSensitive. Please refer to the Manual for valid values.`
				${Continue}
			${EndIf}
		${ElseIf} $0 == INI
			ReadINIStr $2 `${WRAPPER}` FileWrite$R0 Section
			ReadINIStr $3 `${WRAPPER}` FileWrite$R0 Key
			ReadINIStr $4 `${WRAPPER}` FileWrite$R0 Value
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			ExpandEnvStrings $2 $2
			ExpandEnvStrings $3 $3
			ExpandEnvStrings $4 $4
!ifdef XML_ENABLED
		${ElseIf} $0 == "XML attribute"
			ReadINIStr $R2 `${WRAPPER}` FileWrite$R0 XPath
			ReadINIStr $R3 `${WRAPPER}` FileWrite$R0 Attribute
			ReadINIStr $R4 `${WRAPPER}` FileWrite$R0 Value
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			ExpandEnvStrings $R2 $R2
			ExpandEnvStrings $R3 $R3
			ExpandEnvStrings $R4 $R4
		${ElseIf} $0 == "XML text"
			ReadINIStr $R2 `${WRAPPER}` FileWrite$R0 XPath
			ReadINIStr $R3 `${WRAPPER}` FileWrite$R0 Value
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			ExpandEnvStrings $R2 $R2
			ExpandEnvStrings $R3 $R3
!else
		${ElseIf} $0 == "XML attribute"
		${OrIf} $0 == "XML text"
			!insertmacro XML_WarnNotActivated [FileWrite$R0]
			${Continue}
!endif
!ifdef REPLACE
		${ElseIf} $0 == Replace
			ReadINIStr $2 `${WRAPPER}` FileWrite$R0 Find
			ReadINIStr $3 `${WRAPPER}` FileWrite$R0 Replace
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			ExpandEnvStrings $2 $2
			ExpandEnvStrings $3 $3
			ClearErrors
			ReadINIStr $4 `${WRAPPER}` FileWrite$R0 CaseSensitive
			StrCpy $5 skip
			${If} $4 == true
				${If} $2 S!= $3
					StrCpy $5 replace
				${EndIf}
			${Else}
				${If} $4 != false
				${AndIfNot} ${Errors}
					MessageBox MB_OK|MB_ICONSTOP `ERROR: Invalid value '$4' for [FileWrite$R0]:CaseSensitive. Please refer to the Manual for valid values.`
				${EndIf}
				${If} $2 != $3
					StrCpy $5 replace
				${EndIf}
			${EndIf}
			${If} $5 == skip
				${Continue}
			${EndIf}
!else
		${ElseIf} $0 == Replace
			MessageBox MB_OK|MB_ICONSTOP "To use Replace features for [FileWrite$R0] please add 'FileWriteReplace=true' to the AppInfo.ini"
			${Continue}
!endif
		${Else}
			MessageBox MB_OK|MB_ICONSTOP `ERROR: Invalid value '$0' for [FileWrite$R0]:Type. Please refer to the Manual for valid values.`
			${Continue}
		${EndIf}
		${ForEachFile} $R1 $R4 $7
			${If} $0 == ConfigWrite
				${If} $4 == true
					${ConfigWriteS} $R1 $2 $3 $R9
				${Else}
					${ConfigWrite} $R1 $2 $3 $R9
				${EndIf}
			${ElseIf} $0 == INI
				WriteINIStr $R1 $2 $3 $4
!ifdef XML_ENABLED
			${ElseIf} $0 == `XML attribute`
				nsisXML::create
				nsisXML::load $R1
				nsisXML::select $R2
				StrCmpS $2 0 0 +3
				SetErrors
				Goto +5
				nsisXML::setAttribute $R3 $R4
				nsisXML::release $1
				nsisXML::save $R1
				nsisXML::release $0
			${ElseIf} $0 == `XML text`
				nsisXML::create
				nsisXML::load $R1
				nsisXML::select $R2
				StrCmpS $2 0 0 +3
				SetErrors
				Goto +5
				nsisXML::setText $R3
				nsisXML::release $1
				nsisXML::save $R1
				nsisXML::release $0
!endif
!ifdef REPLACE
			${ElseIf} $0 == Replace
				ClearErrors
				ReadINIStr $5 `${WRAPPER}` FileWrite$R0 Encoding
				${If} ${Errors}
					FileOpen $9 $R1 r
					FileReadByte $9 $5
					FileReadByte $9 $6
					IntOp $5 $5 << 8
					IntOp $5 $5 + $6
					${IfThen} $5 = 0xFFFE ${|} StrCpy $5 UTF-16LE ${|}
					FileClose $9
				${ElseIf} $5 != UTF-16LE
				${AndIf} $5 != ANSI
					MessageBox MB_OK|MB_ICONSTOP `ERROR: Invalid value '$5' for [FileWrite$R0]:Encoding. Please refer to the Manual for valid values.`
				${EndIf}
				${If} $5 == UTF-16LE
					${If} $4 == true
						${ReplaceInFileUTF16LECS} $R1 $2 $3
					${Else}
						${ReplaceInFileUTF16LE} $R1 $2 $3
					${EndIf}
				${Else}
					${If} $4 == true
						${ReplaceInFileCS} $R1 $2 $3
					${Else}
						${ReplaceInFile} $R1 $2 $3
					${EndIf}
				${EndIf}
!endif
			${EndIf}
		${NextFile}
	${Loop}
	!ifmacrodef PostFileWrite
		!insertmacro PostFileWrite
	!endif
!macroend
