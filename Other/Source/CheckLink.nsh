;=#
; 
; CheckLink.nsh v.1.0
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

; Check what type of link a path is
; Input: Path on stack
; Output: Link type on stack - "symlink", "junction", "hardlink", "file", "directory", or "notfound"
Function CheckLinkType
    Exch $R0  ; Path to check
    Push $R1  ; File attributes
    Push $R2  ; Handle
    Push $R3  ; Reparse tag
    Push $R4  ; Temp variable
    Push $R5  ; Link count for hardlink detection
    Push $R6  ; File info structure
    Push $R7  ; Result buffer
    
    ; First check if path exists
    ${If} ${FileExists} "$R0"
        ; Get file attributes to check for reparse point
        System::Call "kernel32::GetFileAttributes(t '$R0') i .R1"
        ${If} $R1 = 0xFFFFFFFF
            ; GetFileAttributes failed
            StrCpy $R0 "notfound"
            Goto _CHECK_DONE
        ${EndIf}
        
        ; Check if it has FILE_ATTRIBUTE_REPARSE_POINT (0x400)
        IntOp $R4 $R1 & 0x400
        ${If} $R4 != 0
            ; It's a reparse point (symlink or junction)
            ; Open file to get reparse data
            System::Call "kernel32::CreateFile(t '$R0', i 0, i 7, i 0, i 3, i 0x02200000, i 0) i .R2"
            ${If} $R2 != 0xFFFFFFFF
                ; Allocate buffer for reparse data (8 bytes is enough for the tag)
                System::Alloc 8
                Pop $R7
                
                ; Get reparse point data
                System::Call "kernel32::DeviceIoControl(i R2, i 0x900A8, i 0, i 0, i R7, i 8, *i .R4, i 0) i .R4"
                ${If} $R4 != 0
                    ; Read the reparse tag (first 4 bytes)
                    System::Call "*$R7(i .R3)"
                    
                    ; Check reparse tag values
                    ${If} $R3 = 0xA000000C
                        ; IO_REPARSE_TAG_SYMLINK
                        StrCpy $R0 "symlink"
                    ${ElseIf} $R3 = 0xA0000003
                        ; IO_REPARSE_TAG_MOUNT_POINT (Junction)
                        StrCpy $R0 "junction"
                    ${Else}
                        ; Some other reparse point
                        StrCpy $R0 "symlink"  ; Default to symlink for unknown reparse points
                    ${EndIf}
                ${Else}
                    ; Failed to get reparse data, assume symlink
                    StrCpy $R0 "symlink"
                ${EndIf}
                
                System::Free $R7
                System::Call "kernel32::CloseHandle(i R2)"
            ${Else}
                ; Couldn't open file, but it's a reparse point
                ; Check if it's a directory to guess between symlink and junction
                IntOp $R4 $R1 & 0x10  ; FILE_ATTRIBUTE_DIRECTORY
                ${If} $R4 != 0
                    StrCpy $R0 "junction"  ; Probably a junction
                ${Else}
                    StrCpy $R0 "symlink"  ; Probably a symlink
                ${EndIf}
            ${EndIf}
        ${Else}
            ; Not a reparse point, check if it's a hard link
            ; For hard link detection, we need to check the link count
            System::Call "kernel32::CreateFile(t '$R0', i 0, i 7, i 0, i 3, i 0, i 0) i .R2"
            ${If} $R2 != 0xFFFFFFFF
                ; Allocate structure for BY_HANDLE_FILE_INFORMATION (52 bytes)
                System::Alloc 52
                Pop $R6
                
                ; Get file information
                System::Call "kernel32::GetFileInformationByHandle(i R2, i R6) i .R4"
                ${If} $R4 != 0
                    ; Get link count (at offset 32, 4 bytes)
                    System::Call "*$R6(i, i, i, i, i, i, i, i .R5)"  ; Skip to nNumberOfLinks
                    
                    ${If} $R5 > 1
                        ; Multiple links - it's a hard link
                        StrCpy $R0 "hardlink"
                    ${Else}
                        ; Single link - regular file or directory
                        IntOp $R4 $R1 & 0x10  ; Check FILE_ATTRIBUTE_DIRECTORY
                        ${If} $R4 != 0
                            StrCpy $R0 "directory"
                        ${Else}
                            StrCpy $R0 "file"
                        ${EndIf}
                    ${EndIf}
                ${Else}
                    ; Failed to get file info, fall back to attribute check
                    IntOp $R4 $R1 & 0x10  ; FILE_ATTRIBUTE_DIRECTORY
                    ${If} $R4 != 0
                        StrCpy $R0 "directory"
                    ${Else}
                        StrCpy $R0 "file"
                    ${EndIf}
                ${EndIf}
                
                System::Free $R6
                System::Call "kernel32::CloseHandle(i R2)"
            ${Else}
                ; Can't open file, fall back to basic check
                IntOp $R4 $R1 & 0x10  ; FILE_ATTRIBUTE_DIRECTORY
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
    
    _CHECK_DONE:
    Pop $R7
    Pop $R6
    Pop $R5
    Pop $R4
    Pop $R3
    Pop $R2
    Pop $R1
    Exch $R0
FunctionEnd

; LogicLib macros for link type checking
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
    
    Push "$R0"
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
    
    Push "$R0"
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
    
    Push "$R0"
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
    
    Push "$R0"
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
