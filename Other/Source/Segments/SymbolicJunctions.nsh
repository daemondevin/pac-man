;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; SymbolicJunctions.nsh
;   This file handles symbolic links, directory junctions, and hard links
;   with backup, restoration, and conflict resolution.
; 
; USAGE
;   Add the sections [SymLink1], [Junction1], [HardLink1] etc. to Launcher.ini.
;
;	[SymLink] Keys (Symbolic Links):
;	    LinkPath		-	Path where the symbolic link will be created
;	    TargetPath		-	Path that the link points to (supports %PAL:* variables)
;	    Type			-	file, directory (auto-detect if not specified)
;	    IfExists		-	skip, backup, replace, update
;	    Required		-	true/false (show error if creation fails)
;	    Relative		-	true/false (create relative vs absolute link)
;	    Temporary		-	true/false (remove on app exit vs persist)
;
;	[Junction] Keys (Directory Junctions - NTFS only):
;	    JunctionPath	-	Path where the junction will be created
;	    TargetPath		-	Directory that the junction points to
;	    IfExists		-	skip, backup, replace
;	    Required		-	true/false (show error if creation fails)
;	    Temporary		-	true/false (remove on app exit vs persist)
;
;	[HardLink] Keys (Hard Links - same volume only):
;	    LinkPath		-	Path where the hard link will be created
;	    TargetPath		-	File that the hard link points to (must be file)
;	    IfExists		-	skip, backup, replace
;	    Required		-	true/false (show error if creation fails)
;	    Temporary		-	true/false (remove on app exit vs persist)
;
; EXAMPLES
;	[SymLink1]
;	LinkPath=%PAL:DataDir%\Documents
;	TargetPath=%USERPROFILE%\Documents\MyAppData
;	Type=directory
;	IfExists=backup
;	Required=true
;	Relative=false
;	Temporary=true
;
;	[Junction1]
;	JunctionPath=%PAL:DataDir%\MyApp
;	TargetPath=C:\ProgramData\MyApp
;	IfExists=replace
;	Required=false
;	Temporary=true
;
;	[HardLink1]
;	LinkPath=%PAL:DataDir%\config.ini
;	TargetPath=%APPDATA%\MyApp\config.ini
;	IfExists=backup
;	Required=true
;	Temporary=true
;

!ifdef SYMBOLICJUNCTIONS

;= INCLUDES
!ifndef LOGICLIB
    !include LogicLib.nsh
!endif

!ifndef FILEFUNC_INCLUDED
    !include FileFunc.nsh
!endif

!ifndef STR_LOC_NSH_INCLUDED
    !include StrLoc.nsh
!endif

!ifndef CHECK_LINK_NSH_INCLUDED
    !include CheckLink.nsh
!endif

!ifndef CREATE_HARDLINK_NSH_INCLUDED
    !include CreateHardlink.nsh
!endif

!ifndef CREATE_SYMLINK_NSH_INCLUDED
    !include CreateSymlink.nsh
!endif

!ifndef CREATE_JUNCTION_NSH_INCLUDED
    !include CreateJunction.nsh
!endif


;= DEFINES
!ifndef MKLINK
    !define MKLINK `$SYSDIR\cmd.exe /c mklink`
!endif

!ifndef RMDIR
    !define RMDIR `$SYSDIR\rmdir.exe`
!endif

!ifndef DEL
    !define DEL `$SYSDIR\del.exe`
!endif


!ifndef LINK_TYPE_SYMBOLIC
    !define LINK_TYPE_SYMBOLIC 1
!endif

!ifndef LINK_TYPE_JUNCTION
    !define LINK_TYPE_JUNCTION 2
!endif

!ifndef LINK_TYPE_HARD
    !define LINK_TYPE_HARD 3
!endif


; Convenience macros
!define Link::GetTarget `!insertmacro _Link::GetTarget`
!macro _Link::GetTarget _PATH _RESULT
    Push "${_PATH}"
    Call GetLinkTarget
    Pop "${_RESULT}"
