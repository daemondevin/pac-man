/*______________________________________________________________________________
 
                            GetLocale
________________________________________________________________________________
Get text between two markers in a file. 

Returns text from between first occurrences of markers and then stops searching.
It works even if the markers are or are not on the same line. 

Usage 
${GetLocale} "This" "And This" "$INSTDIR\In_This.txt" "$R0"
; $R0 = output (text between "This", "And This").                             */
 
Function GetLocale
	!macro _GetLocale _FIRSTDELIMITER _SECONDDELIMITER _FILE _RETURN
		Push `${_FIRSTDELIMITER}`
		Push `${_SECONDDELIMITER}`
		Push `${_FILE}`
		Call GetLocale
		Pop `${_RETURN}`
	!macroend
	!define GetLocale `!insertmacro _GetLocale`
	Exch $R0
	Exch
	Exch $R1
	Exch 2
	Exch $R2
	Exch 2
	Exch
	Exch 2
	Push $R3
	Push $R4
	Push $R5
	Push $R6
	Push $R7
	Push $R8
	FileOpen $R6 $R0 r
	StrLen $R4 $R2
	StrLen $R3 $R1
	StrCpy $R0 ""
	ClearErrors
	FileRead $R6 $R7
	IfErrors +22
	StrCpy $R5 0
	IntOp $R5 $R5 - 1
	StrCpy $R8 $R7 $R4 $R5
	StrCmp $R8 "" -6
	StrCmp $R8 $R2 0 -3
	IntOp $R5 $R5 + $R4
	StrCpy $R7 $R7 "" $R5
	StrCpy $R5 -1
	Goto +5
	ClearErrors
	FileRead $R6 $R7
	IfErrors +10
	StrCpy $R5 -1
	IntOp $R5 $R5 + 1
	StrCpy $R8 $R7 $R3 $R5
	StrCmp $R8 "" 0 +3
	StrCpy $R0 $R0$R7
	Goto -8
	StrCmp $R8 $R1 0 -5
	StrCpy $R7 $R7 $R5
	StrCpy $R0 $R0$R7
	FileClose $R6
	Pop $R8
	Pop $R7
	Pop $R6
	Pop $R5
	Pop $R4
	Pop $R3
	Pop $R2
	Pop $R1
	Exch $R0
FunctionEnd