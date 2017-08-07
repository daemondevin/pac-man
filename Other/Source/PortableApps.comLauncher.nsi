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
!define APPINFOINI		`${PACKAGE}\App\AppInfo\appinfo.ini`
!define CUSTOM			`${PACKAGE}\App\AppInfo\Launcher\custom.nsh`
!define LAUNCHERINI		`${PACKAGE}\App\AppInfo\Launcher\${AppID}.ini`
!define NEWLINE			`$\r$\n`

${!echo} "${NEWLINE}Retrieving information from files in the AppInfo directory...${NEWLINE}${NEWLINE}"

!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `ProgramExecutable64=` APPEXE64
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `Registry=` REGISTRY
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `[RegistryValueWrite` RegValueWrite
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `Java=` JAVA
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `JDK=` JDK
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `XML=` XML_PLUGIN
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `Services= ` SERVICES
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `RegDLLs= ` REGISTERDLL
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `Ghostscript=` GHOSTSCRIPT
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `RunAsAdmin=` UAC
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `[DirectoriesMove` DIRECTORIES_MOVE
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `[DirectoriesCleanupIfEmpty` RMEMPTYDIRECTORIES
!searchparse /NOERRORS /FILE `${LAUNCHERINI}` `[FilesMove` FILES_MOVE
!searchparse /NOERRORS /FILE `${APPINFOINI}` `AppID=` APPNAME
!searchparse /NOERRORS /FILE `${APPINFOINI}` `Name=` PORTABLEAPPNAME
!searchparse /NOERRORS /FILE `${APPINFOINI}` `CertSigning=` Certificate
!searchparse /NOERRORS /FILE `${APPINFOINI}` `RegDisableRedirection= ` DISABLEFSR
!searchparse /NOERRORS /FILE `${APPINFOINI}` `UsesDotNetVersion=` dotNET_Version
!searchparse /NOERRORS /FILE `${APPINFOINI}` `FileWriteReplace=` REPLACE
!searchparse /NOERRORS /FILE `${APPINFOINI}` `RegistryValueWrite=` RegValueWrite
!searchparse /NOERRORS /FILE `${APPINFOINI}` `UseStdUtils= ` StdUtils
!searchparse /NOERRORS /FILE `${APPINFOINI}` `ExecAsUser= ` ExecAsUser
!searchparse /NOERRORS /FILE `${APPINFOINI}` `InstallINF= ` INF_Install
!searchparse /NOERRORS /FILE `${APPINFOINI}` `DisableRedirection= ` SYSTEMWIDE_DISABLEREDIR
!searchparse /NOERRORS /FILE `${APPINFOINI}` `ForceDisableRedirection= ` FORCE_SYSTEMWIDE_DISABLEREDIR
!searchparse /NOERRORS /FILE `${APPINFOINI}` `FontsFolder= ` FONTS_ENABLE
!searchparse /NOERRORS /FILE `${APPINFOINI}` `FileLocking= ` FileLocking
!searchparse /NOERRORS /FILE `${APPINFOINI}` `Junctions= ` NTFS
!searchparse /NOERRORS /FILE `${APPINFOINI}` `ACLRegSupport= ` ACL
!searchparse /NOERRORS /FILE `${APPINFOINI}` `ACLDirSupport= ` ACL_DIR
!searchparse /NOERRORS /FILE `${APPINFOINI}` `FileCleanup= ` FileCleanup
!searchparse /NOERRORS /FILE `${APPINFOINI}` `TaskCleanup= ` TaskCleanup
!searchreplace APP "${APPNAME}" "Portable" ""
!searchreplace FULLNAME "${PORTABLEAPPNAME}" " Portable" ""
!define APPDIR			`$EXEDIR\App\${APP}`

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

;=== Certificate
!if "${Certificate}" == true
	!define /REDEF Certificate
!else
	!ifdef Certificate
		!undef Certificate
	!endif
!endif

;=== Custom Defines
!if "${REGISTRY}" == true
	!define /REDEF REGISTRY
	!if "${RegValueWrite}" == "]"
		!define RegSleep 50	
	!endif
	!ifdef APP64
		!if ${DISABLEFSR} == true
			!define /REDEF DISABLEFSR 	;=== Disable Registry redirection for x64 machines.
		!endif
	!endif
