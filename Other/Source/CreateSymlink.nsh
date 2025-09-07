/**
 * CreateSymlink.nsh v1.0
 *
 * This function creates Windows symbolic links with flexible 
 * options for different link types and path configurations.
 *
 * Parameters:
 *   Link         - Specifies the new symbolic link name.
 *   Target       - Specifies the path that the new link points to.
 *   Type         - Specifies if this symlink is a file or directory. 
 *                  Set to auto to let the function decide.
 *   Relative     - Specifies if using a relative or absolute path
 * 
 * Macro Usage:
 *   ${CreateSymlink} "$Link" "$Target" "$Type" "$Relative" $0 $1
 *   $0 holds true/false
 *   $1 holds error message if failed, empty if success
 *
 * Function Usage:
 *   Push $Link
 *   Push $Target
 *   Push $Type             ; "file"|"directory"|"auto"
 *   Push $Relative         ; "true"|"false"
 *   Call CreateSymlink
 *   Pop $R0                ; Result ("true"/"false")
 *   Pop $R1                ; Error message if failed, "" if success
 */
; --- Defines
!ifndef CREATE_SYMLINK_NSH_INCLUDED
!define CREATE_SYMLINK_NSH_INCLUDED
; --- Includes
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
!define CreateSymlink "!insertmacro _CreateSymlink"
!macro _CreateSymlink _LINK _TARGET _TYPE _RELATIVE _RESULT _ERROR
    Push `${_LINK}`
    Push `${_TARGET}`
    Push `${_TYPE}`
    Push `${_RELATIVE}`
    Call CreateJunction
    Pop `${_RESULT}`
    Pop `${_ERROR}`
!macroend
Function CreateSymlink
    Exch $3 ; Relative flag
    Exch
    Exch $2 ; Type
    Exch
    Exch 2
    Exch $1 ; Target
    Exch
    Exch 3
    Exch $0 ; Link
    Push $4
    Push $5
    Push $6
    Push $7

    StrCpy $R0 "false"
    StrCpy $R1 ""

    ${IfNot} ${FileExists} "$1"
        StrCpy $R1 "Target path does not exist: $1"
        Goto _SYMLINK_DONE
    ${EndIf}

    ; Decide flags: 0=file, 1=dir
    StrCpy $4 0
    ${If} "$2" == "directory"
        StrCpy $4 1
    ${ElseIf} "$2" == "auto"
        ${If} ${FileExists} "$1\*.*"
            StrCpy $4 1
        ${EndIf}
    ${EndIf}

    ; Relative path (optional)
    ${If} "$3" == "true"
        ${GetRelativePath} "$0" "$1" $5
        StrCpy $1 "$5"
    ${EndIf}

    ; Call CreateSymbolicLinkW
    System::Call 'kernel32::CreateSymbolicLinkW(w "$0", w "$1", i $4) i .r6'
    ${If} $6 <> 0
        StrCpy $R0 "true"
    ${Else}
        System::Call 'kernel32::GetLastError() i .r7'
        ${If} $7 = 183
            StrCpy $R1 "Link path already exists"
        ${ElseIf} $7 = 1314
            StrCpy $R1 "Insufficient privileges to create symbolic link"
        ${Else}
            StrCpy $R1 "Failed to create symbolic link (Error $7)"
        ${EndIf}
    ${EndIf}

_SYMLINK_DONE:
    Pop $7
    Pop $6
    Pop $5
    Pop $4
    Exch $R1
    Exch
    Exch $R0
FunctionEnd
!endif ; CREATE_SYMLINK_NSH_INCLUDED
