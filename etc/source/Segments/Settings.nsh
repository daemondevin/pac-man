;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
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
	IfFileExists `${CFG}\${_DIR}` +10
	CreateDirectory `${CFG}\${_DIR}`
	Goto +8
	StrCmpS `${_DIR}` "" 0 +4
	IfFileExists `${CFG}\${_FILE}` +6
	CopyFiles /SILENT `${DEFCFG}\${_FILE}` `${CFG}`
	Goto +4
	IfFileExists `${CFG}\${_DIR}\${_FILE}` +3
	CreateDirectory `${CFG}\${_DIR}`
	CopyFiles /SILENT `${DEFCFG}\${_DIR}\${_FILE}` `${CFG}\${_DIR}`
!macroend
${SegmentFile}
${SegmentInit}
	; Check for settings
	${IfNot} ${FileExists} ${CFG}
		${DebugMsg} "${CFG} does not exist. Creating it."
		CreateDirectory ${CFG}
		${If} ${FileExists} ${DEFCFG}\*.*
			${DebugMsg} "Copying default data from ${DEFCFG} to ${CFG}."
			CopyFiles /SILENT ${DEFCFG}\*.* ${CFG}
		${EndIf}
	${EndIf}
	!ifmacrodef Init
		!insertmacro Init
	!endif
!macroend
