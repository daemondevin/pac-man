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

;= INCLUDES
!include PortableAppsCompiler.nsh

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
		${GetParameters} $0
		!ifdef UAC
			${GetOptions} $0 /UAC $1
			${IfNot} ${Errors}
				${WordReplace} $0 /UAC$1 "" + $0
				${Trim} $0 $0
			${EndIf}
			${GetOptions} $0 /NCRC $1
			${IfNot} ${Errors}
				${WordReplace} $0 /NCRC$1 "" + $0
				${Trim} $0 $0
			${EndIf}
		!endif
		!ifmacrodef ProExecInit
			!insertmacro ProExecInit
		!else
			StrCpy $ProgramExecutable ""
			StrCmpS $Bit 64 0 +5
			StrCmpS $0 "" +2
			${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutableWhenParameters64
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutable64
			StrCmpS $0 "" +3
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutableWhenParameters
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutable
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
