Function LineWrite
	!macro _LineWrite _FILE _LINE _STRING
		Push ${_STRING}
		Push ${_LINE}
		Push ${_FILE}
		Call LineWrite
	!macroend
	!define LineWrite "!insertmacro _LineWrite"
	Exch $0 ;file
	Exch
	Exch $1 ;line number
	Exch 2
	Exch $2 ;string to write
	Exch 2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	GetTempFileName $7
	FileOpen $4 $0 r
	FileOpen $5 $7 w
	StrCpy $3 0
	ClearErrors
	FileRead $4 $6
	IfErrors +7
	IntOp $3 $3 + 1
	StrCmp $3 $1 0 +3
	;FileWrite $5 "$2$\r$\n$6" ;=== APPEND TEXT
	FileWrite $5 "$2$\r$\n"    ;=== REPLACE TEXT
	Goto -6
	FileWrite $5 $6
	Goto -8
	FileClose $5
	FileClose $4
	Delete $0
	Rename $7 $0
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd