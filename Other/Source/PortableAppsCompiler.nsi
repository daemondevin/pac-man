;=#
;
; PortableApps Compiler
; Developer: Devin "demon.devin" Gaul
;
; For support, visit the GitHub project:
; https://github.com/demondevin/pac-man
;
; Based on the code stylings of John T. Haller,
; Chris Morgan, FukenGruven, and Azure Zanculmarktum
;
!verbose 3

;= DEFINE PACKAGE
;= ################
!ifndef PACKAGE
	!define PACKAGE ..\..
!endif

;= ECHO MACRO
;= ################
!macro !ECHO _MSG
	!verbose push
	!verbose 4
	!echo "${_MSG}"
	!verbose pop
!macroend
!define !ECHO "!insertmacro !ECHO"

;= Line Break
!define NEWLINE	`$\r$\n`

;= Require at least NSIS 3
!include RequireLatestNSIS.nsh

;= PAC VERSION
;= ################
!include Version.nsh
${!ECHO} "${NEWLINE}PORTABLEAPPS COMPILER${NEWLINE}Developed by demon.devin${NEWLINE}Version: ${PACVER}${NEWLINE}${NEWLINE}"

;= GET/SET DEFINES
;= ################
!include Defines.nsh

;= RUNTIME SWITCHS
;= ################
Unicode true
WindowIcon Off
XPStyle on
SilentInstall Silent
AutoCloseWindow true
!ifdef RUNASADMIN_COMPILEFORCE
	RequestExecutionLevel admin
!else ifdef UAC
	RequestExecutionLevel admin
!else
	RequestExecutionLevel user
!endif
SetCompressor /SOLID lzma
SetCompressorDictSize 32

;= DEFINES
;= ################
!define APPINFO         `$EXEDIR\App\AppInfo`
!define INFOINI			`${APPINFO}\appinfo.ini`
!define DATA            `$EXEDIR\Data`
!define SET             `${DATA}\settings`
!define DEFDATA         `$EXEDIR\App\DefaultData`
!define DEFSET          `${DEFDATA}\settings`
!define LAUNCHDIR       `${APPINFO}\Launcher`
!define LAUNCHER        `${LAUNCHDIR}\${APPNAME}.ini`
!define LAUNCHER2       `$PLUGINSDIR\launcher.ini`
!define RUNTIME         `${DATA}\PortableAppsCompilerRuntimeData-${APPNAME}.ini`
!define RUNTIME2        `$PLUGINSDIR\runtimedata.ini`
!define SETINI          `${SET}\${APPNAME}Settings.ini`
!define CONFIG          `$EXEDIR\${APPNAME}.ini`
!define OTHER           `$EXEDIR\Other`
!define PAC				PortableAppsCompiler
!define /DATE YEAR		`%Y`
!define LCID			`kernel32::GetUserDefaultLangID()i .r0`
!define GETSYSWOW64		`kernel32::GetSystemWow64Directory(t .r0, i ${NSIS_MAX_STRLEN})`
!define DISABLEREDIR	`kernel32::Wow64EnableWow64FsRedirection(i0)`
!define ENABLEREDIR		`kernel32::Wow64EnableWow64FsRedirection(i1)`
!define GETCURRPROC		`kernel32::GetCurrentProcess()i.s`
!define WOW				`kernel32::IsWow64Process(is,*i.r0)`

;= MACROS
;= ################
!define ReadAppInfoConfig `!insertmacro _ReadAppInfoConfig`
!macro _ReadAppInfoConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} `${INFOINI}` `${_SECTION}` `${_KEY}`
!macroend
!define WriteAppInfoConfig `!insertmacro _WriteAppInfoConfig`
!macro _WriteAppInfoConfig _SECTION _KEY _VALUE
	WriteINIStr `${INFOINI}` `${_SECTION}` `${_KEY}` `${_VALUE}`
!macroend
!define DeleteAppInfoConfig `!insertmacro _DeleteAppInfoConfig`
!macro _DeleteAppInfoConfig _SECTION _KEY
	DeleteINIStr `${INFOINI}` `${_SECTION}` `${_KEY}`
!macroend
!define DeleteAppInfoConfigSec `!insertmacro _DeleteAppInfoConfigSec`
!macro _DeleteAppInfoConfigSec _SECTION
	DeleteINISec `${LAUNCHER}` `${_SECTION}`
