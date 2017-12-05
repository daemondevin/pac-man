;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; WrapperCompiler.nsi
; Version 1.1
;

;= RUNTIME SWITCHES
;= ################
Unicode true 
ManifestDPIAware true
RequestExecutionLevel user

!define CustomIconAndName

;= NSIS VERSION
;= ################
!include RequireLatestNSIS.nsh

;= PAC VERSION
;= ################
!include Version.nsh

;= PAC DETAILS
;= ################
Name "PortableApps Compiler"
OutFile ..\..\PortableAppsCompiler.exe
Icon ..\..\app\AppInfo\appicon.ico
Caption "PortableApps Compiler"
VIProductVersion ${PACVER}
VIAddVersionKey ProductName "PortableApps Compiler"
VIAddVersionKey Comments "A small utility for generating a portable wrapper for an application."
VIAddVersionKey CompanyName "How Dumb, LLC"
VIAddVersionKey LegalCopyright "Copyright daemon.devin"
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
;(Standard)
!include FileFunc.nsh
!include LogicLib.nsh
!include MUI.nsh
!include nsDialogs.nsh
!include NewTextReplace.nsh
!AddPluginDir Plugins
!include ReplaceInFileWithTextReplace.nsh
!include ForEachPath.nsh

;= ICON & STYLE
;= ################
!define MUI_ICON "..\..\App\AppInfo\AppIcon.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP header.bmp
BrandingText "PortableApps Compiler - Port And Let Portable!"
InstallButtonText "Go >" 
ShowInstDetails show
SubCaption 3 " | Compiling Portable Wrapper"

;= VARIABLES
;= ################
Var FINISHTEXT
Var FINISHTITLE
Var NSIS
Var PACKAGE
Var SKIPWELCOMEPAGE
Var AUTOMATICCOMPILE
Var DEFINES
Var FGBUILD
Var ERROROCCURED
Var AppID
Var AppPName
Var AppFullname
Var AppShortname
Var AppVersion
Var Name
Var Hybrid
Var CONVERT

;= PAGES
;= ################
!define MUI_WELCOMEFINISHPAGE_BITMAP welcomefinish.bmp
!define MUI_WELCOMEPAGE_TITLE "PortableApps Compiler"
!define MUI_WELCOMEPAGE_TEXT "Welcome to the PortableApps Compiler.\r\n\r\nThis utility is an advanced compiler which allows you to create a portable wrapper for an application which adheres to the PortableApps Compiler format specifications. Click next to start the compiling process."
!define MUI_PAGE_CUSTOMFUNCTION_PRE ShowWelcomeWindow
!insertmacro MUI_PAGE_WELCOME
Page custom ShowOptionsWindow LeaveOptionsWindow " | Portable App Folder Selection" 
Page instfiles
!define MUI_PAGE_CUSTOMFUNCTION_PRE ShowFinishPage
!define MUI_FINISHPAGE_TITLE "$FINISHTITLE"
!define MUI_FINISHPAGE_TEXT "$FINISHTEXT"
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_RUN_TEXT "Test Wrapper"
!define MUI_FINISHPAGE_RUN_FUNCTION "RunOnFinish"
!define MUI_FINISHPAGE_SHOWREADME "$EXEDIR\bin\WrapperCompilerLog.txt"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_SHOWREADME_TEXT "Review Log"
!insertmacro MUI_PAGE_FINISH

;= DEFINITIONS
;= ################
!define NEWLINE		"$\r$\n"
!define DBUG		"Debug.nsh"
!define APPINFOINI	"AppInfo.ini"
!define WRAPPERINI	"Wrapper.ini"
!define INSTALLINI	"Installer.ini"
!define EXTEND		"ExtendWrapper.nsh"
!define EXTINS		"ExtendInstaller.nsh"
!define APPINFOPATH	"$PACKAGE\App\AppInfo\${APPINFOINI}"
!define WRAPPERPATH	"$PACKAGE\App\AppInfo\${WRAPPERINI}"
!define EXTENDPATH	"$PACKAGE\App\AppInfo\${EXTEND}"
!define EXTINSPATH	"$PACKAGE\App\AppInfo\${EXTINS}"
!define DEFINEINC	"$EXEDIR\etc\Source\PortableAppsCompilerDefines.nsh"
!define DEFHEADER	"${DEFHEADER1}${DEFHEADER2}${DEFHEADER3}${DEFHEADER4}${DEFHEADER5}"
!define DEFHEADER1	";=# ${NEWLINE}; ${NEWLINE}; PORTABLEAPPS COMPILER${NEWLINE}; Developed by daemon.devin"
!define DEFHEADER2	"${NEWLINE}; ${NEWLINE}; For support visit the GitHub project:${NEWLINE}; "
!define DEFHEADER3	"https://github.com/demondevin/pac-man${NEWLINE}; ${NEWLINE}; PortableAppsCompilerDefines.nsh${NEWLINE}; "
!define DEFHEADER4	"This file was generated automatically by the PortableApps Compiler.${NEWLINE}; "
!define DEFHEADER5	"It's also created as well as deleted for each new creation process.${NEWLINE}; ${NEWLINE}"
!define EXTHEADER	"${NEWLINE}${EXTHEADER1}${EXTHEADER2}${EXTHEADER3}${EXTHEADER4}"
!define EXTHEADER1	";= WRAPPER${NEWLINE};= ################${NEWLINE};  "
!define EXTHEADER2	"This portable application was compiled with${NEWLINE};  "
!define EXTHEADER3	"PortableApps Compiler: Development Edition:${NEWLINE};  "
!define EXTHEADER4	"https://github.com/daemondevin/pac-man/tree/dev${NEWLINE}; ${NEWLINE}"
!define PAInstaller "${EXTINS} -> PortableApps.comInstallerCustom.nsh${NEWLINE}I haven't built an installer compiler yet.${NEWLINE}${NEWLINE}Creating a dummy help.html file so you can still package this build with PA.c Installer"

;= MACROS
;= ################
!define ReadAppInfoConfig `!insertmacro _ReadAppInfoConfig`
!macro _ReadAppInfoConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} `${_}\App\AppInfo\AppInfo.ini` `${_SECTION}` `${_KEY}`
!macroend
!define ReadWrapperConfig `!insertmacro _ReadWrapperConfig`
!macro _ReadWrapperConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} `${_}\App\AppInfo\${WRAPPERINI}` `${_SECTION}` `${_KEY}`
!macroend
!define WriteDefineConfig "!insertmacro _WriteDefineConfig"
!macro _WriteDefineConfig _DEFINE _VALUE _TAB
	!if ! "${_VALUE}" == ""
		DetailPrint "Defining ${_DEFINE}"
		SetDetailsPrint none
		FileWrite $DEFINES "!define ${_DEFINE}${_TAB}`${_VALUE}`${NEWLINE}"
	!else 
		DetailPrint "Defining ${_DEFINE} -> ${_VALUE}"
		SetDetailsPrint none
		FileWrite $DEFINES "!define ${_DEFINE}${NEWLINE}"
	!endif
	SetDetailsPrint lastused
!macroend
!define AddConditionIfNot "!insertmacro _AddConditionIfNot"
!macro _AddConditionIfNot _DEFINE
	FileWrite $DEFINES `!ifndef ${_DEFINE}${NEWLINE}$\t!define ${_DEFINE}${NEWLINE}!endif${NEWLINE}`
!macroend
!define WriteErrorLog "!insertmacro _WriteErrorLog"
!macro _WriteErrorLog _ERROR
	FileOpen $9 "$EXEDIR\bin\WrapperCompilerLog.txt" a
	FileSeek $9 0 END
	FileWrite $9 `ERROR: ${_ERROR}`
	FileWriteByte $9 "13"
	FileWriteByte $9 "10"
	FileClose $9
	StrCpy $ERROROCCURED "true"
!macroend
!define ConvertPath "!insertmacro _ConvertPath"
!macro _ConvertPath _SOURCE _TARGET
	${If} ${FileExists} "$PACKAGE\${_SOURCE}"
		DetailPrint "Moving ${_SOURCE} -> ${_TARGET}"
		SetDetailsPrint none
		Rename "$PACKAGE\${_SOURCE}" "$PACKAGE\${_TARGET}"
		SetDetailsPrint lastused
	${EndIf}
!macroend
!define StringConvertInFile `!insertmacro _StringConvertInFile`
!macro _StringConvertInFile _FILE _SEARCH _REPLACE
	FileOpen $R8 ${_FILE} r
	FileReadWord $R8 $R7
	FileClose $R8
	${If} $R7 = 0xFEFF
		${ReplaceInFileUTF16LE} ${_FILE} ${_SEARCH} ${_REPLACE}
	${Else}
		${ReplaceInFile} ${_FILE} ${_SEARCH} ${_REPLACE}
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

;= FUNCTIONS
;= ################
Function LineReadInFile
	!define LineReadInFile `!insertmacro _LineReadInFile`
	!macro _LineReadInFile _FILE _NUMBER _RESULT
		Push `${_FILE}`
		Push `${_NUMBER}`
		Call LineReadInFile
		Pop ${_RESULT}
	!macroend
 
	Exch $1
	Exch
	Exch $0
	Exch
	Push $2
	Push $3
	Push $4
	ClearErrors
 
	IfFileExists $0 0 error
	IntOp $1 $1 + 0
	IntCmp $1 0 error 0 plus
	StrCpy $4 0
	FileOpen $2 $0 r
	IfErrors error
	FileRead $2 $3
	IfErrors +3
	IntOp $4 $4 + 1
	Goto -3
	FileClose $2
	IntOp $1 $4 + $1
	IntOp $1 $1 + 1
	IntCmp $1 0 error error
 
	plus:
	FileOpen $2 $0 r
	IfErrors error
	StrCpy $3 0
	IntOp $3 $3 + 1
	FileRead $2 $0
	IfErrors +4
	StrCmp $3 $1 0 -3
	FileClose $2
	goto end
	FileClose $2
 
	error:
	SetErrors
	StrCpy $0 ''
 
	end:
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
Function AddToLineInFile
	!define AddToLineInFile `!insertmacro _AddToLineInFile`
	!macro _AddToLineInFile _FILE _NUMBER _STRING
		Push `${_STRING}`
		Push `${_NUMBER}`
		Push `${_FILE}`
		Call AddToLineInFile
	!macroend

	Exch $0
	Exch
	Exch $1
	Exch 2
	Exch $2
	Exch 2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	 
	 GetTempFileName $7
	 FileOpen $4 $0 r
	 FileOpen $5 $7 w
	 StrCpy $3 0
	 
	Loop:
	ClearErrors
	FileRead $4 $6
	IfErrors Exit
	 IntOp $3 $3 + 1
	 StrCmp $3 $1 0 +3
	FileWrite $5 "$2$\r$\n$6"
	FileWrite $5 "$2$\r$\n"
	Goto Loop
	FileWrite $5 $6
	Goto Loop
	Exit:
	 
	 FileClose $5
	 FileClose $4
	 
	SetDetailsPrint none
	Delete $0
	Rename $7 $0
	SetDetailsPrint both
	 
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd
Function ReplaceLineInFile
	!define ReplaceLineInFile `!insertmacro _ReplaceLineInFile`
	!macro _ReplaceLineInFile _FILE _NUMBER _STRING
		Push `${_STRING}`
		Push `${_NUMBER}`
		Push `${_FILE}`
		Call ReplaceLineInFile
	!macroend

	Exch $0
	Exch
	Exch $1
	Exch 2
	Exch $2
	Exch 2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	 
	 GetTempFileName $7
	 FileOpen $4 $0 r
	 FileOpen $5 $7 w
	 StrCpy $3 0
	 
	Loop:
	ClearErrors
	FileRead $4 $6
	IfErrors Exit
	 IntOp $3 $3 + 1
	 StrCmp $3 $1 0 +3
	FileWrite $5 "$2$\r$\n"
	Goto Loop
	FileWrite $5 $6
	Goto Loop
	Exit:
	 
	 FileClose $5
	 FileClose $4
	 
	SetDetailsPrint none
	Delete $0
	Rename $7 $0
	SetDetailsPrint both
	 
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd
Function .onInit
	!insertmacro MUI_INSTALLOPTIONS_EXTRACT "WrapperCompilerForm.ini"
	SetOutPath $EXEDIR
	
	CreateDirectory $EXEDIR\bin
	
	ReadINIStr $SKIPWELCOMEPAGE $EXEDIR\bin\settings.ini WrapperCompiler SkipWelcomePage
	ReadINIStr $0 $EXEDIR\bin\settings.ini WrapperCompiler Drive
	ReadINIStr $PACKAGE $EXEDIR\bin\settings.ini WrapperCompiler Package
	; Update drive letter; doesn't matter if $0 == ""
	StrLen $1 $0
	StrCpy $2 $PACKAGE $1
	${If} $2 == $0
		StrCpy $PACKAGE $PACKAGE "" $1
		StrCpy $PACKAGE $0$PACKAGE
	${EndIf}

	;StrCpy $NSIS "$EXEDIR\App\NSIS\makensis.exe"
	ReadINIStr $NSIS $EXEDIR\bin\settings.ini WrapperCompiler makensis
	${If} $NSIS == ""
		StrCpy $NSIS ..\NSISPortable\App\NSIS\makensis.exe
		WriteINIStr $EXEDIR\bin\settings.ini WrapperCompiler makensis $NSIS
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
		WriteINIStr $PLUGINSDIR\WrapperCompilerForm.ini "Field 2" "State" "$PACKAGE"
