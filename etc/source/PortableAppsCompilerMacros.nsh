;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; PortableAppsCompilerMacros.nsh
; This file declares and defines all the macros for use with PortableApps Compiler.
; 

; 
; ${ReadAppInfoConfig}
; Reads a key from AppInfo.ini for a value.
; 
!define ReadAppInfoConfig "!insertmacro _ReadAppInfoConfig"
!macro _ReadAppInfoConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} "${INFOINI}" "${_SECTION}" "${_KEY}"
!macroend
; 
; ${WriteAppInfoConfig}
; Writes a value to a key in AppInfo.ini.
; 
!define WriteAppInfoConfig "!insertmacro _WriteAppInfoConfig"
!macro _WriteAppInfoConfig _SECTION _KEY _VALUE
	WriteINIStr "${INFOINI}" "${_SECTION}" "${_KEY}" "${_VALUE}"
!macroend
; 
; ${DeleteAppInfoConfig}
; Deletes a key from AppInfo.ini.
; 
!define DeleteAppInfoConfig "!insertmacro _DeleteAppInfoConfig"
!macro _DeleteAppInfoConfig _SECTION _KEY
	DeleteINIStr "${INFOINI}" "${_SECTION}" "${_KEY}"
!macroend
; 
; ${DeleteAppInfoConfigSec}
; Deletes a section from AppInfo.ini.
; 
!define DeleteAppInfoConfigSec "!insertmacro _DeleteAppInfoConfigSec"
!macro _DeleteAppInfoConfigSec _SECTION
	DeleteINISec "${INFOINI}" "${_SECTION}"
!macroend
; 
; ${ReadWrapperConfig}
; Reads a key in Wrapper.ini for a value.
; 
!define ReadWrapperConfig "!insertmacro _ReadWrapperConfig"
!macro _ReadWrapperConfig _VALUE _SECTION _KEY
	ReadINIStr ${_VALUE} "${WRAPPER}" "${_SECTION}" "${_KEY}"
!macroend
; 
; ${WriteWrapperConfig}
; Writes a value to a key in Wrapper.ini.
; 
!define WriteWrapperConfig "!insertmacro _WriteWrapperConfig"
!macro _WriteWrapperConfig _SECTION _KEY _VALUE
	WriteINIStr "${WRAPPER}" "${_SECTION}" "${_KEY}" "${_VALUE}"
!macroend
; 
; ${DeleteWrapperConfig}
; Deletes a key from Wrapper.ini.
; 
!define DeleteWrapperConfig "!insertmacro _DeleteWrapperConfig"
!macro _DeleteWrapperConfig _SECTION _KEY
	DeleteINIStr "${WRAPPER}" "${_SECTION}" "${_KEY}"
!macroend
; 
; ${DeleteWrapperConfigSec}
; Deletes a section from Wrapper.ini.
; 
!define DeleteWrapperConfigSec "!insertmacro _DeleteWrapperConfigSec"
!macro _DeleteWrapperConfigSec _SECTION
	DeleteINISec "${WRAPPER}" "${_SECTION}"
!macroend
; 
; ${ReadWrapperConfigWithDefault}
; Reads a key in Wrapper.ini for a value. 
; If it doesn't exist, defaults to a specified value.
; 
!define ReadWrapperConfigWithDefault "!insertmacro _ReadWrapperConfigWithDefault"
!macro _ReadWrapperConfigWithDefault _VALUE _SECTION _KEY _DEFAULT
	ClearErrors
	${ReadWrapperConfig} ${_VALUE} "${_SECTION}" "${_KEY}"
	${IfThen} ${Errors} ${|} StrCpy ${_VALUE} "${_DEFAULT}" ${|}
!macroend
; 
; ${ReadUserConfig}
; Reads a key from the user configuration file for a value.
; 
!define ReadUserConfig "!insertmacro _ReadUserConfig"
!macro _ReadUserConfig _VALUE _KEY
	${ConfigReadS} "${CONFIG}" "${_KEY}=" "${_VALUE}"
!macroend
; 
; ${WriteUserConfig}
; Writes a value to a key in the user configuration file.
; 
!define WriteUserConfig "!insertmacro _WriteUserConfig"
!macro _WriteUserConfig _VALUE _KEY
	${ConfigWriteS} "${CONFIG}" "${_KEY}=" "${_VALUE}" $R0
