/*
Allows you to validate a string with a custom criteria. This means you can validate a string to only contain numbers, or just letters, or a combination of both. Enjoy!

ALPHA   = "abcdefghijklmnopqrstuvwxyz"
NUMERIC = "1234567890"
SPECIAL = "~!@#$%^&*()_+|`\=-}{$\":?><][';/.," # workaround for syntax highlighting - '

Example:
	${Validate} $VAR "test" ${ALPHA}
		$VAR = 1
	${Validate} $out "test1" ${ALPHA}
		$VAR = 0
	${Validate} $out "123" ${NUMERIC}
		$VAR = 1
	${Validate} $out "123asdf" ${NUMERIC}
		$VAR = 0
*/
!define ALPHA   abcdefghijklmnopqrstuvwxyz
!define NUMERIC 1234567890
!define SPECIAL "~!@#$%^&*()_+|`\=-}{$\":?><][';/.,"
Function StrVal
	!macro _StrVal _STR _TEST _RET
		Push `${_STR}`
		Push `${_TEST}`
		Call StrVal
		Pop ${_RET}
	!macroend
	!define StrVal `!insertmacro _StrVal`
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	Push $8
	Exch 9
	Pop $1
	Exch 9
	Pop $2
	StrCpy $0 1
	StrLen $3 $2
	StrLen $6 $1
	StrCpy $4 0
	StrCpy $5 $2 1 $4
	StrCpy $7 0
	StrCpy $8 $1 1 $7
	StrCmp $5 $8 +3 0
	IntOp $7 $7 + 1
	IntCmp $7 $6 -3 -3 +3
	IntOp $4 $4 + 1
	IntCmp $4 $3 -7 -7 +2
	StrCpy $0 0
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch 2
	Pop $7
	Pop $8
	Exch $0
FunctionEnd