FunctionEnd

Function ShowWelcomeWindow
	StrCmp $SKIPWELCOMEPAGE "true" "" ShowWelcomeWindowEnd
		Abort
	ShowWelcomeWindowEnd:
FunctionEnd

Function ShowOptionsWindow
	!insertmacro MUI_HEADER_TEXT "PortableApps Compiler" "a better alternative to PA.c Launcher"
	${IfThen} $AUTOMATICCOMPILE == "true" ${|} Abort ${|}
	InstallOptions::InitDialog /NOUNLOAD "$PLUGINSDIR\WrapperCompilerForm.ini"
    Pop $0
    InstallOptions::Show
FunctionEnd

Function LeaveOptionsWindow
	ReadINIStr $PACKAGE $PLUGINSDIR\WrapperCompilerForm.ini "Field 2" "State"

	${If} $PACKAGE == ""
		MessageBox MB_OK|MB_ICONEXCLAMATION `Please select a valid base directory to create a wrapper for.`
		Abort
	${EndIf}
	${GetRoot} $EXEDIR $0
	WriteINIStr $EXEDIR\bin\settings.ini WrapperCompiler Drive $0
	WriteINIStr $EXEDIR\bin\settings.ini WrapperCompiler Package $PACKAGE
FunctionEnd

Function ConvertLanguageEnvironmentVariables
	Pop $9 # file

	FileOpen $8 $9 r
	FileReadWord $8 $7
	FileClose $8

	SetDetailsPrint none
	${If} $7 = 0xFEFF
		; Convert old PAL to PAC
		${ReplaceInFileUTF16LE} $9 PortableApps.comLanguageCode  PAC:LanguageCode
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleCode2   PAC:LanguageCode2
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleCode3   PAC:LanguageCode3
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleGlibc   PAC:LanguageGlibc
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleWinName PAC:LanguageNSIS
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleName    PAC:LanguageName
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleID      PAC:LanguageLCID
		; Convert new PAL to PAC
		${ReplaceInFileUTF16LE} $9 PAL:LanguageCode		PAC:LanguageCode
		${ReplaceInFileUTF16LE} $9 PAL:LocaleCode2		PAC:LanguageCode2
		${ReplaceInFileUTF16LE} $9 PAL:LocaleCode3		PAC:LanguageCode3
		${ReplaceInFileUTF16LE} $9 PAL:LocaleGlibc		PAC:LanguageGlibc
		${ReplaceInFileUTF16LE} $9 PAL:LocaleWinName	PAC:LanguageNSIS
		${ReplaceInFileUTF16LE} $9 PAL:LocaleName		PAC:LanguageName
		${ReplaceInFileUTF16LE} $9 PAL:LocaleID			PAC:LanguageLCID
		${ReplaceInFileUTF16LE} $9 PAL:LanguageCustom	PAC:LanguageCustom
	${Else}
		; Convert old PAL to PAC
		${ReplaceInFile} $9 PortableApps.comLanguageCode  PAC:LanguageCode
		${ReplaceInFile} $9 PortableApps.comLocaleCode2   PAC:LanguageCode2
		${ReplaceInFile} $9 PortableApps.comLocaleCode3   PAC:LanguageCode3
		${ReplaceInFile} $9 PortableApps.comLocaleGlibc   PAC:LanguageGlibc
		${ReplaceInFile} $9 PortableApps.comLocaleWinName PAC:LanguageNSIS
		${ReplaceInFile} $9 PortableApps.comLocaleName    PAC:LanguageName
		${ReplaceInFile} $9 PortableApps.comLocaleID      PAC:LanguageLCID
		; Convert new PAL to PAC
		${ReplaceInFile} $9 PAL:LanguageCode	PAC:LanguageCode
		${ReplaceInFile} $9 PAL:LocaleCode2		PAC:LanguageCode2
		${ReplaceInFile} $9 PAL:LocaleCode3		PAC:LanguageCode3
		${ReplaceInFile} $9 PAL:LocaleGlibc		PAC:LanguageGlibc
		${ReplaceInFile} $9 PAL:LocaleWinName	PAC:LanguageNSIS
		${ReplaceInFile} $9 PAL:LocaleName		PAC:LanguageName
		${ReplaceInFile} $9 PAL:LocaleID		PAC:LanguageLCID
		${ReplaceInFile} $9 PAL:LanguageCustom	PAC:LanguageCustom
	${EndIf}
	SetDetailsPrint lastused
FunctionEnd

