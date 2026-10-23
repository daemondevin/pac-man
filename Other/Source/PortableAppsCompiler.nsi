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
!define ECHO "!insertmacro _ECHO"
!macro _ECHO _MSG
	!verbose push
	!verbose 4
	!echo "${_MSG}"
	!verbose pop
!macroend
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
!else ifdef SEGMENTS_UAC
	RequestExecutionLevel admin
!else
	RequestExecutionLevel user
!endif

ManifestSupportedOS "{35138b9a-5d96-4fbd-8e2d-a2440225f93a}"  # Windows 7
ManifestSupportedOS "{1f676c76-80e1-4239-95bb-83d0f6d0da78}"  # Windows 8.1
ManifestSupportedOS "{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}"  # Windows 10 & Later

;= PAC VERSION
;= ################
!include Version.nsh
${ECHO} "${NEWLINE}PORTABLEAPPS COMPILER\
		${NEWLINE}$\tFOUNDER: daemon.devin\
		${NEWLINE}$\tEDITION: ${EDITION}\
		${NEWLINE}$\tVERSION: ${PACVER}\
		${NEWLINE}$\tRELEASE: ${PACKAGEDATE} (${DISPLAYDATE})${NEWLINE}${NEWLINE}"

;= GLOBAL DEFINES
;= ################
${ECHO} "${NEWLINE}Reading/Writing Package Definitions...${NEWLINE}${NEWLINE}"
!ifndef PACMAN
    !include GlobalCLDefines.nsh
!endif
!include FeatureFlags.nsh
!define APPINFO         `$EXEDIR\App\AppInfo`
!define INFOINI			`${APPINFO}\appinfo.ini`
!define INSTINI			`${APPINFO}\installer.ini`
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
${ECHO} "${NEWLINE}Including required files and/or plugins...${NEWLINE}${NEWLINE}"
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
!ifdef EXEC_AS_USER
	!include StdUtils.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef REPLACE
	!include NewTextReplace.nsh
	!include ReplaceInFileWithTextReplace.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef SEGMENTS_FIREWALL
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef SEGMENTS_UAC
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
!ifdef SEGMENTS_XML
	!include XML.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef StdUtils
	!ifndef EXEC_AS_USER
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
!ifdef SEGMENTS_REGISTRY
	!include Registry.nsh
	!define REGEXE	`$SYSDIR\reg.exe`
	!define REGEDIT	`$SYSDIR\regedit.exe`
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
!ifdef Include_LineWrite
	!include LineWrite.nsh
!endif
!ifdef Include_WinMessages
	!include WinMessages.nsh
!endif
!ifdef SEGMENTS_UAC
	!include UAC.nsh
    !ifdef CertSigning
        !include AddCertToStore.nsh
    !endif
	!ifndef TrimString
		!define TrimString
	!endif
!endif
!ifdef DIRECTORIES_MOVE
	!ifndef GET_ROOT
		!define GET_ROOT
	!endif
!endif
!ifdef SEGMENTS_RUNTIME
	!ifndef TrimString
		!define TrimString
	!endif
!endif 
;= PAC MACROS
;= ################
!include GlobalMacros.nsh

;= LANGUAGES
;= ################
${ECHO} "${NEWLINE}Loading language strings...${NEWLINE}${NEWLINE}"
!verbose push
!verbose 1
!include Languages.nsh
!verbose pop

;= VARIABLES
;= ################
${ECHO} "${NEWLINE}Initializing variables and macros...${NEWLINE}${NEWLINE}"
Var Bit
Var Arch
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
!ifdef SEGMENTS_REGISTRY
	Var Registry
!endif
!ifdef SEGMENTS_UAC
	Var RunAsAdmin
!endif
!ifdef SEGMENTS_JAVA
	Var JavaMode
	Var JavaDirectory
!endif
!ifdef SEGMENTS_GHOSTSCRIPT
	Var GSMode
	Var GSDirectory
	Var GSRegExists
	Var GSExecutable