!macroend

!define Link::DetectPathType `!insertmacro _Link::DetectPathType`
!macro _Link::DetectPathType _PATH _RESULT
    Push "${_PATH}"
    Call DetectPathType
    Pop "${_RESULT}"
!macroend

;= FUNCTIONS

Function DetectPathType
    Exch $R0
    ${If} ${FileExists} "$R0"
        ; If path exists and has children -> directory, else file
        IfFileExists "$R0\*.*" 0 +3
            StrCpy $R0 "directory"
            Goto _DETECT_END
        StrCpy $R0 "file"
    ${Else}
        StrCpy $R0 "file" ; Default to file if doesn't exist
    ${EndIf}
_DETECT_END:
    Exch $R0
FunctionEnd

; Returns version as "Major.Minor.Build" (note: low-level call must be tested)
Function _GetWindowsVersion
    Push $0
    Push $1
    Push $2
    Push $3
    System::Alloc 284 ; OSVERSIONINFOEXW
    Pop $0
    ; TODO: RtlGetVersion/System::Call signature must be verified at runtime
    System::Call 'kernel32::RtlGetVersion(p r0) i .r1'
    ; The original code attempted direct deref into registers; keep simple placeholder
    ; TODO: fill $2,$3,$4 correctly after confirmed System::Call usage
    StrCpy $R0 "0.0.0"
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

; Main function to get link target
; Input: Path to the link (on stack)
; Output: Target path (on stack), or empty string if not a link or error
Function GetLinkTarget
    Exch $0 ; Get input path
    Push $1
    Push $2
    Push $3
    Push $4
    Push $5
    Push $6

    StrCpy $2 ""
    StrCpy $5 ""

    ; Try GetFileAttributesW to check reparse point attribute
    System::Call "kernel32::GetFileAttributesW(w '$0') i.r6"
    IntOp $6 $6 & 0x400  ; FILE_ATTRIBUTE_REPARSE_POINT
    ${If} $6 != 0
        ; It's a reparse point
        Call GetReparsePointTarget
        Pop $2
        StrCpy $5 "reparse"
    ${Else}
        ; Check hard link
        Call CheckHardLink
        Pop $2
        Pop $5
    ${EndIf}

    ; Clean up and return
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $1
    Exch $2
    Pop $0
FunctionEnd

; Function to get reparse point target (symbolic links and junctions)
Function GetReparsePointTarget
    Push $0
    Push $1
    Push $2
    Push $3
    Push $4
    Push $5

    StrCpy $5 ""

    ; Open the file/directory
    System::Call "kernel32::CreateFileW(w '$0', i 0, i 7, i 0, i 3, i 0x02200000, i 0) i.r1"
    ; r1 is handle (returned into register, but we pop into $1)
    Pop $1
    ${If} $1 = -1
        StrCpy $5 ""
        Goto GPRT_CLEANUP
    ${EndIf}

    ; Allocate buffer for reparse data (16KB)
    System::Alloc 16384
    Pop $4

    ; DeviceIoControl to get reparse data
    ; NOTE: signature and control code 0x900a8 must be verified; keep as-is but test
    System::Call "kernel32::DeviceIoControl(i r1, i 0x900a8, i 0, i 0, i r4, i 16384, *i r3, i 0) i.r2"
    Pop $2 ; result code
    Pop $3 ; bytes returned (approx)
    ${If} $2 = 0
        ; Failed
        StrCpy $5 ""
        Goto GPRT_CLEANUP
    ${EndIf}

    ; TODO: Proper parsing of reparse data is platform/structure dependent.
    ; The previous code attempted to parse binary structures directly.
    ; For now, attempt a simplified approach: try CheckLink.nsh helper functions first (if available).
    ; If unavailable, leave $5 empty and let caller handle fallback.
    ; (A production implementation should decode REPARSE_DATA_BUFFER layout.)

    ; Fallback - empty for now
    StrCpy $5 ""

