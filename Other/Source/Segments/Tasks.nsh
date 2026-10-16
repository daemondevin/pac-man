;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Tasks.nsh
;   Session-bound Windows scheduled tasks, journaled so none of them outlive
;   the app, even after a crash.
;
; USAGE
;   [Activate]
;   Tasks=true
;
;   Tasks the app itself creates while it runs:
;
;   [TaskCleanup]
;   1=MyAppTask1
;   2=Another Task w/ Spaces
;
;   Each name is checked before the app starts. A task that does not exist
;   yet is deleted again when the app exits (or on the next launch after a
;   crash). A task that already existed is somebody else's and is left alone.
;
;   Tasks the launcher creates for as long as the app runs:
;
;   [ScheduledTask1]
;   Name=MyAppMaintenance
;   Command=%PAL:AppDir%\MyApp\maintenance.exe
;   Arguments=--cleanup --temp
;   Schedule=DAILY
;   StartTime=02:00
;
;   Name        Task name, optionally with a folder (\Vendor\Task). Required.
;   Command     Program to run. Supports %PAL:...% and environment variables.
;   Arguments   Command line arguments (optional).
;   Schedule    ONCE, MINUTE, HOURLY, DAILY, WEEKLY, MONTHLY, ONIDLE,
;               ONSTART or ONLOGON. Required.
;   Modifier    Repeat interval (/MO), e.g. 15 with MINUTE.
;   Days        Days for WEEKLY/MONTHLY (/D), e.g. MON,FRI or 1,15.
;   Months      Months for MONTHLY (/M), e.g. JAN,JUL.
;   StartTime   HH:mm (/ST).
;   StartDate   /SD, in the date format of the Windows locale.
;   EndDate     /ED, same format.
;   IdleTime    Minutes for ONIDLE (/I).
;   RunAsUser   SYSTEM, or omit for the current user. Other accounts would
;               need a password in Launcher.ini, which is not supported.
;   RunLevel    LIMITED (default) or HIGHEST.
;   Enabled     true (default) or false.
;   RunNow      true to run the task once right after it is created.
;   IfExists    skip (default) leaves an existing task with that name alone.
;               replace exports it (PowerShell Export-ScheduledTask), replaces
;               it and re-creates the original on exit. Tasks that store a
;               password cannot be re-created without it and are skipped.
;   Required    true to warn when the task cannot be created.
;
;   SYSTEM and HIGHEST need administrator rights; without them the task is
;   skipped and one warning is shown.
;
; HOW IT IS UNDONE
;   A TASK entry is journaled before every create: it deletes the task if it
;   exists and, for a replaced task, re-creates the exported original.
;

!ifdef SEGMENTS_TASKS

!define TASKS_EXE `"$SYSDIR\schtasks.exe"`

Var TaskName
Var TaskArgs
Var TaskBackup
Var TaskAdminFlag
Var TaskRequired
Var TaskWarned

;= HELPERS
;= ################

; Reads [ScheduledTask$R0] key _KEY into _VAR, strips one pair of quotes and
; expands variables.
!macro _Task_Read _VAR _KEY
	${ReadLauncherConfig} ${_VAR} ScheduledTask$R0 `${_KEY}`
	StrCpy $_JT1 ${_VAR} 1
	${If} $_JT1 == `"`
		StrCpy $_JT1 ${_VAR} "" -1
		${If} $_JT1 == `"`
			StrCpy ${_VAR} ${_VAR} -1 1
		${EndIf}
	${EndIf}
	ExpandEnvStrings ${_VAR} ${_VAR}
!macroend
!define Task_Read `!insertmacro _Task_Read`

; Sets $_JT4 to 1 when task $TaskName exists.
Function Task_Exists
	Push $0
	Push $1
	nsExec::ExecToStack `${TASKS_EXE} /Query /TN "$TaskName"`
	Pop $0
	Pop $1
	${If} $0 == 0
		StrCpy $_JT4 1
	${Else}
		StrCpy $_JT4 0
	${EndIf}
	Pop $1
	Pop $0
FunctionEnd

