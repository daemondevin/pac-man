;=#
; 
; CheckLink.nsh v.1.2
; Developed by daemon.devin (daemon.devin@gmail.com)
; 
; Determines if a path is a symbolic link, junction, 
; hard link, or regular file/directory.
;
; LogicLib Macros:
;
; ${IsSymbolicLink} "path"  - True only for symbolic links (not junctions)
; ${IsSymLink} "path"       - True for symbolic links OR junctions
; ${IsJunction} "path"      - True only for junctions
; ${IsHardLink} "path"      - True only for hard links
; ${IsAnyLink} "path"       - True for any type of link
; ${IsRegularFile} "path"   - True for regular files (not links)
; ${IsRegularDir} "path"    - True for regular directories (not links)
;
; Functions: 
;
; CheckLinkType
; IsAnyLink
; IsHardLink
; IsJunction
; IsSymbolicLink
;
; Example Useage:
;
; ${If} ${IsHardLink} "C:\MyFile.txt"
;   MessageBox MB_OK "It's a hard link!"
; ${EndIf}
;
; ${IfNot} ${IsJunction} "C:\MyFolder" 
;   MessageBox MB_OK "This is NOT a junction"
; ${EndIf}
;
; ${If} ${IsJunction} "$INSTDIR\cache"
;   MessageBox MB_OK "Cache is a junction"
; ${ElseIf} ${IsSymbolicLink} "$INSTDIR\cache"
;   MessageBox MB_OK "Cache is a symbolic link"
; ${ElseIf} ${IsRegularDir} "$INSTDIR\cache"
;   MessageBox MB_OK "Cache is a regular directory"
; ${Else}
;   MessageBox MB_OK "Cache doesn't exist or is a file"
; ${EndIf}
;
; ${If} ${IsAnyLink} "$APPDATA\MyApp\config"
;   MessageBox MB_YESNO "Config appears to be a link. Remove it?" IDYES remove_link
; ${EndIf}
;
; ${If} ${FileExists} "$INSTDIR\important.dll"
;   ${If} ${IsHardLink} "$INSTDIR\important.dll"
;       DetailPrint "Found hard-linked DLL"
;   ${Else}
;       DetailPrint "Found regular DLL file"
;   ${EndIf}
; ${EndIf}
;
!ifndef CHECK_LINK_NSH_INCLUDED
!define CHECK_LINK_NSH_INCLUDED

!ifndef LOGICLIB
    !include LogicLib.nsh
!endif

; Constants
!define FILE_ATTRIBUTE_REPARSE_POINT 0x400
!define FILE_ATTRIBUTE_DIRECTORY 0x10
!define IO_REPARSE_TAG_SYMLINK 0xA000000C
!define IO_REPARSE_TAG_MOUNT_POINT 0xA0000003
!define FSCTL_GET_REPARSE_POINT 0x900A8
!define MAX_REPARSE_DATA_BUFFER_SIZE 16384 ; safe max size

