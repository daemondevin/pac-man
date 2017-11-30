;=#
;
; Defines.nsh
; 
; This file gathers all the necessary settings definitions for runtime.
; 
!define APPINFOINI		`${PACKAGE}\App\AppInfo\appinfo.ini`
!define CUSTOM			`${PACKAGE}\App\AppInfo\Launcher\custom.nsh`
!define LAUNCHERINI		`${PACKAGE}\App\AppInfo\Launcher\${AppID}.ini`

${!ECHO} "${NEWLINE}Retrieving information from files in the AppInfo directory...${NEWLINE}${NEWLINE}"

!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `ProgramExecutable64=` APPEXE64
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `Registry=` REGISTRY
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `Java=` JAVA
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `JDK=` JDK
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `XML=` XML_PLUGIN
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `Services=` SERVICES
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `RegDLLs=` REGISTERDLL
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `Ghostscript=` GHOSTSCRIPT
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `RunAsAdmin=` UAC
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `ExecAsUser=` ExecAsUser
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `RegRedirection=` DISABLEFSR
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `Redirection=` SYSTEMWIDE_DISABLEREDIR
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `ForceRedirection=` FORCE_SYSTEMWIDE_DISABLEREDIR
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `Tasks=` TaskCleanUp
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `RegCopyKeys=` RegCopy
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `FileCleanup=` FileCleanup
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `DirectoryCleanup=` DirectoryCleanup
!searchparse /ignorecase /noerrors /file "${LAUNCHERINI}" `FontsFolder=` FONTS_ENABLE

!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `AppID=` APPNAME
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `Name=` PORTABLEAPPNAME
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `CertSigning=` Certificate
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `UsesDotNetVersion=` dotNET_Version
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `ElevatedPrivileges=` Elevate
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `FileWriteReplace=` REPLACE
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `RegistryValueWrite=` RegValueWrite
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `UseStdUtils=` StdUtils
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `InstallINF=` INF_Install
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `FileLocking=` FileLocking
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `Junctions=` NTFS
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `ACLRegSupport=` ACL
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `ACLDirSupport=` ACL_DIR
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `RMEmptyDir=` RMEMPTYDIRECTORIES
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `LocalLow=` LocalLow
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `PublicDoc=` PublicDoc
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `CompareVersions=` CompareVersions
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `ConfigFunctions=` ConFunc
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `CloseWindow=` CloseWindow
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `JSONSupport=` JSON
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `RestartSleep=` SleepValue
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `WinMessages=` WinMessages
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `LineWrite=` LineWrite
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `TrimString=` TrimString
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `CloseProcess=` CloseProc
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `Include64=` Include64
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `IncludeWordRep=` IncludeWordRep
!searchparse /ignorecase /noerrors /file "${APPINFOINI}" `GetBetween=` GetBetween

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
			!define /REDEF DISABLEFSR 	;= Disable Registry redirection for x64 machines.
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
!else if  "${UAC}" == "compile-force"
	!define /REDEF UAC
	!ifndef TrimString
		!define TrimString
	!endif
!else if "${UAC}" == "try"
	!define /REDEF UAC
	!ifndef TrimString
		!define TrimString
	!endif
	!include UAC.nsh
!else if "${Elevate}" == "auto"
	!define /REDEF UAC
	!ifndef TrimString
		!define TrimString
	!endif
!else
	!ifdef UAC
		!undef UAC
	!endif
!endif
!if ${SERVICES} == true
	!define /REDEF SERVICES 			;= Enable support for Services
!else
	!ifdef SERVICES
		!undef SERVICES
	!endif
!endif
!if ${REGISTERDLL} == true
	!define /REDEF REGISTERDLL 			;= Enable support for registering library (DLLs) files
!else
	!ifdef REGISTERDLL
		!undef REGISTERDLL
	!endif
!endif
!if ! ${SleepValue} == ""
	!define Sleep ${SleepValue}			;= Specify a number (milliseconds) to set a Sleep value for applications that need to restart.
!else
	!error "The key 'RestartSleep' in AppInfo.ini needs a value that's an integer!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${LineWrite} == ""
	!if ${LineWrite} == true 			;= include LineWrite.nsh
		!define Include_LineWrite
	!else if ${LineWrite} == false
		!undef LineWrite
	!endif
!else
	!error "The key 'LineWrite' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${WinMessages} == ""
	!if ${WinMessages} == true 			;= include WinMessages.nsh
		!define Include_WinMessages
	!else if ${WinMessages} == false
		!undef WinMessages
	!endif
!else
	!error "The key 'WinMessages' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${GetBetween} == ""
	!if ${GetBetween} == true 			;= include GetBetween.nsh
		!define GetBetween.nsh
	!else if ${GetBetween} == false
		!undef GetBetween
	!endif
!else
	!error "The key 'GetBetween' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${IncludeWordRep} == ""
	!if ${IncludeWordRep} == true 			;= include the WordRep(S) functions.
		!define Include_WordRep
	!else if ${IncludeWordRep} == false
		!undef IncludeWordRep
	!endif
!else
	!error "The key 'IncludeWordRep' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${Include64} == ""
	!if ${Include64} == true 			;= include x64.nsh
		!define 64.nsh
	!else if ${Include64} == false
		!undef Include64
	!endif
!else
	!error "The key 'Include64' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${ConFunc} == ""
	!if ${ConFunc} == true 				;= Enable ConfigWrite(S), ConfigRead(S) Functions.
		!define /REDEF ConFunc
	!else if ${ConFunc} == false
		!undef ConFunc
	!endif
