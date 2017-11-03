/**
 * PortableApps Compiler developed by Devin "demon.devin" Gaul
 * For support, visit the GitHub project page:
 * https://github.com/demondevin/pac-man
 *
 */

;=== For NSIS3
Unicode true 
;ManifestDPIAware true

!define CustomIconAndName

;=== Require at least Unicode NSIS 2.46
!include RequireLatestNSIS.nsh

;=== Program Details
Name "PortableApps Compiler"
OutFile ..\..\PortableAppsCompiler.exe
Icon ..\..\App\AppInfo\appicon.ico
Caption "PortableApps Compiler"
VIProductVersion 3.0.0.0
VIAddVersionKey ProductName "PortableApps Compiler"
VIAddVersionKey Comments "A compiler for custom-built, portable applications based on PortableApps.com Launcher provided by PortableApps.com"
VIAddVersionKey CompanyName "How Dumb, LLC"
VIAddVersionKey LegalCopyright "Copyleft demon.devin"
VIAddVersionKey FileDescription "PortableApps Compiler"
VIAddVersionKey FileVersion 3.0.0.0
VIAddVersionKey ProductVersion 3.0.0.0
VIAddVersionKey InternalName "PortableApps Compiler"
VIAddVersionKey LegalTrademarks "PortableApps.com is a Trademark of Rare Ideas, LLC."
VIAddVersionKey OriginalFilename PortableAppsCompiler.exe

;=== Runtime Switches
RequestExecutionLevel user

; Best Compression
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On

;=== Include
;(Standard)
!include FileFunc.nsh
!include LogicLib.nsh
!include MUI.nsh

;(NSIS Plugins)
!include NewTextReplace.nsh
!AddPluginDir Plugins

;(Custom)
!include ReplaceInFileWithTextReplace.nsh

;=== Icon & Stye ===
!define MUI_ICON "..\..\App\AppInfo\appicon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP header.bmp

BrandingText "PortableApps Compiler - Port And Let Portable!"
InstallButtonText "Go >" 
ShowInstDetails show
SubCaption 3 " | Compiling Portable Launcher"


;=== Variables
Var FINISHTEXT
Var FINISHTITLE
Var NSIS
Var PACKAGE
Var SKIPWELCOMEPAGE
Var AUTOMATICCOMPILE
Var ERROROCCURED
Var AppID
Var Name

;=== Pages
!define MUI_WELCOMEFINISHPAGE_BITMAP welcomefinish.bmp
!define MUI_WELCOMEPAGE_TITLE "PortableApps Compiler"
!define MUI_WELCOMEPAGE_TEXT "Welcome to the PortableApps Compiler.\r\n\r\nThis utility is based on the PortableApps.com Launcher Generator. This advanced compiler allows you to create a portable launcher for an application in the PortableApps.com Format specifications. Click next to start the compiling process."
!define MUI_PAGE_CUSTOMFUNCTION_PRE ShowWelcomeWindow
!insertmacro MUI_PAGE_WELCOME
Page custom ShowOptionsWindow LeaveOptionsWindow " | Portable App Folder Selection" 
Page instfiles
!define MUI_PAGE_CUSTOMFUNCTION_PRE ShowFinishPage
!define MUI_FINISHPAGE_TITLE "$FINISHTITLE"
!define MUI_FINISHPAGE_TEXT "$FINISHTEXT"
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_RUN_TEXT "Test Launcher"
!define MUI_FINISHPAGE_RUN_FUNCTION "RunOnFinish"
!define MUI_FINISHPAGE_SHOWREADME "$EXEDIR\Data\PortableAppsCompilerLog.txt"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "View log file"
!insertmacro MUI_PAGE_FINISH

;=== Languages
;!insertmacro MUI_LANGUAGE "English"

