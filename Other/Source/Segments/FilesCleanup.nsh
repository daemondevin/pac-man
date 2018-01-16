;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
;   FilesCleanup.nsh
;   This file allows support for cleaning up files that are configured in the Launcher.ini file.
; 

!ifdef FileCleanup
${SegmentFile}
${SegmentPrePrimary}
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $R1 FilesCleanup $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $R1
		Delete `$R1`
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentPostPrimary}
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $R1 FilesCleanup $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $R1
		Delete `$R1`
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentUnload}
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $R1 FilesCleanup $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $R1
		Delete `$R1`
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
!endif
