;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; LauncherCompiler.nsi
;

;= GFLAGS
;= ################
!define CustomIconAndName
!define CONTRIB		`Contrib\bin`
!define SIGNDIR		`${CONTRIB}\signtool`
!define SIGNTOOL	`${SIGNDIR}\signtool.exe`
!define NEWLINE		`$\r$\n`
!define TAB			`$\t`

;= NSIS VERSION
;= ################
!include RequireLatestNSIS.nsh

;= RUNTIME SWITCHES
;= ################
Unicode true
ManifestSupportedOS all
ManifestDPIAware true
CRCCheck on
WindowIcon off
RequestExecutionLevel user
XPStyle on

;= PAC VERSION
;= ################
!include Version.nsh

;= PAC DETAILS
;= ################
Name "PortableApps Compiler"
OutFile ..\..\PortableAppsCompiler.exe
Icon ..\..\App\AppInfo\Appicon.ico
Caption "PortableApps Compiler"
VIProductVersion ${PACVER}
VIAddVersionKey ProductName "PortableApps Compiler"
VIAddVersionKey Comments "A compiler for advanced, custom PortableApps.com Launchers. \
							For information, visit: https://github.com/daemondevin/pac-man"
VIAddVersionKey CompanyName "How Dumb, LLC"
VIAddVersionKey LegalCopyright "daemon.devin"
VIAddVersionKey FileDescription "PortableApps Compiler"
VIAddVersionKey FileVersion ${PACVER}
VIAddVersionKey ProductVersion ${PACVER}
VIAddVersionKey InternalName "PortableApps Compiler"
VIAddVersionKey OriginalFilename PortableAppsCompiler.exe

;= COMPRESSION
;= ################
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On

;= INCLUDES/PLUGINS
;= ################
!include FileFunc.nsh
!include LogicLib.nsh
!include MUI.nsh
!include nsDialogs.nsh
!include NewTextReplace.nsh
!include ReplaceInFileWithTextReplace.nsh
!include LogicLibAdditions.nsh
!AddPluginDir Plugins

;= ICON & STYLE
;= ################
!define MUI_ICON "..\..\App\AppInfo\appicon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP header.bmp
BrandingText "PortableApps Compiler - Port And Let Portable!"
InstallButtonText "Go >" 
ShowInstDetails show
SubCaption 3 " | Compiling Launcher"

;= VARIABLES
;= ################
Var FINISHTEXT
Var FINISHTITLE
Var NSIS
Var GFLAGS
Var PACKAGE
Var SKIPWELCOMEPAGE
Var AUTOMATICCOMPILE
Var ERROROCCURED
Var AppID
Var AppPName
Var AppFullname
Var AppShortname
Var AppVersion
Var Name
Var Hybrid

;= PAGES
;= ################
!define MUI_WELCOMEFINISHPAGE_BITMAP welcomefinish.bmp
!define MUI_WELCOMEPAGE_TITLE "PortableApps Compiler"
!define MUI_WELCOMEPAGE_TEXT "Welcome to the PortableApps Compiler.\r\n\r\n\
								This utility is an advanced, portable compiler which \
								enables you to create an executable which handles and \
								contains a program and its data in a launcher which \
								allows it to be stealth. \r\n\r\n \
								To port and let portable click next..\r\n\r\n\
								NOTE:\r\nYou can skip this welcome message by adding the \
								following to the settings.ini file in the Data folder:\r\n\r\n\
								[LauncherCompiler]\r\nSkipWelcomePage=true"
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
!define MUI_FINISHPAGE_SHOWREADME "$EXEDIR\Data\LauncherCompilerLog.txt"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Review Log"
!insertmacro MUI_PAGE_FINISH

;= MACROS
;= ################
!define ReadAppInfoConfig `!insertmacro _ReadAppInfoConfig`
!macro _ReadAppInfoConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} `${_}\App\AppInfo\AppInfo.ini` `${_SECTION}` `${_KEY}`
!macroend
!define ReadLauncherConfig `!insertmacro _ReadLauncherConfig`
!macro _ReadLauncherConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} `${_}\App\AppInfo\Launcher\$AppID.ini` `${_SECTION}` `${_KEY}`
!macroend
!define WriteGlobalDefines "!insertmacro _WriteGlobalDefines"
!macro _WriteGlobalDefines _DEFINE _VALUE _TAB
	!if ! "${_VALUE}" == ""
		DetailPrint "Initializing ${_DEFINE}"
		SetDetailsPrint none
		FileWrite $GFLAGS "!define ${_DEFINE}${_TAB}`${_VALUE}`${NEWLINE}"
	!else 
		DetailPrint "Initializing ${_DEFINE} -> ${_VALUE}"
		SetDetailsPrint none
		FileWrite $GFLAGS "!define ${_DEFINE}${NEWLINE}"
	!endif
	SetDetailsPrint lastused