!macroend
; 
; ${InvalidValueError}
; Alerts the user if there is an invalid value used in an INI file.
; 
!define InvalidValueError "!insertmacro _InvalidValueError"
!macro _InvalidValueError _SECTION_KEY _VALUE
	MessageBox MB_OK|MB_ICONSTOP "ERROR: Invalid value '${_VALUE}' for ${_SECTION_KEY}."
!macroend
; 
; ${WriteRuntimeData}
; Writes a value to a key in both runtime INI files.
; 
!define WriteRuntimeData "!insertmacro _WriteRuntimeData"
!macro _WriteRuntimeData _SECTION _KEY _VALUE
	WriteINIStr "${RUNTIME}" "${_SECTION}" "${_KEY}" "${_VALUE}"
	WriteINIStr "${RUNTIME2}" "${_SECTION}" "${_KEY}" "${_VALUE}"
!macroend
; 
; ${DeleteRuntimeData}
; Deletes a key from both runtime INI files.
; 
!define DeleteRuntimeData "!insertmacro _DeleteRuntimeData"
!macro _DeleteRuntimeData _SECTION _KEY
	DeleteINIStr "${RUNTIME}" "${_SECTION}" "${_KEY}"
	DeleteINIStr "${RUNTIME2}" "${_SECTION}" "${_KEY}"
!macroend
; 
; ${ReadRuntimeData}
; Reads a key from one or the other runtime INI files for a value.
; 
!define ReadRuntimeData "!insertmacro _ReadRuntimeData"
!macro _ReadRuntimeData _VALUE _SECTION _KEY
	IfFileExists "${RUNTIME}" 0 +3
	ReadINIStr "${_VALUE}" "${RUNTIME}" "${_SECTION}" "${_KEY}"
	Goto +2
	ReadINIStr "${_VALUE}" "${RUNTIME2}" "${_SECTION}" "${_KEY}"
!macroend
; 
; ${WriteRuntime}
; Writes a value to a key in both runtime INI files.
; Writes values to the [PortableAppsCompiler] section.
; 
!define WriteRuntime "!insertmacro _WriteRuntime"
!macro _WriteRuntime _VALUE _KEY
	WriteINIStr "${RUNTIME}" ${PAC} "${_KEY}" "${_VALUE}"
	WriteINIStr "${RUNTIME2}" ${PAC} "${_KEY}" "${_VALUE}"
!macroend
; 
; ${ReadRuntime}
; Reads a key from one or the other runtime INI files for a value.
; Reads keys from the [PortableAppsCompiler] section.
; 
!define ReadRuntime "!insertmacro _ReadRuntime"
!macro _ReadRuntime _VALUE _KEY
	IfFileExists "${RUNTIME}" 0 +3
	ReadINIStr "${_VALUE}" "${RUNTIME}" ${PAC} "${_KEY}"
	Goto +2
	ReadINIStr "${_VALUE}" "${RUNTIME2}" ${PAC} "${_KEY}"
!macroend
; 
; ${WriteSettings}
; Writes a value to a key in the portable settings INI file.
; 
!define WriteSettings "!insertmacro _WriteSettings"
!macro _WriteSettings _VALUE _KEY
	WriteINIStr "${SETINI}" "${APPNAME}Settings" "${_KEY}" "${_VALUE}"
!macroend
; 
; ${ReadSettings}
; Reads a key from the portable settings INI file for a value.
; 
!define ReadSettings "!insertmacro _ReadSettings"
!macro _ReadSettings _VALUE _KEY
	ReadINIStr "${_VALUE}" "${SETINI}" "${APPNAME}Settings" "${_KEY}"
!macroend
; 
; ${DeleteSettings}
; Deletes a key from the portable settings INI file.
; 
!define DeleteSettings "!insertmacro _DeleteSettings"
!macro _DeleteSettings _KEY
	DeleteINIStr "${SETINI}" "${APPNAME}Settings" "${_KEY}"
!macroend
; 
; ${DISABLE_REDIRECTION}
; Disables filesystem redirection.
; 
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
; 
; ${ENABLE_REDIRECTION}
; Enables filesystem redirection.
; 
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
;
; ${InsertMacroIfExists}
; Inserts a defined macro if it exists.
;
!define InsertMacroIfExists "!insertmacro _InsertMacroIfExists"
!macro _InsertMacroIfExists _MACRO
	!ifmacrodef ${_MACRO}
		!insertmacro ${_MACRO}
	!endif
!macroend