!endif

;= DEBUGGING
;= ################
; Included before the journal and the segments so their functions can use
; ${DebugMsg} when they are compiled.
!include Debug.nsh

;= JOURNAL
;= ################
${ECHO} "${NEWLINE}Loading the rollback journal...${NEWLINE}${NEWLINE}"
!include Journal.nsh

;= SEGMENTS
;= ################
${ECHO} "${NEWLINE}Loading Segments...${NEWLINE}${NEWLINE}"
!include Segments.nsh

;= PACKAGE DETAILS
;= ################
${ECHO}			    `${NEWLINE}Writing launcher's specification details...${NEWLINE}${NEWLINE}`
Name				`${PORTABLEAPPNAME}`
OutFile				`${PACKAGE}\${APPNAME}.exe`
Icon				`${PACKAGE}\App\AppInfo\AppIcon.ico`
Caption				`${PORTABLEAPPNAME}`
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
; The certificate password is never stored in source. Set it in the
; environment before compiling, e.g.  set PACMAN_CERT_PASS=secret
; It is read at compile time only and never ends up in the launcher.
!ifdef CertSigning
	${ECHO} "${NEWLINE}Grabbing the certificate and other information then signing ${OUTFILE}...${NEWLINE}${NEWLINE}"
	!define /ifndef CertExtension	pfx
	; CertTimestamp may be a URL or a service name; names fall back to Sectigo.
	!define /ifndef CertTimestamp	`http://timestamp.sectigo.com/`
	!searchparse /noerrors "${CertTimestamp}" "://" _TSA_IS_URL
	!ifdef _TSA_IS_URL
		!define TSA_URL `${CertTimestamp}`
	!else
		!define TSA_URL `http://timestamp.sectigo.com/`
	!endif
	!define SIGNTOOL	`bin\signtool\signtool.exe`
	!define CERT		`contrib\certificates\${DEVELOPER}.${CertExtension}`
	!define _PASS_RAW	`$%PACMAN_CERT_PASS%`
	!searchparse /noerrors "${_PASS_RAW}" "%PACMAN_CERT_PASS" _PASS_UNSET
	!if /FileExists "${CERT}"
		!ifdef _PASS_UNSET
			!finalize `"${SIGNTOOL}" sign /f "${CERT}" /fd sha512 /t "${TSA_URL}" /v "%1"`
		!else
			!finalize `"${SIGNTOOL}" sign /f "${CERT}" /p "${_PASS_RAW}" /fd sha512 /t "${TSA_URL}" /v "%1"`
		!endif
	!else
		!warning "Cannot find the certificate ${CERT}; ${OUTFILE} will not be signed."
	!endif
!endif
;= FUNCTIONS
;= ################
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
	; $Arch is the architecture Windows itself runs on: x86, x64 or arm64.
	; IsWow64Process2 (Windows 10 1709 and later) tells an ARM64 PC apart
	; from an x64 one, which IsWow64Process can't: both report WOW64 for this
	; 32-bit launcher. Where it is missing, PROCESSOR_ARCHITEW6432 is used.
	; Custom.nsh may change $Arch in its .onInit hook to force a build.
	Push $1
	Push $2
	Push $3
	${If} $Bit == 64
		StrCpy $Arch x64
	${Else}
		StrCpy $Arch x86
	${EndIf}
	StrCpy $2 0
	System::Call `*(i 0) p .r1`
	System::Call `*(i 0) p .r3`
	System::Call `kernel32::IsWow64Process2(p -1, p r1, p r3) i .r2`
	${If} $2 <> 0
		; IMAGE_FILE_MACHINE_ARM64 = 0xAA64 = 43620
		System::Call `*$3(&i2 .r2)`
		${IfThen} $2 = 43620 ${|} StrCpy $Arch arm64 ${|}
	${Else}
		ReadEnvStr $2 PROCESSOR_ARCHITEW6432
		${IfThen} $2 == ARM64 ${|} StrCpy $Arch arm64 ${|}
	${EndIf}
	System::Free $1
	System::Free $3
	Pop $3
	Pop $2
	Pop $1
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
	; A package without its program says how to add it, in the user's
	; language and before any UAC prompt.
	!ifdef SEGMENTS_MISSINGAPP
		${RunSegment} MissingApp
	!endif
	!ifdef SEGMENTS_UAC
		${RunSegment} RunAsAdmin
	!endif
	${ENABLE_REDIRECTION}
	Pop $0
