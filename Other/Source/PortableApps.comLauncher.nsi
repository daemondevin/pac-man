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
  /**
  * This is a modified version of the official release
  * The modifacations to this file were added by Devin Gaul
  * For support on this variant visit the GitHub project page below.
  *
  * https://github.com/demondevin/portableapps.comlauncher
  *
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

!searchparse /NOERRORS /FILE `${APPINFO}` `Name=` PORTABLEAPPNAME
!searchreplace FULLNAME "${PORTABLEAPPNAME}" " Portable" ""

!define APPDIR			`$EXEDIR\App\${APP}`

!searchparse /NOERRORS /FILE `${LAUNCHER}` `ProgramExecutable64=` APPEXE64
!if ! "${APPEXE64}" == ""
	!searchreplace APP64 "${APPNAME}" "Portable" "64"
!else
	!ifdef APPEXE64
		!undef APPEXE64
	!endif
!endif

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
!define ResHacker		`Contrib\bin\ResHacker.exe`
!define ManifDir		`Contrib\manifests`
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
	!searchparse /NOERRORS /FILE `${LAUNCHER}` `Type=Rep` REPLACE
	!if "${REPLACE}" == "lace"
		!define /REDEF REPLACE ;=== Enables Replace functionality in [FileWrite]
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
!searchparse /NOERRORS /FILE `${APPINFO}` `UsesDotNetVersion=` dotNET_Version
!ifdef dotNET_Version
	!if ! ${dotNET_Version} == ""
		!define DOTNET
	!else
		!error "The key 'UsesDotNetVersion' in AppInfo.ini is set but has no value! If this PAF does not require the .NET Framework please omit this key entirely."
	!endif
!else
	!ifdef dotNET_Version
		!undef dotNET_Version
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
!searchparse /NOERRORS /FILE `${LAUNCHER}` `XML=` XML_PLUGIN
!if "${XML_PLUGIN}" == true
	!define /REDEF XML_PLUGIN
	!include XML.nsh
!else
	!ifdef XML_PLUGIN
		!undef XML_PLUGIN
	!endif
!endif
!searchparse /NOERRORS /FILE `${LAUNCHER}` `Ghostscript=` GHOSTSCRIPT
!if "${GHOSTSCRIPT}" == "find"
	!define /REDEF GHOSTSCRIPT
!else if "${GHOSTSCRIPT}" == "require"
	!define /REDEF GHOSTSCRIPT
!else
	!ifdef GHOSTSCRIPT
		!undef GHOSTSCRIPT
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
!searchparse /NOERRORS /FILE `${LAUNCHER}` `[DirectoriesCleanupIfEmpty` RMEMPTYDIRECTORIES
!if "${RMEMPTYDIRECTORIES}" == "]"
	!define /REDEF RMEMPTYDIRECTORIES	;=== enable for the [DirectoriesCleanupIfEmpty] section in launcher.ini
!else
	!ifdef RMEMPTYDIRECTORIES
		!undef RMEMPTYDIRECTORIES
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `UseStdUtils= ` StdUtils	;=== Include StndUtils without ExecAsUser
!if ${StdUtils} == true
	!define /REDEF StdUtils
!else
	!ifdef StdUtils
		!undef StdUtils
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `ExecAsUser= ` ExecAsUser	;=== For applications which need to run as normal user.
!if ${ExecAsUser} == true
	!define /REDEF ExecAsUser
!else
	!ifdef ExecAsUser
		!undef ExecAsUser
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `DisableRedirection= ` SYSTEMWIDE_DISABLEREDIR
!if ${SYSTEMWIDE_DISABLEREDIR} == true
	!define /REDEF SYSTEMWIDE_DISABLEREDIR
!else
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!undef SYSTEMWIDE_DISABLEREDIR
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `ForceDisableRedirection= ` FORCE_SYSTEMWIDE_DISABLEREDIR
!if ${FORCE_SYSTEMWIDE_DISABLEREDIR} == true
	!define /REDEF FORCE_SYSTEMWIDE_DISABLEREDIR
!else
	!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
		!undef FORCE_SYSTEMWIDE_DISABLEREDIR
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `FontsFolder= ` FONTS_ENABLE	;=== Adds font support in ..\Data\Fonts
!if ${FONTS_ENABLE} == true
	!define /REDEF FONTS_ENABLE
!else
	!ifdef FONTS_ENABLE
		!undef FONTS_ENABLE
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `FileLocking= ` IsFileLocked	
!if ${IsFileLocked} == true
	!define /REDEF IsFileLocked ;=== If enabled, PortableApp will ensure DLL(s) are unlocked.
	!define CloseWindow
!else
	!ifdef IsFileLocked
		!undef IsFileLocked
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `Junctions= ` NTFS	
!if ${NTFS} == true
	!define /REDEF NTFS ;=== Enable support for Junctions
!else
	!ifdef NTFS
		!undef NTFS
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `ACLSupport= ` ACL	
!if ${ACL} == true
	!define /REDEF ACL ;=== Enable AccessControl support 
!else
	!ifdef ACL
		!undef ACL
	!endif
!endif
!searchparse /NOERRORS /FILE `${APPINFO}` `ACLDirSupport= ` ACL_DIR	
!if ${ACL_DIR} == true
	!define /REDEF ACL_DIR ;=== Enable AccessControl support for directories
!else
	!ifdef ACL_DIR
		!undef ACL_DIR
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
${!echo}	`${NewLine}Specifying program details and setting options...${NewLine}${NewLine}`

### BRANDING ###
!searchparse /NOERRORS /FILE ${PACKAGE}\App\AppInfo\appinfo.ini `Trademarks=` TRADEMARK
!searchparse /NOERRORS /FILE ${PACKAGE}\App\AppInfo\appinfo.ini `Developer=` DEVELOPER
!searchparse /NOERRORS /FILE ${PACKAGE}\App\AppInfo\appinfo.ini `Publisher=` PUBLISHER
!searchparse /NOERRORS /FILE ${PACKAGE}\App\AppInfo\appinfo.ini `PackageVersion=` PACKAGE_VERSION
!searchparse /NOERRORS /FILE ${PACKAGE}\App\AppInfo\appinfo.ini `Start=` OUTFILE

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
		VIAddVersionKey /LANG=${LANG_ENGLISH} LegalCopyright   `Copyright © ${PUBLISHER} ${YEAR}`
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
		VIAddVersionKey /LANG=${LANG_ENGLISH} Comments         `Developed by ${DEVELOPER} (http://softables.tk/)`
	!else
		VIAddVersionKey /LANG=${LANG_ENGLISH} Comments         `A portable build of ${FULLNAME} using the PortableApps.com Launcher`
		!ifdef DEVELOPER
			!undef DEVELOPER
		!endif
	!endif
!endif
VIAddVersionKey /LANG=${LANG_ENGLISH} ProductVersion   Portable

!verbose 4

Function .onInit           ;{{{1
	Push $0
	CreateDirectory `${SET}`
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
Function Init           ;{{{1
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
Function Pre           ;{{{1
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
Function PrePrimary           ;{{{1
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
Function PreSecondary           ;{{{1
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
Function PreExec           ;{{{1
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
Function PreExecPrimary           ;{{{1
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
Function PreExecSecondary           ;{{{1
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
Function Execute           ;{{{1
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
Function PostPrimary           ;{{{1
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
	${RunSegment} DirectoriesCleanup
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
Function PostSecondary           ;{{{1
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
Function Post           ;{{{1
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
Function Unload           ;{{{1
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
		${RunSegment} FilesCleanup
		${RunSegment} DirectoriesCleanup
	${EndIf}
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
Section           ;{{{1
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
	System::Call 'Kernel32::OpenMutex(i1048576, b0, t"PortableApps.comLauncher${APPNAME}-${APPNAME}::Starting") i.R0 ?e'
	System::Call 'Kernel32::CloseHandle(iR0)'
	Pop $R9
	${If} $R9 <> 2
		MessageBox MB_ICONSTOP $(LauncherAlreadyStarting)
		Quit
	${EndIf}
	System::Call 'Kernel32::OpenMutex(i1048576, i0, t"PortableApps.comLauncher${APPNAME}-${APPNAME}::Stopping") i.R0 ?e'
	System::Call 'Kernel32::CloseHandle(iR0)'
	Pop $R9
	${If} $R9 <> 2
		MessageBox MB_ICONSTOP $(LauncherAlreadyStopping)
		Quit
	${EndIf}
	${IfNot} ${FileExists} `${RUNTIME}`
	${OrIf} $SecondaryLaunch == true
		${If} $SecondaryLaunch != true
			System::Call 'Kernel32::CreateMutex(i0, i0, t"PortableApps.comLauncher${APPNAME}-${APPNAME}::Starting") i.r0'
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
		System::Call 'Kernel32::CreateMutex(i0, i0, t"PortableApps.comLauncher${APPNAME}-${APPNAME}::Stopping")'
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
Function .onInstFailed           ;{{{1
	Call Unload
FunctionEnd
