;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   RunBeforeAfter.nsh
;   This file reads the CompilerWrapper.ini which then handles executing something before and/or after launching the wrapper.
; 

!define RunBeforeAfter "!insertmacro _RunBeforeAfter"
!macro _RunBeforeAfter _WHEN
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadWrapperConfig} $1 Launch Run${_WHEN}$R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $1

		; Safety check so paths with spaces work
		StrCpy $R1 $1 1
		${If} $R1 != '"'
			MessageBox MB_ICONEXCLAMATION `[Launch]:Run${_WHEN}$R0 doesn't have the path quoted!${NEWLINE}${NEWLINE}Use something like the following:${NEWLINE}Run${_WHEN}$R0='"$1"').`
		${EndIf}

		ExecWait $1
		IntOp $R0 $R0 + 1
	${Loop}
!macroend

${SegmentFile}
${SegmentPreExec}
	${RunBeforeAfter} Before
!macroend
${SegmentPostExec}
	${RunBeforeAfter} After
!macroend
