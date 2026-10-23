;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; HelpFile.nsh
;	Writes the package's help.html from Other\Source\HelpTemplate.html, filled
;	in with the package's details. Used by LauncherCompiler.nsi after a
;	launcher compiles.
;
;	help.html is written when the package has none, when its help.html was
;	generated before (it carries the pac-man:help-generated marker), or when
;	it is the old PortableApps.com help template; that one is first copied to
;	Other\Source\help.original.html. Any other help.html was written by hand
;	and is left alone.
;
;	See the comment at the top of HelpTemplate.html for the words it
;	replaces and the IF blocks it understands.
;
; USAGE
;	${Help::Generate} PackageDir AppID PortableName AppName TemplateFile
;

!ifndef HELPFILE_NSH_INCLUDED
!define HELPFILE_NSH_INCLUDED

!include LogicLib.nsh
!include WordFunc.nsh

!define HELP_MARKER `pac-man:help-generated`
!define HELP_PAF_MARKER `Help_Logo_Top.png`

Var HelpPackage
Var HelpAppID
Var HelpPName
Var HelpAppName
Var HelpTemplate
Var HelpAppInfo
Var HelpLauncherIni
Var HelpLauncher
Var HelpDescription
Var HelpHomepage
Var HelpVersion
Var HelpPackager

!macro _Help::Generate _PACKAGE _APPID _PNAME _APPNAME _TEMPLATE
	Push `${_TEMPLATE}`
	Push `${_APPNAME}`
	Push `${_PNAME}`
	Push `${_APPID}`
	Push `${_PACKAGE}`
	Call Help_Generate
!macroend
!define Help::Generate `!insertmacro _Help::Generate`

; Sets $0 to true when file $1 contains the text $2, else false.
Function Help_FileHas
	Push $3
	Push $4
	StrCpy $0 false
	ClearErrors
	FileOpen $3 $1 r
	${IfNot} ${Errors}
		${Do}
			ClearErrors
			FileRead $3 $4
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			ClearErrors
			${WordFind} $4 $2 "E*" $4
			${IfNot} ${Errors}
				StrCpy $0 true
				${ExitDo}
			${EndIf}
		${Loop}
		FileClose $3
	${EndIf}
	ClearErrors
	Pop $4
	Pop $3
FunctionEnd

; Sets $0 to $0 with &, <, > and " written as HTML entities.
Function Help_Escape
	Push $1
	Push $2
	Push $3
	StrCpy $1 ""
	StrCpy $2 0
	${Do}
		StrCpy $3 $0 1 $2
		${IfThen} $3 == "" ${|} ${ExitDo} ${|}
		${If} $3 == "&"
			StrCpy $3 "&amp;"
		${ElseIf} $3 == "<"
			StrCpy $3 "&lt;"
		${ElseIf} $3 == ">"
			StrCpy $3 "&gt;"
		${ElseIf} $3 == '"'
			StrCpy $3 "&quot;"
		${EndIf}
		StrCpy $1 "$1$3"
		IntOp $2 $2 + 1
	${Loop}
	StrCpy $0 $1
	Pop $3
	Pop $2
	Pop $1
FunctionEnd

; Sets $0 to the escaped value of key $2 in section $1 of appinfo.ini.
Function Help_AppInfo
	ClearErrors
	ReadINIStr $0 $HelpAppInfo $1 $2
	${IfThen} ${Errors} ${|} StrCpy $0 "" ${|}
	ClearErrors
	Call Help_Escape
FunctionEnd

; Sets $0 to true or false for the IF block named $1.
Function Help_Condition
	Push $2
	Push $3
	StrCpy $0 false
	${Select} $1
		${Case} Description
			${IfThen} $HelpDescription != "" ${|} StrCpy $0 true ${|}
		${Case} Homepage
			${IfThen} $HelpHomepage != "" ${|} StrCpy $0 true ${|}
		${Case} Version
			${IfThen} $HelpVersion != "" ${|} StrCpy $0 true ${|}
		${Case} Packager
			${IfThen} $HelpPackager != "" ${|} StrCpy $0 true ${|}
		${Case} MissingApp
			ReadINIStr $2 $HelpLauncherIni Activate MissingApp
			${If} $2 != ""
			${AndIf} $2 != false
				StrCpy $0 true
			${EndIf}
		${Case} Admin
			ReadINIStr $2 $HelpLauncherIni Launch RunAsAdmin
			${If} $2 == force
			${OrIf} $2 == compile-force
				StrCpy $0 true
			${EndIf}
		${CaseElse}
			; The licence blocks: exactly one of the three is kept.
			ReadINIStr $2 $HelpAppInfo License OpenSource
			ReadINIStr $3 $HelpAppInfo License Freeware
			${If} $1 == OpenSource
				${IfThen} $2 == true ${|} StrCpy $0 true ${|}
			${ElseIf} $1 == Freeware
				${If} $2 != true
				${AndIf} $3 == true
					StrCpy $0 true
				${EndIf}
			${ElseIf} $1 == Commercial
				${If} $2 != true
				${AndIf} $3 != true
					StrCpy $0 true
				${EndIf}
			${EndIf}
	${EndSelect}
	ClearErrors
	Pop $3
	Pop $2
FunctionEnd

; Writes $1 to the open file $2 as UTF-8.
Function Help_WriteUTF8
	Push $0
	Push $3
	Push $4
	System::Call `kernel32::WideCharToMultiByte(i 65001, i 0, w r1, i -1, p 0, i 0, p 0, p 0) i .r3`
	${If} $3 > 1
		System::Alloc $3
		Pop $4
		System::Call `kernel32::WideCharToMultiByte(i 65001, i 0, w r1, i -1, p r4, i r3, p 0, p 0)`
		; The count includes the terminating null, which isn't written.
		IntOp $3 $3 - 1
		System::Call `kernel32::WriteFile(p r2, p r4, i r3, *i .r0, p 0)`
		System::Free $4
	${EndIf}
	Pop $4
	Pop $3
	Pop $0
