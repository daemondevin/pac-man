Function WordReplace
	!define WordReplace `!insertmacro WordReplaceCall`
 
	!macro WordReplaceCall _STRING _WORD1 _WORD2 _NUMBER _RESULT
		Push `${_STRING}`
		Push `${_WORD1}`
		Push `${_WORD2}`
		Push `${_NUMBER}`
		Call WordReplace
		Pop ${_RESULT}
	!macroend
 
	Exch $2
	Exch
	Exch $1
	Exch
	Exch 2
	Exch $0
	Exch 2
	Exch 3
	Exch $R0
	Exch 3
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	Push $8
	Push $9
	Push $R1
	ClearErrors
 
	StrCpy $R1 $R0
	StrCpy $9 ''
	StrCpy $3 $2 1
	StrCpy $2 $2 '' 1
	StrCmp $3 'E' 0 +3
	StrCpy $9 E
	goto -4
 
	StrCpy $4 $2 1 -1
	StrCpy $5 ''
	StrCpy $6 ''
	StrLen $7 $0
 
	StrCmp $7 0 error1
	StrCmp $R0 '' error1
	StrCmp $3 '{' beginning
	StrCmp $3 '}' ending errorchk
 
	beginning:
	StrCpy $8 $R0 $7
	StrCmp $8 $0 0 +4
	StrCpy $R0 $R0 '' $7
	StrCpy $5 '$5$1'
	goto -4
	StrCpy $3 $2 1
	StrCmp $3 '}' 0 merge
 
	ending:
	StrCpy $8 $R0 '' -$7
	StrCmp $8 $0 0 +4
	StrCpy $R0 $R0 -$7
	StrCpy $6 '$6$1'
	goto -4
 
	merge:
	StrCmp $4 '*' 0 +5
	StrCmp $5 '' +2
	StrCpy $5 $1
	StrCmp $6 '' +2
	StrCpy $6 $1
	StrCpy $R0 '$5$R0$6'
	goto end
 
	errorchk:
	StrCmp $3 '+' +2
	StrCmp $3 '-' 0 error3
 
	StrCpy $5 $2 1
	IntOp $2 $2 + 0
	StrCmp $2 0 0 one
	StrCmp $5 0 error2
	StrCpy $3 ''
 
	all:
	StrCpy $5 0
	StrCpy $2 $R0 $7 $5
	StrCmp $2 '' +4
	StrCmp $2 $0 +6
	IntOp $5 $5 + 1
	goto -4
	StrCmp $R0 $R1 error1
	StrCpy $R0 '$3$R0'
	goto end
	StrCpy $2 $R0 $5
	IntOp $5 $5 + $7
	StrCmp $4 '*' 0 +3
	StrCpy $6 $R0 $7 $5
	StrCmp $6 $0 -3
	StrCpy $R0 $R0 '' $5
	StrCpy $3 '$3$2$1'
	goto all
 
	one:
	StrCpy $5 0
	StrCpy $8 0
	goto loop
 
	preloop:
	IntOp $5 $5 + 1
 
	loop:
	StrCpy $6 $R0 $7 $5
	StrCmp $6$8 0 error1
	StrCmp $6 '' minus
	StrCmp $6 $0 0 preloop
	IntOp $8 $8 + 1
	StrCmp $3$8 +$2 found
	IntOp $5 $5 + $7
	goto loop
 
	minus:
	StrCmp $3 '-' 0 error2
	StrCpy $3 +
	IntOp $2 $8 - $2
	IntOp $2 $2 + 1
	IntCmp $2 0 error2 error2 one
 
	found:
	StrCpy $3 $R0 $5
	StrCmp $4 '*' 0 +5
	StrCpy $6 $3 '' -$7
	StrCmp $6 $0 0 +3
	StrCpy $3 $3 -$7
	goto -3
	IntOp $5 $5 + $7
	StrCmp $4 '*' 0 +3
	StrCpy $6 $R0 $7 $5
	StrCmp $6 $0 -3
	StrCpy $R0 $R0 '' $5
	StrCpy $R0 '$3$1$R0'
	goto end
 
	error3:
	StrCpy $R0 3
	goto error
	error2:
	StrCpy $R0 2
	goto error
	error1:
	StrCpy $R0 1
	error:
	StrCmp $9 'E' +3
	StrCpy $R0 $R1
	goto +2
	SetErrors
 
	end:
	Pop $R1
	Pop $9
	Pop $8
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
	Exch $R0
FunctionEnd
