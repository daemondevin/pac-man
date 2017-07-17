/* Copyright 2004-2010 PortableApps.com
 * Website: http://portableapps.com/development
 * Main developer and contact: Chris Morgan
 *
 * This software is OSI Certified Open Source Software.
 * OSI Certified is a certification mark of the Open Source Initiative.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

!verbose 3

!ifndef PACKAGE
	!define PACKAGE ..\..
!endif

!macro !echo msg
	!verbose push
	!verbose 4
	!echo "${msg}"
	!verbose pop
!macroend
!define !echo "!insertmacro !echo"

;=== Require at least Unicode NSIS 2.46 {{{1
;!include RequireLatestNSIS.nsh

;= DEFINES
;= ################
!define APPINFO			`${PACKAGE}\App\AppInfo\appinfo.ini`
!define CUSTOM			`${PACKAGE}\App\AppInfo\Launcher\custom.nsh`
!define NEWLINE			`$\r$\n`

!searchparse /NOERRORS /FILE `${APPINFO}` `AppID=` APPNAME

!define LAUNCHER		`${PACKAGE}\App\AppInfo\Launcher\${APPNAME}.ini`

!searchreplace APP "${APPNAME}" "Portable" ""

!searchparse /NOERRORS /FILE `${LAUNCHER}` `ProgramExecutable64=` APPEXE64

!if ! "${APPEXE64}" == ""
	!searchreplace APP64 "${APPNAME}" "Portable" "64"
!endif
!undef APPEXE64

!searchparse /NOERRORS /FILE `${APPINFO}` `Name=` PORTABLEAPPNAME
!searchreplace FULLNAME "${PORTABLEAPPNAME}" " Portable" ""

!define APPDIR			`$EXEDIR\App\${APP}`

!ifdef APP64
	!define APPDIR64	`$EXEDIR\App\${APP64}`
!endif

${!echo} "${NEWLINE}Retrieving information from files in the AppInfo directory...${NEWLINE}${NEWLINE}"

;=== Manifest
!searchparse /NOERRORS /FILE `${APPINFO}` `ElevatedPrivileges= ` RequestLevel
!if "${RequestLevel}" == true
	!define /REDEF RequestLevel ADMIN
!else 
	!define /REDEF RequestLevel USER
!endif
!define ResHacker		`Tools\bin\ResHacker.exe`
!define ManifDir		`Tools\manifests`
!define Manifest		`NSIS_3.01_Win8`
!packhdr				`$%TEMP%\exehead.tmp` \ 
						`"${Reshacker}" -addoverwrite "%TEMP%\exehead.tmp", "%TEMP%\exehead.tmp", "${ManifDir}\${Manifest}_${RequestLevel}.manifest", 24,1,1033`

;=== Custom Defines
!searchparse /NOERRORS /FILE `${LAUNCHER}` `Registry=` REGISTRY
!if "${REGISTRY}" == true
	!define /REDEF REGISTRY
	!define REGEXE		`$SYSDIR\reg.exe`
	!define REGEDIT		`$SYSDIR\regedit.exe`
	!searchparse /NOERRORS /FILE `${LAUNCHER}` `[RegistryValueWrite` RegValueWrite
	!if "${RegValueWrite}" == "]"
		!define RegSleep 50	;=== Sleep value for [RegistryValueWrite]; function is inaccurate otherwise.
	!endif
	!searchparse /NOERRORS /FILE `${LAUNCHER}` `Type=Replace` Replace
	!if "${RegValueWrite}" == "]"
		!define RegSleep 50	;=== Sleep value for [RegistryValueWrite]; function is inaccurate otherwise.
	!endif
	!ifdef APP64
		;= TODO: Figure out a better way to handle this.
		; !define DISABLEFSR	;=== Disable redirection
	!endif
!else
	!ifdef REGISTRY
		!undef REGISTRY
	!endif
!endif
!searchparse /NOERRORS /FILE `${LAUNCHER}` `Java=` JAVA
!if "${JAVA}" == true
	!define /REDEF JAVA
	Var UsingJavaExecutable
	Var JavaMode
	Var JavaDirectory
!else
	!ifdef JAVA
		!undef JAVA
	!endif
!endif
!if "${RequestLevel}" == "ADMIN"
	Var RunAsAdmin
	!define UAC
	!define TrimString
	!include UAC.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!else
	!ifdef UAC
		!undef UAC
	!endif
!endif

;=== ExecAsUser
!searchparse /noerrors /file `${APPINFO}` `UseStdUtils= ` StdUtils	;=== Include StndUtils without ExecAsUser
!searchparse /noerrors /file `${APPINFO}` `ExecAsUser= ` ExecAsUser	;=== For applications which need to run as normal user.
!if ${StdUtils} == true
	!define /redef StdUtils
!else
	!ifdef StdUtils
		!undef StdUtils
	!endif
!endif
!if ${ExecAsUser} == true
	!define /redef ExecAsUser
!else
	!ifdef ExecAsUser
		!undef ExecAsUser
	!endif
!endif

;=== Runtime Switches {{{1
Unicode true	;=== NSIS3 Support
ManifestDPIAware true
WindowIcon Off
XPStyle on
SilentInstall Silent
AutoCloseWindow True
!ifdef RUNASADMIN_COMPILEFORCE
RequestExecutionLevel admin
!else
RequestExecutionLevel user
!endif
SetCompressor /SOLID lzma
SetCompressorDictSize 32

!define PAL				PortableApps.comLauncher
!define /DATE YEAR		`%Y`
!define LCID			`kernel32::GetUserDefaultLangID()i .r0`
!define GETSYSWOW64		`kernel32::GetSystemWow64Directory(t .r0, i ${NSIS_MAX_STRLEN})`
!define DISABLEREDIR	`kernel32::Wow64EnableWow64FsRedirection(i0)`
!define ENABLEREDIR		`kernel32::Wow64EnableWow64FsRedirection(i1)`
!define GETCURRPROC		`kernel32::GetCurrentProcess()i.s`
!define WOW				`kernel32::IsWow64Process(is,*i.r0)`
Function IsWOW64
	!macro _IsWOW64 _RETURN
		Push ${_RETURN}
		Call IsWOW64
		Pop ${_RETURN}
	!macroend
	!define IsWOW64 `!insertmacro _IsWOW64`
	Exch $0
	System::Call `${GETCURRPROC}`
	System::Call `${WOW}`
	Exch $0
FunctionEnd
!define ReadLauncherConfig `!insertmacro ReadLauncherConfig`
!macro ReadLauncherConfig _RETURN _SECTION _ENTRY
	ReadINIStr ${_RETURN} `${LAUNCHER}` `${_SECTION}` `${_ENTRY}`
!macroend
!define WriteLauncherConfig `!insertmacro WriteLauncherConfig`
!macro WriteLauncherConfig _SECTION _ENTRY _VALUE
	WriteINIStr `${LAUNCHER}` `${_SECTION}` `${_ENTRY}` `${_VALUE}`
!macroend
!define DeleteLauncherConfig `!insertmacro DeleteLauncherConfig`
!macro DeleteLauncherConfig _SECTION _ENTRY
	DeleteINIStr `${LAUNCHER}` `${_SECTION}` `${_ENTRY}`
!macroend
!define DeleteLauncherConfigSec `!insertmacro DeleteLauncherConfigSec`
!macro DeleteLauncherConfigSec _SECTION
	DeleteINISec `${LAUNCHER}` `${_SECTION}`
!macroend
!define ReadLauncherConfigWithDefault `!insertmacro ReadLauncherConfigWithDefault`
!macro ReadLauncherConfigWithDefault _RETURN _SECTION _VALUE _DEFAULT
	ClearErrors
	${ReadLauncherConfig} ${_RETURN} `${_SECTION}` `${_VALUE}`
	${IfThen} ${Errors} ${|} StrCpy ${_OUTPUT} `${_DEFAULT}` ${|}
!macroend
!define ReadUserConfig `!insertmacro ReadUserConfig`
!macro ReadUserConfig _RETURN _KEY
	${ConfigReadS} `${CONFIG}` `${_KEY}=` `${_RETURN}`
!macroend
!define WriteUserConfig `!insertmacro WriteUserConfig`
!macro WriteUserConfig _VALUE _KEY
	${ConfigWriteS} `${CONFIG}` `${_KEY}=` `${_VALUE}` $R0
!macroend
!define ReadUserOverrideConfig `!insertmacro ReadUserOverrideConfigError`
!macro ReadUserOverrideConfigError a b
	!error `ReadUserOverrideConfig has been renamed to ReadUserConfig in PAL 2.1.`
!macroend
!define InvalidValueError `!insertmacro InvalidValueError`
!macro InvalidValueError _SECTION_KEY _VALUE
	MessageBox MB_OK|MB_ICONSTOP `Error: invalid value '${_VALUE}' for ${_SECTION_KEY}. Please refer to the Manual for valid values.`
!macroend
!define WriteRuntimeData "!insertmacro WriteRuntimeData"
!macro WriteRuntimeData _SECTION _KEY _VALUE
	WriteINIStr `${RUNTIME}` `${_SECTION}` `${_KEY}` `${_VALUE}`
	WriteINIStr `${RUNTIME2}` `${_SECTION}` `${_KEY}` `${_VALUE}`
!macroend
!define DeleteRuntimeData "!insertmacro DeleteRuntimeData"
!macro DeleteRuntimeData _SECTION _KEY
	DeleteINIStr `${RUNTIME}` `${_SECTION}` `${_KEY}`
	DeleteINIStr `${RUNTIME2}` `${_SECTION}` `${_KEY}`
!macroend
!define ReadRuntimeData "!insertmacro ReadRuntimeData"
!macro ReadRuntimeData _RETURN _SECTION _KEY
	IfFileExists `${RUNTIME}` 0 +3
	ReadINIStr `${_RETURN}` `${RUNTIME}` `${_SECTION}` `${_KEY}`
	Goto +2
	ReadINIStr `${_RETURN}` `${RUNTIME2}` `${_SECTION}` `${_KEY}`
!macroend
!define WriteRuntime "!insertmacro WriteRuntime"
!macro WriteRuntime _VALUE _KEY
	WriteINIStr `${RUNTIME}` PortableApps.comLauncher `${_KEY}` `${_VALUE}`
	WriteINIStr `${RUNTIME2}` PortableApps.comLauncher `${_KEY}` `${_VALUE}`
!macroend
!define ReadRuntime "!insertmacro ReadRuntime"
!macro ReadRuntime _RETURN _KEY
	IfFileExists `${RUNTIME}` 0 +3
	ReadINIStr `${_RETURN}` `${RUNTIME}` PortableApps.comLauncher `${_KEY}`
	Goto +2
	ReadINIStr `${_RETURN}` `${RUNTIME2}` PortableApps.comLauncher `${_KEY}`
!macroend
!define WriteSettings `!insertmacro WriteSettings`
!macro WriteSettings _VALUE _KEY
	WriteINIStr `${SETINI}` ${APPNAME}Settings `${_KEY}` `${_VALUE}`
!macroend
!define ReadSettings `!insertmacro ReadSettings`
!macro ReadSettings _RETURN _KEY
	ReadINIStr `${_RETURN}` `${SETINI}` ${APPNAME}Settings `${_KEY}`
!macroend
!define DeleteSettings `!insertmacro DeleteSettings`
!macro DeleteSettings _KEY
	DeleteINIStr `${SETINI}` ${APPNAME}Settings `${_KEY}`
!macroend

;=== Include {{{1
${!echo} "${NEWLINE}Including required files...${NEWLINE}${NEWLINE}"
;(Standard NSIS) {{{2
!include LangFile.nsh
!include LogicLib.nsh
!include FileFunc.nsh
!include TextFunc.nsh
!include WordFunc.nsh

;(NSIS Plugins) {{{
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
!ifdef XML_PLUGIN
	!include XML.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif
!ifdef NSIS_REGISTRY
	!include NSISRegistry.nsh
	!insertmacro MOVEREGKEY
!endif
;(Custom) {{{2
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
!ifdef Include_LineWrite.nsh
	!include LineWrite.nsh
!endif
!ifdef Include_WinMessages.nsh
	!include WinMessages.nsh
!endif
!ifdef DIRECTORIES_MOVE
	!ifndef GET_ROOT
		!define GET_ROOT
	!endif
!endif


;(Custom) {{{2
!include ReplaceInFileWithTextReplace.nsh
!include ForEachINIPair.nsh
!include ForEachPath.nsh
!include SetFileAttributesDirectoryNormal.nsh
!include ProcFunc.nsh
!include EmptyWorkingSet.nsh
!include SetEnvironmentVariable.nsh
!include CheckForPlatformSplashDisable.nsh
!include LogicLibAdditions.nsh

;=== Languages {{{1
${!echo} "${NEWLINE}Loading language strings...${NEWLINE}${NEWLINE}"
!include Languages.nsh

;=== Variables {{{1
${!echo} "${NEWLINE}Initialising variables and macros...${NEWLINE}${NEWLINE}"
Var AppID
Var BaseName
Var MissingFileOrPath
Var AppNamePortable
Var AppName
Var ProgramExecutable
Var StatusMutex
Var WaitForProgram

; Load the segments {{{1
${!echo} "${NEWLINE}Loading segments...${NEWLINE}${NEWLINE}"
!include Segments.nsh

;=== Debugging {{{1
!include Debug.nsh

;=== Program Details {{{1
${!echo} "${NEWLINE}Specifying program details and setting options...${NEWLINE}${NEWLINE}"

Name "${NamePortable} (PortableApps.com Launcher)"
OutFile "${PACKAGE}\${AppID}.exe"
Icon "${PACKAGE}\App\AppInfo\appicon.ico"
Caption "${NamePortable} (PortableApps.com Launcher)"
VIProductVersion ${Version}
VIAddVersionKey ProductName "${NamePortable}"
VIAddVersionKey Comments "A build of the PortableApps.com Launcher for ${NamePortable}, allowing it to be run from a removable drive.  For additional details, visit PortableApps.com"
VIAddVersionKey CompanyName PortableApps.com
VIAddVersionKey LegalCopyright PortableApps.com
VIAddVersionKey FileDescription "${NamePortable} (PortableApps.com Launcher)"
VIAddVersionKey FileVersion ${Version}
VIAddVersionKey ProductVersion ${Version}
VIAddVersionKey InternalName "PortableApps.com Launcher"
VIAddVersionKey LegalTrademarks "PortableApps.com is a Trademark of Rare Ideas, LLC."
VIAddVersionKey OriginalFilename "${AppID}.exe"

!verbose 4

Function .onInit           ;{{{1
	${RunSegment} Custom
	${RunSegment} Core
	${RunSegment} Temp
	${RunSegment} Language
	${RunSegment} OperatingSystem
	${RunSegment} RunAsAdmin
FunctionEnd

Function Init              ;{{{1
	${RunSegment} Custom
	${RunSegment} Core
	${RunSegment} PathChecks
	${RunSegment} Settings
	${RunSegment} DriveLetter
	${RunSegment} DirectoryMoving
	${RunSegment} Variables
	${RunSegment} Language
	${RunSegment} Registry
	${RunSegment} Java
	${RunSegment} DotNet
	${RunSegment} Ghostscript
	${RunSegment} RunLocally
	${RunSegment} Temp
	${RunSegment} InstanceManagement
	${RunSegment} SplashScreen
	${RunSegment} RefreshShellIcons
FunctionEnd

Function Pre               ;{{{1
	${RunSegment} Custom
	${RunSegment} RunLocally
	${RunSegment} Temp
	${RunSegment} LastRunEnvironment
	${RunSegment} Environment
	${RunSegment} ExecString
FunctionEnd

Function PrePrimary        ;{{{1
	${RunSegment} Custom
	${RunSegment} DriveLetter
	${RunSegment} Variables
	${RunSegment} DirectoryMoving
	${RunSegment} LastRunEnvironment
	${RunSegment} FileWrite
	${RunSegment} FilesMove
	${RunSegment} DirectoriesMove
	;${RunSegment} RegisterDLL
	${RunSegment} RegistryKeys
	${RunSegment} RegistryValueBackupDelete
	${RunSegment} RegistryValueWrite
	${RunSegment} Services
FunctionEnd

Function PreSecondary      ;{{{1
	${RunSegment} Custom
	;${RunSegment} *
FunctionEnd

Function PreExec           ;{{{1
	${RunSegment} Custom
	${RunSegment} RefreshShellIcons
	${RunSegment} WorkingDirectory
	${RunSegment} RunBeforeAfter
FunctionEnd

Function PreExecPrimary    ;{{{1
	${RunSegment} Custom
	${RunSegment} Core
	${RunSegment} LastRunEnvironment
	${RunSegment} SplashScreen
FunctionEnd

Function PreExecSecondary  ;{{{1
	${RunSegment} Custom
	;${RunSegment} *
FunctionEnd

Function Execute           ;{{{1
	; Users can override this function in Custom.nsh
	; like this (see Segments.nsh for the OverrideExecute define):
	;
	;   ${OverrideExecute}
	;       [code to replace this function]
	;   !macroend

	!ifmacrodef OverrideExecuteFunction
		!insertmacro OverrideExecuteFunction
	!else
	${!getdebug}
	!ifdef DEBUG
		${If} $WaitForProgram != false
			${DebugMsg} "About to execute the following string and wait till it's done: $ExecString"
		${Else}
			${DebugMsg} "About to execute the following string and finish: $ExecString"
		${EndIf}
	!endif
	${EmptyWorkingSet}
	ClearErrors
	${ReadLauncherConfig} $0 Launch HideCommandLineWindow
	${If} $0 == true
		; TODO: do this without a plug-in or at least some way it won't wait with secondary
		ExecDos::exec $ExecString
		Pop $0
	${Else}
		${IfNot} ${Errors}
		${AndIf} $0 != false
			${InvalidValueError} [Launch]:HideCommandLineWindow $0
		${EndIf}
		${If} $WaitForProgram != false
			ExecWait $ExecString
		${Else}
			Exec $ExecString
		${EndIf}
	${EndIf}
	${DebugMsg} "$ExecString has finished."

	${If} $WaitForProgram != false
		; Wait till it's done
		ClearErrors
		${ReadLauncherConfig} $0 Launch WaitForOtherInstances
		${If} $0 == true
		${OrIf} ${Errors}
			${GetFileName} $ProgramExecutable $1
			${DebugMsg} "Waiting till any other instances of $1 and any [Launch]:WaitForEXE[N] values are finished."
			${EmptyWorkingSet}
			${Do}
				${ProcessWaitClose} $1 -1 $R9
				${IfThen} $R9 > 0 ${|} ${Continue} ${|}
				StrCpy $0 1
				${Do}
					ClearErrors
					${ReadLauncherConfig} $2 Launch WaitForEXE$0
					${IfThen} ${Errors} ${|} ${ExitDo} ${|}
					${ProcessWaitClose} $2 -1 $R9
					${IfThen} $R9 > 0 ${|} ${ExitDo} ${|}
					IntOp $0 $0 + 1
				${Loop}
			${LoopWhile} $R9 > 0
			${DebugMsg} "All instances are finished."
		${ElseIf} $0 != false
			${InvalidValueError} [Launch]:WaitForOtherInstances $0
		${EndIf}
	${EndIf}
	!endif
FunctionEnd

Function PostExecPrimary   ;{{{1
	${RunSegment} Custom
FunctionEnd

Function PostExecSecondary ;{{{1
	${RunSegment} Custom
FunctionEnd

Function PostExec          ;{{{1
	${RunSegment} RunBeforeAfter
	${RunSegment} Custom
FunctionEnd

Function PostPrimary       ;{{{1
	${RunSegment} Services
	${RunSegment} RegistryValueBackupDelete
	${RunSegment} RegistryKeys
	${RunSegment} RegistryCleanup
	;${RunSegment} RegisterDLL
	${RunSegment} Qt
	${RunSegment} DirectoriesMove
	${RunSegment} FilesMove
	${RunSegment} DirectoriesCleanup
	${RunSegment} RunLocally
	${RunSegment} Temp
	${RunSegment} Custom
FunctionEnd

Function PostSecondary     ;{{{1
	;${RunSegment} *
	${RunSegment} Custom
FunctionEnd

Function Post              ;{{{1
	${RunSegment} Ghostscript
	${RunSegment} RefreshShellIcons
	${RunSegment} Custom
FunctionEnd

Function Unload            ;{{{1
	${RunSegment} XML
	${RunSegment} Registry
	${RunSegment} SplashScreen
	${RunSegment} Core
	${RunSegment} Custom
FunctionEnd

; Call a segment-calling function with primary/secondary variants as well {{{1
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
!define CallPS `!insertmacro CallPS`

Section           ;{{{1
	Call Init

	System::Call 'Kernel32::OpenMutex(i1048576, b0, t"PortableApps.comLauncher$AppID-$BaseName::Starting") i.R0 ?e'
	System::Call 'Kernel32::CloseHandle(iR0)'
	Pop $R9
	${If} $R9 <> 2
		MessageBox MB_ICONSTOP $(LauncherAlreadyStarting)
		Quit
	${EndIf}
	System::Call 'Kernel32::OpenMutex(i1048576, i0, t"PortableApps.comLauncher$AppID-$BaseName::Stopping") i.R0 ?e'
	System::Call 'Kernel32::CloseHandle(iR0)'
	Pop $R9
	${If} $R9 <> 2
		MessageBox MB_ICONSTOP $(LauncherAlreadyStopping)
		Quit
	${EndIf}

	${IfNot} ${FileExists} $DataDirectory\PortableApps.comLauncherRuntimeData-$BaseName.ini
	${OrIf} $SecondaryLaunch == true
		${If} $SecondaryLaunch != true
			System::Call 'Kernel32::CreateMutex(i0, i0, t"PortableApps.comLauncher$AppID-$BaseName::Starting") i.r0'
			StrCpy $StatusMutex $0
		${EndIf}
		${CallPS} Pre +
		${CallPS} PreExec +
		${If} $SecondaryLaunch != true
			StrCpy $0 $StatusMutex
			System::Call 'Kernel32::CloseHandle(ir0) ?e'
			Pop $R9
		${EndIf}
		; File gets deleted in segment Core, hook Unload, so it'll only exist
		; in case of power-outage, disk removal while running or something like that.
		Call Execute
	${Else}
		; After doing Post, we don't do restart automatically as the variables
		; and environment are all altered and this may affect what happens
		; (some variables are checked against "" rather than initialising every
		; variable, and some may depend on environment variables, so spawing a
		; new instance isn't safe either)
		MessageBox MB_ICONSTOP $(LauncherCrashCleanup)
		; One possible solution: ExecWait another copy of self to do cleanup
	${EndIf}
	${If} $SecondaryLaunch != true
		System::Call 'Kernel32::CreateMutex(i0, i0, t"PortableApps.comLauncher$AppID-$BaseName::Stopping")'
	${EndIf}
	${If} $WaitForProgram != false
		${CallPS} PostExec -
		${CallPS} Post -
	${EndIf}
	Call Unload
SectionEnd

Function .onInstFailed ;{{{1
	; If Abort is called
	Call Unload
FunctionEnd ;}}}1

; This file has been optimised for use in Vim with folding.
; (If you can't cope, :set nofoldenable) vim:foldenable:foldmethod=marker
