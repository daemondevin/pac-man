/**
 * CreateJunction.nsh v1.0
 *
 * This function creates Windows hard links with proper 
 * validation and error handling.
 * 
 * Macro Usage:
 *   ${CreateJunction} "$Junction" "$Target" $0 $1
 *   $0 holds true/false
 *   $1 holds error message if failed, empty if success
 *
 * Function Usage:
 *   Push $Junction
 *   Push $Target
 *   Call CreateJunction
 *   Pop $R0 ; Result ("true"/"false")
 *   Pop $R1 ; Error message if failed, "" if success
 */
; --- Defines
!ifndef CREATE_JUNCTION_NSH_INCLUDED
!define CREATE_JUNCTION_NSH_INCLUDED
; --- Includes
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
!define CreateJunction "!insertmacro _CreateJunction"
!macro _CreateJunction _JUNCTION _TARGET _RESULT _ERROR
    Push `${_JUNCTION}`
    Push `${_TARGET}`
    Call CreateJunction
    Pop `${_RESULT}`
    Pop `${_ERROR}`
!macroend
Function CreateJunction
    Exch $1 ; Target
    Exch
    Exch $0 ; Junction
    Push $2
    Push $3
    Push $4
    Push $5
    Push $6
    Push $7
    Push $8
    Push $9

    StrCpy $R0 "false"
    StrCpy $R1 ""

    ; Check target exists
    ${IfNot} ${FileExists} "$1\*.*"
        StrCpy $R1 "Target directory does not exist: $1"
        Goto _JUNCTION_DONE
    ${EndIf}

    ; Already exists?
    ${If} ${FileExists} "$0"
        StrCpy $R1 "Junction path already exists: $0"
        Goto _JUNCTION_DONE
    ${EndIf}

    ; Build SubstituteName = \??\Target
    StrCpy $2 "\\??\\$1"
    StrCpy $3 "$1"

    ${StrLen} $4 "$2" ; SubName chars
    ${StrLen} $5 "$3" ; PrintName chars
    IntOp $6 $4 * 2   ; SubName bytes
    IntOp $7 $5 * 2   ; PrintName bytes
    IntOp $8 $6 + 2
    IntOp $8 $8 + $7
    IntOp $8 $8 + 2
    IntOp $8 $8 + 8   ; ReparseDataLength
    IntOp $9 $8 + 8   ; TotalSize

    ; Create empty dir
    System::Call 'kernel32::CreateDirectoryW(w "$0", p 0) i .r2'
    ${If} $2 = 0
        System::Call 'kernel32::GetLastError() i .r3'
        StrCpy $R1 "Failed to create directory (Error $3)"
        Goto _JUNCTION_DONE
    ${EndIf}

    ; Open reparse handle
    System::Call 'kernel32::CreateFileW(w "$0", i 0x40000000, i 0, p 0, i 3, i 0x02200000, p 0) p .r4'
    ${If} $4 = 0
        System::Call 'kernel32::GetLastError() i .r3'
        StrCpy $R1 "Failed to open reparse handle (Error $3)"
        RMDir "$0"
        Goto _JUNCTION_DONE
    ${EndIf}

    ; Allocate buffer
    System::Alloc $9
    Pop $5
    System::Call 'msvcrt::memset(p $5, i 0, i $9)'

    ; Fill fields
    System::Call '*$5(i 0xA0000003, s $8, s 0, s 0, s $6, s $6+2, s $7, &w "$2", &w "$3")'

    ; FSCTL_SET_REPARSE_POINT = 0x000900A4
    System::Call 'kernel32::DeviceIoControl(p $4, i 0x000900A4, p $5, i $9, p 0, i 0, *i .r6, p 0) i .r7'
    ${If} $7 = 0
        System::Call 'kernel32::GetLastError() i .r3'
        StrCpy $R1 "Failed to set reparse point (Error $3)"
        System::Call 'kernel32::CloseHandle(p $4)'
        RMDir "$0"
        Goto _FREE_BUFFER
    ${EndIf}

    StrCpy $R0 "true"
    System::Call 'kernel32::CloseHandle(p $4)'

_FREE_BUFFER:
    System::Free $5

_JUNCTION_DONE:
    Pop $9
    Pop $8
    Pop $7
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Exch $R1
    Exch
    Exch $R0
FunctionEnd
!endif ; CREATE_JUNCTION_NSH_INCLUDED