FunctionEnd

; Replaces every placeholder in $1.
Function Help_Fill
	${WordReplace} $1 "%%PortableName%%" $HelpPName "+" $1
	${WordReplace} $1 "%%AppName%%" $HelpAppName "+" $1
	${WordReplace} $1 "%%AppID%%" $HelpAppID "+" $1
	${WordReplace} $1 "%%Launcher%%" $HelpLauncher "+" $1
	${WordReplace} $1 "%%Description%%" $HelpDescription "+" $1
	${WordReplace} $1 "%%Homepage%%" $HelpHomepage "+" $1
	${WordReplace} $1 "%%Version%%" $HelpVersion "+" $1
	${WordReplace} $1 "%%Packager%%" $HelpPackager "+" $1
	ClearErrors
FunctionEnd

Function Help_Generate
	Pop $HelpPackage
	Pop $HelpAppID
	Pop $HelpPName
	Pop $HelpAppName
	Pop $HelpTemplate
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5

	StrCpy $HelpAppInfo `$HelpPackage\App\AppInfo\appinfo.ini`
	StrCpy $HelpLauncherIni `$HelpPackage\App\AppInfo\Launcher\$HelpAppID.ini`
	; $5 = help.html
	StrCpy $5 `$HelpPackage\help.html`

	${IfNot} ${FileExists} $HelpTemplate
		DetailPrint "help.html: no template at $HelpTemplate, skipped."
		Goto Help_Generate_End
	${EndIf}

	${If} ${FileExists} $5
		StrCpy $1 $5
		StrCpy $2 `${HELP_MARKER}`
		Call Help_FileHas
		${If} $0 != true
			StrCpy $2 `${HELP_PAF_MARKER}`
			Call Help_FileHas
			${If} $0 == true
				CreateDirectory `$HelpPackage\Other\Source`
				${IfNot} ${FileExists} `$HelpPackage\Other\Source\help.original.html`
					CopyFiles /SILENT $5 `$HelpPackage\Other\Source\help.original.html`
				${EndIf}
				DetailPrint "help.html: replacing the PortableApps.com help page (kept as Other\Source\help.original.html)."
			${Else}
				DetailPrint "help.html: written by hand, left as it is."
				Goto Help_Generate_End
			${EndIf}
		${EndIf}
	${EndIf}

	; The package's details, escaped for HTML.
	StrCpy $1 Details
	StrCpy $2 Description
	Call Help_AppInfo
	StrCpy $HelpDescription $0
	StrCpy $2 Homepage
	Call Help_AppInfo
	StrCpy $HelpHomepage $0
	StrCpy $1 Version
	StrCpy $2 DisplayVersion
	Call Help_AppInfo
	${If} $0 == ""
		StrCpy $2 PackageVersion
		Call Help_AppInfo
	${EndIf}
	StrCpy $HelpVersion $0
	StrCpy $1 Team
	StrCpy $2 Developer
	Call Help_AppInfo
	${If} $0 == ""
		StrCpy $1 Details
		StrCpy $2 Publisher
		Call Help_AppInfo
	${EndIf}
	StrCpy $HelpPackager $0
	StrCpy $1 Control
	StrCpy $2 Start
	Call Help_AppInfo
	${IfThen} $0 == "" ${|} StrCpy $0 `$HelpAppID.exe` ${|}
	StrCpy $HelpLauncher $0
	StrCpy $0 $HelpPName
	Call Help_Escape
	StrCpy $HelpPName $0
	StrCpy $0 $HelpAppName
	Call Help_Escape
	StrCpy $HelpAppName $0

	ClearErrors
	FileOpen $3 $HelpTemplate r
	FileOpen $2 `$5.tmp` w
	${If} ${Errors}
		DetailPrint "help.html: couldn't write $5.tmp, skipped."
		FileClose $3
		FileClose $2
		Goto Help_Generate_End
	${EndIf}

	; Skip a UTF-8 byte order mark an editor may have added to the template.
	FileReadByte $3 $0
	FileReadByte $3 $1
	FileReadByte $3 $4
	${If} $0 <> 0xEF
	${OrIf} $1 <> 0xBB
	${OrIf} $4 <> 0xBF
		FileSeek $3 0 SET
	${EndIf}

	; $4 = true while inside an IF block whose condition is false
	StrCpy $4 false
	${Do}
		ClearErrors
		FileRead $3 $1
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		StrCpy $0 $1 7
		${If} $0 == "<!--IF:"
			; The block's name is what's left without "<!--IF:", "-->" and
			; the line break.
			StrCpy $1 $1 "" 7
			${WordFind} $1 "-->" "+1{" $1
			Call Help_Condition
			${If} $0 == false
				StrCpy $4 true
			${EndIf}
			${Continue}
		${EndIf}
		StrCpy $0 $1 12
		${If} $0 == "<!--ENDIF-->"
			StrCpy $4 false
			${Continue}
		${EndIf}
		${If} $4 == false
			Call Help_Fill
			Call Help_WriteUTF8
		${EndIf}
	${Loop}
	FileClose $3
	FileClose $2

	Delete $5
	Rename `$5.tmp` $5
	${If} ${FileExists} `$5.tmp`
		DetailPrint "help.html: couldn't replace $5, is it open?"
		Delete `$5.tmp`
	${Else}
		DetailPrint "help.html: written for $HelpPName."
	${EndIf}

	Help_Generate_End:
	ClearErrors
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

!endif ; HELPFILE_NSH_INCLUDED
