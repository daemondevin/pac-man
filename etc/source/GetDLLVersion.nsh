/*
 * GetDLLVersion.nsh v1.0
 *
 * Author: LegendaryHawk
 *
 * Retrieve the version number of a DLL/EXE file and store it in a variable.
 * The version number will look like 1.2.3.4
 *
 * Example:
 * ${GetDLLVersion} $0 file.ext
 */

; --- Defines
!ifndef GETDLLVERSION_NSH_INCLUDED
!define GETDLLVERSION_NSH_INCLUDED

; --- Includes
!include Util.nsh

!macro GetDLLVersionCall _RESULT _FILE
    !verbose push 3
    Push `${_FILE}`
    ${CallArtificialFunction} GetDLLVersion_
    Pop `${_RESULT}`
    !verbose pop
!macroend
!define GetDLLVersion "!insertmacro GetDLLVersionCall"

!macro GetDLLVersion_
    !verbose push 3

    ; Prepare stack and preserve variable(s)
    Exch $0
    Push $1
    Push $2
    Push $3
    Push $4

    ; Calculate version number
    GetDllVersion $0 $1 $2
    IntOp $3 $1 / 0x00010000
    IntOp $1 $1 & 0x0000FFFF
    IntOp $4 $2 / 0x00010000
    IntOp $2 $2 & 0x0000FFFF
    StrCpy $0 "$3.$1.$4.$2"

    ; Clean-up stack and restore variable(s)
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Exch $0

    !verbose pop
!macroend
!endif ; GETDLLVERSION_NSH_INCLUDED