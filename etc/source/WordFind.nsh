/*______________________________________________________________________________
 
                            WordFind v2.0
________________________________________________________________________________
Multi-features string function.
 
Strings:
"[word+1][delimiter][word+2][delimiter][word+3]..."
"[delimiter][word+1][delimiter][word+2][delimiter]..."
"[delimiter][delimiter][word+1][delimiter][delimiter][delimiter]..."
"...[word-3][delimiter][word-2][delimiter][word-1]"
"...[delimiter][word-2][delimiter][word-1][delimiter]"
"...[delimiter][delimiter][word-1][delimiter][delimiter][delimiter]"
 
Syntax: 
${WordFind} "[string]" "[delimiter]" "[E][options]" $var
 
"[string]"         ;[string]
                   ;  input string
"[delimiter]"      ;[delimiter]
                   ;  one or several symbols
"[E][options]"     ;[options]
                   ;  +number   : word number from start
                   ;  -number   : word number from end
                   ;  +number}  : delimiter number from start
                   ;              all space after this
                   ;              delimiter to output
                   ;  +number{  : delimiter number from start
                   ;              all space before this
                   ;              delimiter to output
                   ;  +number}} : word number from start
                   ;              all space after this word
                   ;              to output
                   ;  +number{{ : word number from start
                   ;              all space before this word
                   ;              to output
                   ;  +number{} : word number from start
                   ;              all space before and after
                   ;              this word (word exclude)
                   ;  +number*} : word number from start
                   ;              all space after this
                   ;              word to output with word
                   ;  +number{* : word number from start
                   ;              all space before this
                   ;              word to output with word
                   ;  #         : sum of words to output
                   ;  *         : sum of delimiters to output
                   ;  /word     : number of word to output
                   ;
                   ;[E]
                   ;  with errorlevel output
                   ;  IfErrors:
                   ;     $var=1  delimiter not found
                   ;     $var=2  no such word number
                   ;     $var=3  syntax error (Use: +1,-1},#,*,/word,...)
                   ;[]
                   ;  no errorlevel output (default)
                   ;  If some errors found then (result=input string)
                   ;
$var               ;output (result)
 
Note:
-Accepted numbers 1,01,001,...

Example (Find word by number): 
	Section
		${WordFind} "C:\io.sys C:\Program Files C:\WINDOWS" " C:\" "-02" $R0
		; $R0="Program Files"
	SectionEnd

Example (Delimiter exclude): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys C:\WINDOWS" "sys" "-2}" $R0
		; $R0=" C:\logo.sys C:\WINDOWS"
	SectionEnd

Example (Sum of words): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys C:\WINDOWS" " C:\" "#" $R0
		; $R0="3"
	SectionEnd

Example (Sum of delimiters): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys C:\WINDOWS" "sys" "*" $R0
		; $R0="2"
	SectionEnd

Example (Find word number): 
	Section
		${WordFind} "C:\io.sys C:\Program Files C:\WINDOWS" " " "/Files" $R0
		; $R0="3"
	SectionEnd

Example ( }} ): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys C:\WINDOWS" " " "+2}}" $R0
		; $R0=" C:\WINDOWS"
	SectionEnd

Example ( {} ): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys C:\WINDOWS" " " "+2{}" $R0
		; $R0="C:\io.sys C:\WINDOWS"
	SectionEnd

Example ( *} ): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys C:\WINDOWS" " " "+2*}" $R0
		; $R0="C:\logo.sys C:\WINDOWS"
	SectionEnd

Example (Get parent directory): 
	Section
		StrCpy $R0 "C:\Program Files\NSIS\NSIS.chm"
	;	           "C:\Program Files\NSIS\Include\"
	;	           "C:\\Program Files\\NSIS\\NSIS.chm"
		${WordFind} "$R0" "\" "-2{*" $R0
		; $R0="C:\Program Files\NSIS"
		;     "C:\\Program Files\\NSIS"
	SectionEnd

Example (Coordinates): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys C:\WINDOWS" ":\lo" "E+1{" $R0
		; $R0="C:\io.sys C"
		IfErrors end
		StrLen $0 $R0             ; $0 = Start position of word (11)
		StrLen $1 ':\lo'          ; $1 = Word leght (4)
		; StrCpy $R0 $R1 $1 $0    ; $R0 = :\lo
		end:
	SectionEnd

Example (With errorlevel output): 
	Section
		${WordFind} "[string]" "[delimiter]" "E[options]" $R0
		IfErrors 0 end
		StrCmp $R0 1 0 +2       ; errorlevel 1?
		MessageBox MB_OK 'delimiter not found' IDOK end
		StrCmp $R0 2 0 +2       ; errorlevel 2?
		MessageBox MB_OK 'no such word number' IDOK end
		StrCmp $R0 3 0 +2       ; errorlevel 3?
		MessageBox MB_OK 'syntax error'
		end:
	SectionEnd

Example (Without errorlevel output): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys" "_" "+1" $R0
		; $R0="C:\io.sys C:\logo.sys" (error: delimiter "_" not found)
	SectionEnd

	Example (If found): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys" ":\lo" "E+1{" $R0
		IfErrors notfound found
		found:
		MessageBox MB_OK 'Found' IDOK end
		notfound:
		MessageBox MB_OK 'Not found'
		end:
	SectionEnd

Example (If found 2): 
	Section
		${WordFind} "C:\io.sys C:\logo.sys" ":\lo" "+1{" $R0
		StrCmp $R0 "C:\io.sys C:\logo.sys" notfound found        ; error?
		found:
		MessageBox MB_OK 'Found' IDOK end
		notfound:
		MessageBox MB_OK 'Not found'
		end:
	SectionEnd

Example (To accept one word in string if delimiter not found): 
	Section
		StrCpy $0 'OneWord'
		StrCpy $1 1
		loop:
		${WordFind} "$0" " " "E+$1" $R0
		IfErrors 0 code
		StrCmp $1$R0 11 0 error
		StrCpy $R0 $0
		goto end
		code:
		; ...
		IntOp $1 $1 + 1
		goto loop
		error:
		StrCpy $1 ''
		StrCpy $R0 ''
		end:
		; $R0="OneWord"
	SectionEnd                                                               */

