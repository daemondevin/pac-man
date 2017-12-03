/*______________________________________________________________________________
 
                            WordFind3X v1.0
________________________________________________________________________________
Find word, that contain string, between two delimiters.
 
Syntax:
${WordFind3X} "[string]" "[delimiter1]" "[center]" "[delimiter2]" "[E][options]" $var
 
"[string]"         ;[string]
                   ;  input string
"[delimiter1]"     ;[delimiter1]
                   ;  first delimiter
"[center]"         ;[center]
                   ;  center string
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
		${WordFind3X} "[1.AAB];[2.BAA];[3.BBB];" "[" "AA" "];" "+1" $R0
		; $R0="1.AAB"
	SectionEnd

Example (2): 
	Section
		${WordFind3X} "[1.AAB];[2.BAA];[3.BBB];" "[" "AA" "];" "-1" $R0
		; $R0="2.BAA"
	SectionEnd

Example (3): 
	Section
		${WordFind3X} "[1.AAB];[2.BAA];[3.BBB];" "[" "AA" "];" "-1{{" $R0
		; $R0="[1.AAB];"
	SectionEnd

Example (4): 
	Section
		${WordFind3X} "[1.AAB];[2.BAA];[3.BBB];" "[" "AA" "];" "-1{}" $R0
		; $R0="[1.AAB];[3.BBB];"
	SectionEnd

Example (5): 
	Section
		${WordFind3X} "[1.AAB];[2.BAA];[3.BBB];" "[" "AA" "];" "-1{*" $R0
		; $R0="[1.AAB];[2.BAA];"
	SectionEnd

Example (6): 
	Section
		${WordFind3X} "[1.AAB];[2.BAA];[3.BBB];" "[" "AA" "];" "/2.BAA" $R0
		; $R0="2"
	SectionEnd

Example (With errorlevel output): 
	Section
		${WordFind3X} "[1.AAB];[2.BAA];[3.BBB];" "[" "XX" "];" "E+1" $R0
		; $R0="1" ("[...XX...];" not found)
	 
		IfErrors 0 noerrors
		MessageBox MB_OK 'Errorlevel=$R0' IDOK end
	 
		noerrors:
		MessageBox MB_OK 'No errors'
	 
		end:
	SectionEnd                                                               */

Function WordFind3X
	!macro WordFind3XCall _STRING _DELIMITER1 _CENTER _DELIMITER2 _NUMBER _RESULT
		Push `${_STRING}`
		Push `${_DELIMITER1}`
		Push `${_CENTER}`
		Push `${_DELIMITER2}`
		Push `${_NUMBER}`
		Call WordFind3X
		Pop ${_RESULT}
	!macroend
	!define WordFind3X `!insertmacro WordFind3XCall`
	Exch $3
	Exch
	Exch $2
	Exch
	Exch 2
	Exch $1
	Exch 2
	Exch 3
	Exch $0
	Exch 3
	Exch 4
	Exch $R0
	Exch 4
	Push $4
	Push $5
	Push $6
	Push $7
	Push $8
	Push $9
	Push $R1
	Push $R2
	Push $R3
	Push $R4
	Push $R5
	ClearErrors
	StrCpy $R5 ''
	StrCpy $4 $3 1
	StrCpy $3 $3 '' 1
	StrCmp $4 'E' 0 +3
	StrCpy $R5 E
	goto -4
	StrCmp $4 '+' +5
	StrCmp $4 '-' +4
	StrCmp $4 '#' restart
	StrCmp $4 '/' restart
	goto error3
	StrCpy $5 $3 2 -2
	StrCmp $5 '{{' +9
	StrCmp $5 '}}' +8
	StrCmp $5 '{*' +7
	StrCmp $5 '*{' +6
	StrCmp $5 '*}' +5
	StrCmp $5 '}*' +4
	StrCmp $5 '{}' +3
	StrCpy $5 ''
	goto +2
	StrCpy $3 $3 -2
	IntOp $3 $3 + 0
	StrCmp $3 0 error2
	restart:
	StrCmp $R0 '' error1
	StrCpy $6 -1
	StrCpy $7 0
	StrCpy $8 ''
	StrCpy $9 ''
	StrLen $R1 $0
	StrLen $R2 $1
	StrLen $R3 $2
	loop:
	IntOp $6 $6 + 1
	delim1:
	StrCpy $R4 $R0 $R1 $6
	StrCmp $R4$7 0 error1
	StrCmp $R4 '' minus
	StrCmp $R4 $0 +2
	StrCmp $8 '' loop center
	StrCmp $0 $1 +2
	StrCmp $0 $2 0 +2
	StrCmp $8 '' 0 center
	IntOp $8 $6 + $R1
	StrCpy $6 $8
	goto delim1
	center:
	StrCmp $9 '' 0 delim2
	StrCpy $R4 $R0 $R2 $6
	StrCmp $R4 $1 0 loop
	IntOp $9 $6 + $R2
	StrCpy $6 $9
	goto delim1
	delim2:
	StrCpy $R4 $R0 $R3 $6
	StrCmp $R4 $2 0 loop
	IntOp $7 $7 + 1
	StrCmp $4$7 '+$3' plus
	StrCmp $4 '/' 0 nextword
	IntOp $R4 $6 - $8
	StrCpy $R4 $R0 $R4 $8
	StrCmp $R4 $3 0 +3
	StrCpy $R4 $7
	goto end
	nextword:
	IntOp $6 $6 + $R3
	StrCpy $8 ''
	StrCpy $9 ''
	goto delim1
	minus:
	StrCmp $4 '-' 0 sum
	StrCpy $4 +
	IntOp $3 $7 - $3
	IntOp $3 $3 + 1
	IntCmp $3 0 error2 error2 restart
	sum:
	StrCmp $4 '#' 0 error2
	StrCpy $R4 $7
	goto end
	plus:
	StrCmp $5 '' 0 +4
	IntOp $R4 $6 - $8
	StrCpy $R4 $R0 $R4 $8
	goto end
	IntOp $6 $6 + $R3
	IntOp $8 $8 - $R1
	StrCmp $5 '{*' +2
	StrCmp $5 '*{' 0 +3
	StrCpy $R4 $R0 $6
	goto end
	StrCmp $5 '*}' +2
	StrCmp $5 '}*' 0 +3
	StrCpy $R4 $R0 '' $8
	goto end
	StrCmp $5 '}}' 0 +3
	StrCpy $R4 $R0 '' $6
	goto end
	StrCmp $5 '{{' 0 +3
	StrCpy $R4 $R0 $8
	goto end
	StrCmp $5 '{}' 0 error3
	StrCpy $6 $R0 '' $6
	StrCpy $8 $R0 $8
	StrCpy $R4 '$8$6'
	goto end
	error3:
	StrCpy $R4 3
	goto error
	error2:
	StrCpy $R4 2
	goto error
	error1:
	StrCpy $R4 1
	error:
	StrCmp $R5 'E' 0 +3
	SetErrors
	end:
	StrCpy $R0 $R4
	Pop $R5
	Pop $R4
	Pop $R3
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