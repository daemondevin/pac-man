;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   DriveLetter.nsh
;   This file sets variables according to the current drive letter and the drive letter from the previous launch.
; 

${SegmentFile}
${SegmentInit}
	!ifmacrodef Drive
		!insertmacro Drive
	!endif
	ReadINIStr $1 "${CONFIGINI}" "${APPNAME}Settings" LastDrive
	${GetRoot} $EXEDIR $0
	${IfThen} $1 == "" ${|} StrCpy $1 $0 ${|}
	${SetEnvironmentVariable} PAC:Drive $0
	StrCpy $0 $0 1
	${SetEnvironmentVariable} PAC:DriveLetter $0
	${SetEnvironmentVariable} PAC:LastDrive $1
	StrCpy $1 $1 1
	${SetEnvironmentVariable} PAC:LastDriveLetter $1
!macroend

${SegmentPrePrimary}
	!ifmacrodef PreDrive
		!insertmacro PreDrive
	!endif
	ReadEnvStr $0 PAC:Drive
	WriteINIStr `${CONFIGINI}` `${APPNAME}Settings` LastDrive `$0`
!macroend