!macroend
!define AddConditionIfNot "!insertmacro _AddConditionIfNot"
!macro _AddConditionIfNot _DEFINE
	FileWrite $GFLAGS `!ifndef ${_DEFINE}${NEWLINE}$\t!define ${_DEFINE}${NEWLINE}!endif${NEWLINE}`
!macroend
!define WriteErrorLog "!insertmacro _WriteErrorLog"
!macro _WriteErrorLog _ERROR
	FileOpen $9 "$EXEDIR\Data\LauncherCompilerLog.txt" a
	FileSeek $9 0 END
	FileWrite $9 `ERROR: ${_ERROR}`
	FileWriteByte $9 "13"
	FileWriteByte $9 "10"
	FileWriteByte $9 "13"
	FileWriteByte $9 "10"
	FileWrite $9 `${DISPLAYBUILD}`
	FileWriteByte $9 "13"
	FileWriteByte $9 "10"
	FileClose $9
	StrCpy $ERROROCCURED "true"
!macroend
!define UpdatePath "!insertmacro _UpdatePath"
!macro _UpdatePath _SOURCE _TARGET
	${If} ${FileExists} "$PACKAGE\${_SOURCE}"
		DetailPrint "${_SOURCE} -> ${_TARGET}"
		SetDetailsPrint none
		Rename "$PACKAGE\${_SOURCE}" "$PACKAGE\${_TARGET}"
		SetDetailsPrint lastused
	${EndIf}
!macroend
!define PromptUserInput "!insertmacro _PromptUserInput"
!macro _PromptUserInput _BOXTITLE _FILE _SECTION _KEY _PROMPT _DEFAULTVALUE _VALUE _REQUIRED
	ReadINIStr ${_VALUE} "${_FILE}" "${_SECTION}" "${_KEY}"
	${If} ${_VALUE} == ""
		StrCpy $9 "${_DEFAULTVALUE}"
		DialogsW::InputBox 0 "${_BOXTITLE}" "${_PROMPT}" "OK" "Cancel" 8 9
		${If} $8 == 1
			StrCpy ${_VALUE} $9
			WriteINIStr "${_FILE}" "${_SECTION}" "${_KEY}" $9
		!if ${_REQUIRED} == required
		${Else}
			${WriteErrorLog} "[${_SECTION}]:${_KEY} is missing from ${_FILE}."
		!endif
		${EndIf}
	${EndIf}
!macroend

;= LANGUAGES
;= ################
!insertmacro MUI_LANGUAGE "English"

Function .onInit
	!insertmacro MUI_INSTALLOPTIONS_EXTRACT "LauncherCompilerForm.ini"
	SetOutPath $EXEDIR
	
	CreateDirectory $EXEDIR\Data
	
	ReadINIStr $SKIPWELCOMEPAGE $EXEDIR\Data\settings.ini LauncherCompiler SkipWelcomePage
	ReadINIStr $0 $EXEDIR\Data\settings.ini LauncherCompiler Drive
	ReadINIStr $PACKAGE $EXEDIR\Data\settings.ini LauncherCompiler Package
	; Update drive letter; doesn't matter if $0 == ""
	StrLen $1 $0
	StrCpy $2 $PACKAGE $1
	${If} $2 == $0
		StrCpy $PACKAGE $PACKAGE "" $1
		StrCpy $PACKAGE $0$PACKAGE
	${EndIf}

	;StrCpy $NSIS "$EXEDIR\App\NSIS\makensis.exe"
	ReadINIStr $NSIS $EXEDIR\Data\settings.ini LauncherCompiler makensis
	${If} $NSIS == ""
		StrCpy $NSIS ..\NSISPortable\App\NSIS\makensis.exe
		WriteINIStr $EXEDIR\Data\settings.ini LauncherCompiler makensis $NSIS
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
		WriteINIStr $PLUGINSDIR\LauncherCompilerForm.ini "Field 2" "State" "$PACKAGE"