Function ConvertDefines
	Pop $9 # file

	FileOpen $8 $9 r
	FileReadWord $8 $7
	FileClose $8

	SetDetailsPrint none
	StrCpy $0 $${
	${If} $7 = 0xFEFF
		${ReplaceInFileUTF16LE} $9 PortableApps.comLanguageCode		PortableAppsLanguageCode
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleCode2		PortableAppsLocaleCode2
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleCode3		PortableAppsLocaleCode3
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleGlibc		PortableAppsLocaleGlibc
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleWinName	PortableAppsLocaleWinName
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleName		PortableAppsLocaleName
		${ReplaceInFileUTF16LE} $9 PortableApps.comLocaleID			PortableAppsLocaleID
		${ReplaceInFileUTF16LE} $9 $0ReadUser}						$0ReadUserConfig}
		${ReplaceInFileUTF16LE} $9 $0LAUNCHER}						$0WRAPPER}
		${ReplaceInFileUTF16LE} $9 $0LAUNCHER2}						$0WRAPPER2}
		${ReplaceInFileUTF16LE} $9 $0OTHER}							$0ETC}
		${ReplaceInFileUTF16LE} $9 $0SETINI}						$0CONFIGINI}
		${ReplaceInFileUTF16LE} $9 $0PAL}							$0PAC}
		${ReplaceInFileUTF16LE} $9 $0DEFSET}						$0DEFCONF}
		${ReplaceInFileUTF16LE} $9 $0SET}							$0CONF}
		${ReplaceInFileUTF16LE} $9 $0DEFDATA}						$0DEFSET}
		${ReplaceInFileUTF16LE} $9 $0DATA}							$0SET}
		${ReplaceInFileUTF16LE} $9 $0ReadLauncherConfig}			$0ReadWrapperConfig}
		${ReplaceInFileUTF16LE} $9 $0WriteLauncherConfig}			$0WriteWrapperConfig}
		${ReplaceInFileUTF16LE} $9 $0DeleteLauncherConfig}			$0DeleteWrapperConfig}
		${ReplaceInFileUTF16LE} $9 $0DeleteLauncherConfigSec}		$0DeleteWrapperConfigSec}
		${ReplaceInFileUTF16LE} $9 $0ReadLauncherConfigWithDefault}	$0ReadWrapperConfigWithDefault}
		${ReplaceInFileUTF16LE} $9 $0PAF}							$0TREE}
		${ReplaceInFileUTF16LE} $9 $0PAFKEYS}						$0TREEKEYS}		
		${ReplaceInFileUTF16LE} $9 PAL:LanguageCode					PAC:LanguageCode
		${ReplaceInFileUTF16LE} $9 PAL:LocaleCode2					PAC:LanguageCode2
		${ReplaceInFileUTF16LE} $9 PAL:LocaleCode3					PAC:LanguageCode3
		${ReplaceInFileUTF16LE} $9 PAL:LocaleGlibc					PAC:LanguageGlibc
		${ReplaceInFileUTF16LE} $9 PAL:LocaleWinName				PAC:LanguageNSIS
		${ReplaceInFileUTF16LE} $9 PAL:LocaleName					PAC:LanguageName
		${ReplaceInFileUTF16LE} $9 PAL:LocaleID						PAC:LanguageLCID
		${ReplaceInFileUTF16LE} $9 PAL:LanguageCustom				PAC:LanguageCustom
	${Else}
		${ReplaceInFile} $9 PortableApps.comLanguageCode		PortableAppsLanguageCode
		${ReplaceInFile} $9 PortableApps.comLocaleCode2			PortableAppsLocaleCode2
		${ReplaceInFile} $9 PortableApps.comLocaleCode3			PortableAppsLocaleCode3
		${ReplaceInFile} $9 PortableApps.comLocaleGlibc			PortableAppsLocaleGlibc
		${ReplaceInFile} $9 PortableApps.comLocaleWinName		PortableAppsLocaleWinName
		${ReplaceInFile} $9 PortableApps.comLocaleName			PortableAppsLocaleName
		${ReplaceInFile} $9 PortableApps.comLocaleID			PortableAppsLocaleID
		${ReplaceInFile} $9 $0ReadUser}							$0ReadUserConfig}
		${ReplaceInFile} $9 $0LAUNCHER}							$0WRAPPER}
		${ReplaceInFile} $9 $0LAUNCHER2}						$0WRAPPER2}
		${ReplaceInFile} $9 $0OTHER}							$0ETC}
		${ReplaceInFile} $9 $0SETINI}							$0CONFIGINI}
		${ReplaceInFile} $9 $0PAL}								$0PAC}
		${ReplaceInFile} $9 $0DEFSET}							$0DEFCONF}
		${ReplaceInFile} $9 $0SET}								$0CONF}
		${ReplaceInFile} $9 $0DEFDATA}							$0DEFSET}
		${ReplaceInFile} $9 $0DATA}								$0SET}
		${ReplaceInFile} $9 $0ReadLauncherConfig}				$0ReadWrapperConfig}
		${ReplaceInFile} $9 $0WriteLauncherConfig}				$0WriteWrapperConfig}
		${ReplaceInFile} $9 $0DeleteLauncherConfig}				$0DeleteWrapperConfig}
		${ReplaceInFile} $9 $0DeleteLauncherConfigSec}			$0DeleteWrapperConfigSec}
		${ReplaceInFile} $9 $0ReadLauncherConfigWithDefault}	$0ReadWrapperConfigWithDefault}
		${ReplaceInFile} $9 $0PAF}								$0TREE}
		${ReplaceInFile} $9 $0PAFKEYS}							$0TREEKEYS}		
		${ReplaceInFile} $9 PAL:LanguageCode					PAC:LanguageCode
		${ReplaceInFile} $9 PAL:LocaleCode2						PAC:LanguageCode2
		${ReplaceInFile} $9 PAL:LocaleCode3						PAC:LanguageCode3
		${ReplaceInFile} $9 PAL:LocaleGlibc						PAC:LanguageGlibc
		${ReplaceInFile} $9 PAL:LocaleWinName					PAC:LanguageNSIS
		${ReplaceInFile} $9 PAL:LocaleName						PAC:LanguageName
		${ReplaceInFile} $9 PAL:LocaleID						PAC:LanguageLCID
		${ReplaceInFile} $9 PAL:LanguageCustom					PAC:LanguageCustom
	${EndIf}
	SetDetailsPrint lastused
FunctionEnd

