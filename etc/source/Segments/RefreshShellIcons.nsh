;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   RefreshShellIcons.nsh
;   This file enables support for handling the icon cache of Windows Explorer to refresh them before and after launch.
; 

!ifndef SHCNE_ASSOCCHANGED
	!define SHCNE_ASSOCCHANGED 0x08000000
!endif
!ifndef SHCNF_IDLIST
	!define SHCNF_IDLIST 0
!endif

${SegmentFile}
${SegmentPreExec}
	!ifmacrodef PreShellIcons
		!insertmacro PreShellIcons
	!else
		${ReadWrapperConfig} $0 Launch RefreshShellIcons
		StrCmp $0 before +2
		StrCmp $0 both 0 +2
		System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v (${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
	!endif
!macroend
${SegmentPost}
	!ifmacrodef PostShellIcons
		!insertmacro PostShellIcons
	!else
		${ReadWrapperConfig} $0 Launch RefreshShellIcons
		StrCmp $0 after +2
		StrCmp $0 both 0 +2
		System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v (${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'
	!endif
!macroend
