;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Settings.nsh
;   This file is responsible for moving the default settings to the settings folder before launching the wrapper.
; 

!macro !defineifexist _VAR_NAME _FILE_NAME
	!tempfile _TEMPFILE
	!ifdef NSIS_WIN32_MAKENSIS
		!system 'if exist "${_FILE_NAME}" echo !define ${_VAR_NAME} > "${_TEMPFILE}"'
	!else
		!system 'if [ -e "${_FILE_NAME}" ]; then echo "!define ${_VAR_NAME}" > "${_TEMPFILE}"; fi'
	!endif
	!include '${_TEMPFILE}'
	!delfile '${_TEMPFILE}'
	!undef _TEMPFILE
!macroend
!define !defineifexist "!insertmacro !defineifexist"
!define Init::File "!insertmacro _Init::File"
!macro _Init::File _DIR _FILE
	StrCmpS `${_FILE}` "" 0 +4
	IfFileExists `${SET}\${_DIR}` +10
	CreateDirectory `${SET}\${_DIR}`
	Goto +8
	StrCmpS `${_DIR}` "" 0 +4
	IfFileExists `${SET}\${_FILE}` +6
	CopyFiles /SILENT `${DEFSET}\${_FILE}` `${SET}`
	Goto +4
	IfFileExists `${SET}\${_DIR}\${_FILE}` +3
	CreateDirectory `${SET}\${_DIR}`
	CopyFiles /SILENT `${DEFSET}\${_DIR}\${_FILE}` `${SET}\${_DIR}`
!macroend
${SegmentFile}
${SegmentInit}
	; Check for settings
	${IfNot} ${FileExists} ${SET}
		${DebugMsg} "${SET} does not exist. Creating it."
		CreateDirectory ${SET}
		${If} ${FileExists} ${DEFSET}\*.*
			${DebugMsg} "Copying default data from ${DEFSET} to ${SET}."
			CopyFiles /SILENT ${DEFSET}\*.* ${SET}
		${EndIf}
	${EndIf}
	!ifmacrodef Init
		!insertmacro Init
	!endif
!macroend
