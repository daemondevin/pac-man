;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
;   RunAsAdmin.nsh
;   This file enables support for executing the launcher with administrative rights. 
;
; VALID VALUES FOR [Launch]:RunAsAdmin
;   force        — Admin is required. Launcher will retry or quit if elevation fails.
;   try          — Admin is requested. Launcher continues without it if elevation fails.
;   prompt       — Admin is optional but beneficial. User is asked before elevation is
;                  attempted. Declining skips elevation entirely; the app still launches.
;                  If user accepts but elevation fails, behaviour falls back to try-mode.
;   compile-force — Admin is forced at compile time. Requires regenerating the launcher
;                  to remove. Emits an error if set at runtime without a matching build.
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

; NOTE: prompt is a valid OS-override value. When set via [Launch]:RunAsAdminXP (etc.),
; it overrides the base RunAsAdmin value for that specific Windows version only.
!macro RunAsAdmin_OSOverride OS
	${If} ${IsWin${OS}}
		ClearErrors
		${ReadLauncherConfig} $0 Launch RunAsAdmin${OS}
		${If} $0 == force
		${OrIf} $0 == try
		${OrIf} $0 == prompt
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
			${ReadLauncherConfig} $RunAsAdmin Launch RunAsAdmin
		!ifdef RUNASADMIN_COMPILEFORCE
			IfErrors +2
			StrCmpS $RunAsAdmin compile-force +2
			MessageBox MB_OK|MB_ICONSTOP "To turn off compile-time RunAsAdmin, you must regenerate the launcher."
		!else
			${IfNot} ${Errors}
			${AndIf} $RunAsAdmin != force
			${AndIf} $RunAsAdmin != try
			${AndIf} $RunAsAdmin != prompt
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
			${OrIf} $RunAsAdmin == prompt
				;=# PROMPT MODE
				; When RunAsAdmin=prompt the user is asked whether they want elevation
				; before anything is attempted. Two outcomes:
				;
				;   No  → Jump straight to RunAsAdminEnd. UAC is never triggered.
				;          The app launches in the current (user-level) context.
				;
				;   Yes → $RunAsAdmin is rewritten to "try" so that the existing
				;          elevation flow handles all UAC return codes without change:
				;          success elevates normally; any failure is non-fatal and the
				;          app continues without admin, consistent with try semantics.
				;          Other segments that inspect $RunAsAdmin after .onInit will
				;          see "try", which is the correct post-decision state.
				${If} $RunAsAdmin == prompt
                    ${ConfigReads} `${CONFIG}` PromptAdmin= $0
                    StrCmpS $0 false RunAsAdminEnd  ; opt-out: skip prompt and launch normally
                    MessageBox MB_YESNO|MB_ICONQUESTION|MB_TOPMOST "$(LauncherAdminOptionalPrompt)" IDNO RunAsAdminEnd
                    StrCpy $RunAsAdmin try
                ${EndIf}
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