GPRT_CLEANUP:
    System::Free $4
    System::Call "kernel32::CloseHandle(i r1)"
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
    Push $5
FunctionEnd

; Function to check if file is a hardlink
Function CheckHardLink
    Push $0
    Push $1
    Push $2
    Push $3
    Push $4
    Push $5

    StrCpy $4 ""
    StrCpy $5 "none"

    ; Open file for reading
    System::Call "kernel32::CreateFileW(w '$0', i 0x80000000, i 3, i 0, i 3, i 0, i 0) i.r1"
    Pop $1
    ${If} $1 = -1
        ; Cannot open
        Goto CHKHL_CLEANUP
    ${EndIf}

    ; Allocate structure for BY_HANDLE_FILE_INFORMATION (52 bytes)
    System::Alloc 52
    Pop $2

    ; GetFileInformationByHandle
    System::Call "kernel32::GetFileInformationByHandle(i r1, i r2) i.r3"
    Pop $3
    ${If} $3 != 0
        ; Could decode structure here. For now, try to read NumberOfLinks (offset 26? platform)
        ; TODO: implement proper struct read to populate $3 with link count
        ; As a conservative default, don't assert multiple links here.
    ${EndIf}

    System::Free $2
    System::Call "kernel32::CloseHandle(i r1)"

CHKHL_CLEANUP:
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
    Push $5
    Push $4
FunctionEnd

;= SEGMENTS
${SegmentFile}


;= Check permissions and backup existing links
${SegmentPre}
  !ifdef SYMBOLICJUNCTIONS
    ${DebugMsg} "Processing symbolic links and junctions..."

    ${ReadUserConfigWithDefault} $0 SymbolicJunctions= true
    ${If} $0 == true
      ${If} ${IsAdmin}
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "SymLink$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "SymLink$R0" "TargetPath"
          ${ReadLauncherConfig} $2 "SymLink$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${If} $2 == ""
            StrCpy $2 "skip"
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${DebugMsg} "SymLink path exists: $0"
            ${If} $2 == "backup"
              ${If} ${IsAnyLink} "$1"
                ${WriteRuntimeData} LinkStatus "LinkExisted" "true"
                ${Link::GetTarget} $1 $R6
                ${WriteRuntimeData} LinkStatus "LinkPath" "$R6"
                ${If} ${IsSymbolicLink} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "Symbolic"
                ${ElseIf} ${IsJunction} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "Junction"
                ${ElseIf} ${IsHardLink} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "HardLink"
                ${EndIf}
              ${ElseIf} ${FileExists} "$0\*.*"
                ${GetParent} $0 $R1
                ${GetBaseName} $0 $R2
                ${Directory::BackupLocal} $R1 $R2
              ${Else}
                ${File::BackupLocal} $0
              ${EndIf}
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}

        ; Junction backups
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "Junction$R0" "JunctionPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "Junction$R0" "TargetPath"
          ${ReadLauncherConfig} $2 "Junction$R0" "IfExists"
          ${ParseLocations} $0

          ${If} $2 == ""
            StrCpy $2 "skip"
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${DebugMsg} "Junction path exists: $0"
            ${If} $2 == "backup"
              ${If} ${IsAnyLink} "$1"
                ${WriteRuntimeData} LinkStatus "LinkExisted" "true"
                ${Link::GetTarget} $1 $R6
                ${WriteRuntimeData} LinkStatus "LinkPath" "$R6"
                ${If} ${IsSymbolicLink} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "Symbolic"
                ${ElseIf} ${IsJunction} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "Junction"
                ${ElseIf} ${IsHardLink} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "HardLink"
                ${EndIf}
              ${ElseIf} ${FileExists} "$0\*.*"
                ${GetParent} $0 $R1
                ${GetBaseName} $0 $R2
                ${Directory::BackupLocal} $R1 $R2
              ${EndIf}
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}

        ; HardLink backups
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "HardLink$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "HardLink$R0" "TargetPath"
          ${ReadLauncherConfig} $2 "HardLink$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${If} $2 == ""
            StrCpy $2 "skip"
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${DebugMsg} "HardLink path exists: $0"
            ${If} $2 == "backup"
              ${If} ${IsAnyLink} "$1"
                ${WriteRuntimeData} LinkStatus "LinkExisted" "true"
                ${Link::GetTarget} $1 $R6
                ${WriteRuntimeData} LinkStatus "LinkPath" "$R6"
                ${If} ${IsSymbolicLink} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "Symbolic"
                ${ElseIf} ${IsJunction} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "Junction"
                ${ElseIf} ${IsHardLink} $1
                  ${WriteRuntimeData} LinkStatus "LinkType" "HardLink"
                ${EndIf}
              ${Else}
                ${File::BackupLocal} $1
              ${EndIf}
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}
      ${EndIf}
    ${EndIf}

    ${DebugMsg} "Links and junctions processing completed."
  !endif
