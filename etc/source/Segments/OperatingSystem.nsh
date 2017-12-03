;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   OperatingSystem.nsh
;   This file handles support for the Host's allotted minimum/maximum operating system version.
; 

!ifndef ___WINVER__NSH___
	!include WinVer.nsh
!endif

!define CheckOS "!insertmacro _CheckOS"
!macro _CheckOS Check Value
	ClearErrors
	${ReadWrapperConfig} $0 Launch ${Value}
	${Select} $0
		${Case} 2000
			${IfNotThen} ${At${Check}Win2000}   ${|} StrCpy $2 bad-os ${|}
		${Case} XP
			${IfNotThen} ${At${Check}WinXP}     ${|} StrCpy $2 bad-os ${|}
		${Case} 2003
			${IfNotThen} ${At${Check}Win2003}   ${|} StrCpy $2 bad-os ${|}
		${Case} Vista
			${IfNotThen} ${At${Check}WinVista}  ${|} StrCpy $2 bad-os ${|}
		${Case} 2008
			${IfNotThen} ${At${Check}Win2008}   ${|} StrCpy $2 bad-os ${|}
		${Case} 7
			${IfNotThen} ${At${Check}Win7}      ${|} StrCpy $2 bad-os ${|}
		${Case} 8
			${IfNotThen} ${At${Check}Win8}      ${|} StrCpy $2 bad-os ${|}
		${Case} "2008 R2"
			${IfNotThen} ${At${Check}Win2008R2} ${|} StrCpy $2 bad-os ${|}
		${Default}
			${IfNot} ${Errors} ; If it's defined and we're here, it's a bad value
				${InvalidValueError} [Launch]:${Value} $0
			${EndIf}
	${EndSelect}
	${If} $2 == bad-os
		${If} ${IsWin2000}
			StrCpy $1 2000
		${ElseIf} ${IsWinXP}
			StrCpy $1 XP
		${ElseIf} ${IsWin2003}
			StrCpy $1 2003
		${ElseIf} ${IsWinVista}
			StrCpy $1 Vista
		${ElseIf} ${IsWin2008}
			StrCpy $1 2008
		${ElseIf} ${IsWin7}
			StrCpy $1 7
		${ElseIf} ${IsWin8}
			StrCpy $1 8
		${ElseIf} ${IsWin2008R2}
			StrCpy $1 "2008 R2"
		${Else}
			StrCpy $1 ? ; I wonder what it is.
		${EndIf}
		MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "$(LauncherIncompatible${Value})"
		Quit
	${EndIf}
!macroend

${SegmentFile}
${Segment.onInit}
	!ifmacrodef OS
		!insertmacro OS
	!endif
	${CheckOS} Least MinOS
	${CheckOS} Most MaxOS
!macroend
