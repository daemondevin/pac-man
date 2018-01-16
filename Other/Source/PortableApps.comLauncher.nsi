;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; PortableAppsCompiler.nsi
;
; The following portable framework is based on the programming
; styles and coding practices of all the following developers:
;
;	John T. Haller | https://portableapps.com/
;		Founder of PortableApps.com
;
;	Chris Morgan | https://chrismorgan.info/
;		Former developer of PAL & PAI (PortableApps.com Launcher and Installer)
;
;	FukenGruven (a.k.a. PortableWares)
;		Developer of the first modified PAL providing the inspiration and skeleton for PortableApps Compiler
;
;	Azure Zanculmarktum (a.k.a. PerkedleApps)
;		Developer of PAUL (PortableApps Universal Launcher) - An alternative, portable framework based on PAL
;

!verbose 3

;= PACKAGE
;= ################
!ifndef PACKAGE
	!define PACKAGE ..\..
!endif

;= ECHO
;= ################
!macro !ECHO _MSG
	!verbose push
	!verbose 4
	!echo "${_MSG}"
	!verbose pop
!macroend
!define !ECHO "!insertmacro !ECHO"
!define NEWLINE	`$\r$\n`

;= NSIS VERSION
;= ################
!include RequireLatestNSIS.nsh

;= RUNTIME SWITCHES
;= ################
Unicode true
WindowIcon Off
XPStyle on
SilentInstall Silent
AutoCloseWindow true
SetCompressor /SOLID lzma
SetCompressorDictSize 32
!ifdef RUNASADMIN_COMPILEFORCE
	RequestExecutionLevel admin
!else ifdef UAC
	RequestExecutionLevel admin
!else
	RequestExecutionLevel user
!endif

;= PAC VERSION
;= ################
!include Version.nsh
${!ECHO} "${NEWLINE}PORTABLEAPPS COMPILER\
		  ${NEWLINE}$\tFOUNDER: daemon.devin\
		  ${NEWLINE}$\tEDITION: ${EDITION}\
		  ${NEWLINE}$\tVERSION: ${PACVER}\
		  ${NEWLINE}$\tRELEASE: ${PACKAGEDATE} (${DISPLAYDATE})${NEWLINE}${NEWLINE}"

;= GLOBAL DEFINES
;= ################
${!ECHO} "${NEWLINE}Reading/Writing Package Definitions...${NEWLINE}${NEWLINE}"
!ifndef PACMAN
    !include GlobalCLDefines.nsh
!endif
!define APPINFO         `$EXEDIR\App\AppInfo`
!define INFOINI			`${APPINFO}\appinfo.ini`
!define DATA            `$EXEDIR\Data`
!define SET             `${DATA}\settings`
!define DEFDATA         `$EXEDIR\App\DefaultData`
!define DEFSET          `${DEFDATA}\settings`
!define LAUNCHDIR       `${APPINFO}\Launcher`
!define LAUNCHER        `${LAUNCHDIR}\${APPNAME}.ini`
!define LAUNCHER2       `$PLUGINSDIR\launcher.ini`
!define RUNTIME         `${DATA}\PortableApps.comLauncherRuntimeData-${APPNAME}.ini`
!define RUNTIME2        `$PLUGINSDIR\runtimedata.ini`
!define SETINI          `${SET}\${APPNAME}Settings.ini`
!define CONFIG          `$EXEDIR\${APPNAME}.ini`
!define OTHER           `$EXEDIR\Other`
!define PAL				PortableApps.comLauncher
!define PrimaryInstance	`$SecondaryLaunch != true`
!define SecondInstance	`$SecondaryLaunch == true`
!define BitDepth		`$Bit =`
!define LCID			`kernel32::GetUserDefaultLangID()i .r0`
!define GETSYSWOW64		`kernel32::GetSystemWow64Directory(t .r0, i ${NSIS_MAX_STRLEN})`
!define DISABLEREDIR	`kernel32::Wow64EnableWow64FsRedirection(i0)`
!define ENABLEREDIR		`kernel32::Wow64EnableWow64FsRedirection(i1)`
!define GETCURRPROC		`kernel32::GetCurrentProcess()i.s`
!define WOW				`kernel32::IsWow64Process(is,*i.r0)`
!define /DATE YEAR		`%Y`

;= INCLUDES/PLUGINS
;= ################
${!ECHO} "${NEWLINE}Including required files and/or plugins...${NEWLINE}${NEWLINE}"
!include LangFile.nsh
!include LogicLib.nsh
!include FileFunc.nsh
!include TextFunc.nsh
!include WordFunc.nsh
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
!ifdef REPLACE
	!include NewTextReplace.nsh
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
!ifdef UAC
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
	!include XML.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef DOTNET
	!include DotNetVer.nsh
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
!ifdef NSIS_REGISTRY
	!include NSISRegistry.nsh
	!insertmacro MOVEREGKEY