Function .onInit
	!insertmacro MUI_INSTALLOPTIONS_EXTRACT "CompilerWizardForm.ini"
	SetOutPath $EXEDIR
	
	CreateDirectory $EXEDIR\Data
	
	ReadINIStr $SKIPWELCOMEPAGE $EXEDIR\Data\settings.ini CompilerWizard SkipWelcomePage
	ReadINIStr $0 $EXEDIR\Data\settings.ini CompilerWizard Drive
	ReadINIStr $PACKAGE $EXEDIR\Data\settings.ini CompilerWizard Package
	; Update drive letter; doesn't matter if $0 == ""
	StrLen $1 $0
	StrCpy $2 $PACKAGE $1
	${If} $2 == $0
		StrCpy $PACKAGE $PACKAGE "" $1
		StrCpy $PACKAGE $0$PACKAGE
	${EndIf}

	;StrCpy $NSIS "$EXEDIR\App\NSIS\makensis.exe"
	ReadINIStr $NSIS $EXEDIR\Data\settings.ini CompilerWizard makensis
	${If} $NSIS == ""
		StrCpy $NSIS ..\NSISPortable\App\NSIS\makensis.exe
		WriteINIStr $EXEDIR\Data\settings.ini CompilerWizard makensis $NSIS
	${EndIf}	

	${GetParameters} $R0
	StrCmp $R0 "" PreFillForm
		StrCpy $PACKAGE $R0
		StrCpy $SKIPWELCOMEPAGE "true"
		StrCpy $AUTOMATICCOMPILE "true"
		;Strip quotes from $PACKAGE
		StrCpy $R0 $PACKAGE 1
		StrCmp $R0 `"` "" PreFillForm
		StrCpy $PACKAGE $PACKAGE "" 1
		StrCpy $PACKAGE $PACKAGE -1

	PreFillForm:
		;=== Pre-Fill Path with Directory
		WriteINIStr $PLUGINSDIR\CompilerWizardForm.ini "Field 2" "State" "$PACKAGE"
FunctionEnd

Function ShowWelcomeWindow
	StrCmp $SKIPWELCOMEPAGE "true" "" ShowWelcomeWindowEnd
		Abort
	ShowWelcomeWindowEnd:
FunctionEnd

Function ShowOptionsWindow
	!insertmacro MUI_HEADER_TEXT "PortableApps Compiler" "a better alternative to PA.c Launcher"
	${IfThen} $AUTOMATICCOMPILE == "true" ${|} Abort ${|}
	InstallOptions::InitDialog /NOUNLOAD "$PLUGINSDIR\CompilerWizardForm.ini"
    Pop $0
    InstallOptions::Show
FunctionEnd

Function LeaveOptionsWindow
	ReadINIStr $PACKAGE $PLUGINSDIR\CompilerWizardForm.ini "Field 2" "State"

	${If} $PACKAGE == ""
		MessageBox MB_OK|MB_ICONEXCLAMATION `Please select a valid portable app's base directory to create a launcher for.`
		Abort
	${EndIf}
	${GetRoot} $EXEDIR $0
	WriteINIStr $EXEDIR\Data\settings.ini CompilerWizard Drive $0
	WriteINIStr $EXEDIR\Data\settings.ini CompilerWizard Package $PACKAGE
FunctionEnd

!define WriteErrorToLog "!insertmacro WriteErrorToLog"

!macro WriteErrorToLog ErrorToWrite
	FileOpen $9 "$EXEDIR\Data\PortableAppsCompilerLog.txt" a
	FileSeek $9 0 END
	FileWrite $9 `ERROR: ${ErrorToWrite}`
	FileWriteByte $9 "13"
	FileWriteByte $9 "10"
	FileClose $9
	StrCpy $ERROROCCURED "true"
!macroend

!macro UpdatePath Source Target
	${If} ${FileExists} "$PACKAGE\${Source}"
		DetailPrint "${Source} -> ${Target}"
		SetDetailsPrint none
		Rename "$PACKAGE\${Source}" "$PACKAGE\${Target}"
		SetDetailsPrint lastused
	${EndIf}
!macroend

