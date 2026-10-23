;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
;   Core.nsh
;   This file provides core functionality and instructions for use with the other segments.
; 

;= VARIABLES
Var LauncherFile
Var CoreWantedExecutable

;= INCLUDES
!include PortableAppsCompiler.nsh

; Sets $ProgramExecutable from the [Launch] keys for one architecture. Stack
; in: the key suffix ("ARM64", "64" or "" for x86). $1 holds the command line
; parameters: when there are some, ProgramExecutableWhenParameters<suffix> is
; tried before ProgramExecutable<suffix>. For ARM64 and x64 the file has to
; exist too, so a package whose build for this machine is missing falls back
; to the next one (ARM64 to x64 to x86) instead of failing to start. The
; x64 build is only tried when $Arch isn't x86, so forcing x86 works.
Function Core_ProgramExecutable
	Exch $2
	Push $3
	StrCpy $3 ""
	${If} $1 != ""
		ClearErrors
		${ReadLauncherConfig} $3 Launch ProgramExecutableWhenParameters$2
	${EndIf}
	${If} $3 == ""
		ClearErrors
		${ReadLauncherConfig} $3 Launch ProgramExecutable$2
	${EndIf}
	${If} $3 != ""
		${If} $2 == ""
		${OrIf} ${FileExists} `$EXEDIR\App\$3`
			StrCpy $ProgramExecutable $3
		${EndIf}
	${EndIf}
	ClearErrors
	Pop $3
	Pop $2
FunctionEnd

; Sets $0 to the command line parameters meant for the app: the launcher's
; own /UAC and /NCRC switches are taken out.
Function Core_LaunchParameters
	Push $1
	${GetParameters} $0
	!ifdef UAC
		ClearErrors
		${GetOptions} $0 /UAC $1
		${IfNot} ${Errors}
			${WordReplace} $0 /UAC$1 "" + $0
			${Trim} $0 $0
		${EndIf}
		ClearErrors
		${GetOptions} $0 /NCRC $1
		${IfNot} ${Errors}
			${WordReplace} $0 /NCRC$1 "" + $0
			${Trim} $0 $0
		${EndIf}
	!endif
	ClearErrors
	Pop $1
FunctionEnd

; Sets $ProgramExecutable from the [Launch] keys for this machine, trying
; ARM64, then x64, then x86 (see Core_ProgramExecutable). $1 holds the command
; line parameters. $CoreWantedExecutable is set to the first executable the
; launcher.ini names for this machine, whether it exists or not, so a missing
; program can be reported by the name the package expects.
Function Core_SelectProgramExecutable
	Push $2
	StrCpy $ProgramExecutable ""
	StrCpy $CoreWantedExecutable ""
	${If} $Arch == arm64
		Push ARM64
		Call Core_WantedExecutable
		Push ARM64
		Call Core_ProgramExecutable
	${EndIf}
	${If} $ProgramExecutable == ""
	${AndIf} $Arch != x86
		Push 64
		Call Core_WantedExecutable
		Push 64
		Call Core_ProgramExecutable
	${EndIf}
	${If} $ProgramExecutable == ""
		Push ""
		Call Core_WantedExecutable
		Push ""
		Call Core_ProgramExecutable
	${EndIf}
	Pop $2
FunctionEnd

; Sets $CoreWantedExecutable to the [Launch] executable for one architecture
; (stack in: the key suffix), unless an earlier one was found already.
Function Core_WantedExecutable
	Exch $2
	Push $3
	${If} $CoreWantedExecutable == ""
		StrCpy $3 ""
		${If} $1 != ""
			ClearErrors
			${ReadLauncherConfig} $3 Launch ProgramExecutableWhenParameters$2
		${EndIf}
		${If} $3 == ""
			ClearErrors
			${ReadLauncherConfig} $3 Launch ProgramExecutable$2
		${EndIf}
		StrCpy $CoreWantedExecutable $3
	${EndIf}
	ClearErrors
	Pop $3
	Pop $2
FunctionEnd

${SegmentFile}
${Segment.onInit}
	${GetBaseName} $EXEFILE $BaseName
	StrCpy $LauncherFile `${LAUNCHER}`
	StrCpy $AppID `${APPNAME}`
	StrCpy $AppName `${FULLNAME}`
	StrCpy $AppNamePortable `${PORTABLEAPPNAME}`
!macroend
${SegmentInit}
	IfFileExists `${LAUNCHER}` 0 +5
	InitPluginsDir
	CopyFiles /SILENT `${LAUNCHER}` `${LAUNCHER2}`
	StrCpy $LauncherFile `${LAUNCHER2}`
	Goto +5
	StrCpy $MissingFileOrPath `${LAUNCHER}`
	MessageBox MB_OK|MB_ICONSTOP `$(LauncherFileNotFound)`
	Call Unload
	Quit
	!ifndef DisableProgramExecSegment
		Call Core_LaunchParameters
		!ifmacrodef ProExecInit
			!insertmacro ProExecInit
		!else
			StrCpy $1 $0
			Call Core_SelectProgramExecutable
		!endif
	!endif
	StrCmpS $ProgramExecutable "" 0 +3
	MessageBox MB_OK|MB_ICONSTOP `${RUNTIME} is missing [Launch]:ProgramExecutable - what am I to launch?`
	Quit
	!ifmacrodef UnProExecInit
		!insertmacro UnProExecInit
	!endif
!macroend
${SegmentPreExecPrimary}
	${WriteRuntimeData} ${PAL} PluginsDir $PLUGINSDIR
!macroend
${SegmentUnload}
	!ifmacrodef UnloadEXE
		!insertmacro UnloadEXE
	!endif
	!ifmacrodef Unload
		!insertmacro Unload
	!endif
	!ifdef SEGMENTS_REGISTRY
		StrCmpS $Registry true 0 +2
		Registry::_Unload
	!endif
	SetOutPath `$TEMP` ;=== prevents $PLUGINSDIR from being locked.
	FileClose $_FEIP_FileHandle
	Delete `$PLUGINSDIR\launcher.ini`
	Delete `${LAUNCHER2}`
	${If} $SecondaryLaunch != true
		${ReadRuntimeData} $0 ${PAL} PluginsDir
		${If} $0 != ""
		${AndIf} $0 != $PLUGINSDIR
			RMDir /r `$0`
		${EndIf}
		Delete `${RUNTIME}`
	${EndIf}
	Delete `${RUNTIME2}`
	System::Free 0
!macroend
