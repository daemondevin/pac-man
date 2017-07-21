${SegmentFile}
${SegmentInit}
	!ifmacrodef Variables
		!insertmacro Variables
	!endif
!macroend
${SegmentPre}
	${ForEachINIPair} Environment $0 $1
		ExpandEnvStrings $1 $1
		System::Call `Kernel32::SetEnvironmentVariable(tr0,tr1)`
	${NextINIPair}
!macroend