Function UpdateLanguageEnvironmentVariables
	Pop $9 # file

	FileOpen $8 $9 r
	FileReadWord $8 $7
	FileClose $8

	SetDetailsPrint none
	${If} $7 = 0xFEFF
		${ReplaceInFileUTF16LE} $9 PortableApps.comLanguageCode  PAL:LanguageCode
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleCode2   PAL:LanguageCode2
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleCode3   PAL:LanguageCode3
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleGlibc   PAL:LanguageGlibc
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleWinName PAL:LanguageNSIS
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleName    PAL:LanguageName
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleID      PAL:LanguageLCID
	${Else}
		${ReplaceInFile} $9 PortableApps.comLanguageCode  PAL:LanguageCode
		${ReplaceInFile} $9 PortableApps.comLocaleCode2   PAL:LanguageCode2
		${ReplaceInFile} $9 PortableApps.comLocaleCode3   PAL:LanguageCode3
		${ReplaceInFile} $9 PortableApps.comLocaleGlibc   PAL:LanguageGlibc
		${ReplaceInFile} $9 PortableApps.comLocaleWinName PAL:LanguageNSIS
		${ReplaceInFile} $9 PortableApps.comLocaleName    PAL:LanguageName
		${ReplaceInFile} $9 PortableApps.comLocaleID      PAL:LanguageLCID
	${EndIf}
	SetDetailsPrint lastused
FunctionEnd