FunctionEnd

Function ShowWelcomeWindow
	StrCmp $SKIPWELCOMEPAGE "true" "" ShowWelcomeWindowEnd
		Abort
	ShowWelcomeWindowEnd:
FunctionEnd

Function ShowOptionsWindow
	!insertmacro MUI_HEADER_TEXT "PortableApps Launcher Compiler" "Port And Let Portable!"
	${IfThen} $AUTOMATICCOMPILE == "true" ${|} Abort ${|}
	InstallOptions::InitDialog /NOUNLOAD "$PLUGINSDIR\LauncherCompilerForm.ini"
    Pop $0
    InstallOptions::Show
FunctionEnd

Function LeaveOptionsWindow
	ReadINIStr $PACKAGE $PLUGINSDIR\LauncherCompilerForm.ini "Field 2" "State"

	${If} $PACKAGE == ""
		MessageBox MB_OK|MB_ICONEXCLAMATION `Select a valid, base directory to compile a launcher for.`
		Abort
	${EndIf}
	${GetRoot} $EXEDIR $0
	WriteINIStr $EXEDIR\Data\settings.ini LauncherCompiler Drive $0
	WriteINIStr $EXEDIR\Data\settings.ini LauncherCompiler Package $PACKAGE
FunctionEnd

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
		${WriteErrorLog} "NSIS not found at $NSIS."
		MessageBox MB_ICONSTOP "\
			NSIS was not found! (Looked for it in $NSIS)${NEWLINE} \
			${NEWLINE}You can specify a custom path to makensis.exe \
			in $EXEDIR\Data\settings.ini, [LauncherCompiler]:makensis"
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
	${If}   ${FileExists} $PACKAGE\Other\Source\PortableApps.comLauncherCustom.nsh
	${OrIf} ${FileExists} $PACKAGE\Other\Source\PortableApps.comLauncherDebug.nsh
		DetailPrint "Upgrading from 2.0 to 2.1..."
		${UpdatePath} Other\Source\PortableApps.comLauncherCustom.nsh App\AppInfo\Launcher\Custom.nsh
		${UpdatePath} Other\Source\PortableApps.comLauncherDebug.nsh  App\AppInfo\Launcher\Debug.nsh

		; Replace ${ReadUserOverrideConfig} with ${ReadUserConfig}
		; Check if it's UTF-16LE
		FileOpen $0 $PACKAGE\App\AppInfo\Launcher\Custom.nsh r
		FileReadWord $0 $1
		FileClose $0
		; Avoid ${...} being taken amiss
		StrCpy $0 $${ReadUser
		${If} $1 = 0xFEFF
			${If} $5 == UTF-16LE
				${ReplaceInFileUTF16LECS} $PACKAGE\App\AppInfo\Launcher\Custom.nsh $0OverrideConfig} $0Config}
			${Else}
				${ReplaceInFileCS} $PACKAGE\App\AppInfo\Launcher\Custom.nsh $0OverrideConfig} $0Config}
			${EndIf}
		${EndIf}
		DetailPrint " "
	${EndIf}

	; Check if any upgrade needs to be done from 2.1
	DetailPrint "Upgrading from 2.1 if needed..."
	; Replace the PortableApps.com language environment variables with their PAL counterparts
	Push $PACKAGE\App\AppInfo\Launcher\Custom.nsh
	Call UpdateLanguageEnvironmentVariables
	FindFirst $0 $1 $PACKAGE\App\AppInfo\Launcher\*.ini
	${DoUntil} $1 == ""
		Push $PACKAGE\App\AppInfo\Launcher\$1
		Call UpdateLanguageEnvironmentVariables
		FindNext $0 $1
	${Loop}
	FindClose $0
	DetailPrint " "

	DetailPrint "Compiling launcher..."
	SetDetailsPrint none
	
	Delete "$EXEDIR\Data\LauncherCompilerLog.txt"
	
	Delete "$EXEDIR\Other\Source\GlobalDefines.nsh"

	!ifdef CustomIconAndName
		!define _ $PACKAGE
	!else
		!define _ $EXEDIR
	!endif

	;Delete existing installer if there is one
	Delete "$PACKAGE\$AppID.exe"
	${If} ${FileExists} "$PACKAGE\$AppID.exe"
		StrCpy $ERROROCCURED true
		${WriteErrorLog} "Unable to delete $PACKAGE\$AppID.exe, is it running?"
	${EndIf}
	
	; Read/write the needed defines to PortableAppsCompilerDefines.nsh 
	DetailPrint "Writing the wrapper's configuration settings..."
	DetailPrint " "

	FileOpen $GFLAGS "$EXEDIR\Other\Source\GlobalDefines.nsh" w
	FileWrite $GFLAGS	";=# ${NEWLINE}\
						; ${NEWLINE}\
						; PORTABLEAPPS COMPILER${NEWLINE}\
						; Developed by daemon.devin (daemon.devin@gmail.com)${NEWLINE}\
						; ${NEWLINE}\
						; For support, visit the GitHub project:${NEWLINE}\
						; https://github.com/daemondevin/pac-man${NEWLINE}\
						; ${NEWLINE}\
						; GlobalDefines.nsh${NEWLINE}\
						; 	This file was generated automatically by the PortableApps Compiler.${NEWLINE}\
						; 	It's also created as well as deleted for each new creation process.${NEWLINE}\
						; ${NEWLINE}"
	FileWriteByte $GFLAGS "13"
	FileWriteByte $GFLAGS "10"
	
	${IfNot} ${FileExists} "${_}\App\AppInfo\AppInfo.ini"
		StrCpy $ERROROCCURED true
		${WriteErrorLog} "${_}\App\AppInfo\AppInfo.ini doesn't exist!"
	${Else}
	
		${PromptUserInput} \
			"Package Name" \
			"${_}\App\AppInfo\appinfo.ini" \
			"Details" \
			"Name" \
			"What's this package's name? (e.g. Discord Portable):" \
			"App Portable" \
			$Name \
			required
		${PromptUserInput} \
			"Package AppID" \
			"${_}\App\AppInfo\appinfo.ini" \
			"Details" \
			"AppID" \
			"Enter the package's name with no spaces (e.g. DiscordPortable):" \
			"AppPortable" \
			$AppID \
			required
		${PromptUserInput} \
			"Package Version" \
			"${_}\App\AppInfo\appinfo.ini" \
			"Version" \
			"PackageVersion" \
			"Enter the package's version (e.g. 1.2.3.4):" \
			"1.2.3.4" \
			$AppVersion \
			required
			
		StrCpy $1 $Name "" -8
		${If} $1 == "Portable"
			StrCpy $AppPName $Name
		${Else}
			StrCpy $AppPName "$Name Portable"
		${EndIf}
		StrCpy $1 $Name "" -8
		${If} $1 == "Portable"
			StrCpy $AppFullname $Name -9
		${Else}
			StrCpy $AppFullname "$Name"
		${EndIf}
		StrCpy $1 $AppID "" -8
		${If} $1 == "Portable"
			StrCpy $AppShortname $AppID -8
		${Else}
			StrCpy $AppShortname $AppID
		${EndIf}
	
		ClearErrors
		${WriteGlobalDefines} "PORTABLEAPPNAME" "$AppPName" "$\t"
		${WriteGlobalDefines} "FULLNAME" "$AppFullname" "$\t$\t"
		${WriteGlobalDefines} "APPNAME" "$AppID" "$\t$\t$\t"
		${WriteGlobalDefines} "PACKAGE_VERSION" "$AppVersion" "$\t"
		
		ClearErrors
		${ReadLauncherConfig} $Hybrid "Activate" "DualMode"
		${IfNot} ${Errors}
		${AndIf} $Hybrid != ""
			${WriteGlobalDefines} "APP" "$AppShortname" "$\t$\t$\t$\t"
			${WriteGlobalDefines} "APPDIR" "$$EXEDIR\App\$${APP}" "$\t$\t$\t"
			${ReadLauncherConfig} $0 "Launch" "ProgramExecutable"
			${IfNot} ${Errors}
				${WriteGlobalDefines} "32" "$0" "$\t$\t$\t$\t"
				${WriteGlobalDefines} "EXE32" "$$EXEDIR\App\$${32}" "$\t$\t$\t"
				${WriteGlobalDefines} "SET32" "Kernel32::SetEnvironmentVariable(t'$Hybrid',t'$AppShortname')" "$\t$\t$\t"
			${EndIf}
			${WriteGlobalDefines} "APP64" "$AppShortname64" "$\t$\t$\t"
			${WriteGlobalDefines} "APPDIR64" "$$EXEDIR\App\$${APP64}" "$\t$\t"
			ClearErrors
			${ReadLauncherConfig} $0 "Launch" "ProgramExecutable64"
			${IfNot} ${Errors}
				${WriteGlobalDefines} "64" "$0" "$\t$\t$\t$\t"
				${WriteGlobalDefines} "EXE64" "$$EXEDIR\App\$${64}" "$\t$\t$\t"
				${WriteGlobalDefines} "SET64" "Kernel32::SetEnvironmentVariable(t'$Hybrid',t'$AppShortname64')" "$\t$\t$\t"
			${EndIf}
		${Else}
			${ReadLauncherConfig} $0 "Launch" "ProgramExecutable64"
			${IfNot} ${Errors}
				${WriteGlobalDefines} "APP64" "$AppShortname64" "$\t$\t$\t$\t"
				${WriteGlobalDefines} "APPDIR64" "$$EXEDIR\App\$${APP64}" "$\t$\t$\t"
			${Else}
				${WriteGlobalDefines} "APP" "$AppShortname" "$\t$\t$\t$\t"
				${WriteGlobalDefines} "APPDIR" "$$EXEDIR\App\$${APP}" "$\t$\t$\t"
			${EndIf}
		${EndIf}
		ClearErrors
		${PromptUserInput} \
			"Developer" \
			"${_}\App\AppInfo\AppInfo.ini" \
			"Team" \
			"Developer" \
			"Who's making this package? (e.g. daemon.devin):" \
			"PortableAppsCompiler" \
			$0 \
			optional 
		${If} $0 == "demon.devin"
			StrCpy $0 "daemon.devin"
			WriteINIStr "${_}\App\AppInfo\AppInfo.ini" "Team" "Developer" "$0" 
		${EndIf}
		${WriteGlobalDefines} "DEVELOPER" "$0" "$\t$\t"
		ClearErrors
		${ReadAppInfoConfig} $0 "Team" "Contributors"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "CONTRIBUTORS" "$0" "$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Team" "CertSigning"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "CertSigning" "" ""
		${EndIf}		
		ClearErrors
		${ReadAppInfoConfig} $0 "Team" "CertExtension"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "CertExtension" "$0" "$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Team" "CertTimestamp"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "CertTimestamp" "$0" "$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Details" "Publisher"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "PUBLISHER" "$0" "$\t$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Details" "Trademarks"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "TRADEMARK" "$0" "$\t$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Control" "Start"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "OUTFILE" "$0" "$\t$\t$\t"
		${EndIf}		
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "UsesDotNetVersion"
		${IfNot} ${Errors}
			${If} $0 != false
				${WriteGlobalDefines} "DOTNET" "" ""
			${EndIf}
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "UseStdUtils"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "UseStdUtils" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "INF_Install"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "INF_Install" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "RegistryValueWrite"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "RegSleep" "50" "$\t$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "FileWriteReplace"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "REPLACE" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "CloseWindow"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "CloseWindow" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "FileLocking"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "IsFileLocked" "" ""
			${AddConditionIfNot} "CloseWindow"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "Firewall"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "FIREWALL" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "Junctions"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "NTFS" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "ACLRegSupport"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "ACL" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "ACLDirSupport"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "ACL_DIR" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "RMEmptyDir"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "RMEMPTYDIRECTORIES" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "LocalLow"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "LocalLow" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "PublicDoc"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "PublicDoc" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "CompareVersions"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "CompareVersions" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "ConfigFunctions"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "ConFunc" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "JSONSupport"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "JSON" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "RestartSleep"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "Sleep" "$0" "$\t$\t$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "WinMessages"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "Include_WinMessages" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "LineWrite"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "Include_LineWrite" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "TrimString"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "TrimString" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "CloseProcess"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "CloseProc" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "Include64"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "64.nsh" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "IncludeWordRep"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "Include_WordRep" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "GetBetween"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "GetBetween.nsh" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "DisableLanguageCustom"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "DisablePAC:LanguageCustom" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "DisableProgramExecSegment"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "DisableProgramExecSegment" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "TLB_FUNCTION"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "TLB_FUNCTION" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "DirectX"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "DIRECTX" "" ""
		${EndIf}
	${EndIf}

	${IfNot} ${FileExists} "${_}\App\AppInfo\Launcher\$AppID.ini"
		StrCpy $ERROROCCURED true
		${WriteErrorLog} "${_}\App\AppInfo\Launcher\$AppID.ini doesn't exist!"
	${Else}
		ClearErrors
		${ReadLauncherConfig} $0 "Launch" "RunAsAdmin"
        ${IfNot} ${Errors}
			${If} $0 == "try"
			${OrIf} $0 == "force"
			${OrIf} $0 == "compile-force"
				${WriteGlobalDefines} "UAC" "" ""
			${EndIf}
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "DualMode"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "HYBRID" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "Registry"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "REGISTRY" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "RegRedirection"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "DISABLEFSR" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "RegCopyKeys"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "RegCopy" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "Redirection"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "SYSTEMWIDE_DISABLEREDIR" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "ForceRedirection"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "FORCE_SYSTEMWIDE_DISABLEREDIR" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "ExecAsUser"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "ExecAsUser" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "Services"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "SERVICES" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "RegDLLs"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "REGISTERDLL" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "Tasks"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "TaskCleanUp" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "Java"
		${IfNot} ${Errors}
			${If} $0 == "find"
			${OrIf} $0 == "require"
				${WriteGlobalDefines} "JAVA" "" ""
			${EndIf}
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "XML"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "XML_PLUGIN" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "Ghostscript"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "GHOSTSCRIPT" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "FontsFolder"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "FONTS_ENABLE" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "FileCleanup"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "FileCleanup" "" ""
		${EndIf}
		ClearErrors
		${ReadLauncherConfig} $0 "Activate" "DirectoryCleanup"
		${IfNot} ${Errors}
			${WriteGlobalDefines} "DirectoryCleanup" "" ""
		${EndIf}
		
		FileClose $GFLAGS

		StrCpy $2 ""
		ReadINIStr $3 "${_}\App\AppInfo\Launcher\$AppID.ini" Activate XML
		${If} $3 == true
			StrCpy $2 "$2 /DXML_ENABLED"
		${EndIf}

		ReadINIStr $3 "${_}\App\AppInfo\Launcher\$AppID.ini" Launch RunAsAdmin
		${If} $3 == compile-force
			StrCpy $2 "$2 /DRUNASADMIN_COMPILEFORCE"
		${EndIf}
		
	${EndIf}

	${If} $ERROROCCURED != true
		ExecDos::exec `"$NSIS" /O"$EXEDIR\Data\LauncherCompilerLog.txt" \
						/X"!include $EXEDIR\Other\Source\GlobalDefines.nsh" \
						/DPACMAN /DPACKAGE="$PACKAGE" \
						/DNamePortable="$Name" \
						/DAppID="$AppID" \
						/DVersion="${PACVER}"$2 \
						"$EXEDIR\Other\Source\PortableAppsCompiler.nsi"` "" ""
		Pop $R1
		${If} $R1 <> 0
			StrCpy $ERROROCCURED true
			${WriteErrorLog} "MakeNSIS exited with status code $R1"
		${EndIf}
	${EndIf}

	SetDetailsPrint ListOnly

	DetailPrint " "
	DetailPrint "Process complete.."
	${If} ${FileExists} $PACKAGE\$AppID.exe
		StrCpy $FINISHTITLE "Launcher Packaged"
		StrCpy $FINISHTEXT "The launcher has been compiled. It's located at:\r\n$PACKAGE\r\n\r\nLauncher Name:\r\n$AppID.exe" 
	${Else}
		StrCpy $FINISHTITLE "An Error Occurred"
		StrCpy $FINISHTEXT "Compiling the launcher failed. Review the log file to debug the issue."
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

; Sign ourselves using both SHA-1 and SHA-2 too.
!finalize `"${SIGNTOOL}" sign /f "Contrib\certificates\daemon.devin.pfx" /fd sha512 /t "http://timestamp.sectigo.com/" /v "%1"`