!endif
!ifdef JSON
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef REGISTRY
	!include Registry.nsh
	!define REGEXE	`$SYSDIR\reg.exe`
	!define REGEDIT	`$SYSDIR\regedit.exe`
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
!include StrCase.nsh
!include IsFile.nsh
!include LogicLibAdditions.nsh
!include nsDialogs.nsh
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
!ifdef Include_LineWrite.nsh
	!include LineWrite.nsh
!endif
!ifdef Include_WinMessages.nsh
	!include WinMessages.nsh
!endif
!ifdef UAC
	!include UAC.nsh
	!ifndef TrimString
		!define TrimString
	!endif
!endif
!ifdef DIRECTORIES_MOVE
	!ifndef GET_ROOT
		!define GET_ROOT
	!endif
!endif

;= PAC MACROS
;= ################
!include GlobalMacros.nsh

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
Var App
Var Admin
Var AppID
Var BaseName
Var MissingFileOrPath
Var AppName
Var AppNamePortable
Var ProgramExecutable
Var StatusMutex
Var WaitForProgram
Var UsingJavaExecutable
	Var Parameters
!ifdef REGISTRY
	Var Registry
!endif
!ifdef UAC
	Var RunAsAdmin
!endif
!ifdef DOTNET
	Var DotNETVersion
!endif
!ifdef JAVA
	Var JavaMode
	Var JavaDirectory
!endif
!ifdef GHOSTSCRIPT
	Var GSMode
	Var GSDirectory
	Var GSRegExists
	Var GSExecutable
!endif

;= SEGMENTS
;= ################
${!ECHO} "${NEWLINE}Loading Segments...${NEWLINE}${NEWLINE}"
!include Segments.nsh

;= DEBUGGING
;= ################
!include Debug.nsh

;= PACKAGE DETAILS
;= ################
${!ECHO}	`${NEWLINE}Writing launcher's specification details...${NEWLINE}${NEWLINE}`
Name		`${PORTABLEAPPNAME}`
OutFile		`${PACKAGE}\${APPNAME}.exe`
Icon		`${PACKAGE}\App\AppInfo\AppIcon.ico`
Caption		`${PORTABLEAPPNAME}`
VIProductVersion	${PACKAGE_VERSION}
VIAddVersionKey /LANG=1033 FileVersion      ${PACKAGE_VERSION}
VIAddVersionKey /LANG=1033 CompanyName      `${PUBLISHER}`
VIAddVersionKey /LANG=1033 LegalCopyright   `Copyright ${YEAR} ${PUBLISHER}`
VIAddVersionKey /LANG=1033 InternalName     `${APPNAME}Portable.exe`
VIAddVersionKey /LANG=1033 OriginalFilename `${APPNAME}.exe`
VIAddVersionKey /LANG=1033 ProductName      `${PORTABLEAPPNAME}`
VIAddVersionKey /LANG=1033 FileDescription  `${FULLNAME}`
VIAddVersionKey /LANG=1033 ProductVersion   Portable
!ifdef DEVELOPER
	!ifdef CONTRIBUTORS
		VIAddVersionKey /LANG=1033 Comments	`Developed by ${DEVELOPER} (with help from ${CONTRIBUTORS})`
	!else
		VIAddVersionKey /LANG=1033 Comments	`Developed by ${DEVELOPER}`
	!endif
!endif
!ifdef TRADEMARK
	VIAddVersionKey /LANG=1033 LegalTrademarks  `${TRADEMARK}`
!endif

;= CODE SIGNING
;= ################
${!ECHO} "${NEWLINE} Grabbing the certificate and other information then signing ${OUTFILE}...${NEWLINE}${NEWLINE}"

!define SIGNTOOL	`Contrib\bin\signtool\signtool.exe`
!define CERT		`Contrib\certificates\${DEVELOPER}.${CertExtension}`
!define PASS		``
!ifdef CertSigning
	!finalize `"${SIGNTOOL}" sign /f "${CERT}" /p "${PASS}" /v "%1"`
	!finalize `"${SIGNTOOL}" sign /f "${CERT}" /p "${PASS}" /fd sha256 /td sha256 /as /v "%1"`
