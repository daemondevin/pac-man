;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
;
; PortableAppsCompilerMacros.nsh
; This file declares and defines all the macros for use with PortableApps Compiler.
; 

!define ReadAppInfoConfig "!insertmacro _ReadAppInfoConfig"
!macro _ReadAppInfoConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} "${INFOINI}" "${_SECTION}" "${_KEY}"
!macroend
!define WriteAppInfoConfig "!insertmacro _WriteAppInfoConfig"
!macro _WriteAppInfoConfig _SECTION _KEY _VALUE
	WriteINIStr "${INFOINI}" "${_SECTION}" "${_KEY}" "${_VALUE}"
!macroend
!define DeleteAppInfoConfig "!insertmacro _DeleteAppInfoConfig"
!macro _DeleteAppInfoConfig _SECTION _KEY
	DeleteINIStr "${INFOINI}" "${_SECTION}" "${_KEY}"
!macroend
!define DeleteAppInfoConfigSec "!insertmacro _DeleteAppInfoConfigSec"
!macro _DeleteAppInfoConfigSec _SECTION
	DeleteINISec "${INFOINI}" "${_SECTION}"
!macroend
!define ReadWrapperConfig "!insertmacro _ReadWrapperConfig"
!macro _ReadWrapperConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} "${WRAPPER}" "${_SECTION}" "${_KEY}"
!macroend
!define WriteWrapperConfig "!insertmacro _WriteWrapperConfig"
!macro _WriteWrapperConfig _SECTION _KEY _VALUE
	WriteINIStr "${WRAPPER}" "${_SECTION}" "${_KEY}" "${_VALUE}"
!macroend
!define DeleteWrapperConfig "!insertmacro _DeleteWrapperConfig"
!macro _DeleteWrapperConfig _SECTION _KEY
	DeleteINIStr "${WRAPPER}" "${_SECTION}" "${_KEY}"
!macroend
!define DeleteWrapperConfigSec "!insertmacro _DeleteWrapperConfigSec"
!macro _DeleteWrapperConfigSec _SECTION
	DeleteINISec "${WRAPPER}" "${_SECTION}"
!macroend
!define ReadWrapperConfigWithDefault "!insertmacro _ReadWrapperConfigWithDefault"
!macro _ReadWrapperConfigWithDefault _VALUE _SECTION _KEY _DEFAULT
	ClearErrors
	${ReadWrapperConfig} ${_VALUE} "${_SECTION}" "${_KEY}"
	${IfThen} ${Errors} ${|} StrCpy ${_VALUE} "${_DEFAULT}" ${|}
!macroend
!define ReadUserConfig "!insertmacro _ReadUserConfig"
!macro _ReadUserConfig _VALUE _KEY
	${ConfigReadS} "${CONFIG}" "${_KEY}=" "${_VALUE}"
!macroend
!define WriteUserConfig "!insertmacro _WriteUserConfig"
!macro _WriteUserConfig _VALUE _KEY
	${ConfigWriteS} "${CONFIG}" "${_KEY}=" "${_VALUE}" $R0
!macroend
!define InvalidValueError "!insertmacro _InvalidValueError"
!macro _InvalidValueError _SECTION_KEY _VALUE
	MessageBox MB_OK|MB_ICONSTOP "ERROR: Invalid value '${_VALUE}' for ${_SECTION_KEY}."
!macroend
!define WriteRuntimeData "!insertmacro _WriteRuntimeData"
!macro _WriteRuntimeData _SECTION _KEY _VALUE
	WriteINIStr "${RUNTIME}" "${_SECTION}" "${_KEY}" "${_VALUE}"
	WriteINIStr "${RUNTIME2}" "${_SECTION}" "${_KEY}" "${_VALUE}"
!macroend
!define DeleteRuntimeData "!insertmacro _DeleteRuntimeData"
!macro _DeleteRuntimeData _SECTION _KEY
	DeleteINIStr "${RUNTIME}" "${_SECTION}" "${_KEY}"
	DeleteINIStr "${RUNTIME2}" "${_SECTION}" "${_KEY}"
!macroend
!define ReadRuntimeData "!insertmacro _ReadRuntimeData"
!macro _ReadRuntimeData _VALUE _SECTION _KEY
	IfFileExists "${RUNTIME}" 0 +3
	ReadINIStr "${_VALUE}" "${RUNTIME}" "${_SECTION}" "${_KEY}"
	Goto +2
	ReadINIStr "${_VALUE}" "${RUNTIME2}" "${_SECTION}" "${_KEY}"
!macroend
!define WriteRuntime "!insertmacro _WriteRuntime"
!macro _WriteRuntime _VALUE _KEY
	WriteINIStr "${RUNTIME}" ${PAC} "${_KEY}" "${_VALUE}"
	WriteINIStr "${RUNTIME2}" ${PAC} "${_KEY}" "${_VALUE}"
!macroend
!define ReadRuntime "!insertmacro _ReadRuntime"
!macro _ReadRuntime _VALUE _KEY
	IfFileExists "${RUNTIME}" 0 +3
	ReadINIStr "${_VALUE}" "${RUNTIME}" ${PAC} "${_KEY}"
	Goto +2
	ReadINIStr "${_VALUE}" "${RUNTIME2}" ${PAC} "${_KEY}"
!macroend
!define WriteSettings "!insertmacro _WriteSettings"
!macro _WriteSettings _VALUE _KEY
	WriteINIStr "${CONFIGINI}" "${APPNAME}Settings" "${_KEY}" "${_VALUE}"
!macroend
!define ReadSettings "!insertmacro _ReadSettings"
!macro _ReadSettings _VALUE _KEY
	ReadINIStr "${_VALUE}" "${CONFIGINI}" "${APPNAME}Settings" "${_KEY}"
!macroend
!define DeleteSettings "!insertmacro _DeleteSettings"
!macro _DeleteSettings _KEY
	DeleteINIStr "${CONFIGINI}" "${APPNAME}Settings" "${_KEY}"
!macroend
!define DISABLE_REDIRECTION "!insertmacro _DISABLE_REDIRECTION"
!macro _DISABLE_REDIRECTION
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${DISABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${DISABLEREDIR}`
		!endif
	!endif
!macroend
!define ENABLE_REDIRECTION "!insertmacro _ENABLE_REDIRECTION"
!macro _ENABLE_REDIRECTION
	!ifdef SYSTEMWIDE_DISABLEREDIR
		!ifdef FORCE_SYSTEMWIDE_DISABLEREDIR
			IntCmp $Bit 64 0 +2 +2
			System::Call `${ENABLEREDIR}`
		!else
			StrCmpS $APP ${APP64} 0 +2
			System::Call `${ENABLEREDIR}`
		!endif
	!endif
!macroend