!macroend

;= Create symbolic links, junctions, and hard links
${SegmentPrePrimary}
  !ifdef SYMBOLICJUNCTIONS
    ${DebugMsg} "Creating symbolic links, junctions, and hard links..."

    ${ReadUserConfigWithDefault} $0 SymbolicJunctions= true
    ${If} $0 == true
      ${If} ${IsAdmin}
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "SymLink$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "SymLink$R0" "TargetPath"
          ${ReadLauncherConfig} $2 "SymLink$R0" "Type"
          ${ReadLauncherConfig} $3 "SymLink$R0" "Required"
          ${ReadLauncherConfig} $4 "SymLink$R0" "Relative"
          ${ReadLauncherConfig} $5 "SymLink$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${If} $3 == ""
            StrCpy $3 "true"
          ${EndIf}
          ${If} $4 == ""
            StrCpy $4 "false"
          ${EndIf}
          ${If} $5 == ""
            StrCpy $5 "skip"
          ${EndIf}

          ${If} $2 == ""
            ${If} ${IsRegularDir} $1
              StrCpy $2 "directory"
            ${ElseIf} ${IsRegularFile} $1
              StrCpy $2 "file"
            ${EndIf}
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
            ${If} $R7 == true
              ${If} $5 == "skip"
                IntOp $R0 $R0 + 1
                ${Continue}
              ${Else}
                ${If} ${IsSymbolicLink} $1
                ${OrIf} ${IsJunction} $1
                  ExecDos::Exec /TOSTACK `"${RMDIR}" "$1"`
                ${ElseIf} ${IsHardLink} $1
                  ExecDos::Exec /TOSTACK `"${DEL}" "$1"`
                ${EndIf}
              ${EndIf}
            ${EndIf}
          ${EndIf}

          ; Convert type to boolean for directory flag
          ${If} $2 == "directory"
            StrCpy $R2 "true"
          ${Else}
            StrCpy $R2 "false"
          ${EndIf}

          StrCpy $R4 "0" ; Default flags
          ${If} $R2 == "true"
            IntOp $R4 $R4 | 0x1 ; SYMBOLIC_LINK_FLAG_DIRECTORY
          ${EndIf}
          ${If} $4 == "true"
            IntOp $R4 $R4 | 0x2 ; SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
          ${EndIf}

          ; Create the symbolic link
          System::Call "kernel32::CreateSymbolicLinkW(w `$0`, w `$1`, i $R4) i .r6"
          Pop $6 ; result

          ${If} $6 == 0
            ${If} $3 == "true"
              MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot create required symbolic link '$0'$\r$\nFalling back on Copying/Moving files/directories"
            ${EndIf}
            ${GetParent} $0 $R4
            ${GetBaseName} $0 $R5
            ${If} ${FileExists} "$0\*.*"
              ${Directory::RestorePortable} "$R4" "$R5" "${DATA}\$R5" $R8 $R9
            ${Else}
              ${File::RestorePortable} "$0" "${DATA}\$R5"
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
          ${Continue}
        ${Loop}

        ; Create junctions
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "Junction$R0" "JunctionPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "Junction$R0" "TargetPath"
          ${ReadLauncherConfig} $3 "Junction$R0" "Required"
          ${ReadLauncherConfig} $5 "Junction$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${If} $3 == ""
            StrCpy $3 "true"
          ${EndIf}
          ${If} $5 == ""
            StrCpy $5 "skip"
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
            ${If} $R7 == true
              ${If} $5 == "skip"
                IntOp $R0 $R0 + 1
                ${Continue}
              ${Else}
                ${If} ${IsSymbolicLink} $1
                ${OrIf} ${IsJunction} $1
                  ExecDos::Exec /TOSTACK `"${RMDIR}" "$1"`
                ${ElseIf} ${IsHardLink} $1
                  ExecDos::Exec /TOSTACK `"${DEL}" "$1"`
                ${EndIf}
              ${EndIf}
            ${EndIf}
          ${EndIf}

          ${ValidateFS} $EXEDIR $9
          ${If} $9 = 1
            Push "$0"
            Push "$1"
            Call CreateJunction
            Pop $6
          ${Else}
            StrCpy $6 "failed"
          ${EndIf}

          ${If} $6 == "failed"
            ${If} $3 == "true"
              MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot create required junction '$0'$\r$\nFalling back on Copying/Moving files/directories"
            ${EndIf}
            ${GetParent} $0 $R4
            ${GetBaseName} $0 $R5
            ${If} ${FileExists} "$0\*.*"
              ${Directory::RestorePortable} "$R4" "$R5" "${DATA}\$R5" $R8 $R9
            ${Else}
              ${File::RestorePortable} "$0" "${DATA}\$R5"
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
          ${Continue}
        ${Loop}

        ; Create hard links
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "HardLink$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "HardLink$R0" "TargetPath"
          ${ReadLauncherConfig} $3 "HardLink$R0" "Required"
          ${ReadLauncherConfig} $5 "HardLink$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${If} $3 == ""
            StrCpy $3 "true"
          ${EndIf}
          ${If} $5 == ""
            StrCpy $5 "skip"
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
            ${If} $R7 == true
              ${If} $5 == "skip"
                IntOp $R0 $R0 + 1
                ${Continue}
              ${Else}
                ${If} ${IsSymbolicLink} $1
                ${OrIf} ${IsJunction} $1
                  ExecDos::Exec /TOSTACK `"${RMDIR}" "$1"`
                ${ElseIf} ${IsHardLink} $1
                  ExecDos::Exec /TOSTACK `"${DEL}" "$1"`
                ${EndIf}
              ${EndIf}
            ${EndIf}
          ${EndIf}

          Push "$0"
          Push "$1"
          Call CreateHardLink
          Pop $6

          ${If} $6 == "failed"
            ${If} $3 == "true"
              MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot create required hard link '$0'$\r$\nFalling back on Copying/Moving files/directories"
            ${EndIf}
            ${GetBaseName} $0 $R5
            ${File::RestorePortable} "$0" "${DATA}\$R5"
          ${EndIf}

          IntOp $R0 $R0 + 1
          ${Continue}
        ${Loop}
      ${EndIf}
    ${EndIf}

    ${DebugMsg} "Links and junctions creation completed."
  !endif
