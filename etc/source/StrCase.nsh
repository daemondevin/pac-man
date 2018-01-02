;
; StrCase.nsh
; by daemon.devin (daemon.devin@gmail.com)
;
; Based on the StrCase function by deguix 
; http://nsis.sourceforge.net/StrCase
;
; ${StrCase} "Return" "String" "Case"
; Changes a strings case.
;
; RETURN
;	Variable where the output string is returned to.
;
; STRING
;	The string to change the case of.
;
; CASE
; 	 L | Lower Case.
;	 U | Upper Case.
;	 T | Title Case.
;	 S | Sentence Case.
;	<> | Switch Case (inverse).
;
; EXAMPLE
;
;	Using supplied macro:
;
;		${StrCase} $0 "Example" "L" 			- $0 = "example"
;		${StrCase} $0 "Example" "<>" 			- $0 = "eXAMPLE"
;		${StrCase} $0 "title case example" "T" 	- $0 = "Title Case Example"
;
;	Calling the function:
;
;		Push "Uppercase example"
;		Push "U"
;		Call StrCase
;		Pop $0 
;		
;		$0 = "UPPERCASE EXAMPLE"
;

!ifndef LOGICLIB
	!include LogicLib.nsh
!endif

!ifndef STR_CASE_NSH_INCLUDED
	!define STR_CASE_NSH_INCLUDED

	!define StrCase "!insertmacro _StrCase"
	!macro _StrCase _RETURN _STRING _CASE
		Push "${_STRING}"
		Push "${_CASE}"
		Call StrCase
		Pop "${_RETURN}"
	!macroend

	Function StrCase
		;	$0 = String (input)
		;	$1 = Case (input)
		;	$2 = StrLength (temp)
		;	$3 = StartChar (temp)
		;	$4 = EndChar (temp)
		;	$5 = Result (temp)
		;	$6 = CurrentChar (temp)
		;	$7 = LastChar (temp)
		;	$8 = Temp (temp)

		Exch $1
		Exch
		Exch $0
		Exch
		Push $2
		Push $3
		Push $4
		Push $5
		Push $6
		Push $7
		Push $8
	 
		StrCpy $2 ""
		StrCpy $3 ""
		StrCpy $4 ""
		StrCpy $5 ""
		StrCpy $6 ""
		StrCpy $7 ""
		StrCpy $8 ""

		; Upper Case 
		${If} $1 == "U"
		${OrIf} $1 == "u"
		
			System::Call "User32::CharUpper(t r0 r5)i"
			Goto _STR_CASE_END
		
		; Lower Case
		${ElseIf} $1 == "L"

			System::Call "User32::CharLower(t r0 r5)i"
			Goto _STR_CASE_END

		${ElseIf} $1 == "l"

			System::Call "User32::CharLower(t r0 r5)i"
			Goto _STR_CASE_END

		${EndIf}

		; Get String length
		StrLen $2 $0
	 
		; Loop 'til the end of the String
		${For} $3 0 $2
			IntOp $4 $3 + 1
			
			${If} $3 <> 0
				StrCpy $6 $0 `` $3
			${EndIf}

			${If} $4 <> $2
				${If} $3 = 0
					StrCpy $6 $0 1
				${Else}
					StrCpy $6 $6 1
				${EndIf}
			${EndIf}

			; Title Case
			${If} $1 == "T"
			${OrIf} $1 == "t"
	 
				System::Call "*(&t1 r7) i .r8"
				System::Call "*$8(&i1 .r7)"
				System::Free $8
				System::Call "user32::IsCharAlpha(i r7) i .r8"
	 
				; Check return and convert
				${If} $8 = 0
					System::Call "User32::CharUpper(t r6 r6)i"
				${Else}
					System::Call "User32::CharLower(t r6 r6)i"
				${EndIf}

			; Sentence Case
			${ElseIf} $1 == "S"

				${If} $6 == " "
				${OrIf} $6 == "$\t"
					Goto _IGNORE_LETTER
				${EndIf}
	 
				${If} $7 == "."
				${OrIf} $7 == "!"
				${OrIf} $7 == "?"
				${OrIf} $7 == ""
					System::Call "User32::CharUpper(t r6 r6)i"
				${Else}
					System::Call "User32::CharLower(t r6 r6)i"
				${EndIf}

			; Sentence Case
			${ElseIf} $1 == "s"

				${If} $6 == " "
				${OrIf} $6 == "$\t"
					Goto _IGNORE_LETTER
				${EndIf}
	 
				${If} $7 == "."
				${OrIf} $7 == "!"
				${OrIf} $7 == "?"
				${OrIf} $7 == ""
					System::Call "User32::CharUpper(t r6 r6)i"
				${Else}
					System::Call "User32::CharLower(t r6 r6)i"
				${EndIf}

			; Switch Case
			${ElseIf} $1 == "<>"
	 
				System::Call "*(&t1 r6) i .r8"
				System::Call "*$8(&i1 .r7)"
				System::Free $8
				System::Call "user32::IsCharUpper(i r7) i .r8"
	 
				; Check return and convert
				${If} $8 = 0
					System::Call "User32::CharUpper(t r6 r6)i"
				${Else}
					System::Call "User32::CharLower(t r6 r6)i"
				${EndIf}
			${EndIf}

			StrCpy $7 $6
	 
			_IGNORE_LETTER:
			StrCpy $5 `$5$6`
		${Next}
	 
		_STR_CASE_END:
	 
		; Get return variable. | $0 = Result
		StrCpy $0 $5
	 
		; Return output to user
		Pop $8
		Pop $7
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
	FunctionEnd

!endif ; STR_CASE_NSH_INCLUDED