!macroend
!define ReadLauncherConfig `!insertmacro _ReadLauncherConfig`
!macro _ReadLauncherConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} `${LAUNCHER}` `${_SECTION}` `${_KEY}`
!macroend
!define WriteLauncherConfig `!insertmacro _WriteLauncherConfig`
!macro _WriteLauncherConfig _SECTION _KEY _VALUE
	WriteINIStr `${LAUNCHER}` `${_SECTION}` `${_KEY}` `${_VALUE}`
!macroend
!define DeleteLauncherConfig `!insertmacro _DeleteLauncherConfig`
!macro _DeleteLauncherConfig _SECTION _KEY
	DeleteINIStr `${LAUNCHER}` `${_SECTION}` `${_KEY}`
!macroend
!define DeleteLauncherConfigSec `!insertmacro _DeleteLauncherConfigSec`
!macro _DeleteLauncherConfigSec _SECTION
	DeleteINISec `${LAUNCHER}` `${_SECTION}`
!macroend
!define ReadLauncherConfigWithDefault `!insertmacro _ReadLauncherConfigWithDefault`
!macro _ReadLauncherConfigWithDefault _VALUE _SECTION _KEY _DEFAULT
	ClearErrors
	${ReadLauncherConfig} ${_VALUE} `${_SECTION}` `${_KEY}`
	${IfThen} ${Errors} ${|} StrCpy ${_VALUE} `${_DEFAULT}` ${|}
!macroend
!define ReadUserConfig `!insertmacro _ReadUserConfig`
!macro _ReadUserConfig _VALUE _KEY
	${ConfigReadS} `${CONFIG}` `${_KEY}=` `${_VALUE}`
!macroend
!define WriteUserConfig `!insertmacro _WriteUserConfig`
!macro _WriteUserConfig _VALUE _KEY
	${ConfigWriteS} `${CONFIG}` `${_KEY}=` `${_VALUE}` $R0
!macroend
!define ReadUserOverrideConfig `!insertmacro _ReadUserOverrideConfigError`
!macro _ReadUserOverrideConfigError a b
	!error `ReadUserOverrideConfig has been renamed to ReadUserConfig in PAL 2.1.`
!macroend
!define InvalidValueError `!insertmacro _InvalidValueError`
!macro _InvalidValueError _SECTION_KEY _VALUE
	MessageBox MB_OK|MB_ICONSTOP `ERROR: Invalid value '${_VALUE}' for ${_SECTION_KEY}. Please refer to the official PA.c Launcher's Manual for valid values.`
!macroend
!define WriteRuntimeData "!insertmacro _WriteRuntimeData"
!macro _WriteRuntimeData _SECTION _KEY _VALUE
	WriteINIStr `${RUNTIME}` `${_SECTION}` `${_KEY}` `${_VALUE}`
	WriteINIStr `${RUNTIME2}` `${_SECTION}` `${_KEY}` `${_VALUE}`
!macroend
!define DeleteRuntimeData "!insertmacro _DeleteRuntimeData"
!macro _DeleteRuntimeData _SECTION _KEY
	DeleteINIStr `${RUNTIME}` `${_SECTION}` `${_KEY}`
	DeleteINIStr `${RUNTIME2}` `${_SECTION}` `${_KEY}`
!macroend
!define ReadRuntimeData "!insertmacro _ReadRuntimeData"
!macro _ReadRuntimeData _VALUE _SECTION _KEY
	IfFileExists `${RUNTIME}` 0 +3
	ReadINIStr `${_VALUE}` `${RUNTIME}` `${_SECTION}` `${_KEY}`
	Goto +2
	ReadINIStr `${_VALUE}` `${RUNTIME2}` `${_SECTION}` `${_KEY}`
!macroend
!define WriteRuntime "!insertmacro _WriteRuntime"
!macro _WriteRuntime _VALUE _KEY
	WriteINIStr `${RUNTIME}` ${PAC} `${_KEY}` `${_VALUE}`
	WriteINIStr `${RUNTIME2}` ${PAC} `${_KEY}` `${_VALUE}`
!macroend
!define ReadRuntime "!insertmacro _ReadRuntime"
!macro _ReadRuntime _VALUE _KEY
	IfFileExists `${RUNTIME}` 0 +3
	ReadINIStr `${_VALUE}` `${RUNTIME}` ${PAC} `${_KEY}`
	Goto +2
	ReadINIStr `${_VALUE}` `${RUNTIME2}` ${PAC} `${_KEY}`
!macroend
!define WriteSettings `!insertmacro _WriteSettings`
!macro _WriteSettings _VALUE _KEY
	WriteINIStr `${SETINI}` ${APPNAME}Settings `${_KEY}` `${_VALUE}`