FunctionEnd
; PAC-MAN segment ordering
; Apply order follows the README: Runtime, RegDLL, Fonts, Symlinks,
; Associations, Firewall, Hosts, Services, Tasks. Drivers and DirectX sit
; with their providers. Cleanup and recovery run the exact reverse, so no
; consumer outlives its provider. A segment is only dispatched when its
; feature flag is compiled in, which keeps disabled segments out of the
; build and out of the warning log.
!macro _RunIfEnabled _FLAG _SEG
	!ifdef ${_FLAG}
		; Segments only implement the hooks they need, so skip missing ones quietly.
		!ifmacrodef ${_SEG}.nsh_${__FUNCTION__}
			${RunSegment} ${_SEG}
		!endif
	!endif
!macroend
!define RunIfEnabled `!insertmacro _RunIfEnabled`
!macro _PacSegmentsApply
	${RunIfEnabled} SEGMENTS_RUNTIME       Runtime
	${RunIfEnabled} SEGMENTS_REGDLL        RegDLL
	${RunIfEnabled} SEGMENTS_DIRECTX       DirectX
	${RunIfEnabled} SEGMENTS_FONTS         Fonts
	${RunIfEnabled} SEGMENTS_SYMLINKS      Symlinks
	${RunIfEnabled} SEGMENTS_ASSOCIATIONS  Associations
	${RunIfEnabled} SEGMENTS_FIREWALL      Firewall
	${RunIfEnabled} SEGMENTS_HOSTS         Hosts
	${RunIfEnabled} SEGMENTS_DRIVERS       Drivers
	${RunIfEnabled} SEGMENTS_SERVICES      Services
	${RunIfEnabled} SEGMENTS_TASKS         Tasks
!macroend
!define PacSegmentsApply `!insertmacro _PacSegmentsApply`
!macro _PacSegmentsCleanup
	${RunIfEnabled} SEGMENTS_TASKS         Tasks
	${RunIfEnabled} SEGMENTS_SERVICES      Services
	${RunIfEnabled} SEGMENTS_DRIVERS       Drivers
	${RunIfEnabled} SEGMENTS_HOSTS         Hosts
	${RunIfEnabled} SEGMENTS_FIREWALL      Firewall
	${RunIfEnabled} SEGMENTS_ASSOCIATIONS  Associations
	${RunIfEnabled} SEGMENTS_SYMLINKS      Symlinks
	${RunIfEnabled} SEGMENTS_FONTS         Fonts
	${RunIfEnabled} SEGMENTS_DIRECTX       DirectX
	${RunIfEnabled} SEGMENTS_REGDLL        RegDLL
	${RunIfEnabled} SEGMENTS_RUNTIME       Runtime
!macroend
!define PacSegmentsCleanup `!insertmacro _PacSegmentsCleanup`
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
	${RunIfEnabled} SEGMENTS_JAVA Java
	${RunIfEnabled} SEGMENTS_GHOSTSCRIPT Ghostscript
	${RunIfEnabled} SEGMENTS_DOTNET DotNet
	${RunSegment} RunLocally
	${If} ${PrimaryInstance}
		${RunSegment} Temp
	${EndIf}
	${RunSegment} InstanceManagement
	${RunIfEnabled} SEGMENTS_REGISTRY Registry
	; Runtime checks need the PAL variables and the instance state (a second
	; launch must not repeat them) and may stop the launch, so they run here,
	; before anything is changed.
	${RunIfEnabled} SEGMENTS_RUNTIME Runtime
	${If} ${PrimaryInstance}
		${RunSegment} Settings
	${EndIf}
	${ENABLE_REDIRECTION}