Section Main
	${IfNot} ${FileExists} $NSIS
		StrCpy $ERROROCCURED true
		${WriteErrorLog} "NSIS not found at $NSIS."
		MessageBox MB_ICONSTOP "NSIS was not found! (Looked for it in $NSIS)${NEWLINE}${NEWLINE}You can specify a custom path to makensis.exe in $EXEDIR\bin\settings.ini, [WrapperCompiler]:makensis"
		Abort
	${EndIf}

	; Fix the package path, if necessary
	StrCpy $R1 $PACKAGE 1 -1
	${IfThen} $R1 == "\" ${|} StrCpy $PACKAGE $PACKAGE -1 ${|}

	SetDetailsPrint ListOnly
	DetailPrint "App: $PACKAGE"
	DetailPrint " "
	RealProgress::SetProgress /NOUNLOAD 0
	RealProgress::GradualProgress /NOUNLOAD 1 20 90 "Process complete."

	${IfNot} ${FileExists} "${APPINFOPATH}"
		StrCpy $ERROROCCURED true
		${WriteErrorLog} "${APPINFOPATH} doesn't exist!"
	${Else}
		${PromptUserInput} \
			"Package Name" \
			"${APPINFOPATH}" \
			"Details" \
			"Name" \
			"What's this package's name? (e.g. Discord Portable):" \
			"App Portable" \
			$Name \
			required
		${PromptUserInput} \
			"Package AppID" \
			"${APPINFOPATH}" \
			"Details" \
			"AppID" \
			"Enter the package's name with no spaces (e.g. DiscordPortable):" \
			"AppPortable" \
			$AppID \
			required
		${PromptUserInput} \
			"Package Version" \
			"${APPINFOPATH}" \
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
			
		;Delete existing installer if there is one
		Delete "$PACKAGE\$AppID.exe"
		${If} ${FileExists} "$PACKAGE\$AppID.exe"
			StrCpy $ERROROCCURED true
			${WriteErrorLog} "ERROR: Cannot remove $PACKAGE\$AppID.exe! Is $AppID currently running?"
		${EndIf}
	${EndIf}
		
	; Check for old PAF builds and convert them to the new format...
	DetailPrint "Checking for old PAF build to convert to the new format..."
	DetailPrint " "
	
	${If} ${FileExists} "$PACKAGE\App\AppInfo\Launcher\*.*"
		StrCpy $CONVERT true
	${EndIf}

	SetDetailsPrint none
	${IfNot} ${FileExists} "$PACKAGE\bin\*.*"
		CreateDirectory "$PACKAGE\bin"
	${EndIf}
	${IfNot} ${FileExists} "$PACKAGE\etc\*.*"
		CreateDirectory "$PACKAGE\etc"
	${EndIf}
	SetDetailsPrint lastused
	
	${If} $CONVERT == true
		${If} ${FileExists} "$PACKAGE\App\AppInfo\Launcher\Custom.nsh"
			${ConvertPath} "App\AppInfo\Launcher\Custom.nsh" "App\AppInfo\${EXTEND}"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\App\AppInfo\Launcher\Debug.nsh"
			${ConvertPath} "App\AppInfo\Launcher\Debug.nsh" "App\AppInfo\${DBUG}"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\App\AppInfo\instsller.ini"
			${ConvertPath} "App\AppInfo\installer.ini" "App\AppInfo\${INSTALLINI}"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\App\AppInfo\Launcher\$AppID.ini"
			${ConvertPath} "App\AppInfo\Launcher\$AppID.ini" "App\AppInfo\${WRAPPERINI}"
			${If} ${FileExists} "$PACKAGE\App\AppInfo\Launcher\Source\*.*"
				StrCpy $FGBUILD true
				DetailPrint "Found a PAF built by FukenGruven!"
				DetailPrint "Preserving his old source files..."
				DetailPrint "Moving App\AppInfo\Launcher\Source -> etc\FGSource"
				SetDetailsPrint none
				CopyFiles /SILENT "$PACKAGE\App\AppInfo\Launcher\Source" "$PACKAGE\etc\FGSource"
				RMDir /r "$PACKAGE\App\AppInfo\Launcher\Source"
			${EndIf}
			RMDir /r "$PACKAGE\App\AppInfo\Launcher"
			SetDetailsPrint lastused
		${EndIf}
		${If} ${FileExists} "$PACKAGE\App\$AppShortname\*.*"
			DetailPrint "Moving the 32-bit application files..."
			DetailPrint "Moving App\$AppShortname -> bin\$AppShortname"
			SetDetailsPrint none
			CopyFiles /SILENT "$PACKAGE\App\$AppShortname" "$PACKAGE\bin\$AppShortname"
			RMDir /r "$PACKAGE\App\$AppShortname"
			SetDetailsPrint lastused
		${EndIf}
		${If} ${FileExists} "$PACKAGE\App\$AppShortname64\*.*"
			DetailPrint "Moving the 64-bit application files..."
			DetailPrint "Moving App\$AppShortname64 -> bin\$AppShortname64"
			SetDetailsPrint none
			CopyFiles /SILENT "$PACKAGE\App\$AppShortname64" "$PACKAGE\bin\$AppShortname64"
			RMDir /r "$PACKAGE\App\$AppShortname64"
			SetDetailsPrint lastused
		${EndIf}
		${If} ${FileExists} "$PACKAGE\App\DefaultData\*.*"
			${If} ${FileExists} "$PACKAGE\App\DefaultData\settings\*.*"
				${ConvertPath} "App\DefaultData\settings" "App\DefaultData\Config"
			${EndIf}
			${ConvertPath} "App\DefaultData" "App\DefaultSettings"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\Data\*.*"
			${If} ${FileExists} "$PACKAGE\Data\settings\*.*"
				${ConvertPath} "Data\settings" "Data\Config"
			${EndIf}
			DetailPrint "Moving Data -> bin\Settings"
			SetDetailsPrint none
			CopyFiles /SILENT "$PACKAGE\Data" "$PACKAGE\bin\Settings"
			RMDir /r "$PACKAGE\Data"
			SetDetailsPrint lastused
		${EndIf}
		SetDetailsPrint none
		${If} ${FileExists} "$PACKAGE\App\Readme.txt"
			Delete "$PACKAGE\App\Readme.txt"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\help.html"
			Delete "$PACKAGE\help.html"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\App\AppInfo\eula.txt"
			Rename "$PACKAGE\App\AppInfo\eula.txt" "$PACKAGE\App\AppInfo\eula.txt.temp"
			Rename "$PACKAGE\App\AppInfo\eula.txt.temp" "$PACKAGE\App\AppInfo\EULA.txt"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\Other\Source\LauncherLicense.txt"
			Delete "$PACKAGE\Other\Source\LauncherLicense.txt"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\Other\Source\COPYING"
			Delete "$PACKAGE\Other\Source\COPYING"
		${EndIf}
		${If} ${FileExists} "$PACKAGE\Other\*.*"
			${If} ${FileExists} "$PACKAGE\Other\Help\*.*"
				RMDir /r "$PACKAGE\Other\Help"
			${EndIf}
			SetDetailsPrint lastused
			${If} ${FileExists} "$PACKAGE\Other\Source\Readme.txt"
				${ConvertPath} "Other\Source\Readme.txt" "etc\README"
			${EndIf}
			${If} ${FileExists} "$PACKAGE\Other\notes.txt"
				${ConvertPath} "Other\notes.txt" "etc\NOTES"
			${EndIf}
			${If} ${FileExists} "$PACKAGE\Other\Source\$AppID.ini"
				${ConvertPath} "Other\Source\$AppID.ini" "etc\$AppID.ini"
			${EndIf}
			${ForEachFile} $5 $6 "$PACKAGE\Other\Source\*.*"
				Rename "$5\$6" "etc\$6"
			${NextFile}
			${ForEachFile} $5 $6 "$PACKAGE\Other\*.*"
				Rename "$5\$6" "etc\$6"
			${NextFile}
			${If} ${FileExists} "$PACKAGE\Other\Source\PortableApps.comInstallerCustom.nsh"
				${ConvertPath} "Other\Source\PortableApps.comInstallerCustom.nsh" "App\AppInfo\${EXTINS}"
			${EndIf}
			SetDetailsPrint none
			${IfNot} ${FileExists} "$PACKAGE\etc\UNLICENSE"
				CopyFiles /SILENT "$EXEDIR\etc\UNLICENSE" "$PACKAGE\etc\UNLICENSE"
			${EndIf}
			CopyFiles /SILENT "App\Other\*.*" "$PACKAGE\etc"
			RMDir /r "$PACKAGE\Other"
			Rename "$PACKAGE\App" "$PACKAGE\AppTemp"
			Rename "$PACKAGE\AppTemp" "$PACKAGE\app"
			Rename "$PACKAGE\App\AppInfo\appinfo.ini" "$PACKAGE\App\AppInfo\appinfo.ini.temp"
			Rename "$PACKAGE\App\AppInfo\appinfo.ini.temp" "$PACKAGE\App\AppInfo\AppInfo.ini"
			Rename "$PACKAGE\App\AppInfo\appicon.ico" "$PACKAGE\App\AppInfo\appicon.ico.temp"
			Rename "$PACKAGE\App\AppInfo\appicon.ico.temp" "$PACKAGE\App\AppInfo\AppIcon.ico"
			Rename "$PACKAGE\App\AppInfo\appicon_16.png" "$PACKAGE\App\AppInfo\appicon_16.png.temp"
			Rename "$PACKAGE\App\AppInfo\appicon_16.png.temp" "$PACKAGE\App\AppInfo\AppIcon_16.png"
			Rename "$PACKAGE\App\AppInfo\appicon_32.png" "$PACKAGE\App\AppInfo\appicon_32.png.temp"
			Rename "$PACKAGE\App\AppInfo\appicon_32.png.temp" "$PACKAGE\App\AppInfo\AppIcon_32.png"
			Rename "$PACKAGE\App\AppInfo\appicon_128.png" "$PACKAGE\App\AppInfo\appicon_128.png.temp"
			Rename "$PACKAGE\App\AppInfo\appicon_128.png.temp" "$PACKAGE\App\AppInfo\AppIcon_128.png"
			ClearErrors
			${If} ${FileExists} "$PACKAGE\App\AppInfo\${EXTINS}"
				MessageBox MB_ICONEXCLAMATION|MB_TOPMOST "${PAInstaller}"					
				DetailPrint "Converting ${EXTINS} -> PortableApps.comInstallerCustom.nsh"
				${IfNot} ${FileExists} "$PACKAGE\Other\Source\*.*"
					CreateDirectory "$PACKAGE\Other\Source"
				${EndIf}
				Rename "$PACKAGE\App\AppInfo\${EXTINS}" "$PACKAGE\Other\Source\PortableApps.comInstallerCustom.nsh"
				CopyFiles /SILENT "$EXEDIR\etc\*.html" "$PACKAGE"
			${EndIf}
			; ReadINIStr $0 $EXEDIR\bin\settings.ini WrapperCompiler notified
			; ${If} ${Errors}
			; ${AndIf} $0 != true
				; ReadINIStr $1 $EXEDIR\bin\settings.ini WrapperCompiler help
				; ${If} $1 != false
					; MessageBox MB_ICONEXCLAMATION|MB_TOPMOST "The Help.html was deleted but creating a dummy one now.$\r$\n$\r$\nThis is so you can use the PA.c Installer to package this build."
					; CopyFiles /SILENT "$EXEDIR\etc\*.html" "$PACKAGE"
					; WriteINIStr $EXEDIR\bin\settings.ini WrapperCompiler notified true
				; ${EndIf}
				; MessageBox MB_ICONQUESTION|MB_YESNO|MB_TOPMOST "Keep creating the dummy help.html file for future builds?" /SD IDYES IDNO _DUMMY_NO
				; WriteINIStr $EXEDIR\bin\settings.ini WrapperCompiler help true
				; Goto _DUMMY_END
				; _DUMMY_NO:
				; WriteINIStr $EXEDIR\bin\settings.ini WrapperCompiler help false
				; Delete "$PACKAGE\help.html"
				; MessageBox MB_ICONEXCLAMATION|MB_TOPMOST "Okay. Deleting current help.html file...$\r$\n$\r$\nFuture builds won't have it either!"
				; _DUMMY_END:
				; MessageBox MB_ICONEXCLAMATION|MB_TOPMOST "That was the last time you will see that message."
			; ${EndIf}
		${EndIf}
		SetDetailsPrint lastused
	
		; Check for old PAF builds and convert them to the new format...
		DetailPrint "Process complete."
		DetailPrint " "
		DetailPrint "Converting all old variables to the new variables..."
		DetailPrint "For Example: %PAL:AppDir% -> %PAC:AppDir%"
		DetailPrint " "
		SetDetailsPrint none
		${StringConvertInFile} "$PACKAGE\bin\Settings\Config\$AppIDSettings.ini" "PAL:" "PAC:"
		${StringConvertInFile} "$PACKAGE\bin\Settings\Config\$AppIDSettings.ini" "PortableApps.comLauncher" "PortableAppsCompiler"
		${StringConvertInFile} "${WRAPPERPATH}" "%PAL:" "%PAC:"
		${StringConvertInFile} "${WRAPPERPATH}" "PortableApps.comLauncher" "PortableAppsCompiler"
		${StringConvertInFile} "${WRAPPERPATH}" "PortableApps.com" "PortableApps"

		Push "${WRAPPERPATH}"
		Call ConvertLanguageEnvironmentVariables
		Push "${EXTENDPATH}"
		Call ConvertDefines
		SetDetailsPrint lastused
		DetailPrint "Process complete."
		DetailPrint " "
	${Else}
		DetailPrint "No conversion needed."
		DetailPrint " "
	${EndIf}
	
	SetDetailsPrint none
	${If} ${FileExists} "${EXTENDPATH}"
		${LineReadInFile} "${EXTENDPATH}" "2" $R0
		${If} $R0 != ";= WRAPPER$\r$\n"
			FileOpen $0 "${EXTENDPATH}" r
			FileOpen $1 "${EXTENDPATH}.temp" w

			FileWrite $1 "${EXTHEADER}"
			FileWriteByte $1 "13"
			FileWriteByte $1 "10"
			_EXT_LOOP:
				ClearErrors
				FileReadByte $0 $2
				IfErrors _EXT_DONE
				FileWriteByte $1 $2
				Goto _EXT_LOOP
			_EXT_DONE:
				FileClose $0
				FileClose $1
				
			Delete "${EXTENDPATH}"
			Rename "${EXTENDPATH}.temp" "${EXTENDPATH}"
		${ElseIf} $R0 == ";= LAUNCHER$\r$\n"
			${ReplaceLineInFile} "${EXTENDPATH}" "2" ";= WRAPPER"
			${ReplaceLineInFile} "${EXTENDPATH}" "4" ";  This portable application was compiled with"
			${ReplaceLineInFile} "${EXTENDPATH}" "5" ";  PortableApps Compiler: Development Edition:"
			${LineReadInFile} "${EXTENDPATH}" "6" $R0
			${If} $R0 == "$\r$\n"
				${AddToLineInFile} "${EXTENDPATH}" "6" "$\r$\n"
			${EndIf}
			${ReplaceLineInFile} "${EXTENDPATH}" "6" ";  https://github.com/daemondevin/pac-man/tree/dev"
			${LineReadInFile} "${EXTENDPATH}" "7" $R0
			${If} $R0 == "$\r$\n"
				${AddToLineInFile} "${EXTENDPATH}" "7" "$\r$\n"
			${EndIf}
			${ReplaceLineInFile} "${EXTENDPATH}" "7" "; "
		${EndIf}
	${EndIf}
	SetDetailsPrint lastused
	
	DetailPrint "Compiling the portable wrapper..."
	DetailPrint " "
	SetDetailsPrint none
	
	Delete "$EXEDIR\bin\WrapperCompilerLog.txt"

	Delete "${DEFINEINC}"

	!ifdef CustomIconAndName
		!define _ $PACKAGE
	!else
		!define _ $EXEDIR
	!endif
	SetDetailsPrint lastused
	
	; Read/write the needed defines to PortableAppsCompilerDefines.nsh 
	DetailPrint "Writing the wrapper's configuration settings..."
	DetailPrint " "
	FileOpen $DEFINES "${DEFINEINC}" w
	FileWrite $DEFINES "${DEFHEADER}"
	FileWriteByte $9 "13"
	FileWriteByte $9 "10"
	
	${IfNot} ${FileExists} "${_}\App\AppInfo\AppInfo.ini"
		StrCpy $ERROROCCURED true
		${WriteErrorLog} "${_}\App\AppInfo\AppInfo.ini doesn't exist!"
	${Else}
		ClearErrors
		${WriteDefineConfig} "PORTABLEAPPNAME" "$AppPName" "$\t"
		${WriteDefineConfig} "FULLNAME" "$AppFullname" "$\t$\t"
		${WriteDefineConfig} "APPNAME" "$AppID" "$\t$\t$\t"
		${WriteDefineConfig} "PACKAGE_VERSION" "$AppVersion" "$\t"
		
		ClearErrors
		${ReadWrapperConfig} $Hybrid "Activate" "DualMode"
		${IfNot} ${Errors}
		${AndIf} $Hybrid != ""
			${WriteDefineConfig} "APP" "$AppShortname" "$\t$\t$\t$\t"
			${WriteDefineConfig} "APPDIR" "$$EXEDIR\bin\$${APP}" "$\t$\t$\t"
			${ReadWrapperConfig} $0 "Launch" "ProgramExecutable"
			${IfNot} ${Errors}
				${WriteDefineConfig} "32" "$0" "$\t$\t$\t$\t"
				${WriteDefineConfig} "EXE32" "$$EXEDIR\bin\$${32}" "$\t$\t$\t"
				${WriteDefineConfig} "SET32" "Kernel32::SetEnvironmentVariable(t'$Hybrid',t'$AppShortname')" "$\t$\t$\t"
			${EndIf}
			${WriteDefineConfig} "APP64" "$AppShortname64" "$\t$\t$\t"
			${WriteDefineConfig} "APPDIR64" "$$EXEDIR\bin\$${APP64}" "$\t$\t"
			ClearErrors
			${ReadWrapperConfig} $0 "Launch" "ProgramExecutable64"
			${IfNot} ${Errors}
				${WriteDefineConfig} "64" "$0" "$\t$\t$\t$\t"
				${WriteDefineConfig} "EXE64" "$$EXEDIR\bin\$${64}" "$\t$\t$\t"
				${WriteDefineConfig} "SET64" "Kernel32::SetEnvironmentVariable(t'$Hybrid',t'$AppShortname64')" "$\t$\t$\t"
			${EndIf}
		${Else}
			${ReadWrapperConfig} $0 "Launch" "ProgramExecutable64"
			${IfNot} ${Errors}
				${WriteDefineConfig} "APP64" "$AppShortname64" "$\t$\t$\t$\t"
				${WriteDefineConfig} "APPDIR64" "$$EXEDIR\bin\$${APP64}" "$\t$\t$\t"
			${Else}
				${WriteDefineConfig} "APP" "$AppShortname" "$\t$\t$\t$\t"
				${WriteDefineConfig} "APPDIR" "$$EXEDIR\bin\$${APP}" "$\t$\t$\t"
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
		${WriteDefineConfig} "DEVELOPER" "$0" "$\t$\t"
		ClearErrors
		${ReadAppInfoConfig} $0 "Team" "Contributors"
		${IfNot} ${Errors}
			${WriteDefineConfig} "CONTRIBUTORS" "$0" "$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Details" "Publisher"
		${IfNot} ${Errors}
			${WriteDefineConfig} "PUBLISHER" "$0" "$\t$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Details" "Trademarks"
		${IfNot} ${Errors}
			${WriteDefineConfig} "TRADEMARK" "$0" "$\t$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Control" "Start"
		${IfNot} ${Errors}
			${WriteDefineConfig} "OUTFILE" "$0" "$\t$\t$\t"
		${EndIf}		
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "UsesDotNetVersion"
		${IfNot} ${Errors}
			${If} $0 != false
				${WriteDefineConfig} "DOTNET" "" ""
			${EndIf}
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "UseStdUtils"
		${IfNot} ${Errors}
			${WriteDefineConfig} "UseStdUtils" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "INF_Install"
		${IfNot} ${Errors}
			${WriteDefineConfig} "INF_Install" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "RegistryValueWrite"
		${IfNot} ${Errors}
			${WriteDefineConfig} "RegSleep" "50" "$\t$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "FileWriteReplace"
		${IfNot} ${Errors}
			${WriteDefineConfig} "REPLACE" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "CloseWindow"
		${IfNot} ${Errors}
			${WriteDefineConfig} "CloseWindow" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "FileLocking"
		${IfNot} ${Errors}
			${WriteDefineConfig} "IsFileLocked" "" ""
			${AddConditionIfNot} "CloseWindow"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "Firewall"
		${IfNot} ${Errors}
			${WriteDefineConfig} "FIREWALL" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "Junctions"
		${IfNot} ${Errors}
			${WriteDefineConfig} "NTFS" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "ACLRegSupport"
		${IfNot} ${Errors}
			${WriteDefineConfig} "ACL" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "ACLDirSupport"
		${IfNot} ${Errors}
			${WriteDefineConfig} "ACL_DIR" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "RMEmptyDir"
		${IfNot} ${Errors}
			${WriteDefineConfig} "RMEMPTYDIRECTORIES" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "LocalLow"
		${IfNot} ${Errors}
			${WriteDefineConfig} "LocalLow" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "PublicDoc"
		${IfNot} ${Errors}
			${WriteDefineConfig} "PublicDoc" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "CompareVersions"
		${IfNot} ${Errors}
			${WriteDefineConfig} "CompareVersions" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "ConfigFunctions"
		${IfNot} ${Errors}
			${WriteDefineConfig} "ConFunc" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "JSONSupport"
		${IfNot} ${Errors}
			${WriteDefineConfig} "JSON" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "RestartSleep"
		${IfNot} ${Errors}
			${WriteDefineConfig} "Sleep" "$0" "$\t$\t$\t"
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "WinMessages"
		${IfNot} ${Errors}
			${WriteDefineConfig} "Include_WinMessages" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "LineWrite"
		${IfNot} ${Errors}
			${WriteDefineConfig} "Include_LineWrite" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "TrimString"
		${IfNot} ${Errors}
			${WriteDefineConfig} "TrimString" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "CloseProcess"
		${IfNot} ${Errors}
			${WriteDefineConfig} "CloseProc" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "Include64"
		${IfNot} ${Errors}
			${WriteDefineConfig} "64.nsh" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "IncludeWordRep"
		${IfNot} ${Errors}
			${WriteDefineConfig} "Include_WordRep" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "GetBetween"
		${IfNot} ${Errors}
			${WriteDefineConfig} "GetBetween.nsh" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "DisableLanguageCustom"
		${IfNot} ${Errors}
			${WriteDefineConfig} "DisablePAC:LanguageCustom" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "DisableProgramExecSegment"
		${IfNot} ${Errors}
			${WriteDefineConfig} "DisableProgramExecSegment" "" ""
		${EndIf}
		ClearErrors
		${ReadAppInfoConfig} $0 "Dependencies" "TLB_FUNCTION"
		${IfNot} ${Errors}
			${WriteDefineConfig} "TLB_FUNCTION" "" ""
		${EndIf}
	${EndIf}

	${IfNot} ${FileExists} "${_}\App\AppInfo\${WRAPPERINI}"
		StrCpy $ERROROCCURED true
		${WriteErrorLog} "${_}\App\AppInfo\${WRAPPERINI} doesn't exist!"
	${Else}
		ClearErrors
		${ReadWrapperConfig} $0 "Launch" "RunAsAdmin"
        ${IfNot} ${Errors}
			${If} $0 == "try"
			${OrIf} $0 == "force"
			${OrIf} $0 == "compile-force"
				${WriteDefineConfig} "UAC" "" ""
			${EndIf}
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "DualMode"
		${IfNot} ${Errors}
			${WriteDefineConfig} "HYBRID" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "Registry"
		${IfNot} ${Errors}
			${WriteDefineConfig} "REGISTRY" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "RegRedirection"
		${IfNot} ${Errors}
			${WriteDefineConfig} "DISABLEFSR" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "RegCopyKeys"
		${IfNot} ${Errors}
			${WriteDefineConfig} "RegCopy" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "Redirection"
		${IfNot} ${Errors}
			${WriteDefineConfig} "SYSTEMWIDE_DISABLEREDIR" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "ForceRedirection"
		${IfNot} ${Errors}
			${WriteDefineConfig} "FORCE_SYSTEMWIDE_DISABLEREDIR" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "ExecAsUser"
		${IfNot} ${Errors}
			${WriteDefineConfig} "ExecAsUser" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "Services"
		${IfNot} ${Errors}
			${WriteDefineConfig} "SERVICES" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "RegDLLs"
		${IfNot} ${Errors}
			${WriteDefineConfig} "REGISTERDLL" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "Tasks"
		${IfNot} ${Errors}
			${WriteDefineConfig} "TaskCleanUp" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "Java"
		${IfNot} ${Errors}
			${If} $0 == "find"
			${OrIf} $0 == "require"
				${WriteDefineConfig} "JAVA" "" ""
			${EndIf}
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "XML"
		${IfNot} ${Errors}
			${WriteDefineConfig} "XML_PLUGIN" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "Ghostscript"
		${IfNot} ${Errors}
			${WriteDefineConfig} "GHOSTSCRIPT" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "FontsFolder"
		${IfNot} ${Errors}
			${WriteDefineConfig} "FONTS_ENABLE" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "FileCleanup"
		${IfNot} ${Errors}
			${WriteDefineConfig} "FileCleanup" "" ""
		${EndIf}
		ClearErrors
		${ReadWrapperConfig} $0 "Activate" "DirectoryCleanup"
		${IfNot} ${Errors}
			${WriteDefineConfig} "DirectoryCleanup" "" ""
		${EndIf}
		
		FileClose $DEFINES
	
		StrCpy $2 ""
		; See if we need to enable XML
		ReadINIStr $3 "${_}\App\AppInfo\${WRAPPERINI}" Activate XML
		${If} $3 == true
			StrCpy $2 "$2 /DXML_ENABLED"
		${EndIf}

		; See if we need to use the RequestExecutionLevel admin
		ReadINIStr $3 "${_}\App\AppInfo\${WRAPPERINI}" Launch RunAsAdmin
		${If} $3 == compile-force
			StrCpy $2 "$2 /DRUNASADMIN_COMPILEFORCE"
		${EndIf}
		
		; See if automatic signing is requested
		ReadINIStr $3 "${_}\App\AppInfo\AppInfo.ini" Team CertSigning
		${If} $3 == true
			StrCpy $2 "$2 /DCertificate"
			${PromptUserInput} \
				"Code Signing" \
				"${_}\App\AppInfo\AppInfo.ini" \
				"Team" \
				"CertExtension" \
				"What's the extension of you're certificate? (e.g. pfx):" \
				"p12" \
				$5 \
				optional
			StrCpy $2 "$2 /DCertExtension=$5"
			${PromptUserInput} \
				"Code Signing" \
				"${_}\App\AppInfo\AppInfo.ini" \
				"Team" \
				"CertTimestamp" \
				"What time-stamp service to use? (e.g. GlobalSign):" \
				"Comodo" \
				$6 \
				optional
			StrCpy $2 "$2 /DCertTimestamp=$6"
		${EndIf}
	${EndIf}

	${If} $ERROROCCURED != true
		; Build the thing
		ExecDos::exec `"$NSIS" /O"$EXEDIR\bin\WrapperCompilerLog.txt" /DPACKAGE="$PACKAGE" /DNamePortable="$Name" /DAppID="$AppID" /DVersion="${PACVER}"$2 "$EXEDIR\etc\source\PortableAppsCompiler.nsi"` "" ""
		Pop $R1
		${If} $R1 <> 0
			StrCpy $ERROROCCURED true
			${WriteErrorLog} "MakeNSIS exited with status code $R1"
		${EndIf}
	${EndIf}

	SetDetailsPrint ListOnly

	DetailPrint " "
	DetailPrint "Process Complete."
	${If} ${FileExists} $PACKAGE\$AppID.exe
		StrCpy $FINISHTITLE "Wrapper Created"
		StrCpy $FINISHTEXT "The wrapper has been created. Wrapper location:\r\n$PACKAGE\r\n\r\nWrapper name:\r\n$AppID.exe" 
	${Else}
		StrCpy $FINISHTITLE "An Error Occurred"
		StrCpy $FINISHTEXT "The wrapper was not created. You can view the log file for more information."
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