!macroend
!define ReadSettings `!insertmacro _ReadSettings`
!macro _ReadSettings _VALUE _KEY
	ReadINIStr `${_VALUE}` `${SETINI}` ${APPNAME}Settings `${_KEY}`
!macroend
!define DeleteSettings `!insertmacro _DeleteSettings`
!macro _DeleteSettings _KEY
	DeleteINIStr `${SETINI}` ${APPNAME}Settings `${_KEY}`
!macroend

;= NSIS INCLUDES
;= ################
${!ECHO} "${NEWLINE}Including required files...${NEWLINE}${NEWLINE}"
;(Standard NSIS) {{{2
!include LangFile.nsh
!include LogicLib.nsh
!include FileFunc.nsh
!include TextFunc.nsh
!include WordFunc.nsh
!ifdef UAC
	!include UAC.nsh
!endif

;= NSIS PLUGINS
;= ################
!ifdef TLB_FUNCTION
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef ExecAsUser
	!include StdUtils.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef StdUtils
	!ifndef ExecAsUser
		!include StdUtils.nsh
		!ifndef PLUGINSDIR
			!define PLUGINSDIR
			!AddPluginDir Plugins
		!endif
	!endif
!endif
!ifdef REPLACE
	!include NewTextReplace.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef UAC
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef JSON
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef ACL
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef ACL_DIR
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef FIREWALL
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef WRITEREGBIN
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef XML_PLUGIN
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef NSIS_REGISTRY
	!include NSISRegistry.nsh
	!insertmacro MOVEREGKEY
!endif
!ifdef REGISTRY
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif

;= CUSTOM
;= ################
!ifdef REGISTRY
	!include Registry.nsh
	!define REGEXE `$SYSDIR\reg.exe`
	!define REGEDIT `$SYSDIR\regedit.exe`
!endif
!ifdef REPLACE
	!include ReplaceInFileWithTextReplace.nsh
!endif
!include ForEachINIPair.nsh
!include ForEachPath.nsh
!include SetFileAttributesDirectoryNormal.nsh
!include ProcFunc.nsh
!include EmptyWorkingSet.nsh
!include SetEnvironmentVariable.nsh
!include LogicLibAdditions.nsh
!ifdef GetBetween.nsh
	!include GetBetween.nsh
!endif
!ifdef GetLocale.nsh
	!include GetLocale.nsh
!endif
!ifdef 64.nsh
	!include x64.nsh
!endif
!ifdef IsFileLocked
	!ifndef 64.nsh
		!include x64.nsh
	!endif
!endif
!ifdef Include_LineWrite
	!include LineWrite.nsh
!endif
!ifdef Include_WinMessages
	!include WinMessages.nsh
!endif
!ifdef DIRECTORIES_MOVE
	!ifndef GET_ROOT
		!define GET_ROOT
	!endif
!endif

;= LANGUAGES
;= ################
${!ECHO} "${NEWLINE}Loading language strings...${NEWLINE}${NEWLINE}"
!verbose push
!verbose 1
!include Languages.nsh
!verbose pop

;= VARIABLES
;= ################
${!ECHO} "${NEWLINE}Initialising variables and macros...${NEWLINE}${NEWLINE}"
Var Bit
Var Admin
Var AppID
Var BaseName
Var MissingFileOrPath
Var AppName
Var AppNamePortable
Var ProgramExecutable
Var StatusMutex
Var WaitForProgram
!ifdef REGISTRY
	Var Registry
!endif
!ifdef UAC
	Var RunAsAdmin
!endif
!ifdef JAVA
	Var UsingJavaExecutable
	Var JavaMode
	Var JavaDirectory
!endif
!ifdef GHOSTSCRIPT
	Var GSMode
	Var GSDirectory
	Var GSRegExists
	Var GSExecutable
!endif

;= LOAD SEGMENTS
;= ################
${!ECHO} "${NEWLINE}Loading Segments...${NEWLINE}${NEWLINE}"
!include Segments.nsh

;= Debugging
;= ################
!include Debug.nsh

;= App Details
;= ################
${!ECHO}	`${NewLine}Specifying program details and setting options...${NewLine}${NewLine}`
!searchparse /ignorecase /noerrors /file ${PACKAGE}\App\AppInfo\appinfo.ini `Trademarks=` TRADEMARK
!searchparse /ignorecase /noerrors /file ${PACKAGE}\App\AppInfo\appinfo.ini `Developer=` DEVELOPER
!searchparse /ignorecase /noerrors /file ${PACKAGE}\App\AppInfo\appinfo.ini `Contributors=` CONTRIBUTORS
!searchparse /ignorecase /noerrors /file ${PACKAGE}\App\AppInfo\appinfo.ini `Publisher=` PUBLISHER
!searchparse /ignorecase /noerrors /file ${PACKAGE}\App\AppInfo\appinfo.ini `PackageVersion=` PACKAGE_VERSION
!searchparse /ignorecase /noerrors /file ${PACKAGE}\App\AppInfo\appinfo.ini `Start=` OUTFILE
Name		`${PORTABLEAPPNAME}`
OutFile		`${PACKAGE}\${APPNAME}.exe`
Icon		`${PACKAGE}\App\AppInfo\appicon.ico`
Caption		`${FULLNAME}`
!ifdef PACKAGE_VERSION
	!if ! ${PACKAGE_VERSION} == ""
		VIProductVersion	${PACKAGE_VERSION}
		VIAddVersionKey /LANG=${LANG_ENGLISH} FileVersion      ${PACKAGE_VERSION}
	!else
		!error "The key 'PackageVersion' in AppInfo.ini needs a value! (i.e. 0.0.0.0)"
	!endif
!else
	!error "The key 'PackageVersion' in AppInfo.ini is missing!"
!endif
!ifdef PUBLISHER
	!if ! "${PUBLISHER}" == ""
		VIAddVersionKey /LANG=${LANG_ENGLISH} CompanyName      `${PUBLISHER}`
		VIAddVersionKey /LANG=${LANG_ENGLISH} LegalCopyright   `Copyright ${YEAR} ${PUBLISHER}`
	!else
		!error "The key 'Publisher' in AppInfo.ini needs a value!"
	!endif
!else
	!error "The key 'Publisher' in AppInfo.ini is missing!"
!endif
!ifdef APPNAME
	!if ! "${APPNAME}" == ""
		VIAddVersionKey /LANG=${LANG_ENGLISH} InternalName     `${APPNAME}Portable.exe`
		VIAddVersionKey /LANG=${LANG_ENGLISH} OriginalFilename `${APPNAME}.exe`
	!else
		!error "The key 'AppID' in AppInfo.ini needs a value!"
	!endif
!else
	!error "The key 'AppID' in AppInfo.ini is missing!"
!endif
!ifdef FULLNAME
	!if ! "${FULLNAME}" == ""
		VIAddVersionKey /LANG=${LANG_ENGLISH} ProductName      `${FULLNAME}`
		VIAddVersionKey /LANG=${LANG_ENGLISH} FileDescription  `${FULLNAME}`
	!else
		!error "The key 'Name' in AppInfo.ini needs a value!"
	!endif
!else
	!error "The key 'Name' in AppInfo.ini is missing!"
!endif
!ifdef TRADEMARK
	!if ! "${TRADEMARK}" == ""
		VIAddVersionKey /LANG=${LANG_ENGLISH} LegalTrademarks  `${TRADEMARK}`
	!else
		!ifdef TRADEMARK
			!undef TRADEMARK
		!endif
	!endif
!endif
!ifdef DEVELOPER
	!if ! "${DEVELOPER}" == ""
		!ifdef CONTRIBUTORS
			!if ! "${CONTRIBUTORS}" == ""
				VIAddVersionKey /LANG=${LANG_ENGLISH} Comments         `Developed by ${DEVELOPER} (with help from ${CONTRIBUTORS})`
			!else
				VIAddVersionKey /LANG=${LANG_ENGLISH} Comments         `Developed by ${DEVELOPER}`
			!endif
		!else
			VIAddVersionKey /LANG=${LANG_ENGLISH} Comments         `Developed by ${DEVELOPER}`
		!endif
	!else
		VIAddVersionKey /LANG=${LANG_ENGLISH} Comments         `A portable build of ${FULLNAME} using the PortableApps.com Launcher`
		!ifdef DEVELOPER
			!undef DEVELOPER
		!endif
	!endif
!endif
VIAddVersionKey /LANG=${LANG_ENGLISH} ProductVersion   Portable

;= CODE SIGNING
;= ################
!ifdef Certificate
	${!ECHO}	`${NewLine} Gathering the certificate and other information then signing ${OUTFILE}...${NewLine}${NewLine}`
	;=== Signing Macro
	!define Finalize::Sign  `!insertmacro _Finalize::Sign`
	!macro _Finalize::Sign _CMD
		!finalize `${_CMD}`
	!macroend
	!define Timestamp
	!define TimestampSHA256
	!searchparse /ignorecase /noerrors /file ${PACKAGE}\App\AppInfo\appinfo.ini `CertExtension=` CertExtension
	!searchparse /ignorecase /noerrors /file ${PACKAGE}\App\AppInfo\appinfo.ini `CertTimestamp=` CertTimestamp
	!if ! "${CertTimestamp}" == ""
		!if "${CertTimestamp}" == "Comodo"
			!define /REDEF Timestamp "http://timestamp.comodoca.com"
			!define /REDEF TimestampSHA256 "http://timestamp.comodoca.com/?td=sha256"
		!else if "${CertTimestamp}" == "Verisign"
			!define /REDEF Timestamp "http://timestamp.verisign.com/scripts/timstamp.dll"
			!define /REDEF TimestampSHA256 "http://sha256timestamp.ws.symantec.com/sha256/timestamp"
		!else if "${CertTimestamp}" == "GlobalSign"
			!define /REDEF Timestamp "http://timestamp.globalsign.com/scripts/timstamp.dll"
			!define /REDEF TimestampSHA256 "http://timestamp.globalsign.com/?signature=sha2"
		!else if "${CertTimestamp}" == "DigiCert"
			!define /REDEF Timestamp "http://timestamp.digicert.com"
			!define /REDEF TimestampSHA256 "http://timestamp.digicert.com"
		!else if "${CertTimestamp}" == "Starfield"
			!define /REDEF Timestamp "http://tsa.starfieldtech.com"
			!define /REDEF TimestampSHA256 "http://tsa.starfieldtech.com"
		!else if "${CertTimestamp}" == "SwissSign"
			!define /REDEF Timestamp "http://tsa.swisssign.net"
			!define /REDEF TimestampSHA256 "http://tsa.swisssign.net"
		!else
			!define /REDEF Timestamp "http://timestamp.comodoca.com"
			!define /REDEF TimestampSHA256 "http://timestamp.comodoca.com/?td=sha256"
		!endif
	!else
		!define /REDEF Timestamp "http://timestamp.comodoca.com"
		!define /REDEF TimestampSHA256 "http://timestamp.comodoca.com/?td=sha256"
	!endif
	!define CERT		`Contrib\certificates\${DEVELOPER}.${CertExtension}`
	!define SIGNTOOL	`Contrib\bin\signtool.exe`
	!define SHA1		`"${SIGNTOOL}" sign /f "${CERT}" /p "" /t "${Timestamp}" /v "${PACKAGE}\${OUTFILE}"`
	!define SHA256		`"${SIGNTOOL}" sign /f "${CERT}" /p "" /fd sha256 /tr "${TimestampSHA256}" /td sha256 /as /v "${PACKAGE}\${OUTFILE}"`
	;=== Sign
	${Finalize::Sign} `${SHA1}`
	${Finalize::Sign} `${SHA256}`
!endif

!verbose 4

;= FUNCTIONS
;= ################
;=# Check 64-bit
Function IsWOW64
	!macro _WOW64 _RETURN
		Push ${_RETURN}
		Call IsWOW64
		Pop ${_RETURN}
	!macroend
	!define WOW64 `!insertmacro _WOW64`
	Exch $0
	System::Call `${GETCURRPROC}`
	System::Call `${WOW}`
	Exch $0
FunctionEnd
;=# Prevent Shutdown
!include nsDialogs.nsh
!define /ifndef WS_POPUP 0x80000000
!define CreateWinEx1		`USER32::CreateWindowEx(i0,t"STATIC",t"$(^Name)",`
!define CreateWinEx2		`i${WS_CHILD}|${WS_POPUP},i0,i0,i0,i0,pr1,i0,i0,i0)p.r1`
!define BlockReason1		`USER32::ShutdownBlockReasonCreate(pr1,w`
!define BlockReason2		`"${PORTABLEAPPNAME} is running and still needs to clean up before shutting down!")`
Function CreateShutdownBlockReason
	StrCpy $1 $hwndParent
	${If} $1 Z= 0
		System::Call `${CreateWinEx1}${CreateWinEx2}`
	${EndIf}
	System::Call `${BlockReason1}${BlockReason2}`
FunctionEnd
;=# Fonts Folder
!ifdef FONTS_ENABLED
	Function CreateFontsFolder
		IfFileExists "${PACKAGE}\App\DefaultData\Fonts" +2
		CreateDirectory /SILENT "${PACKAGE}\App\DefaultData\Fonts"
		IfFileExists "${PACKAGE}\App\DefaultData\Fonts\.Portable.Fonts.txt" +11
		!tempfile FONTFILE
		!appendfile "${FONTFILE}" "Font(s) added here will be loaded on launch and accessible during runtime.$\n$\n"
		!appendfile "${FONTFILE}" "NOTE:$\n"
		!appendfile "${FONTFILE}" "$\tThe launcher will have to load and unload any fonts in this directory.$\n"
		!appendfile "${FONTFILE}" "$\tThe more fonts you have will mean a longer work load for the launcher.$\n$\n"
		!appendfile "${FONTFILE}" "Fonts Supported:$\n"
		!appendfile "${FONTFILE}" " • .fon$\n • .fnt$\n • .ttf$\n • .ttc$\n • .fot$\n • .otf$\n • .mmm$\n • .pfb$\n • .pfm$\n"
		!system 'copy /Y /A "${FONTFILE}" "${PACKAGE}\App\DefaultData\Fonts\.Portable.Fonts.txt" /A'
		!delfile "${FONTFILE}"
		!undef FONTFILE
	FunctionEnd
!endif
Function .onInit
	Call CreateShutdownBlockReason
	Push $0
	!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
		!ifndef SYSTEMWIDE_DISABLEREDIR
			!define SYSTEMWIDE_DISABLEREDIR
		!endif
	!endif
	System::Call `kernel32::GetModuleHandle(t 'shell32.dll') i .s`
	System::Call `kernel32::GetProcAddress(i s, i 680) i .r0`
	System::Call `::$0() i .r0`
	StrCmpS $0 1 "" +2
	StrCpy $Admin true
	System::Call `${GETCURRPROC}`
	System::Call `${WOW}`
	StrCmpS $0 0 +3
	StrCpy $Bit 64
	Goto +2
	StrCpy $Bit 32
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	${RunSegment} Core
	${RunSegment} Custom
	${RunSegment} Temp
	${RunSegment} Language
	${RunSegment} OperatingSystem
	!ifdef UAC
		${RunSegment} RunAsAdmin
	!endif
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
	Pop $0
FunctionEnd
Function Init
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	!ifdef FONTS_ENABLED
		Call CreateFontsFolder
	!endif
	${If} $SecondaryLaunch != true
		${RunSegment} Language
		${RunSegment} Environment
		${RunSegment} Custom
	${EndIf}
	${RunSegment} Core
	${If} $SecondaryLaunch != true
		${RunSegment} PathChecks
		${RunSegment} DriveLetter
	${EndIf}
	${RunSegment} DirectoryMoving
	${RunSegment} Variables
	!ifdef JAVA
		${RunSegment} Java
	!endif
	!ifdef DOTNET
		${RunSegment} DotNet
	!endif
	!ifdef GHOSTSCRIPT
		${RunSegment} Ghostscript
	!endif
	${RunSegment} RunLocally
	${If} $SecondaryLaunch != true
		${RunSegment} Temp
	${EndIf}
	${RunSegment} InstanceManagement
	${If} $SecondaryLaunch != true
		${RunSegment} Settings
	${EndIf}
	;${RunSegment} SplashScreen
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function Pre
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	${If} $SecondaryLaunch != true
		!ifdef SERVICES
			${RunSegment} Services
		!endif
		!ifdef REGISTERDLL
			${RunSegment} RegisterDLL
		!endif
	${EndIf}
	!ifdef REGISTRY
		${RunSegment} Registry
	!endif
	${RunSegment} Custom
	${RunSegment} RunLocally
	${RunSegment} Temp
	;${RunSegment} LastRunEnvironment
	${RunSegment} Environment
	${RunSegment} ExecString
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function PrePrimary        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	${If} $SecondaryLaunch != true
		!ifdef FileCleanup
			${RunSegment} FilesCleanup
		!endif
	${EndIf}
	${RunSegment} Custom
	${RunSegment} DriveLetter
	${RunSegment} Variables
	${RunSegment} DirectoryMoving
	;${RunSegment} LastRunEnvironment
	${RunSegment} FileWrite
	${RunSegment} FilesMove
	${RunSegment} DirectoriesMove
	!ifdef REGISTRY
		${RunSegment} RegistryKeys
		!ifdef RegCopy
			${If} $SecondaryLaunch != true
				${RunSegment} RegistryCopyKeys
			${EndIf}
		!endif
		${RunSegment} RegistryValueBackupDelete
	!endif
	${If} $SecondaryLaunch != true
		!ifdef REGISTERDLL
			${RunSegment} RegisterDLL
		!endif
	${EndIf}
	!ifdef REGISTRY
		;=== this belongs here after Registering DLLs.
		${RunSegment} RegistryValueWrite
	!endif
	${If} $SecondaryLaunch != true
		!ifdef SERVICES
			${RunSegment} Services
		!endif
		!ifdef TaskCleanup
			${RunSegment} TaskCleanUp
		!endif
		!ifdef FONTS_ENABLE
			${RunSegment} Fonts
		!endif
	${EndIf}
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function PreSecondary        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	${RunSegment} Custom
	;${RunSegment} *
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function PreExec        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	${RunSegment} Custom
	${If} $SecondaryLaunch != true
		!ifdef REGISTERDLL
			${RunSegment} RegisterDLL
		!endif
	${EndIf}
	${RunSegment} RefreshShellIcons
	${RunSegment} WorkingDirectory
	${RunSegment} RunBeforeAfter
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function PreExecPrimary        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	${RunSegment} Custom
	${RunSegment} Core
	;${RunSegment} LastRunEnvironment
	;${RunSegment} SplashScreen
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function PreExecSecondary        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	${RunSegment} Custom
	;${RunSegment} *
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function Execute
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	!ifmacrodef OverrideExecuteFunction
		!insertmacro OverrideExecuteFunction
	!else
		!ifmacrodef PreExecExecute
			!insertmacro PreExecExecute
		!endif
		${EmptyWorkingSet}
		ClearErrors
		${ReadLauncherConfig} $0 Launch HideCommandLineWindow
		${If} $0 == true
			StrCpy $ExecString "$ExecString $Parameters"
			ExecDos::exec /TOSTACK $ExecString
			Pop $0
		${Else}
			${IfNot} ${Errors}
			${AndIf} $0 != false
				${InvalidValueError} [Launch]:HideCommandLineWindow $0
			${EndIf}
			${If} $WaitForProgram != false
				!ifdef ExecAsUser
					${ConfigReads} `${CONFIG}` ExecAsAdmin= $0
					${If} $0 == true
						StrCpy $ExecString "$ExecString $Parameters"
						ExecWait $ExecString
					${Else}
						${StdUtils.ExecShellAsUser} $0 "$ExecString" "" "$Parameters"
						${EmptyWorkingSet}
						Sleep 1000
						${GetFileName} $ProgramExecutable $1
						${EmptyWorkingSet}
						${Do}
							${ProcessWaitClose} $1 -1 $R9
							${IfThen} $R9 > 0 ${|} ${Continue} ${|}
						${LoopWhile} $R9 > 0
					${EndIf}
				!else
					ExecWait $ExecString
				!endif
			${Else}
				!ifdef ExecAsUser
					${StdUtils.ExecShellAsUser} $0 "$ExecString" "" "$Parameters"
				!else
					Exec $ExecString
				!endif
			${EndIf}
		${EndIf}
		!ifmacrodef PostExecWaitCommand
			!insertmacro PostExecWaitCommand
		!endif
		${If} $WaitForProgram != false
			ClearErrors
			${ReadLauncherConfig} $0 Launch WaitForOtherInstances
			${If} $0 == true
			${OrIf} ${Errors}
				${GetFileName} $ProgramExecutable $1
				${EmptyWorkingSet}
				${Do}
					!ifdef Sleep
						Sleep ${Sleep}
					!endif
					${ProcessWaitClose} $1 -1 $R9
					${IfThen} $R9 > 0 ${|} ${Continue} ${|}
					StrCpy $0 1
					${Do}
						!ifdef Sleep
							Sleep ${Sleep}
						!endif
						ClearErrors
						${ConfigReadS} `${LAUNCHER}` WaitForEXE$0= $2
						${IfThen} ${Errors} ${|} ${ExitDo} ${|}
						ExpandEnvStrings $2 $2
						${ProcessWaitClose} $2 -1 $R9
						${IfThen} $R9 > 0 ${|} ${ExitDo} ${|}
						IntOp $0 $0 + 1
					${Loop}
				${LoopWhile} $R9 > 0
			${ElseIf} $0 != false
				${InvalidValueError} [Launch]:WaitForOtherInstances $0
			${EndIf}
		${EndIf}
	!endif
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function PostExecPrimary
	${RunSegment} Custom
FunctionEnd
Function PostExecSecondary
	${RunSegment} Custom
FunctionEnd
Function PostExec       
	${RunSegment} RunBeforeAfter
	${RunSegment} Custom
FunctionEnd
Function PostPrimary        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	${If} $SecondaryLaunch != true
		!ifdef REGISTERDLL
			${RunSegment} RegisterDLL
		!endif
		!ifdef SERVICES
			${RunSegment} Services
		!endif
		!ifdef TaskCleanup
			${RunSegment} TaskCleanUp
		!endif
	${EndIf}
	!ifdef REGISTRY
		${RunSegment} RegistryValueBackupDelete
		${If} $SecondaryLaunch != true
			!ifdef RegCopy
				${RunSegment} RegistryCopyKeys
			!endif
		${EndIf}
		${RunSegment} RegistryKeys
		${RunSegment} RegistryCleanup
	!endif
	${If} $SecondaryLaunch != true
		${RunSegment} Qt
		!ifdef FileCleanup
			${RunSegment} FilesCleanup
		!endif
	${EndIf}
	!ifdef DirectoryCleanup
		${RunSegment} DirectoriesCleanup
	!endif
	${RunSegment} DirectoriesMove
	${RunSegment} FilesMove
	${RunSegment} RunLocally
	${RunSegment} Temp
	${RunSegment} Custom
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function PostSecondary        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	;${RunSegment} *
	${RunSegment} Custom
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function Post        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	!ifdef GHOSTSCRIPT
		${RunSegment} Ghostscript
	!endif
	${RunSegment} RefreshShellIcons
	${RunSegment} Custom
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
Function Unload        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	;${RunSegment} XML
	${If} $SecondaryLaunch != true
		!ifdef REGISTERDLL
			${RunSegment} RegisterDLL
		!endif
		!ifdef SERVICES
			${RunSegment} Services
		!endif
		!ifdef FONTS_ENABLE
			${RunSegment} Fonts
		!endif
		!ifdef FileCleanup
			${RunSegment} FilesCleanup
		!endif
		!ifdef DirectoryCleanup
			${RunSegment} DirectoriesCleanup
		!endif
	${EndIf}
	;${RunSegment} SplashScreen
	${RunSegment} Core
	${RunSegment} Custom
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
FunctionEnd
!define CallPS `!insertmacro CallPS`
!macro CallPS _func _rev
	!if ${_rev} == +
		Call ${_func}
	!endif
	${If} $SecondaryLaunch == true
		Call ${_func}Secondary
	${Else}
		Call ${_func}Primary
	${EndIf}
	!if ${_rev} != +
		Call ${_func}
	!endif
!macroend
Section        
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
	Call Init
	System::Call 'Kernel32::OpenMutex(i1048576, b0, t"${PAC}${APPNAME}-${APPNAME}::Starting") i.R0 ?e'
	System::Call 'Kernel32::CloseHandle(iR0)'
	Pop $R9
	${If} $R9 <> 2
		MessageBox MB_ICONSTOP $(LauncherAlreadyStarting)
		Quit
	${EndIf}
	System::Call 'Kernel32::OpenMutex(i1048576, i0, t"${PAC}${APPNAME}-${APPNAME}::Stopping") i.R0 ?e'
	System::Call 'Kernel32::CloseHandle(iR0)'
	Pop $R9
	${If} $R9 <> 2
		MessageBox MB_ICONSTOP $(LauncherAlreadyStopping)
		Quit
	${EndIf}
	${IfNot} ${FileExists} `${RUNTIME}`
	${OrIf} $SecondaryLaunch == true
		${If} $SecondaryLaunch != true
			System::Call 'Kernel32::CreateMutex(i0, i0, t"${PAC}${APPNAME}-${APPNAME}::Starting") i.r0'
			StrCpy $StatusMutex $0
		${EndIf}
		${CallPS} Pre +
		${CallPS} PreExec +
		${If} $SecondaryLaunch != true
			StrCpy $0 $StatusMutex
			System::Call 'Kernel32::CloseHandle(ir0) ?e'
			Pop $R9
		${EndIf}
		Call Execute
	${Else}
		MessageBox MB_ICONSTOP $(LauncherCrashCleanup)
	${EndIf}
	${If} $SecondaryLaunch != true
		System::Call 'Kernel32::CreateMutex(i0, i0, t"${PAC}${APPNAME}-${APPNAME}::Stopping")'
	${EndIf}
	${If} $WaitForProgram != false
		${CallPS} Post -
	${EndIf}
	Call Unload
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
SectionEnd
Function .onInstFailed        
	Call Unload
FunctionEnd
