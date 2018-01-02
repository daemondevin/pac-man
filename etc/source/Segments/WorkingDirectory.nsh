;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
;   WorkingDirectory.nsh
;   This file is responsible for setting the working directory getting it's value from the CompilerWrapper.ini file.
; 

${SegmentFile}
${SegmentPreExec}
	ClearErrors
	${ReadWrapperConfig} $0 Launch WorkingDirectory
	IfErrors +3
	ExpandEnvStrings $0 $0
	SetOutPath $0
!macroend