Function CheckLinkType
    Exch $R0  ; Path to check 
    ; Preserve registers we will use
    Push $R1
    Push $R2
    Push $R3
    Push $R4
    Push $R5
    Push $R6
    Push $R7

    ; Initialize $R7 (we'll use it to track allocation pointer)
    StrCpy $R7 ""

    ; First check if path exists
    ${If} ${FileExists} "$R0"
        ; Get file attributes to check for reparse point
        System::Call "kernel32::GetFileAttributes(t '$R0') i .R1"
        ${If} $R1 = 0xFFFFFFFF
            ; GetFileAttributes failed
            StrCpy $R0 "notfound"
            Goto _CHECK_DONE
        ${EndIf}

        ; Check if it has FILE_ATTRIBUTE_REPARSE_POINT
        IntOp $R4 $R1 & ${FILE_ATTRIBUTE_REPARSE_POINT}
        ${If} $R4 != 0
            ; It's a reparse point (symlink or junction or other)
            ; Open the file *without* following the reparse point so we can query it
            ; Use GENERIC_READ + open reparse point flags to succeed for files and dirs
            System::Call "kernel32::CreateFile(t '$R0', i 0x80000000, i 7, i 0, i 3, i 0x02200000, i 0) i .R2"
            ${If} $R2 != 0xFFFFFFFF
                ; Allocate buffer for reparse data (use safe large buffer)
                System::Alloc ${MAX_REPARSE_DATA_BUFFER_SIZE}
                Pop $R7
                ${If} $R7 == ""
                    ; Allocation failed
                    StrCpy $R0 "reparse"
                    System::Call "kernel32::CloseHandle(i R2)"
                    Goto _CLEANUP_AFTER_REPARSE_OPEN
                ${EndIf}

                ; Call DeviceIoControl to get reparse data
                System::Call "kernel32::DeviceIoControl(i R2, i ${FSCTL_GET_REPARSE_POINT}, i 0, i 0, i R7, i ${MAX_REPARSE_DATA_BUFFER_SIZE}, *i .R4, i 0) i .R4"
                ${If} $R4 != 0
                    ; Read the reparse tag (first 4 bytes in buffer)
                    System::Call "*$R7(i .R3)"
                    ${If} $R3 = ${IO_REPARSE_TAG_SYMLINK}
                        StrCpy $R0 "symlink"
                    ${ElseIf} $R3 = ${IO_REPARSE_TAG_MOUNT_POINT}
                        StrCpy $R0 "junction"
                    ${Else}
                        ; Unknown/other reparse tag
                        StrCpy $R0 "reparse"
                    ${EndIf}
                ${Else}
                    ; Failed to get reparse data
                    StrCpy $R0 "reparse"
                ${EndIf}

                System::Free $R7
                StrCpy $R7 ""            ; mark freed
                System::Call "kernel32::CloseHandle(i R2)"
            ${Else}
                ; Couldn't open file handle but it's a reparse point.
                ; Fall back to attribute-based guess: directories are often junctions
                IntOp $R4 $R1 & ${FILE_ATTRIBUTE_DIRECTORY}
                ${If} $R4 != 0
                    StrCpy $R0 "junction"
                ${Else}
                    StrCpy $R0 "symlink"
                ${EndIf}
            ${EndIf}
        ${Else}
            ; Not a reparse point. Check for hard link via GetFileInformationByHandle.
            ; Open file for attribute reading (works for files and dirs with BACKUP_SEMANTICS)
            System::Call "kernel32::CreateFile(t '$R0', i 0x80, i 7, i 0, i 3, i 0x02000000, i 0) i .R2"
            ${If} $R2 != 0xFFFFFFFF
                ; Allocate BY_HANDLE_FILE_INFORMATION structure (13 DWORDs = 52 bytes)
                System::Alloc 52
                Pop $R6
                ${If} $R6 == ""
                    ; Allocation failed, fallback to attribute check
                    System::Call "kernel32::CloseHandle(i R2)"
                    IntOp $R4 $R1 & ${FILE_ATTRIBUTE_DIRECTORY}
                    ${If} $R4 != 0
                        StrCpy $R0 "directory"
                    ${Else}
                        StrCpy $R0 "file"
                    ${EndIf}
                    Goto _CLEANUP_AFTER_INFO
                ${EndIf}

                ; Get file information
                System::Call "kernel32::GetFileInformationByHandle(i R2, i R6) i .R4"
                ${If} $R4 != 0
                    ; BY_HANDLE_FILE_INFORMATION layout (13 DWORDs). We only need the 11th DWORD (nNumberOfLinks).
                    ; Read the structure and capture the 11th DWORD into $R5.
                    ; The System::Call format lists 13 'i' then we capture the last one .R5
                    System::Call "*$R6(i,i,i,i,i,i,i,i,i,i,i,i,i .R1 .R2 .R3 .R4 .R6 .R7 .R8 .R9 .R0 .R1 .R5 .R2 .R3)"
                    ; Note: Only $R5 contains the nNumberOfLinks we care about (11th DWORD). Others are temp/clobbered.
                    ${If} $R5 > 1
                        StrCpy $R0 "hardlink"
                    ${Else}
                        IntOp $R4 $R1 & ${FILE_ATTRIBUTE_DIRECTORY}
                        ${If} $R4 != 0
                            StrCpy $R0 "directory"
                        ${Else}
                            StrCpy $R0 "file"
                        ${EndIf}
                    ${EndIf}
                ${Else}
                    ; Failed to get file info, fall back to attribute check
                    IntOp $R4 $R1 & ${FILE_ATTRIBUTE_DIRECTORY}
                    ${If} $R4 != 0
                        StrCpy $R0 "directory"
                    ${Else}
                        StrCpy $R0 "file"
                    ${EndIf}
                ${EndIf}

                System::Free $R6
                System::Call "kernel32::CloseHandle(i R2)"
            ${Else}
                ; Can't open file, fallback to basic check
                IntOp $R4 $R1 & ${FILE_ATTRIBUTE_DIRECTORY}
                ${If} $R4 != 0
                    StrCpy $R0 "directory"
                ${Else}
                    StrCpy $R0 "file"
                ${EndIf}
            ${EndIf}
        ${EndIf}
    ${Else}
        ; Path doesn't exist
        StrCpy $R0 "notfound"
    ${EndIf}

_CLEANUP_AFTER_INFO:
    ; ensure any allocated buffer is freed (if not already)
    ${If} $R6 != ""
        ; If we somehow didn't free R6 above, free it
        System::Free $R6
        StrCpy $R6 ""
    ${EndIf}

_CLEANUP_AFTER_REPARSE_OPEN:
    ${If} $R7 != ""
        System::Free $R7
        StrCpy $R7 ""
    ${EndIf}

_CHECK_DONE:
    ; Restore registers (reverse order of Push)
    Pop $R7
    Pop $R6
    Pop $R5
    Pop $R4
    Pop $R3
    Pop $R2
    Pop $R1
    ; Return result on stack
    Exch $R0
FunctionEnd

; LogicLib macros for link type checking (unchanged semantics)
!macro _IsSymbolicLink _a _b _t _f
    !insertmacro _LOGICLIB_TEMP
    Push `${_b}`
    Call CheckLinkType
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP "symlink" `${_t}` `${_f}`
!macroend
!define IsSymbolicLink `"" IsSymbolicLink`

!macro _IsSymLink _a _b _t _f
    !insertmacro _LOGICLIB_TEMP
    Push `${_b}`
    Call CheckLinkType
    Pop $_LOGICLIB_TEMP
    StrCmp $_LOGICLIB_TEMP "symlink" +2
    StrCmp $_LOGICLIB_TEMP "junction" 0 +3
    Goto `${_t}`
    Goto `${_f}`
!macroend
!define IsSymLink `"" IsSymLink`

!macro _IsJunction _a _b _t _f
    !insertmacro _LOGICLIB_TEMP
    Push `${_b}`
    Call CheckLinkType
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP "junction" `${_t}` `${_f}`
!macroend
!define IsJunction `"" IsJunction`

!macro _IsHardLink _a _b _t _f
    !insertmacro _LOGICLIB_TEMP
    Push `${_b}`
    Call CheckLinkType
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP "hardlink" `${_t}` `${_f}`
!macroend
!define IsHardLink `"" IsHardLink`

!macro _IsAnyLink _a _b _t _f
    !insertmacro _LOGICLIB_TEMP
    Push `${_b}`
    Call CheckLinkType
    Pop $_LOGICLIB_TEMP
    StrCmp $_LOGICLIB_TEMP "symlink" +4
    StrCmp $_LOGICLIB_TEMP "junction" +3
    StrCmp $_LOGICLIB_TEMP "hardlink" +2
    Goto `${_f}`
    Goto `${_t}`
!macroend
!define IsAnyLink `"" IsAnyLink`

!macro _IsRegularFile _a _b _t _f
    !insertmacro _LOGICLIB_TEMP
    Push `${_b}`
    Call CheckLinkType
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP "file" `${_t}` `${_f}`
!macroend
!define IsRegularFile `"" IsRegularFile`

!macro _IsRegularDir _a _b _t _f
    !insertmacro _LOGICLIB_TEMP
    Push `${_b}`
    Call CheckLinkType
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP "directory" `${_t}` `${_f}`
!macroend
!define IsRegularDir `"" IsRegularDir`

; Convenience function to check if a path is any type of link
; Input: Path on stack
; Output: "true" or "false" on stack
Function IsAnyLink   
    Exch $R0  ; Path
    Push $R1  ; Result from CheckLinkType

    Push $R0
    Call CheckLinkType
    Pop $R1

    ${If} $R1 == "symlink"
    ${OrIf} $R1 == "junction"
    ${OrIf} $R1 == "hardlink"
        StrCpy $R0 "true"
    ${Else}
        StrCpy $R0 "false"
    ${EndIf}

    Pop $R1
    Exch $R0
FunctionEnd

; Convenience function to check if a path is a symbolic link (including junctions)
; Input: Path on stack
; Output: "true" or "false" on stack
Function IsSymbolicLink    
    Exch $R0  ; Path
    Push $R1  ; Result from CheckLinkType

    Push $R0
    Call CheckLinkType
    Pop $R1

    ${If} $R1 == "symlink"
    ${OrIf} $R1 == "junction"
        StrCpy $R0 "true"
    ${Else}
        StrCpy $R0 "false"
    ${EndIf}

    Pop $R1
    Exch $R0
FunctionEnd

; Convenience function to check if a path is specifically a junction
; Input: Path on stack
; Output: "true" or "false" on stack
Function IsJunction    
    Exch $R0  ; Path
    Push $R1  ; Result from CheckLinkType

    Push $R0
    Call CheckLinkType
    Pop $R1

    ${If} $R1 == "junction"
        StrCpy $R0 "true"
    ${Else}
        StrCpy $R0 "false"
    ${EndIf}

    Pop $R1
    Exch $R0
FunctionEnd

; Convenience function to check if a path is a hard link
; Input: Path on stack
; Output: "true" or "false" on stack
Function IsHardLink    
    Exch $R0  ; Path
    Push $R1  ; Result from CheckLinkType

    Push $R0
    Call CheckLinkType
    Pop $R1

    ${If} $R1 == "hardlink"
        StrCpy $R0 "true"
    ${Else}
        StrCpy $R0 "false"
    ${EndIf}

    Pop $R1
    Exch $R0
FunctionEnd

!endif ; CHECK_LINK_NSH_INCLUDED
