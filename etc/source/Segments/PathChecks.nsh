;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   PathChecks.nsh
;   This file checks and verifies the current path for UNC/spaces support before launching the wrapper.
; 

${SegmentFile}
${SegmentInit}
	${If} $EXEDIR startswith $PROGRAMFILES32
		StrCpy $0 $PROGRAMFILES32
	${ElseIf} $EXEDIR startswith $PROGRAMFILES64
		StrCpy $0 $PROGRAMFILES64
	${Else}
		StrCpy $0 ""
	${EndIf}
	${If} $0 != ""
		ReadEnvStr $1 IPromiseNotToComplainWhenPortableAppsDontWorkRightInProgramFiles
		${If} $1 S== "I understand that this may not work and that I can not ask for help with any of my apps when operating in this fashion."
		${Else}
			MessageBox MB_ICONSTOP|MB_TOPMOST `ERROR: ${PORTABLEAPPNAME} cannot be run from $0`
			Quit
		${EndIf}
	${EndIf}
	StrCpy $1 nounc
	${IfThen} $EXEDIR startswith "\\" ${|} StrCpy $1 unc ${|}
	ClearErrors
	${ReadWrapperConfig} $0 Launch SupportsUNC
	${If} $0 == no
		${If} $1 == unc
			MessageBox MB_ICONSTOP|MB_TOPMOST `$(LauncherNoUNCSupport)`
			Quit
		${EndIf}
	${ElseIf} $0 == warn
	${OrIf} ${Errors}
		${If} $1 == unc
		${AndIf} ${Cmd} `MessageBox MB_YESNO|MB_ICONSTOP|MB_TOPMOST $(LauncherUNCWarn) IDNO`
			Quit
		${EndIf}
	${ElseIf} $0 == yes
		Nop
	${Else}
		${InvalidValueError} [Launch]:SupportsUNC $0
	${EndIf}
	ClearErrors
	${ReadWrapperConfig} $0 Launch NoSpacesInPath
	${If} $0 == true
		${WordFind} $EXEDIR ` ` E+1 $R9
		${IfNot} ${Errors}
			MessageBox MB_ICONSTOP|MB_TOPMOST $(LauncherNoSpaces)
			Quit
		${EndIf}
	${ElseIf} $0 != false
	${AndIfNot} ${Errors}
		${InvalidValueError} [Launch]:NoSpacesInPath $0
	${EndIf}
!macroend
