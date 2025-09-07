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
!ifndef GetRelativePath
; Get relative path between two absolute paths
!define GetRelativePath `!insertmacro _GetRelativePath`
!macro _GetRelativePath _FROM _TO _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $R8
	Push $R9
	
	; Split paths into components
	${WordReplace} "${_FROM}" "\" "$\n" "+" $0
	${WordReplace} "${_TO}" "\" "$\n" "+" $1
	
	; Find common root
	StrCpy $2 1 ; Component index
	StrCpy $3 "" ; Common components
	${Do}
		${WordFind} "$0" "$\n" "+$2" $4
		${If} ${Errors}
			${ExitDo}
		${EndIf}
		${WordFind} "$1" "$\n" "+$2" $5
		${If} ${Errors}
			${ExitDo}
		${EndIf}
		
		${If} $4 == $5
			${If} $3 == ""
				StrCpy $3 "$4"
			${Else}
				StrCpy $3 "$3\$4"
			${EndIf}
			IntOp $2 $2 + 1
		${Else}
			${ExitDo}
		${EndIf}
	${Loop}
	
	; Calculate relative path
	StrCpy $R8 ""
	StrCpy $R9 $2
	
	; Count remaining components in FROM path (how many .. needed)
	${Do}
		${WordFind} "$0" "$\n" "+$R9" $4
		${If} ${Errors}
			${ExitDo}
		${EndIf}
		${If} $R8 == ""
			StrCpy $R8 ".."
		${Else}
			StrCpy $R8 "$R8\.."
		${EndIf}
		IntOp $R9 $R9 + 1
	${Loop}
	
	; Add remaining components from TO path
	${Do}
		${WordFind} "$1" "$\n" "+$2" $4
		${If} ${Errors}
			${ExitDo}
		${EndIf}
		${If} $R8 == ""
			StrCpy $R8 "$4"
		${Else}
			StrCpy $R8 "$R8\$4"
		${EndIf}
		IntOp $2 $2 + 1
	${Loop}
	
	${If} $R8 == ""
		StrCpy ${_RESULT} "."
	${Else}
		StrCpy ${_RESULT} "$R8"
	${EndIf}
	
	Pop $R9
	Pop $R8
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend
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