!else
	!ifdef REGISTRY
		!undef REGISTRY
	!endif
!endif
!ifdef dotNET_Version
	!if ! ${dotNET_Version} == ""
		!define DOTNET
		!include DotNetVer.nsh
	!else
		!error "The key 'UsesDotNetVersion' in AppInfo.ini is set but has no value! If this PAF does not require the .NET Framework please omit this key entirely."
	!endif
!else
	!ifdef dotNET_Version
		!undef dotNET_Version
	!endif
!endif
!if "${JAVA}" == "find"
	!define /REDEF JAVA
!else if "${JAVA}" == "require"
	!define /REDEF JAVA
!else
	!ifdef JAVA
		!undef JAVA
	!endif
!endif
!if "${JDK}" == "find"
	!define /REDEF JDK
!else if "${JDK}" == "require"
	!define /REDEF JDK
!else
	!ifdef JDK
		!undef JDK
	!endif
!endif
!if "${XML_PLUGIN}" == true
	!define /REDEF XML_PLUGIN
	!include XML.nsh
!else
	!ifdef XML_PLUGIN
		!undef XML_PLUGIN
	!endif
!endif
!if "${GHOSTSCRIPT}" == "find"
	!define /REDEF GHOSTSCRIPT
!else if "${GHOSTSCRIPT}" == "require"
	!define /REDEF GHOSTSCRIPT
!else
	!ifdef GHOSTSCRIPT
		!undef GHOSTSCRIPT
	!endif
!endif
!if "${UAC}" == "force"
	!define /REDEF UAC
	!define TrimString
	!include UAC.nsh
!else if  "${UAC}" == "compile-force"
	!define /REDEF UAC
	!define TrimString
	!include UAC.nsh
!else
	!ifdef UAC
		!undef UAC
	!endif
!endif
!if "${DIRECTORIES_MOVE}" == "]"
	!define /REDEF DIRECTORIES_MOVE 	;=== Enable for added macros for the [DirectoriesMove] section in launcher.ini. See DirectoriesMove.nsh in the Segments directory.
!else
	!ifdef DIRECTORIES_MOVE
		!undef DIRECTORIES_MOVE
	!endif
!endif
!if "${RMEMPTYDIRECTORIES}" == "]"
	!define /REDEF RMEMPTYDIRECTORIES 	;=== Enable for the [DirectoriesCleanupIfEmpty] section in launcher.ini
!else
	!ifdef RMEMPTYDIRECTORIES
		!undef RMEMPTYDIRECTORIES
	!endif
!endif
!if "${FILES_MOVE}" == "]"
	!define /REDEF FILES_MOVE 			;=== Enable for added macros for the [FilesMove] section in launcher.ini. See FilesMove.nsh in the Segments directory.
!else
	!ifdef FILES_MOVE
		!undef FILES_MOVE
	!endif
!endif
!if "${REPLACE}" == true
	!define /REDEF REPLACE 				;=== Enables Replace functionality in [FileWrite]
!else
	!ifdef REPLACE
		!undef REPLACE
	!endif
!endif
!if "${RegValueWrite}" == true
	!define /REDEF RegValueWrite 50 	;=== Sleep value for [RegistryValueWrite]; function is inaccurate otherwise.
!else
	!ifdef RegValueWrite
		!undef RegValueWrite
	!endif
!endif
!if ${SERVICES} == true
	!define /REDEF SERVICES 			;=== Enable support for Services
!else
	!ifdef SERVICES
		!undef SERVICES
	!endif
!endif
!if ${REGISTERDLL} == true
	!define /REDEF REGISTERDLL 			;=== Enable support for registering library (DLLs) files
!else
	!ifdef REGISTERDLL
		!undef REGISTERDLL
	!endif
!endif
!if ! ${StdUtils} == ""
	!if ${StdUtils} == true
		!define /REDEF StdUtils 		;=== Include StndUtils without ExecAsUser
	!else if ${StdUtils} == false
		!undef StdUtils
	!endif
!else
	!error "The key 'UseStdUtils' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${ExecAsUser} == ""
	!if ${ExecAsUser} == true
		!define /REDEF ExecAsUser 		;=== For applications which need to run as normal user. 
	!else if ${ExecAsUser} == false
		!undef ExecAsUser
	!endif