!else
	!ifndef PACMAN

		!searchparse /ignorecase /noerrors /file "${PACKAGE}\App\AppInfo\appinfo.ini" `CertSigning=` Certificate
		!searchparse /ignorecase /noerrors /file "${PACKAGE}\App\AppInfo\appinfo.ini" `CertExtension=` CERT_EXT
		!searchparse /ignorecase /noerrors /file "${PACKAGE}\App\AppInfo\appinfo.ini" `CertTimestamp=` TIMESTAMP_SVC
		
		!if "${Certificate}" == true
			!define /REDEF Certificate
		!endif
		!if ! "${CERT_EXT}" == ""
			!define CertExtension `${CERT_EXT}`
		!endif
		!if ! "${TIMESTAMP_SVC}" == ""
			!if "${TIMESTAMP_SVC}" == "offline"
				!define MODE "offline"
			!else
				!define CertTimestamp `${TIMESTAMP_SVC}`
			!endif
		!endif

		!if /FileExists "${CERT}" ; Sign only if we can locate the certificate..
			;
			; Sign using dual signature hashing 
			; algorithms (SHA1/SHA2) as well as
			; add a time-stamp to the signature
			; using a specified TSA service.   
			;
			; SHA1
			!finalize `CompilerSigner.exe \
						/pfx "${CERT}" \
						/p "${PASS}" \
						/tsa "${CertTimestamp}" \
						/hash "SHA1" \
						/exe "${PACKAGE}\${OUTFILE}" ${MODE}`
			; SHA2
			!finalize `CompilerSigner.exe \
						/pfx "${CERT}" \
						/p "${PASS}" \
						/tsa "${CertTimestamp}" \
						/hash "SHA2" \
						/exe "${PACKAGE}\${OUTFILE}" ${MODE}`
		!else ; Cannot find the certificate..
			!warning "Cannot find a certificate to sign the launcher. Please \
					  check the spelling and/or the path to your certificate \
					  are correct and recompile to sign ${OUTFILE}!"

		!endif
	!endif
!endif

;= PREVENT SHUTDOWN
;= ################
!define /ifndef WS_POPUP	0x80000000
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

!verbose 4

Function .onInit
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
	!ifdef HYBRID
		StrCmpS $Bit 32 +6
		IfFileExists `${EXE64}` 0 +5
		SetRegView 64
		StrCpy $App ${APP64}
		System::Call `${SET64}`
		Goto +3
		StrCpy $App ${APP}
		System::Call `${SET32}`
	!else if /FileExists "${EXE64}"
		SetRegView 64
		StrCpy $App ${APP64}
	!else
		StrCpy $App ${APP}
	!endif	
	${DISABLE_REDIRECTION}
	${RunSegment} Core
	${RunSegment} Custom
	${RunSegment} Temp
	${RunSegment} Language
	${RunSegment} OperatingSystem
	!ifdef UAC
		${RunSegment} RunAsAdmin
	!endif
	${ENABLE_REDIRECTION}
	Pop $0
FunctionEnd
Function Init
	${DISABLE_REDIRECTION}
	${If} ${PrimaryInstance}
		${RunSegment} Language
		${RunSegment} Environment
		${RunSegment} Custom
	${EndIf}
	${RunSegment} Core
	${If} ${PrimaryInstance}
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
	${If} ${PrimaryInstance}
		${RunSegment} Temp
	${EndIf}
	${RunSegment} InstanceManagement
	${If} ${PrimaryInstance}
		${RunSegment} Settings
	${EndIf}
	!ifdef FONTS_ENABLED
		Call CreateFontsFolder
	!endif
	${ENABLE_REDIRECTION}
FunctionEnd
Function Pre
	${DISABLE_REDIRECTION}
	${If} ${PrimaryInstance}
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
	${ENABLE_REDIRECTION}
FunctionEnd
Function PrePrimary        
	${DISABLE_REDIRECTION}
	${If} ${PrimaryInstance}
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
			${If} ${PrimaryInstance}
				${RunSegment} RegistryCopyKeys
			${EndIf}
		!endif
		${RunSegment} RegistryValueBackupDelete
	!endif
	${If} ${PrimaryInstance}
		!ifdef REGISTERDLL
			${RunSegment} RegisterDLL
		!endif
		!ifdef DIRECTX
			${RunSegment} DirectX
		!endif
	${EndIf}
	!ifdef REGISTRY
		${RunSegment} RegistryValueWrite
	!endif
	${If} ${PrimaryInstance}
		!ifdef SERVICES
			${RunSegment} Services
		!endif
		!ifdef TaskCleanup
			${RunSegment} TasksCleanUp
		!endif
		!ifdef FONTS_ENABLE
			${RunSegment} Fonts
		!endif
	${EndIf}
	${ENABLE_REDIRECTION}
FunctionEnd
Function PreSecondary        
	${DISABLE_REDIRECTION}
	${RunSegment} Custom
	${ENABLE_REDIRECTION}
FunctionEnd
Function PreExec        
	${DISABLE_REDIRECTION}
	${RunSegment} Custom
	${If} ${PrimaryInstance}
		!ifdef REGISTERDLL
			${RunSegment} RegisterDLL
		!endif
	${EndIf}
	${RunSegment} RefreshShellIcons
	${RunSegment} WorkingDirectory
	${RunSegment} RunBeforeAfter
	${ENABLE_REDIRECTION}
