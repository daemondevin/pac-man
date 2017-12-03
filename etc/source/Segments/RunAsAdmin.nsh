;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   RunAsAdmin.nsh
;   This file enables support for executing the wrapper with administrative rights. 
; 

!macro CaseUACCodeAlert CODE FORCEMESSAGE TRYMESSAGE
	!if "${CODE}" == ""
		${Default}
	!else
		${Case} "${CODE}"
	!endif
		StrCmpS $RunAsAdmin force 0 +3
		MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST "${FORCEMESSAGE}"
		Quit
		MessageBox MB_OK|MB_ICONINFORMATION|MB_TOPMOST "${TRYMESSAGE}"
	${Break}
!macroend
!define CaseUACCodeAlert "!insertmacro CaseUACCodeAlert"
!macro RunAsAdmin_OSOverride OS
	${If} ${IsWin${OS}}
		ClearErrors
		${ReadWrapperConfig} $0 Launch RunAsAdmin${OS}
		${If} $0 == force
		${OrIf} $0 == try
			StrCpy $RunAsAdmin $0
		${ElseIfNot} ${Errors}
			${InvalidValueError} [Launch]:RunAsAdmin${OS} $0
		${EndIf}
	${EndIf}
!macroend

${SegmentFile}
${Segment.onInit}
	!ifmacrodef CustomOverride
		!insertmacro CustomOverride
	!endif
	!ifmacrodef RunAsAdmin
		!insertmacro RunAsAdmin
	!else
			ClearErrors
			${ReadWrapperConfig} $RunAsAdmin Launch RunAsAdmin
		!ifdef RUNASADMIN_COMPILEFORCE
			IfErrors +2
			StrCmpS $RunAsAdmin compile-force +2
			MessageBox MB_OK|MB_ICONSTOP "To turn off compile-time RunAsAdmin, you must regenerate the launcher."
		!else
			${IfNot} ${Errors}
			${AndIf} $RunAsAdmin != force
			${AndIf} $RunAsAdmin != try
				${If} $RunAsAdmin == compile-force
					MessageBox MB_OK|MB_ICONSTOP "To use [Launch]:RunAsAdmin=compile-force, you must regenerate the launcher. Continuing with 'force'."
					StrCpy $RunAsAdmin force
				${Else}
					${InvalidValueError} [Launch]:RunAsAdmin $RunAsAdmin
				${EndIf}
			${EndIf}
			!insertmacro RunAsAdmin_OSOverride 2000
			!insertmacro RunAsAdmin_OSOverride XP
			!insertmacro RunAsAdmin_OSOverride 2003
			!insertmacro RunAsAdmin_OSOverride Vista
			!insertmacro RunAsAdmin_OSOverride 2008
			!insertmacro RunAsAdmin_OSOverride 7
			!insertmacro RunAsAdmin_OSOverride 2008R2
			${If} $RunAsAdmin == force
			${OrIf} $RunAsAdmin == try
				Elevate:
				!insertmacro UAC_RunElevated
				${Switch} $0
					${Case} 0
						StrCmpS $1 1 0 +2
						Quit
						${If} $3 <> 0
							${Break}
						${EndIf}
						StrCmpS $1 3 0 +6
						StrCmpS $RunAsAdmin force 0 +3
						MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION|MB_TOPMOST \ 
						"$(LauncherRequiresAdmin)$\r$\n$\r$\n$(LauncherNotAdminTryAgain)" IDRETRY Elevate
						Quit
						MessageBox MB_ABORTRETRYIGNORE|MB_ICONEXCLAMATION|MB_TOPMOST \ 
						"$(LauncherNotAdminLimitedFunctionality)$\r$\n$\r$\n$(LauncherNotAdminLimitedFunctionalityTryAgain)" \ 
						IDRETRY Elevate IDIGNORE RunAsAdminEnd
						Quit
					${CaseUACCodeAlert} 1223 \
						"$(LauncherRequiresAdmin)" \
						"$(LauncherNotAdminLimitedFunctionality)"
					${CaseUACCodeAlert} 1062 \
						"$(LauncherAdminLogonServiceNotRunning)" \
						"$(LauncherNotAdminLimitedFunctionality)"
					${CaseUACCodeAlert} "" \
						"$(LauncherAdminError)$\r$\n$(LauncherRequiresAdmin)" \
						"$(LauncherAdminError)$\r$\n$(LauncherNotAdminLimitedFunctionality)"
				${EndSwitch}
				RunAsAdminEnd:
			${EndIf}
		!endif
	!endif
	!ifmacrodef UnRunAsAdmin
		!insertmacro UnRunAsAdmin
	!endif
!macroend