!else
	!error "The key 'ConfigFunctions' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${LocalLow} == ""
	!if ${LocalLow} == true 			;= Enable GetLocalAppDataLow Function.
		!define /REDEF LocalLow
	!else if ${LocalLow} == false
		!undef LocalLow
	!endif
!else
	!error "The key 'LocalLow' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${CompareVersions} == ""
	!if ${CompareVersions} == true 		;= Enable VersionCompare Function.
		!define /REDEF CompareVersions
	!else if ${CompareVersions} == false
		!undef CompareVersions
	!endif
!else
	!error "The key 'CompareVersions' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${PublicDoc} == ""
	!if ${PublicDoc} == true 			;= Enable GetPublicDoc Function.
		!define /REDEF PublicDoc
	!else if ${PublicDoc} == false
		!undef PublicDoc
	!endif
!else
	!error "The key 'PublicDoc' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${RegValueWrite} == ""
	!if ${RegValueWrite} == true
		!define RegSleep 50 			;= Sleep value for the [RegistryValueWrite] section. Function is inaccurate otherwise.
	!else if ${RegValueWrite} == false
		!undef RegValueWrite
	!endif
!else
	!error "The key 'RegistryValueWrite' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${REPLACE} == ""
	!if ${REPLACE} == true 				;= Enables Replace functionality in [FileWrite]
		!define /REDEF REPLACE
	!else if ${REPLACE} == false
		!undef REPLACE
	!endif
!else
	!error "The key 'FileWriteReplace' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${RMEMPTYDIRECTORIES} == ""
	!if ${RMEMPTYDIRECTORIES} == true 	;= Enable RMEmptyDir Function.
		!define /REDEF RMEMPTYDIRECTORIES
	!else if ${RMEMPTYDIRECTORIES} == false
		!undef RMEMPTYDIRECTORIES
	!endif
!else
	!error "The key 'RMEmptyDir' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${StdUtils} == ""
	!if ${StdUtils} == true
		!define /REDEF StdUtils 		;= Include StndUtils without ExecAsUser
	!else if ${StdUtils} == false
		!undef StdUtils
	!endif
!else
	!error "The key 'UseStdUtils' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${ExecAsUser} == ""
	!if ${ExecAsUser} == true
		!define /REDEF ExecAsUser 		;= For applications which need to run as normal user. 
	!else if ${ExecAsUser} == false
		!undef ExecAsUser
	!endif
!else
	!error "The key 'ExecAsUser' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${INF_Install} == ""
	!if ${INF_Install} == true
		!define /REDEF INF_Install 		;= Enable for INF installation support.
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
		!define /REDEF FONTS_ENABLE 	;= Enable font support in ..\Data\Fonts
	!else if ${FONTS_ENABLE} == false
		!undef FONTS_ENABLE 
	!endif
!else
	!error "The key 'FontsFolder' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${JSON} == ""
	!if ${JSON} == true
		!define /REDEF JSON		;= Enable the Close function
	!else if ${JSON} == false
		!undef JSON 
	!endif
!else
	!error "The key 'JSONSupport' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${CloseWindow} == ""
	!if ${CloseWindow} == true
		!define /REDEF CloseWindow		;= Enable the Close function
	!else if ${CloseWindow} == false
		!undef CloseWindow 
	!endif
!else
	!error "The key 'CloseWindow' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${FileLocking} == ""
	!if ${FileLocking} == true
		!define IsFileLocked 			;= If enabled, PortableApp will ensure DLL(s) are unlocked.
		!ifndef CloseWindow
			!define CloseWindow
		!endif
	!else if ${FileLocking} == false
		!undef FileLocking 				;= Disable 
	!endif
!else
	!error "The key 'FileLocking' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${NTFS} == ""
	!if ${NTFS} == true
		!define /REDEF NTFS 			;= Enable support for Junctions (Symlinks)
	!else if ${NTFS} == false
		!undef NTFS 					;= Disable
	!endif
!else
	!error "The key 'Junctions' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${ACL} == ""
	!if ${ACL} == true
		!define /REDEF ACL 				;= Enable AccessControl support for registry keys
	!else if ${ACL} == false
		!undef ACL 						;= Disable AccessControl support for registry keys
	!endif
!else
	!error "The key 'ACLRegSupport' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${ACL_DIR} == ""
	!if ${ACL_DIR} == true
		!define /REDEF ACL_DIR 			;= Enable AccessControl support for directories
	!else if ${ACL_DIR} == false
		!undef ACL_DIR 					;= Disable AccessControl support for directories
	!endif
!else
	!error "The key 'ACLDirSupport' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${FileCleanup} == ""
	!if ${FileCleanup} == true
		!define /REDEF FileCleanup 		;= Enable FileCleanup segment
	!else if ${FileCleanup} == false
		!undef FileCleanup 				;= Disable FileCleanup segment
	!endif
!else
	!error "The key 'FileCleanup' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${DirectoryCleanup} == ""
	!if ${DirectoryCleanup} == true
		!define /REDEF DirectoryCleanup 		;= Enable DirectoryCleanup segment
	!else if ${DirectoryCleanup} == false
		!undef DirectoryCleanup 				;= Disable DirectoryCleanup segment
	!endif
!else
	!error "The key 'DirectoryCleanup' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
!if ! ${TaskCleanup} == ""
	!if ${TaskCleanup} == true
		!define /REDEF TaskCleanup 		;= Enable TaskCleanup segment
	!else if ${TaskCleanup} == false
		!undef TaskCleanup 				;= Disable TaskCleanup segment
	!endif
!else
	!error "The key 'TaskCleanup' in AppInfo.ini needs a true/false value!${NewLine}${NewLine}If support for this isn't needed, omit this key entirely!"
!endif