FunctionEnd
Function PreExecPrimary        
	${DISABLE_REDIRECTION}
	${RunSegment} Custom
	${RunSegment} Core
	;${RunSegment} LastRunEnvironment
	${ENABLE_REDIRECTION}
FunctionEnd
Function PreExecSecondary        
	${DISABLE_REDIRECTION}
	${RunSegment} Custom
	${ENABLE_REDIRECTION}
FunctionEnd
Function Execute
	${DISABLE_REDIRECTION}
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
	${ENABLE_REDIRECTION}
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
	${DISABLE_REDIRECTION}
	${If} ${PrimaryInstance}
		!ifdef REGISTERDLL
			${RunSegment} RegisterDLL
		!endif
		!ifdef DIRECTX
			${RunSegment} DirectX
		!endif
		!ifdef SERVICES
			${RunSegment} Services
		!endif
		!ifdef TaskCleanup
			${RunSegment} TasksCleanUp
		!endif
	${EndIf}
	!ifdef REGISTRY
		${RunSegment} RegistryValueBackupDelete
		${If} ${PrimaryInstance}
			!ifdef RegCopy
				${RunSegment} RegistryCopyKeys
			!endif
		${EndIf}
		${RunSegment} RegistryKeys
		${RunSegment} RegistryCleanup
	!endif
	${If} ${PrimaryInstance}
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
	${ENABLE_REDIRECTION}
FunctionEnd
Function PostSecondary        
	${DISABLE_REDIRECTION}
	${RunSegment} Custom
	${ENABLE_REDIRECTION}
FunctionEnd
Function Post        
	${DISABLE_REDIRECTION}
	!ifdef GHOSTSCRIPT
		${RunSegment} Ghostscript
	!endif
	${RunSegment} RefreshShellIcons
	${RunSegment} Custom
	${ENABLE_REDIRECTION}
FunctionEnd
Function Unload        
	${DISABLE_REDIRECTION}
	${If} ${PrimaryInstance}
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
	${RunSegment} Core
	${RunSegment} Custom
	${ENABLE_REDIRECTION}
FunctionEnd
!define CallPS `!insertmacro CallPS`
!macro CallPS _func _rev
	!if ${_rev} == +
		Call ${_func}
	!endif
	${If} ${SecondInstance}
		Call ${_func}Secondary
	${Else}
		Call ${_func}Primary
	${EndIf}
	!if ${_rev} != +
		Call ${_func}
	!endif
!macroend
Section
	Call CreateShutdownBlockReason
	${DISABLE_REDIRECTION}
	Call Init
	System::Call 'Kernel32::OpenMutex(i1048576, b0, t"${PAL}${APPNAME}-${APPNAME}::Starting") i.R0 ?e'
	System::Call 'Kernel32::CloseHandle(iR0)'
	Pop $R9
	${If} $R9 <> 2
		MessageBox MB_ICONSTOP $(LauncherAlreadyStarting)
		Quit
	${EndIf}
	System::Call 'Kernel32::OpenMutex(i1048576, i0, t"${PAL}${APPNAME}-${APPNAME}::Stopping") i.R0 ?e'
	System::Call 'Kernel32::CloseHandle(iR0)'
	Pop $R9
	${If} $R9 <> 2
		MessageBox MB_ICONSTOP $(LauncherAlreadyStopping)
		Quit
	${EndIf}
	${IfNot} ${FileExists} `${RUNTIME}`
	${OrIf} ${SecondInstance}
		${If} ${PrimaryInstance}
			System::Call 'Kernel32::CreateMutex(i0, i0, t"${PAL}${APPNAME}-${APPNAME}::Starting") i.r0'
			StrCpy $StatusMutex $0
		${EndIf}
		${CallPS} Pre +
		${CallPS} PreExec +
		${If} ${PrimaryInstance}
			StrCpy $0 $StatusMutex
			System::Call 'Kernel32::CloseHandle(ir0) ?e'
			Pop $R9
		${EndIf}
		Call Execute
	${Else}
		MessageBox MB_ICONSTOP $(LauncherCrashCleanup)
	${EndIf}
	${If} ${PrimaryInstance}
		System::Call 'Kernel32::CreateMutex(i0, i0, t"${PAL}${APPNAME}-${APPNAME}::Stopping")'
	${EndIf}
	${If} $WaitForProgram != false
		${CallPS} Post -
	${EndIf}
	Call Unload
	${ENABLE_REDIRECTION}
SectionEnd
Function .onInstFailed        
	Call Unload
FunctionEnd