; Escapes every " in $TaskArgs as \" for schtasks /TR.
Function Task_EscapeQuotes
	Push $0
	Push $1
	Push $2
	StrCpy $2 ""
	StrCpy $0 0
	${Do}
		StrCpy $1 $TaskArgs 1 $0
		${IfThen} $1 == "" ${|} ${ExitDo} ${|}
		${If} $1 == `"`
			StrCpy $2 `$2\"`
		${Else}
			StrCpy $2 `$2$1`
		${EndIf}
		IntOp $0 $0 + 1
	${Loop}
	StrCpy $TaskArgs $2
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Exports task $TaskName to the journal store as UTF-16 XML. Sets
; $TaskBackup to the file, or to "" when the task could not be exported or
; stores a password (and so could not be re-created from the export).
Function Task_Export
	Push $0
	Push $1
	Push $2
	Push $3
	; Split "\Folder\Name" into the path and the leaf name.
	StrCpy $2 "\"
	StrCpy $3 $TaskName
	StrLen $0 $TaskName
	${Do}
		IntOp $0 $0 - 1
		${IfThen} $0 < 0 ${|} ${ExitDo} ${|}
		StrCpy $1 $TaskName 1 $0
		${If} $1 == "\"
			StrCpy $2 $TaskName $0
			StrCpy $2 `$2\`
			${IfThen} $2 == "\\" ${|} StrCpy $2 "\" ${|}
			IntOp $0 $0 + 1
			StrCpy $3 $TaskName "" $0
			${ExitDo}
		${EndIf}
	${Loop}
	CreateDirectory `${JOURNAL_STORE}\Tasks`
	System::Call `kernel32::GetTickCount()i.r0`
	StrCpy $TaskBackup `${JOURNAL_STORE}\Tasks\$0-$R0.xml`
	Delete $TaskBackup
	nsExec::ExecToStack `"$SYSDIR\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command "Export-ScheduledTask -TaskPath '$2' -TaskName '$3' | Out-File -Encoding Unicode -FilePath '$TaskBackup'"`
	Pop $0
	Pop $1
	${IfNot} ${FileExists} $TaskBackup
		${DebugMsg} "Could not export task $TaskName ($0):$\r$\n$1"
		StrCpy $TaskBackup ""
	${Else}
		; A task that logs on with a stored password can't be re-created
		; from its XML without that password, so don't replace it.
		ClearErrors
		FileOpen $0 $TaskBackup r
		${Do}
			ClearErrors
			FileReadUTF16LE $0 $1
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			StrCpy $_JT1 $1
			StrCpy $_JT2 "<LogonType>Password<"
			Call Journal_Contains
			${If} $_JT4 != 1
				StrCpy $_JT2 "<LogonType>InteractiveTokenOrPassword<"
				Call Journal_Contains
			${EndIf}
			${If} $_JT4 == 1
				FileClose $0
				Delete $TaskBackup
				StrCpy $TaskBackup ""
				${DebugMsg} "Task $TaskName stores a password; it is not replaced."
				Goto task_export_done
			${EndIf}
		${Loop}
		FileClose $0
	${EndIf}
	task_export_done:
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Creates [ScheduledTask$R0].
Function Task_Create
	Push $0
	Push $1
	Push $2
	Push $3

	${Task_Read} $TaskName Name
	${Task_Read} $0 Command
	${ReadLauncherConfig} $1 ScheduledTask$R0 Schedule
	${ReadLauncherConfig} $TaskRequired ScheduledTask$R0 Required
	${If} $TaskName == ""
	${OrIf} $0 == ""
		${InvalidValueError} [ScheduledTask$R0] "Name and Command are required"
		Goto task_done
	${EndIf}
	${NewStrCase} $1 $1 U
	StrCpy $_JT1 "|ONCE|MINUTE|HOURLY|DAILY|WEEKLY|MONTHLY|ONIDLE|ONSTART|ONLOGON|"
	StrCpy $_JT2 "|$1|"
	Call Journal_Contains
	${If} $_JT4 != 1
		${InvalidValueError} [ScheduledTask$R0]:Schedule $1
		Goto task_done
	${EndIf}

	; The task's command line: "Command" Arguments, quotes escaped as \".
	${Task_Read} $TaskArgs Arguments
	${If} $TaskArgs == ""
		StrCpy $TaskArgs `"$0"`
	${Else}
		StrCpy $TaskArgs `"$0" $TaskArgs`
	${EndIf}
	Call Task_EscapeQuotes
	StrCpy $2 `/TN "$TaskName" /TR "$TaskArgs" /SC $1`

	${ReadLauncherConfig} $0 ScheduledTask$R0 Modifier
	${IfThen} $0 != "" ${|} StrCpy $2 `$2 /MO $0` ${|}
	${ReadLauncherConfig} $0 ScheduledTask$R0 Days
	${IfThen} $0 != "" ${|} StrCpy $2 `$2 /D $0` ${|}
	${ReadLauncherConfig} $0 ScheduledTask$R0 Months
	${IfThen} $0 != "" ${|} StrCpy $2 `$2 /M $0` ${|}
	${ReadLauncherConfig} $0 ScheduledTask$R0 StartTime
	${IfThen} $0 != "" ${|} StrCpy $2 `$2 /ST $0` ${|}
	${ReadLauncherConfig} $0 ScheduledTask$R0 StartDate
	${IfThen} $0 != "" ${|} StrCpy $2 `$2 /SD $0` ${|}
	${ReadLauncherConfig} $0 ScheduledTask$R0 EndDate
	${IfThen} $0 != "" ${|} StrCpy $2 `$2 /ED $0` ${|}
	${ReadLauncherConfig} $0 ScheduledTask$R0 IdleTime
	${IfThen} $0 != "" ${|} StrCpy $2 `$2 /I $0` ${|}

	StrCpy $TaskAdminFlag ""
	${ReadLauncherConfig} $0 ScheduledTask$R0 RunAsUser
	${If} $0 != ""
		${NewStrCase} $0 $0 U
		${If} $0 != SYSTEM
			${InvalidValueError} [ScheduledTask$R0]:RunAsUser "$0 (only SYSTEM or the current user)"
			Goto task_done
		${EndIf}
		StrCpy $2 `$2 /RU SYSTEM`
		StrCpy $TaskAdminFlag admin
	${EndIf}
	${ReadLauncherConfig} $0 ScheduledTask$R0 RunLevel
	${If} $0 != ""
		${NewStrCase} $0 $0 U
		${If} $0 == HIGHEST
			StrCpy $2 `$2 /RL HIGHEST`
			StrCpy $TaskAdminFlag admin
		${ElseIf} $0 != LIMITED
			${InvalidValueError} [ScheduledTask$R0]:RunLevel $0
			Goto task_done
		${EndIf}
	${EndIf}
	${If} $TaskAdminFlag == admin
	${AndIf} $Admin != true
		; Fail closed: without admin rights it couldn't be removed again.
		${If} $TaskWarned == ""
			StrCpy $TaskWarned true
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"${PORTABLEAPPNAME} needs administrator rights for scheduled tasks that run as SYSTEM or with highest privileges.$\r$\nThose tasks were not created."
		${EndIf}
		Goto task_done
	${EndIf}

	; An existing task: leave it, or export it so it can be put back.
	StrCpy $TaskBackup ""
	Call Task_Exists
	${If} $_JT4 == 1
		${ReadLauncherConfigWithDefault} $0 ScheduledTask$R0 IfExists skip
		${NewStrCase} $0 $0 L
		${If} $0 != replace
			${DebugMsg} "Task $TaskName already exists; left alone."
			Goto task_done
		${EndIf}
		Call Task_Export
		${If} $TaskBackup == ""
			${If} $TaskRequired == true
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"The scheduled task $TaskName already exists and could not be backed up, so it was not replaced."
			${EndIf}
			Goto task_done
		${EndIf}
		StrCpy $2 `$2 /F`
	${EndIf}

	; Journal before mutation.
	${Journal::Record} Tasks TASK $TaskName $TaskBackup $TaskAdminFlag ""
	nsExec::ExecToStack `${TASKS_EXE} /Create $2`
	Pop $0
	Pop $1
	${If} $0 != 0
		${DebugMsg} "schtasks /Create failed ($0):$\r$\n$1"
		; Nothing changed when the create failed, so a replaced task is
		; still the original.
		${Journal::Discard} Tasks
		${If} $TaskBackup != ""
			Delete $TaskBackup
		${EndIf}
		${If} $TaskRequired == true
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"Could not create the scheduled task $TaskName.$\r$\n$\r$\n$1"
		${EndIf}
		Goto task_done
	${EndIf}
	${DebugMsg} "Created scheduled task $TaskName."

	${ReadLauncherConfig} $0 ScheduledTask$R0 Enabled
	${If} $0 == false
		nsExec::ExecToStack `${TASKS_EXE} /Change /TN "$TaskName" /DISABLE`
		Pop $0
		Pop $1
	${EndIf}
	${ReadLauncherConfig} $0 ScheduledTask$R0 RunNow
	${If} $0 == true
		nsExec::ExecToStack `${TASKS_EXE} /Run /TN "$TaskName"`
		Pop $0
		Pop $1
	${EndIf}

	task_done:
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

${SegmentFile}

${SegmentPrePrimary}
	; Tasks the app may create: only the ones that don't exist yet are ours.
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $TaskName TaskCleanup $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${If} $TaskName != ""
			Call Task_Exists
			${If} $_JT4 == 1
				${DebugMsg} "[TaskCleanup] $TaskName existed before launch; it will be left alone."
			${Else}
				${Journal::Record} Tasks TASK $TaskName "" "" ""
			${EndIf}
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}

	; Tasks the launcher creates.
	StrCpy $TaskWarned ""
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 ScheduledTask$R0 Name
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		Call Task_Create
		IntOp $R0 $R0 + 1
	${Loop}
!macroend

${SegmentPostPrimary}
	${Journal::HasEntries} Tasks $R0
	${If} $R0 > 0
		${Journal::Rollback} Tasks
	${EndIf}
!macroend

!endif ; SEGMENTS_TASKS