Function WordFind
	!macro _WordFind _STRING _DELIMITER _OPTION _RESULT
		Push `${_STRING}`
		Push `${_DELIMITER}`
		Push `${_OPTION}`
		Call WordFind
		Pop ${_RESULT}
	!macroend
	!define WordFind `!insertmacro _WordFind`
	Exch $1
	Exch
	Exch $0
	Exch
	Exch 2
	Exch $R0
	Exch 2
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	Push $8
	Push $9
	Push $R1
	ClearErrors
	StrCpy $9 ''
	StrCpy $2 $1 1
	StrCpy $1 $1 '' 1
	StrCmp $2 'E' 0 +3
	StrCpy $9 E
	goto -4
	StrCpy $3 ''
	StrCmp $2 '+' +6
	StrCmp $2 '-' +5
	StrCmp $2 '/' restart
	StrCmp $2 '#' restart
	StrCmp $2 '*' restart
	goto error3
	StrCpy $4 $1 1 -1
	StrCmp $4 '*' +4
	StrCmp $4 '}' +3
	StrCmp $4 '{' +2
	goto +4
	StrCpy $1 $1 -1
	StrCpy $3 '$4$3'
	goto -7
	StrCmp $3 '*' error3
	StrCmp $3 '**' error3
	StrCmp $3 '}{' error3
	IntOp $1 $1 + 0
	StrCmp $1 0 error2
	restart:
	StrCmp $R0 '' error1
	StrCpy $4 0
	StrCpy $5 0
	StrCpy $6 0
	StrLen $7 $0
	goto loop
	preloop:
	IntOp $6 $6 + 1
	loop:
	StrCpy $8 $R0 $7 $6
	StrCmp $8$5 0 error1
	StrCmp $8 '' +2
	StrCmp $8 $0 +5 preloop
	StrCmp $3 '{' minus
	StrCmp $3 '}' minus
	StrCmp $2 '*' minus
	StrCmp $5 $6 minus +5
	StrCmp $3 '{' +4
	StrCmp $3 '}' +3
	StrCmp $2 '*' +2
	StrCmp $5 $6 nextword
	IntOp $4 $4 + 1
	StrCmp $2$4 +$1 plus
	StrCmp $2 '/' 0 nextword
	IntOp $8 $6 - $5
	StrCpy $8 $R0 $8 $5
	StrCmp $1 $8 0 nextword
	StrCpy $R1 $4
	goto end
	nextword:
	IntOp $6 $6 + $7
	StrCpy $5 $6
	goto loop
	minus:
	StrCmp $2 '-' 0 sum
	StrCpy $2 '+'
	IntOp $1 $4 - $1
	IntOp $1 $1 + 1
	IntCmp $1 0 error2 error2 restart
	sum:
	StrCmp $2 '#' 0 sumdelim
	StrCpy $R1 $4
	goto end
	sumdelim:
	StrCmp $2 '*' 0 error2
	StrCpy $R1 $4
	goto end
	plus:
	StrCmp $3 '' 0 +4
	IntOp $6 $6 - $5
	StrCpy $R1 $R0 $6 $5
	goto end
	StrCmp $3 '{' 0 +3
	StrCpy $R1 $R0 $6
	goto end
	StrCmp $3 '}' 0 +4
	IntOp $6 $6 + $7
	StrCpy $R1 $R0 '' $6
	goto end
	StrCmp $3 '{*' +2
	StrCmp $3 '*{' 0 +3
	StrCpy $R1 $R0 $6
	goto end
	StrCmp $3 '*}' +2
	StrCmp $3 '}*' 0 +3
	StrCpy $R1 $R0 '' $5
	goto end
	StrCmp $3 '}}' 0 +3
	StrCpy $R1 $R0 '' $6
	goto end
	StrCmp $3 '{{' 0 +3
	StrCpy $R1 $R0 $5
	goto end
	StrCmp $3 '{}' 0 error3
	StrLen $3 $R0
	StrCmp $3 $6 0 +3
	StrCpy $0 ''
	goto +2
	IntOp $6 $6 + $7
	StrCpy $8 $R0 '' $6
	StrCmp $4$8 1 +6
	StrCmp $4 1 +2 +7
	IntOp $6 $6 + $7
	StrCpy $3 $R0 $7 $6
	StrCmp $3 '' +2
	StrCmp $3 $0 -3 +3
	StrCpy $R1 ''
	goto end
	StrCmp $5 0 0 +3
	StrCpy $0 ''
	goto +2
	IntOp $5 $5 - $7
	StrCpy $3 $R0 $5
	StrCpy $R1 '$3$0$8'
	goto end
	error3:
	StrCpy $R1 3
	goto error
	error2:
	StrCpy $R1 2
	goto error
	error1:
	StrCpy $R1 1
	error:
	StrCmp $9 'E' 0 +3
	SetErrors
	end:
	StrCpy $R0 $R1
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