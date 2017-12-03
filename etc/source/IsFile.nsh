; Azure Zanculmarktum
;
; IsFile
; ------
; Check whether the given filename is a file
; and not a directory. The default IfFileExists
; will consider the given filename as a file
; even if it was directory.
;
; Used in combination with LogicLib.
;
; Example:
; !include LogicLib.nsh
;
; ${If} ${IsFile} $WINDIR\notepad.exe
;	DetailPrint "notepad is exist and it is not a directory"
; ${EndIf}
;
;
; IsDir
; -----
; Check whether the given filename is a directory.
; The default IfFileExists need "\*.*" to be added
; at the end of the given filename to make it properly
; check if it is a directory.
;
; Used in combination with LogicLib.
;
; Example:
; !include LogicLib.nsh
;
; ${If} ${IsDir} $WINDIR
;	DetailPrint "the directory is exist and it is not a file"
; ${EndIf}
;
;
; IsDirEmpty
; ----------
; Check whether the given directory is completely empty.
;
; Used in combination with LogicLib.
;
; Example:
; !include LogicLib.nsh
;
; ${If} ${IsDirEmpty} "C:\EmptyDir"
;   DetailPrint "the specified directory is empty"
; ${EndIf}

!ifndef ISFILE_NSH_INCLUDED
!define ISFILE_NSH_INCLUDED
!macro _IsFile _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	StrCpy $_LOGICLIB_TEMP -1
	IfFileExists `${_b}` "" +3
	IfFileExists `${_b}\*.*` +2 ; be sure it's not just a directory
	StrCpy $_LOGICLIB_TEMP 0
	!insertmacro _= $_LOGICLIB_TEMP 0 `${_t}` `${_f}`
!macroend
!define IsFile `"" IsFile`

!macro _IsDir _a _b _t _f
	IfFileExists `${_b}\*.*` `${_t}` `${_f}`
!macroend
!define IsDir `"" IsDir`

!macro _IsDirEmpty _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	Push `${_b}`
	${CallArtificialFunction} IsDirEmpty_
	Pop $_LOGICLIB_TEMP
	!insertmacro _== $_LOGICLIB_TEMP 0 `${_t}` `${_f}`
!macroend
!define IsDirEmpty `"" IsDirEmpty`

!macro IsDirEmpty_
	!verbose push 3
		Exch $0
		Push $1
		Push $2
		Push $3

		StrCpy $1 ""
		StrCpy $3 ""

	${__MACRO__}_Loop:
		StrCmp $1 "" "" +3
			FindFirst $1 $2 $0\*.*
		Goto +2
			FindNext $1 $2

		StrCmp $2 "" ${__MACRO__}_Done

		StrCpy $3 $3$2

		Goto ${__MACRO__}_Loop

	${__MACRO__}_Done:
		StrCmp $3 ... ${__MACRO__}_IsEmpty ${__MACRO__}_NotEmpty

	${__MACRO__}_IsEmpty:
		StrCpy $0 0
		Goto ${__MACRO__}_CleanUpStack

	${__MACRO__}_NotEmpty:
		StrCpy $0 -1

	${__MACRO__}_CleanUpStack:
		FindClose $1

		Pop $3
		Pop $2
		Pop $1
		Exch $0
	!verbose pop
!macroend
!endif ; ISFILE_NSH_INCLUDED