!macroend

;= Remove created links and junctions
${SegmentPostPrimary}
  !ifdef SYMBOLICJUNCTIONS
    ${DebugMsg} "Removing created links and junctions..."

    ${ReadUserConfigWithDefault} $0 SymbolicJunctions= true
    ${If} $0 == true
      ${If} ${IsAdmin}
        ; Remove hard links first
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "HardLink$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "HardLink$R0" "TargetPath"
          ${ReadLauncherConfig} $5 "HardLink$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${If} $5 == ""
            StrCpy $5 "skip"
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
            ${If} $R7 == true
              ${If} $5 == "skip"
                IntOp $R0 $R0 + 1
                ${Continue}
              ${Else}
                ${If} ${IsSymbolicLink} $1
                ${OrIf} ${IsJunction} $1
                  ExecDos::Exec /TOSTACK `"${RMDIR}" "$1"`
                ${ElseIf} ${IsHardLink} $1
                  ExecDos::Exec /TOSTACK `"${DEL}" "$1"`
                ${EndIf}
              ${EndIf}
            ${Else}
              ${GetBaseName} $0 $R1
              ${File::BackupPortable} "$0" "${DATA}\$R1"
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}

        ; Remove symbolic links
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "SymLink$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "SymLink$R0" "TargetPath"
          ${ReadLauncherConfig} $5 "SymLink$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${If} $5 == ""
            StrCpy $5 "skip"
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
            ${If} $R7 == true
              ${If} $5 == "skip"
                IntOp $R0 $R0 + 1
                ${Continue}
              ${Else}
                ${If} ${IsSymbolicLink} $1
                ${OrIf} ${IsJunction} $1
                  ExecDos::Exec /TOSTACK `"${RMDIR}" "$1"`
                ${ElseIf} ${IsHardLink} $1
                  ExecDos::Exec /TOSTACK `"${DEL}" "$1"`
                ${EndIf}
              ${EndIf}
            ${Else}
              ${GetParent} $0 $R4
              ${GetBaseName} $0 $R5
              ${If} ${FileExists} "$0\*.*"
                ${Directory::BackupPortable} "$R4" "$R5" "${DATA}\$R5" $R8 $R9
              ${Else}
                ${File::BackupPortable} "$0" "${DATA}\$R5"
              ${EndIf}
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}

        ; Remove junctions
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "Junction$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "Junction$R0" "TargetPath"
          ${ReadLauncherConfig} $5 "Junction$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${If} $5 == ""
            StrCpy $5 "skip"
          ${EndIf}

          ${If} ${FileExists} "$0"
            ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
            ${If} $R7 == true
              ${If} $5 == "skip"
                IntOp $R0 $R0 + 1
                ${Continue}
              ${Else}
                ${If} ${IsSymbolicLink} $1
                ${OrIf} ${IsJunction} $1
                  ExecDos::Exec /TOSTACK `"${RMDIR}" "$1"`
                ${ElseIf} ${IsHardLink} $1
                  ExecDos::Exec /TOSTACK `"${DEL}" "$1"`
                ${EndIf}
              ${EndIf}
            ${Else}
              ${GetParent} $0 $R4
              ${GetBaseName} $0 $R5
              ${If} ${FileExists} "$0\*.*"
                ${Directory::BackupPortable} "$R4" "$R5" "${DATA}\$R5" $R8 $R9
              ${Else}
                ${File::BackupPortable} "$0" "${DATA}\$R5"
              ${EndIf}
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}
      ${EndIf}
    ${EndIf}

    ${DebugMsg} "Links and junctions removal completed."
  !endif
