/*______________________________________________________________________________

                             WordFind2X v2.1
________________________________________________________________________________
Find word between two delimiters.
 
Strings:
"[delimiter1][word+1][delimiter2][delimiter1][word+2][delimiter2]..."
"[text][delimiter1][text][delimiter1][word+1][delimiter2][text]..."
"...[delimiter1][word-2][delimiter2][delimiter1][word-1][delimiter2]"
"...[text][delimiter1][text][delimiter1][word-1][delimiter2][text]"
 
Syntax:
${WordFind2X} "[string]" "[delimiter1]" "[delimiter2]" "[E][options]" $var
 
"[string]"         ;[string]
                   ;  input string
"[delimiter1]"     ;[delimiter1]
                   ;  first delimiter
"[delimiter2]"     ;[delimiter2]
                   ;  second delimiter
"[E][options]"     ;[options]
                   ;  +number   : word number from start
                   ;  -number   : word number from end
                   ;  +number}} : word number from start all space
                   ;              after this word to output
                   ;  +number{{ : word number from end all space
                   ;              before this word to output
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
                   ;  /word     : number of word to output
                   ;
                   ;[E]
                   ;  with errorlevel output
                   ;  IfErrors:
                   ;     $var=1  no words found
                   ;     $var=2  no such word number
                   ;     $var=3  syntax error (Use: +1,-1,#)
                   ;[]
                   ;  no errorlevel output (default)
                   ;  If some errors found then (result=input string)
                   ;
$var               ;output (result)

Example (1): 
	Section
		${WordFind2X} "[C:\io.sys];[C:\logo.sys];[C:\WINDOWS]" "[C:\" "];" "+2" $R0
		; $R0="logo.sys"
	SectionEnd

Example (2): 
	Section
		${WordFind2X} "C:\WINDOWS C:\io.sys C:\logo.sys" "\" "." "-1" $R0
		; $R0="logo"
	SectionEnd

Example (3): 
	Section
		${WordFind2X} "C:\WINDOWS C:\io.sys C:\logo.sys" "\" "." "-1{{" $R0
		; $R0="C:\WINDOWS C:\io.sys C:"
	SectionEnd

Example (4): 
	Section
		${WordFind2X} "C:\WINDOWS C:\io.sys C:\logo.sys" "\" "." "-1{}" $R0
		; $R0="C:\WINDOWS C:\io.sys C:sys"
	SectionEnd

Example (5): 
	Section
		${WordFind2X} "C:\WINDOWS C:\io.sys C:\logo.sys" "\" "." "-1{*" $R0
		; $R0="C:\WINDOWS C:\io.sys C:\logo."
	SectionEnd

Example (6): 
	Section
		${WordFind2X} "C:\WINDOWS C:\io.sys C:\logo.sys" "\" "." "/logo" $R0
		; $R0="2"
	SectionEnd

Example (With errorlevel output): 
	Section
		${WordFind2X} "[io.sys];[C:\logo.sys]" "\" "];" "E+1" $R0
		; $R0="1" ("\...];" not found)
	 
		IfErrors 0 noerrors
		MessageBox MB_OK 'Errorlevel=$R0' IDOK end
	 
		noerrors:
		MessageBox MB_OK 'No errors'
	 
		end:
	SectionEnd                                                               */

Function WordFind2X
	!macro WordFind2XCall _STRING _DELIMITER1 _DELIMITER2 _NUMBER _RESULT
		Push `${_STRING}`
		Push `${_DELIMITER1}`
		Push `${_DELIMITER2}`
		Push `${_NUMBER}`
		Call WordFind2X
		Pop ${_RESULT}
	!macroend
	!define WordFind2X `!insertmacro WordFind2XCall`
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
	Push $R2
	ClearErrors
	StrCpy $R2 ''
	StrCpy $3 $2 1
	StrCpy $2 $2 '' 1
	StrCmp $3 'E' 0 +3
	StrCpy $R2 E
	goto -4
	StrCmp $3 '+' +5
	StrCmp $3 '-' +4
	StrCmp $3 '#' restart
	StrCmp $3 '/' restart
	goto error3
	StrCpy $4 $2 2 -2
	StrCmp $4 '{{' +9
	StrCmp $4 '}}' +8
	StrCmp $4 '{*' +7
	StrCmp $4 '*{' +6
	StrCmp $4 '*}' +5
	StrCmp $4 '}*' +4
	StrCmp $4 '{}' +3
	StrCpy $4 ''
	goto +2
	StrCpy $2 $2 -2
	IntOp $2 $2 + 0
	StrCmp $2 0 error2
	restart:
	StrCmp $R0 '' error1
	StrCpy $5 -1
	StrCpy $6 0
	StrCpy $7 ''
	StrLen $8 $0
	StrLen $9 $1
	loop:
	IntOp $5 $5 + 1
	delim1:
	StrCpy $R1 $R0 $8 $5
	StrCmp $R1$6 0 error1
	StrCmp $R1 '' minus
	StrCmp $R1 $0 +2
	StrCmp $7 '' loop delim2
	StrCmp $0 $1 0 +2
	StrCmp $7 '' 0 delim2
	IntOp $7 $5 + $8
	StrCpy $5 $7
	goto delim1
	delim2:
	StrCpy $R1 $R0 $9 $5
	StrCmp $R1 $1 0 loop
	IntOp $6 $6 + 1
	StrCmp $3$6 '+$2' plus
	StrCmp $3 '/' 0 nextword
	IntOp $R1 $5 - $7
	StrCpy $R1 $R0 $R1 $7
	StrCmp $R1 $2 0 +3
	StrCpy $R1 $6
	goto end
	nextword:
	IntOp $5 $5 + $9
	StrCpy $7 ''
	goto delim1
	minus:
	StrCmp $3 '-' 0 sum
	StrCpy $3 +
	IntOp $2 $6 - $2
	IntOp $2 $2 + 1
	IntCmp $2 0 error2 error2 restart
	sum:
	StrCmp $3 '#' 0 error2
	StrCpy $R1 $6
	goto end
	plus:
	StrCmp $4 '' 0 +4
	IntOp $R1 $5 - $7
	StrCpy $R1 $R0 $R1 $7
	goto end
	IntOp $5 $5 + $9
	IntOp $7 $7 - $8
	StrCmp $4 '{*' +2
	StrCmp $4 '*{' 0 +3
	StrCpy $R1 $R0 $5
	goto end
	StrCmp $4 '*}' +2
	StrCmp $4 '}*' 0 +3
	StrCpy $R1 $R0 '' $7
	goto end
	StrCmp $4 '}}' 0 +3
	StrCpy $R1 $R0 '' $5
	goto end
	StrCmp $4 '{{' 0 +3
	StrCpy $R1 $R0 $7
	goto end
	StrCmp $4 '{}' 0 error3
	StrCpy $5 $R0 '' $5
	StrCpy $7 $R0 $7
	StrCpy $R1 '$7$5'
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
	StrCmp $R2 'E' 0 +3
	SetErrors
	end:
	StrCpy $R0 $R1
	Pop $R2
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