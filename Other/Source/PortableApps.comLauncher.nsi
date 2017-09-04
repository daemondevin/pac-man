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

;= DEFINE PACKAGE
;= ################
!ifndef PACKAGE
	!define PACKAGE ..\..
!endif

;= ECHO MACRO
;= ################
!macro !echo msg
	!verbose push
	!verbose 4
	!echo "${msg}"
	!verbose pop
!macroend
!define !echo "!insertmacro !echo"

;=== Require at least Unicode NSIS 2.46 {{{1
;!include RequireLatestNSIS.nsh

;= READ/SET DEFINES
;= ################
!define APPINFOINI		`${PACKAGE}\App\AppInfo\appinfo.ini`
!define CUSTOM			`${PACKAGE}\App\AppInfo\Launcher\custom.nsh`
!define LAUNCHERINI		`${PACKAGE}\App\AppInfo\Launcher\${AppID}.ini`
!define NEWLINE			`$\r$\n`
${!echo} "${NEWLINE}Retrieving information from files in the AppInfo directory...${NEWLINE}${NEWLINE}"
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `ProgramExecutable64=` APPEXE64
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `Registry=` REGISTRY
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `Java=` JAVA
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `JDK=` JDK
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `XML=` XML_PLUGIN
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `Services=` SERVICES
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `RegDLLs=` REGISTERDLL
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `Ghostscript=` GHOSTSCRIPT
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `RunAsAdmin=` UAC
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `ExecAsUser=` ExecAsUser
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `RegRedirection=` DISABLEFSR
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `Redirection=` SYSTEMWIDE_DISABLEREDIR
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `ForceRedirection=` FORCE_SYSTEMWIDE_DISABLEREDIR
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `Tasks=` TaskCleanUp
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `RegCopyKeys=` RegCopy
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `FileCleanup=` FileCleanup
!searchparse /ignorecase /noerrors /file `${LAUNCHERINI}` `FontsFolder=` FONTS_ENABLE
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `AppID=` APPNAME
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `Name=` PORTABLEAPPNAME
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `CertSigning=` Certificate
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `UsesDotNetVersion=` dotNET_Version
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `FileWriteReplace=` REPLACE
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `RegistryValueWrite=` RegValueWrite
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `UseStdUtils=` StdUtils
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `InstallINF=` INF_Install
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `FileLocking=` FileLocking
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `Junctions=` NTFS
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `ACLRegSupport=` ACL
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `ACLDirSupport=` ACL_DIR
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `RMEmptyDir=` RMEMPTYDIRECTORIES
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `LocalLow=` LocalLow
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `PublicDoc=` PublicDoc
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `CompareVersions=` CompareVersions
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `ConfigFunctions=` ConFunc
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `CloseWindow=` CloseWindow
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `JSONSupport=` JSON
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `RestartSleep=` SleepValue
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `WinMessages=` WinMessages
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `LineWrite=` LineWrite
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `TrimString=` TrimString
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `CloseProcess=` CloseProc
!searchparse /ignorecase /noerrors /file `${APPINFOINI}` `Include64=` Include64
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
!if "${Certificate}" == true
	!define /REDEF Certificate
!else
	!ifdef Certificate
		!undef Certificate
	!endif
!endif
!if "${REGISTRY}" == true
	!define /REDEF REGISTRY
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
!if ! ${TrimString} == ""
	!if ${TrimString} == true
		!define /REDEF TrimString
	!else if ${TrimString} == false
		!undef TrimString
	!endif
!else
	!error "The key 'TrimString' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${CloseProc} == ""
	!if ${CloseProc} == true
		!define /REDEF CloseProc
	!else if ${CloseProc} == false
		!undef CloseProc
	!endif
!else
	!error "The key 'CloseProcess' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if "${UAC}" == "force"
	!define /REDEF UAC
	!ifndef TrimString
		!define TrimString
	!endif
	!include UAC.nsh
!else if  "${UAC}" == "compile-force"
	!define /REDEF UAC
	!ifndef TrimString
		!define TrimString
	!endif
	!include UAC.nsh
!else
	!ifdef UAC
		!undef UAC
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
!if ! ${SleepValue} == ""
	!define Sleep `${SleepValue}`		;=== Specify a number (milliseconds) to set a Sleep value for applications that need to restart.
!else
	!error "The key 'RestartSleep' in AppInfo.ini needs a value that's an integer!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${LineWrite} == ""
	!if ${LineWrite} == true 			;=== include LineWrite.nsh
		!define Include_LineWrite
	!else if ${LineWrite} == false
		!undef LineWrite
	!endif
!else
	!error "The key 'LineWrite' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${WinMessages} == ""
	!if ${WinMessages} == true 			;=== include WinMessages.nsh
		!define Include_WinMessages
	!else if ${WinMessages} == false
		!undef WinMessages
	!endif
!else
	!error "The key 'WinMessages' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${Include64} == ""
	!if ${Include64} == true 			;=== include WinMessages.nsh
		!define 64.nsh
	!else if ${Include64} == false
		!undef Include64
	!endif
!else
	!error "The key 'Include64' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${ConFunc} == ""
	!if ${ConFunc} == true 				;=== Enable ConfigWrite(s), ConfigRead(s) Functions.
		!define /REDEF ConFunc
	!else if ${ConFunc} == false
		!undef ConFunc
	!endif
!else
	!error "The key 'ConfigFunctions' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${LocalLow} == ""
	!if ${LocalLow} == true 			;=== Enable GetLocalAppDataLow Function.
		!define /REDEF LocalLow
	!else if ${LocalLow} == false
		!undef LocalLow
	!endif
!else
	!error "The key 'LocalLow' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${CompareVersions} == ""
	!if ${CompareVersions} == true 		;=== Enable VersionCompare Function.
		!define /REDEF CompareVersions
	!else if ${CompareVersions} == false
		!undef CompareVersions
	!endif
!else
	!error "The key 'CompareVersions' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${PublicDoc} == ""
	!if ${PublicDoc} == true 			;=== Enable GetPublicDoc Function.
		!define /REDEF PublicDoc
	!else if ${PublicDoc} == false
		!undef PublicDoc
	!endif
!else
	!error "The key 'PublicDoc' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${RegValueWrite} == ""
	!if ${RegValueWrite} == true
		!define RegSleep 50 			;=== Sleep value for the [RegistryValueWrite] section. Function is inaccurate otherwise.
	!else if ${RegValueWrite} == false
		!undef RegValueWrite
	!endif
!else
	!error "The key 'RegistryValueWrite' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${REPLACE} == ""
	!if ${REPLACE} == true 				;=== Enables Replace functionality in [FileWrite]
		!define /REDEF REPLACE
	!else if ${REPLACE} == false
		!undef REPLACE
	!endif
!else
	!error "The key 'FileWriteReplace' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${RMEMPTYDIRECTORIES} == ""
	!if ${RMEMPTYDIRECTORIES} == true 	;=== Enable RMEmptyDir Function.
		!define /REDEF RMEMPTYDIRECTORIES
	!else if ${RMEMPTYDIRECTORIES} == false
		!undef RMEMPTYDIRECTORIES
	!endif
!else
	!error "The key 'RMEmptyDir' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
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
!if ! ${JSON} == ""
	!if ${JSON} == true
		!define /REDEF JSON		;=== Enable the Close function
	!else if ${JSON} == false
		!undef JSON 
	!endif
!else
	!error "The key 'JSONSupport' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${CloseWindow} == ""
	!if ${CloseWindow} == true
		!define /REDEF CloseWindow		;=== Enable the Close function
	!else if ${CloseWindow} == false
		!undef CloseWindow 
	!endif
!else
	!error "The key 'CloseWindow' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${FileLocking} == ""
	!if ${FileLocking} == true
		!define IsFileLocked 			;=== If enabled, PortableApp will ensure DLL(s) are unlocked.
		!ifndef CloseWindow
			!define CloseWindow
		!endif
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

;= RUNTIME SWITCHS {{{1
;= ################
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
!define RUNTIME         `${DATA}\PortableApps.comLauncherRuntimeData-${APPNAME}.ini`
!define RUNTIME2        `$PLUGINSDIR\runtimedata.ini`
!define SETINI          `${SET}\${APPNAME}Settings.ini`
!define CONFIG          `$EXEDIR\${APPNAME}.ini`
!define OTHER           `$EXEDIR\Other`
!define PAL				PortableApps.comLauncher
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
	WriteINIStr `${RUNTIME}` ${PAL} `${_KEY}` `${_VALUE}`
	WriteINIStr `${RUNTIME2}` ${PAL} `${_KEY}` `${_VALUE}`
!macroend
!define ReadRuntime "!insertmacro _ReadRuntime"
!macro _ReadRuntime _VALUE _KEY
	IfFileExists `${RUNTIME}` 0 +3
	ReadINIStr `${_VALUE}` `${RUNTIME}` ${PAL} `${_KEY}`
	Goto +2
	ReadINIStr `${_VALUE}` `${RUNTIME2}` ${PAL} `${_KEY}`
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

;= INCLUDES {{{1
;= ################
${!echo} "${NEWLINE}Including required files...${NEWLINE}${NEWLINE}"
;(Standard NSIS) {{{2
!include LangFile.nsh
!include LogicLib.nsh
!include FileFunc.nsh
!include TextFunc.nsh
!include WordFunc.nsh

;= SHUTDOWN
;= ################
!include nsDialogs.nsh
!define /ifndef WS_POPUP 0x80000000
Function CreateShutdownBlockReason
	StrCpy $1 $hwndParent
	${If} $1 Z= 0 ; $hwndParent is 0, create a new window for silent installers
		System::Call 'USER32::CreateWindowEx(i0,t"STATIC",t"$(^Name)",i${WS_CHILD}|${WS_POPUP},i0,i0,i0,i0,pr1,i0,i0,i0)p.r1'
	${EndIf}
	System::Call 'USER32::ShutdownBlockReasonCreate(pr1,w"${PORTABLEAPPNAME} is running and still needs to clean up before shutting down!")'
FunctionEnd

;= (NSIS Plugins) {{{1
;= ################
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

;= (Custom) {{{2
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

;= LANGUAGES {{{1
;= ################
${!echo} "${NEWLINE}Loading language strings...${NEWLINE}${NEWLINE}"
!include Languages.nsh

;= VARIABLES {{{1
;= ################
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

;= Load Segments {{{1
;= ################
${!echo} "${NEWLINE}Loading segments...${NEWLINE}${NEWLINE}"
!include Segments.nsh

;= Debugging {{{1
;= ################
!include Debug.nsh

;= App Details {{{1
;= ################
${!echo}	`${NewLine}Specifying program details and setting options...${NewLine}${NewLine}`
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

;= CODE SIGNING
;= ################
!ifdef Certificate
	${!echo}	`${NewLine} Gathering the certificate and other information then signing ${OUTFILE}...${NewLine}${NewLine}`
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
		!ifdef FONTS_ENABLE
			${RunSegment} Fonts
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
	${OrIf} $SecondaryLaunch == true
		${If} $SecondaryLaunch != true
			System::Call 'Kernel32::CreateMutex(i0, i0, t"${PAL}${APPNAME}-${APPNAME}::Starting") i.r0'
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
		System::Call 'Kernel32::CreateMutex(i0, i0, t"${PAL}${APPNAME}-${APPNAME}::Stopping")'
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