FunctionEnd
Function Pre
	${DISABLE_REDIRECTION}
	${If} ${PrimaryInstance}
		${PacSegmentsApply}
	${EndIf}
	${RunIfEnabled} SEGMENTS_REGISTRY Registry
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
	${RunIfEnabled} FileCleanup FilesCleanup
	${RunSegment} Custom
	${RunSegment} DriveLetter
	${RunSegment} Variables
	${RunSegment} DirectoryMoving
	;${RunSegment} LastRunEnvironment
	${RunSegment} FileWrite
	${RunSegment} FilesMove
	${RunSegment} DirectoriesMove
	!ifdef SEGMENTS_REGISTRY
		${RunSegment} RegistryKeys
		${RunSegment} RegistryCopyKeys
		${RunSegment} RegistryValueBackupDelete
		${RunSegment} RegistryValueWrite
	!endif
	${PacSegmentsApply}
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
				!ifdef EXEC_AS_USER
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
				!ifdef EXEC_AS_USER
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
	${PacSegmentsCleanup}
	!ifdef SEGMENTS_REGISTRY
		${RunSegment} RegistryValueBackupDelete
		${RunSegment} RegistryCopyKeys
		${RunSegment} RegistryKeys
		${RunSegment} RegistryCleanup
	!endif
	${RunSegment} Qt
	${RunIfEnabled} FileCleanup FilesCleanup
	${RunSegment} DirectoriesCleanup
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
	${If} ${PrimaryInstance}
		${PacSegmentsCleanup}
	${EndIf}
	${RunIfEnabled} SEGMENTS_GHOSTSCRIPT Ghostscript
	${RunSegment} RefreshShellIcons
	${RunSegment} Custom
	${ENABLE_REDIRECTION}
FunctionEnd
Function Unload
	${DISABLE_REDIRECTION}
	${If} ${PrimaryInstance}
		${PacSegmentsCleanup}
		${RunIfEnabled} FileCleanup FilesCleanup
		${RunSegment} DirectoriesCleanup
		; Safety net: whatever a segment left in the journal is rolled back
		; here, in recovery order. When the launcher does not wait for the
		; program (WaitForProgram=false) the system changes must outlive the
		; launcher, so the session is left open and the next launch's
		; recovery dispatcher rolls it back.
		${If} $WaitForProgram != false
			Call Journal_RollbackAll
			${Journal::End}
		${ElseIf} $JournalActive == true
			WriteRegStr HKCU `${JOURNAL_KEY}` "State" "detached"
		${EndIf}
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
	; Crash recovery comes first, before this launch changes anything. Only
	; the primary instance may recover: a secondary instance means another
	; launcher for this app is alive and its journal is not stale.
	${If} ${PrimaryInstance}
		${If} ${FileExists} `${RUNTIME}`
			; The PAL crash notice below already tells the user; stay quiet.
			StrCpy $JournalQuiet true
		${EndIf}
		${Journal::Recover}
	${EndIf}
	${IfNot} ${FileExists} `${RUNTIME}`
	${OrIf} ${SecondInstance}
		${If} ${PrimaryInstance}
			System::Call 'Kernel32::CreateMutex(i0, i0, t"${PAL}${APPNAME}-${APPNAME}::Starting") i.r0'
			StrCpy $StatusMutex $0
			${Journal::Begin}
		${EndIf}
		${CallPS} Pre +
		${CallPS} PreExec +
		${If} ${PrimaryInstance}
			StrCpy $0 $StatusMutex
			System::Call 'Kernel32::CloseHandle(ir0) ?e'
			Pop $R9
		${EndIf}
		Call Execute
		${If} $WaitForProgram != false
			${CallPS} PostExec -
		${EndIf}
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
