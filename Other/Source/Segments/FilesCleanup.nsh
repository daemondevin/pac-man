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