Section Main
	${IfNot} ${FileExists} $NSIS
		StrCpy $ERROROCCURED true
		${WriteErrorToLog} "NSIS not found at $NSIS."
		MessageBox MB_ICONSTOP "NSIS was not found! (Looked for it in $NSIS)$\r$\n$\r$\nYou can specify a custom path to makensis.exe in $EXEDIR\Data\settings.ini, [CompilerWizard]:makensis"
		Abort
	${EndIf}

	; Fix the package path, if necessary
	StrCpy $R1 $PACKAGE 1 -1
	${IfThen} $R1 == "\" ${|} StrCpy $PACKAGE $PACKAGE -1 ${|}

	SetDetailsPrint ListOnly
	DetailPrint "App: $PACKAGE"
	DetailPrint " "
	RealProgress::SetProgress /NOUNLOAD 0
	RealProgress::GradualProgress /NOUNLOAD 1 20 90 "Processing complete."

	; Check if any upgrade needs to be done from 2.0 to 2.1
	; ${If}   ${FileExists} $PACKAGE\Other\Source\PortableApps.comLauncherCustom.nsh
	; ${OrIf} ${FileExists} $PACKAGE\Other\Source\PortableApps.comLauncherDebug.nsh
		; DetailPrint "Upgrading from 2.0 to 2.1..."
		; !insertmacro UpdatePath Other\Source\PortableApps.comLauncherCustom.nsh App\AppInfo\Launcher\Custom.nsh
		; !insertmacro UpdatePath Other\Source\PortableApps.comLauncherDebug.nsh  App\AppInfo\Launcher\Debug.nsh

		;Replace ${ReadUserOverrideConfig} with ${ReadUserConfig}
		;Check if it's UTF-16LE
		; FileOpen $0 $PACKAGE\App\AppInfo\Launcher\Custom.nsh r
		; FileReadWord $0 $1
		; FileClose $0
		;Avoid ${...} being taken amiss
		; StrCpy $0 $${ReadUser
		; ${If} $1 = 0xFEFF
			; ${If} $5 == UTF-16LE
				; ${ReplaceInFileUTF16LECS} $PACKAGE\App\AppInfo\Launcher\Custom.nsh $0OverrideConfig} $0Config}
			; ${Else}
				; ${ReplaceInFileCS} $PACKAGE\App\AppInfo\Launcher\Custom.nsh $0OverrideConfig} $0Config}
			; ${EndIf}
		; ${EndIf}
		; DetailPrint " "
	; ${EndIf}

	; Check if any upgrade needs to be done from 2.1
	; DetailPrint "Upgrading from 2.1 if needed..."
	; Replace the PortableApps.com language environment variables with their PAL counterparts
	;Push $PACKAGE\App\AppInfo\Launcher\Custom.nsh
	;Call UpdateLanguageEnvironmentVariables
	;FindFirst $0 $1 $PACKAGE\App\AppInfo\Launcher\*.ini
	;${DoUntil} $1 == ""
	;	Push $PACKAGE\App\AppInfo\Launcher\$1
	;	Call UpdateLanguageEnvironmentVariables
	;	FindNext $0 $1
	;${Loop}
	;FindClose $0
	;DetailPrint " "


	DetailPrint "Compiling portable launcher..."
	SetDetailsPrint none
	
	Delete "$EXEDIR\Data\PortableAppsCompilerLog.txt"

	!ifdef CustomIconAndName
		!define _ $PACKAGE
	!else
		!define _ $EXEDIR
	!endif
	${IfNot} ${FileExists} "${_}\App\AppInfo\appinfo.ini"
		StrCpy $ERROROCCURED true
		${WriteErrorToLog} "${_}\App\AppInfo\appinfo.ini doesn't exist!"
	${Else}
		ClearErrors
		ReadINIStr $Name "${_}\App\AppInfo\appinfo.ini" Details Name
		ReadINIStr $AppID "${_}\App\AppInfo\appinfo.ini" Details AppID
		ReadINIStr $1 "$EXEDIR\App\AppInfo\appinfo.ini" Version PackageVersion

		${If} ${Errors}
			StrCpy $ERROROCCURED true
			${WriteErrorToLog} "[Details]:Name [Details]:AppID or [Version]:PackageVersion not found in appinfo.ini files"
		${Else}
			;Delete existing installer if there is one
			Delete "$PACKAGE\$AppID.exe"
			${If} ${FileExists} "$PACKAGE\$AppID.exe"
				StrCpy $ERROROCCURED true
				${WriteErrorToLog} "Unable to delete $PACKAGE\$AppID.exe, is it running?"
			${EndIf}
		${EndIf}
	${EndIf}

	${If} ${FileExists} "${_}\App\AppInfo\Launcher\$AppID.ini"
		; If not, never mind.  It'll complain when the user tries to run it if they haven't created it yet.

		StrCpy $2 ""
		; See if we need to enable XML
		ReadINIStr $3 "${_}\App\AppInfo\Launcher\$AppID.ini" Activate XML
		${If} $3 == true
			StrCpy $2 "$2 /DXML_ENABLED"
		${EndIf}

		; See if we need to use the RequestExecutionLevel admin
		ReadINIStr $3 "${_}\App\AppInfo\Launcher\$AppID.ini" Launch RunAsAdmin
		${If} $3 == compile-force
			StrCpy $2 "$2 /DRUNASADMIN_COMPILEFORCE"
		${EndIf}
	${EndIf}

	${If} $ERROROCCURED != true
		; Build the thing
		ExecDos::exec `"$NSIS" /O"$EXEDIR\Data\PortableAppsCompilerLog.txt" /DPACKAGE="$PACKAGE" /DNamePortable="$Name" /DAppID="$AppID" /DVersion="$1"$2 "$EXEDIR\Other\Source\PortableAppsCompiler.nsi"` "" ""
		Pop $R1
		${If} $R1 <> 0
			StrCpy $ERROROCCURED true
			${WriteErrorToLog} "MakeNSIS exited with status code $R1"
		${EndIf}
	${EndIf}

	SetDetailsPrint ListOnly

	DetailPrint " "
	DetailPrint "Processing complete."
	${If} ${FileExists} $PACKAGE\$AppID.exe
		StrCpy $FINISHTITLE "Launcher Created"
		StrCpy $FINISHTEXT "The launcher has been created. Launcher location:\r\n$PACKAGE\r\n\r\nLauncher name:\r\n$AppID.exe" 
	${Else}
		StrCpy $FINISHTITLE "An Error Occurred"
		StrCpy $FINISHTEXT "The launcher was not created. You can view the log file for more information."
		StrCpy $ERROROCCURED true
	${EndIf}
SectionEnd

Function ShowFinishPage
	${If} $AUTOMATICCOMPILE == "true"
	${AndIf} $ERROROCCURED != true
		Abort
	${Else}
		${If} $ERROROCCURED == true
			!insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 4" "Flags" "DISABLED"
			!insertmacro MUI_INSTALLOPTIONS_WRITE "ioSpecial.ini" "Field 5" "State" "1"
		${EndIf}
	${EndIf}
FunctionEnd

Function RunOnFinish
	Exec $PACKAGE\$AppID.exe
FunctionEnd

Function .onGUIEnd
	RealProgress::Unload
FunctionEnd
