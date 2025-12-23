;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; Symlinks.nsh
;     This file handles soft links, hard links, symbolic links, and junctions
; 
; USAGE
;   Add the section [SymLink#] (where '#' represents a number in numarical order) to Launcher.ini.
;
;   Keys:
;       Source	-	The name of the folder or file in the Data directory (i.e. Data\SymlinkFolder or Data\HardlinkFile.txt)
;	    Target	-	Path that the link points to (supports all environment variables)
;	    Type	-	soft, hard, symbolic, or junction
;
; EXAMPLES
;   [Symlink1]
;   Type=hard
;   Source=HardlinkFile.txt
;   Target="%USERPROFILE%\Documents\HardlinkFile.txt"
;
;   [Symlink2]
;   Type=soft
;   Source="Symlink'Folder"
;   Target="%APPDATA%\Symlink'Folder"

!ifdef SEGMENTS_SYMLINKS
;= VARIABLES
Var LinkType
Var LinkPath
Var TargetPath
Var UserApprovesSymlinks

;= INCLUDES
!ifndef LOGICLIB
    !include LogicLib.nsh
!endif

;= DEFINES
!define FILE_SUPPORTS_REPARSE_POINTS 0x00000080

;= Macros
!define YESNO "!insertmacro _YESNO"
!macro _YESNO _FLAGS _BIT _VAR
	IntOp ${_VAR} ${_FLAGS} & ${_BIT}
	${IfThen} ${_VAR} <> 0 ${|} StrCpy ${_VAR} 1 ${|}
	${IfThen} ${_VAR} == 0 ${|} StrCpy ${_VAR} 0 ${|}
!macroend

;= FUNCTIONS
Function ValidateFS
	!define ValidateFS `!insertmacro _ValidateFS`
	!macro _ValidateFS _PATH _RETURN
		Push `${_PATH}`
		Call ValidateFS
		Pop ${_RETURN}
	!macroend
	Exch $0
	Push $1
	Push $2
	StrCpy $0 $0 3
	System::Call `Kernel32::GetVolumeInformation(t "$0",t,i ${NSIS_MAX_STRLEN},*i,*i,*i.r1,t,i ${NSIS_MAX_STRLEN})i.r0`
	${If} $0 <> 0
		${YESNO} $1 ${FILE_SUPPORTS_REPARSE_POINTS} $2
	${EndIf}
	Pop $0
	Pop $1
	Exch $2
FunctionEnd

${SegmentFile}
${SegmentPrePrimary}
    ${ReadUserConfigWithDefault} $UserApprovesSymlinks Symlinks true
    ${If} $UserApprovesSymlinks == true
        ${DebugMsg} "Processing symbolic links and junctions..."
        StrCpy $R0 1
        ${Do}
            ClearErrors
            ${ReadLauncherConfig} `$0` Symlink$R0 Source
            ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
            ${ReadLauncherConfig} `$1` Symlink$R0 Target
            ${ReadLauncherConfig} `$2` Symlink$R0 Type
            
            ${Trim} $2 `$2` 
            
            StrCmp $2 "hard" +7 0
            StrCmp $2 "soft" +6 0
            StrCmp $2 "junction" +5 0
            StrCmp $2 "symbolic" +4 0            
            MessageBox MB_ICONSTOP|MB_TOPMOST `[Symlink$R0]Type must be one of four options: $\r$\nhard, soft, junction, or symbolic`
            Call Unload
            Quit
            StrCpy $LinkType $2
            
            ${DebugMsg} "Preparing $LinkType link:$\r$\n$0=$1"
            
            StrCpy $LinkPath `$DataDirectory\$0`
            
            ExpandEnvStrings $TargetPath `$1`
            
            ${DebugMsg} "Full path to target directory:$\r$\n$TargetPath"
            
            ${GetParent} $TargetPath $4
            ${IfNot} ${FileExists} $4
                ${DebugMsg} "Creating parent directory:$\r$\n$4"
                CreateDirectory $4
            ${EndIf}
            
            ${DebugMsg} "Source path:$\r$\n$LinkPath"
            
            ${If} ${FileExists} "$TargetPath\*.*"
                StrCpy $3 "directory"
                ${DebugMsg} "Backing up local directory:$\r$\n$TargetPath --> $TargetPath.BackupBy${APPNAME}"
                ${GetParent} $TargetPath $R1
                ${GetBaseName} $TargetPath $R2
                ${Directory::BackupLocal} $R1 $R2
            ${Else}
                StrCpy $3 "file"
                ${DebugMsg} "Backing up local file:$\r$\n$TargetPath --> $TargetPath.BackupBy${APPNAME}"
                ${File::BackupLocal} $TargetPath
            ${EndIf}

            ${DebugMsg} "Executing CompilerLinker to link:$\r$\n$TargetPath -> $LinkPath"
            ;System::Call "Kernel32::CreateSymbolicLink(t `$TargetPath`, t `$LinkPath`, i 3)i .r0"
            File `/oname=$PLUGINSDIR\CompilerLinker.exe` bin\CompilerLinker.exe
            Push $6
            ${If} $LinkType == "soft"
            ${OrIf} $LinkType == "symbolic"
                ${If} $3 == "directory"
                    nsExec::ExecToStack `"$PLUGINSDIR\CompilerLinker.exe" --soft --link "$TargetPath" --target "$LinkPath"`
                ${Else}
                    nsExec::ExecToStack `"$PLUGINSDIR\CompilerLinker.exe" --symbolic --link "$TargetPath" --target "$LinkPath"`
                ${EndIf}
            ${OrIf} $LinkType == "junction"
                    nsExec::ExecToStack `"$PLUGINSDIR\CompilerLinker.exe" --junction --link "$TargetPath" --target "$LinkPath"`
            ${ElseIf} $LinkType == "hard"
                    nsExec::ExecToStack `"$PLUGINSDIR\CompilerLinker.exe" --hard --link "$TargetPath" --target "$LinkPath"`
            ${EndIf}
            Pop $6 ; result
            ${IfNot} $6 == 2
                MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot create $LinkType link:$\r$\n$TargetPath -> $LinkPath$\r$\n$\r$\n${PORTABLEAPPNAME} may not run correctly!"
            ${EndIf}
            
            IntOp $R0 $R0 + 1
        ${Loop}
        ${DebugMsg} "Links and junctions processing completed."
    ${EndIf}
!macroend
${SegmentPostPrimary}
    ${ReadUserConfigWithDefault} $UserApprovesSymlinks Symlinks true
    ${If} $UserApprovesSymlinks == true
        ${DebugMsg} "Removing created portable links and junctions..."
        StrCpy $R0 1
        ${Do}
            ClearErrors
            ${ReadLauncherConfig} $0 Symlink$R0 Source
            ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
            ${ReadLauncherConfig} $1 Symlink$R0 Target
            ${ReadLauncherConfig} $2 Symlink$R0 Type
            
            ${ParseLocations} $1

            StrCmp $2 "hard" +2 0
            StrCmp $2 "symbolic" +1 +3
            Delete $1
            Goto +4
            StrCmp $2 "junction" +2 0
            StrCmp $2 "symbolic" +1 +2
            RMDir $1
            
            ${If} ${FileExists} "$1.BackupBy${APPNAME}\*.*"
                ${DebugMsg} "Restoring local directory:$\r$\n$1.BackupBy${APPNAME} --> $1"
                ${GetParent} $1 $R1
                ${GetBaseName} $1 $R2
                ${Directory::RestoreLocal} $R1 $R2
            ${Else}
                ${DebugMsg} "Restoring local file:$\r$\n$1.BackupBy${APPNAME} --> $1"
                ${File::RestoreLocal} $1
            ${EndIf}
            IntOp $R0 $R0 + 1
        ${Loop}
        ${DebugMsg} "Portable links and junctions removal completed."
    ${EndIf}
!macroend
!endif