!else
	!error "The key 'ExecAsUser' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${INF_Install} == ""
	!if ${INF_Install} == true
		!define /REDEF INF_Install 		;=== Enable for INF installation support.
	!else if ${INF_Install} == false
		!undef INF_Install
	!endif
!else
	!error "The key 'InstallINF' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${SYSTEMWIDE_DISABLEREDIR} == ""
	!if ${SYSTEMWIDE_DISABLEREDIR} == true
		!define /REDEF SYSTEMWIDE_DISABLEREDIR
	!else if ${SYSTEMWIDE_DISABLEREDIR} == false
		!undef SYSTEMWIDE_DISABLEREDIR
	!endif
!else
	!error "The key 'DisableRedirection' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${FORCE_SYSTEMWIDE_DISABLEREDIR} == ""
	!if ${FORCE_SYSTEMWIDE_DISABLEREDIR} == true
		!define /REDEF FORCE_SYSTEMWIDE_DISABLEREDIR
	!else if ${FORCE_SYSTEMWIDE_DISABLEREDIR} == false
		!undef FORCE_SYSTEMWIDE_DISABLEREDIR
	!endif
!else
	!error "The key 'ForceDisableRedirection' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${FONTS_ENABLE} == ""
	!if ${FONTS_ENABLE} == true
		!define /REDEF FONTS_ENABLE 	;=== Enable font support in ..\Data\Fonts
	!else if ${FONTS_ENABLE} == false
		!undef FONTS_ENABLE 
	!endif
!else
	!error "The key 'FontsFolder' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${FileLocking} == ""
	!if ${FileLocking} == true
		!define IsFileLocked 			;=== If enabled, PortableApp will ensure DLL(s) are unlocked.
		!define CloseWindow
	!else if ${FileLocking} == false
		!undef FileLocking 				;=== Disable 
	!endif
!else
	!error "The key 'FileLocking' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${NTFS} == ""
	!if ${NTFS} == true
		!define /REDEF NTFS 			;=== Enable support for Junctions (Symlinks)
	!else if ${NTFS} == false
		!undef NTFS 					;=== Disable
	!endif
!else
	!error "The key 'Junctions' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${ACL} == ""
	!if ${ACL} == true
		!define /REDEF ACL 				;=== Enable AccessControl support for registry keys
	!else if ${ACL} == false
		!undef ACL 						;=== Disable AccessControl support for registry keys
	!endif
!else
	!error "The key 'ACLRegSupport' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${ACL_DIR} == ""
	!if ${ACL_DIR} == true
		!define /REDEF ACL_DIR 			;=== Enable AccessControl support for directories
	!else if ${ACL_DIR} == false
		!undef ACL_DIR 					;=== Disable AccessControl support for directories
	!endif
!else
	!error "The key 'ACLDirSupport' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${FileCleanup} == ""
	!if ${FileCleanup} == true
		!define /REDEF FileCleanup 		;=== Enable FileCleanup segment
	!else if ${FileCleanup} == false
		!undef FileCleanup 				;=== Disable FileCleanup segment
	!endif
!else
	!error "The key 'FileCleanup' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${TaskCleanup} == ""
	!if ${TaskCleanup} == true
		!define /REDEF TaskCleanup 		;=== Enable TaskCleanup segment
	!else if ${TaskCleanup} == false
		!undef TaskCleanup 				;=== Disable TaskCleanup segment
	!endif
!else
	!error "The key 'TaskCleanup' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif

!define APPINFO         `$EXEDIR\App\AppInfo`
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

