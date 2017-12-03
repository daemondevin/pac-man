;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Qt.nsh
;   This file handles the clean up of any Qt registry entries that are declared in the CompilerWrapper.ini file.
; 

${SegmentFile}
${SegmentPostPrimary}
	!ifmacrodef PreQT
		!insertmacro PreQT
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadWrapperConfig} $0 QtKeysCleanup $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		!ifmacrodef CustomQT
			!insertmacro CustomQT
		!else
			StrCpy $1 Software\Trolltech\OrganizationDefaults\$0\$AppDirectory
		!endif
		DeleteRegKey HKCU $1
		${Do}
			${GetParent} $1 $1
			DeleteRegKey /ifempty HKCU $1
		${LoopUntil} $1 == Software\Trolltech
		IntOp $R0 $R0 + 1
	${Loop}
	!ifmacrodef PostQT
		!insertmacro PostQT
	!endif
!macroend