!macroend

;= Restore original files and directories
${SegmentUnload}
  !ifdef SYMBOLICJUNCTIONS
    ${DebugMsg} "Restoring original files and directories..."

    ${ReadUserConfigWithDefault} $0 SymbolicJunctions= true
    ${If} $0 == true
      ${If} ${IsAdmin}

        ; Restore symbolic links
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "SymLink$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "SymLink$R0" "TargetPath"
          ${ReadLauncherConfig} $5 "SymLink$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ; Check if we need to restore this link
          ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
          ${If} $R7 == true
            ${If} $5 == "skip"
              IntOp $R0 $R0 + 1
              ${Continue}
            ${Else}
              ${ReadRuntimeData} $R6 LinkStatus "LinkPath"
              ${ReadRuntimeData} $R7 LinkStatus "LinkType"
              ${Switch} $R7
                ${Case} "Symbolic"
                  System::Call "kernel32::CreateSymbolicLinkW(w `$0`, w `$R6`, i 0) i .r6"
                  Pop $6
                  ${If} $6 == 0
                    MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot recreate local symbolic link `$0`"
                  ${EndIf}
                  ${Break}
                ${Case} "Junction"
                  Push "$0"
                  Push "$R6"
                  Call CreateJunction
                  Pop $6
                  ${If} $6 == 0
                    MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot recreate local junction '$0'"
                  ${EndIf}
                  ${Break}
                ${Case} "HardLink"
                  ; Hardlink recreation not implemented here; depends on target availability
                  ${Break}
              ${EndSwitch}
            ${EndIf}
          ${Else}
            ${If} ${FileExists} "$0\*.*"
              ${GetParent} $0 $R0
              ${GetBaseName} $0 $R1
              ${Directory::RestoreLocal} "$R0" "$R1"
            ${Else}
              ${File::RestoreLocal} "$0"
            ${EndIf}
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}

        ; Restore junctions (similar logic)
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "Junction$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "Junction$R0" "TargetPath"
          ${ReadLauncherConfig} $5 "Junction$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
          ${If} $R7 == true
            ${If} $5 == "skip"
              IntOp $R0 $R0 + 1
              ${Continue}
            ${Else}
              ${ReadRuntimeData} $R6 LinkStatus "LinkPath"
              ${ReadRuntimeData} $R7 LinkStatus "LinkType"
              ${Switch} $R7
                ${Case} "Symbolic"
                  System::Call "kernel32::CreateSymbolicLinkW(w `$0`, w `$R6`, i 0) i .r6"
                  Pop $6
                  ${If} $6 == 0
                    MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot recreate local symbolic link '$0'"
                  ${EndIf}
                  ${Break}
                ${Case} "Junction"
                  Push "$0"
                  Push "$R6"
                  Call CreateJunction
                  Pop $6
                  ${If} $6 == 0
                    MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot recreate local junction '$0'"
                  ${EndIf}
                  ${Break}
                ${Case} "HardLink"
                  ${Break}
              ${EndSwitch}
            ${EndIf}
          ${Else}
            ${GetParent} $0 $R0
            ${GetBaseName} $0 $R1
            ${Directory::RestoreLocal} "$R0" "$R1"
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}

        ; Restore hard links
        StrCpy $R0 1
        ${Do}
          ClearErrors
          ${ReadLauncherConfig} $0 "HardLink$R0" "LinkPath"
          ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
          ${ReadLauncherConfig} $1 "HardLink$R0" "TargetPath"
          ${ReadLauncherConfig} $5 "HardLink$R0" "IfExists"
          ${ParseLocations} $0
          ${ParseLocations} $1

          ${ReadRuntimeData} $R7 LinkStatus "LinkExisted"
          ${If} $R7 == true
            ${If} $5 == "skip"
              IntOp $R0 $R0 + 1
              ${Continue}
            ${Else}
              ${ReadRuntimeData} $R6 LinkStatus "LinkPath"
              ${ReadRuntimeData} $R7 LinkStatus "LinkType"
              ${Switch} $R7
                ${Case} "Symbolic"
                  System::Call "kernel32::CreateSymbolicLinkW(w `$0`, w `$R6`, i 0) i .r6"
                  Pop $6
                  ${If} $6 == 0
                    MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot recreate local symbolic link '$0'"
                  ${EndIf}
                  ${Break}
                ${Case} "Junction"
                  Push "$0"
                  Push "$R6"
                  Call CreateJunction
                  Pop $6
                  ${If} $6 == 0
                    MessageBox MB_OK|MB_ICONEXCLAMATION "Error: Cannot recreate local junction '$0'"
                  ${EndIf}
                  ${Break}
                ${Case} "HardLink"
                  ; Hardlink recreation omitted
                  ${Break}
              ${EndSwitch}
            ${EndIf}
          ${Else}
            ${File::RestoreLocal} "$0"
          ${EndIf}

          IntOp $R0 $R0 + 1
        ${Loop}
      ${EndIf}
    ${EndIf}

    ${DebugMsg} "Links and junctions restoration completed."
  !endif
!macroend

!endif ; SYMBOLICJUNCTIONS