;=== Runtime Switches {{{1
Unicode true	;=== NSIS3 Support
ManifestDPIAware true
WindowIcon Off
XPStyle on
SilentInstall Silent
AutoCloseWindow True
!ifdef RUNASADMIN_COMPILEFORCE
	RequestExecutionLevel admin
!else ifdef UAC
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

;=== Prevent Win Shutdown
!include nsDialogs.nsh
!define /ifndef WS_POPUP 0x80000000
Function CreateShutdownBlockReason
	StrCpy $1 $hwndParent
	${If} $1 Z= 0 ; $hwndParent is 0, create a new window for silent installers
		System::Call 'USER32::CreateWindowEx(i0,t"STATIC",t"$(^Name)",i${WS_CHILD}|${WS_POPUP},i0,i0,i0,i0,pr1,i0,i0,i0)p.r1'
	${EndIf}
	System::Call 'USER32::ShutdownBlockReasonCreate(pr1,w"${PORTABLEAPPNAME} is running and still needs to clean up before shutting down!")'
FunctionEnd

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
!ifdef UAC
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
;(Custom) {{{2
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
!ifdef DIRECTORIES_MOVE
	!ifndef GET_ROOT
		!define GET_ROOT
	!endif
!endif

;=== Languages {{{1
${!echo} "${NEWLINE}Loading language strings...${NEWLINE}${NEWLINE}"
!include Languages.nsh

;=== Variables {{{1
${!echo} "${NEWLINE}Initialising variables and macros...${NEWLINE}${NEWLINE}"
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
!ifdef JDK
	Var UsingJavaExecutable
	Var JDKMode
	Var jdkDirectory
!endif

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
!searchparse /NOERRORS /FILE ${PACKAGE}\App\AppInfo\appinfo.ini `Contributors=` CONTRIBUTORS
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
		!if ! "${CONTRIBUTORS}" == ""
			VIAddVersionKey /LANG=${LANG_ENGLISH} Comments         `Developed by ${DEVELOPER} (with help from ${CONTRIBUTORS})`
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

;=== Code Signing
!ifdef Certificate
	${!echo}	`${NewLine} Gathering the certificate and other information then signing ${OUTFILE}...${NewLine}${NewLine}`
	;=== Signing Macro
	!define Finalize::Sign  `!insertmacro _Finalize::Sign`
	!macro _Finalize::Sign _CMD
		!finalize `${_CMD}`
	!macroend
	Var Timestamp
	Var TimestampSHA256
	!searchparse /NOERRORS /FILE ${PACKAGE}\App\AppInfo\appinfo.ini `CertExtension=` CertExtension
	!searchparse /NOERRORS /FILE ${PACKAGE}\App\AppInfo\appinfo.ini `CertTimestamp=` CertTimestamp
	!if ! "${CertTimestamp}" == ""
		!if "${CertTimestamp}" == "Comodo"
			StrCpy $Timestamp "http://timestamp.comodoca.com"
			StrCpy $TimestampSHA256 "http://timestamp.comodoca.com/?td=sha256"
		!else if "${CertTimestamp}" == "VeriSign"
			StrCpy $Timestamp "http://timestamp.verisign.com/scripts/timstamp.dll"
			StrCpy $TimestampSHA256 "http://sha256timestamp.ws.symantec.com/sha256/timestamp"
		!else if "${CertTimestamp}" == "GlobalSign"
			StrCpy $Timestamp "http://timestamp.globalsign.com/scripts/timstamp.dll"
			StrCpy $TimestampSHA256 "http://timestamp.globalsign.com/?signature=sha2"
		!else
			StrCpy $Timestamp "http://timestamp.comodoca.com"
			StrCpy $TimestampSHA256 "http://timestamp.comodoca.com/?td=sha256"
		!endif
	!else
		StrCpy $Timestamp "http://timestamp.comodoca.com"
		StrCpy $TimestampSHA256 "http://timestamp.comodoca.com/?td=sha256"
	!endif
	!define CERT		`Contrib\certificates\${DEVELOPER}.${CertExtension}`
	!define SIGNTOOL	`Contrib\bin\signtool.exe`
	!define SHA1		`"${SIGNTOOL}" sign /f "${CERT}" /p "" /t "$Timestamp" /v "${PACKAGE}\${OUTFILE}"`
	!define SHA256		`"${SIGNTOOL}" sign /f "${CERT}" /p "" /fd sha256 /tr "$TimestampSHA256" /td sha256 /as /v "${PACKAGE}\${OUTFILE}"`
	;=== Sign
	${Finalize::Sign} `${SHA1}`
	${Finalize::Sign} `${SHA256}`
!endif

!verbose 4

Function .onInit           ;{{{1
	Call CreateShutdownBlockReason
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
	;${RunSegment} XML
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
		${RunSegment} FilesCleanup
		${RunSegment} DirectoriesCleanup
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
