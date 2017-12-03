Function StrTrimNewLines
	!macro StrTrimNewLines ResultVar String
		Push `${String}`
		Call StrTrimNewLines
		Pop `${ResultVar}`
	!macroend
	!define StrTrimNewLines `!insertmacro StrTrimNewLines`
	Exch $R0
	Push $R1
	Push $R2
	StrCpy $R1 0
	loop:
		IntOp $R1 $R1 - 1
		StrCpy $R2 $R0 1 $R1
		${If} $R2 == `$\r`
		${OrIf} $R2 == `$\n`
			Goto loop
		${EndIf}
	IntOp $R1 $R1 + 1
	${If} $R1 < 0
		StrCpy $R0 $R0 $R1
	${EndIf}
	Pop $R2
	Pop $R1
	Exch $R0
FunctionEnd