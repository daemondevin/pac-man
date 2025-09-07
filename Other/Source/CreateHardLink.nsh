/**
 * CreateHardLink.nsh v1.0
 *
 * This function creates Windows hard links with proper 
 * validation and error handling.
 * 
 * Macro Usage:
 *   ${CreateHardLink} "$Link" "$Target" $0 $1
 *   $0 holds true/false
 *   $1 holds error message if failed, empty if success
 *
 * Function Usage:
 *   Push $Link
 *   Push $Target
 *   Call CreateHardlink
 *   Pop $R0 ; Result ("true"/"false")
 *   Pop $R1 ; Error message if failed, "" if success
 */
; --- Defines
!ifndef CREATE_HARDLINK_NSH_INCLUDED
!define CREATE_HARDLINK_NSH_INCLUDED
; --- Includes
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
!define CreateHardlink "!insertmacro _CreateHardlink"
!macro _CreateHardlink _LINK _TARGET _RESULT _ERROR
    Push `${_LINK}`
    Push `${_TARGET}`
    Call CreateHardlink
    Pop `${_RESULT}`
    Pop `${_ERROR}`
!macroend
Function CreateHardlink
    Exch $1 ; TargetPath
    Exch
    Exch $0 ; LinkPath
    Push $2
    Push $3

    StrCpy $R0 "false"
    StrCpy $R1 ""

    ; Validate target exists
    ${IfNot} ${FileExists} "$1"
        StrCpy $R1 "Target file does not exist: $1"
        Goto _HARDLINK_DONE
    ${EndIf}

    ; Validate target is not a directory
    ${If} ${FileExists} "$1\*.*"
        StrCpy $R1 "Target is a directory, not a file: $1"
        Goto _HARDLINK_DONE
    ${EndIf}

    ; Validate same volume
    StrCpy $2 $0 3
    StrCpy $3 $1 3
    ${If} $2 != $3
        StrCpy $R1 "Hard links require both paths on the same volume"
        Goto _HARDLINK_DONE
    ${EndIf}

    ; BOOL CreateHardLinkW(
    ;   LPCWSTR lpFileName,
    ;   LPCWSTR lpExistingFileName,
    ;   LPSECURITY_ATTRIBUTES lpSecurityAttributes (NULL)
    ; )
    System::Call 'kernel32::CreateHardLinkW(w "$0", w "$1", p 0) i .r2'
    ${If} $2 = 0
        ; failed
        System::Call 'kernel32::GetLastError() i .r3'
        StrCpy $R1 "Failed to create hard link (Error $3)"
    ${Else}
        StrCpy $R0 "true"
    ${EndIf}

_HARDLINK_DONE:
    Pop $3
    Pop $2
    Pop $1
    Pop $0
    Exch $R1
    Exch
    Exch $R0
FunctionEnd
!endif ; CREATE_HARDLINK_NSH_INCLUDED
