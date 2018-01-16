!macro _startswith _a _b _t _f
    !insertmacro _LOGICLIB_TEMP
	StrLen $_LOGICLIB_TEMP `${_b}`
	StrCpy $_LOGICLIB_TEMP `${_a}` $_LOGICLIB_TEMP
	StrCmp $_LOGICLIB_TEMP `${_b}` `${_t}` `${_f}`
!macroend

!macro _contains _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	Push `${_a}`
	Push `${_b}`
	Push ""
	${CallArtificialFunction} _iscontains
	Pop $_LOGICLIB_TEMP
	!insertmacro _== $_LOGICLIB_TEMP 0 `${_t}` `${_f}`
!macroend

!macro _options _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	Push `${_a}`
	Push `${_b}`
	Push o
	${CallArtificialFunction} _iscontains
	Pop $_LOGICLIB_TEMP
	!insertmacro _== $_LOGICLIB_TEMP 0 `${_t}` `${_f}`
!macroend

!macro _lcontains _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	Push `${_a}`
	Push `${_b}`
	Push l
	${CallArtificialFunction} _islrcontains
	Pop $_LOGICLIB_TEMP
	!insertmacro _== $_LOGICLIB_TEMP 0 `${_t}` `${_f}`
!macroend

!macro _rcontains _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	Push `${_a}`
	Push `${_b}`
	Push r
	${CallArtificialFunction} _islrcontains
	Pop $_LOGICLIB_TEMP
	!insertmacro _== $_LOGICLIB_TEMP 0 `${_t}` `${_f}`
!macroend

!macro _iscontains
		Exch $2 ; is it o?
		Exch
		Exch $1 ; _b
		Exch
		Exch 2
		Exch $0 ; _a
		Exch 2
		Push $3 ; _a len
		Push $4 ; _b len
		Push $5 ; int counter
		Push $6 ; temp

		StrCmp $2 o "" ${__MACRO__}_do
		StrCpy $0 " $0 " ; append a space so we can /\s-[a-z]\s for every options
		StrCpy $1 " $1 "

	${__MACRO__}_do:
		StrLen $3 $0
		StrLen $4 $1

		StrCpy $5 0

	${__MACRO__}_loop:
		StrCpy $6 $0 $4 $5
		StrCmp $5 $3 ${__MACRO__}_done
		StrCmp $6 $1 ${__MACRO__}_found
		IntOp $5 $5 + 1
		Goto ${__MACRO__}_loop

	${__MACRO__}_found:
		StrCpy $0 0
		Goto ${__MACRO__}_cleanup

	${__MACRO__}_done:
		StrCpy $0 -1

	${__MACRO__}_cleanup:
		Pop $6
		Pop $5
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
!macroend

!macro _islrcontains
		Exch $2 ; l or r
		Exch
		Exch $1 ; _b
		Exch
		Exch 2
		Exch $0 ; _a
		Exch 2
		Push $3 ; _b len
		Push $4

		StrLen $3 $1

		StrCmp $2 l ${__MACRO__}_left
		StrCmp $2 r ${__MACRO__}_right

	${__MACRO__}_left:
		StrCpy $4 $0 $3
		Goto ${__MACRO__}_compare

	${__MACRO__}_right:
		StrCpy $4 $0 "" -$3

	${__MACRO__}_compare:
		StrCmp $4 $1 ${__MACRO__}_found ${__MACRO__}_done

	${__MACRO__}_found:
		StrCpy $0 0
		Goto ${__MACRO__}_cleanup

	${__MACRO__}_done:
		StrCpy $0 -1

	${__MACRO__}_cleanup:
		Pop $4
		Pop $3
		Pop $2
		Pop $1
		Exch $0
!macroend
