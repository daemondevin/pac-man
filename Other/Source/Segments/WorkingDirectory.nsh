${SegmentFile}
${SegmentPreExec}
	ClearErrors
	${ReadLauncherConfig} $0 Launch WorkingDirectory
	IfErrors +3
	ExpandEnvStrings $0 $0
	SetOutPath $0
!macroend