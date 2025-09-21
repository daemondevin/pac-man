;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; TaskScheduler.nsh
;   This file handles Windows scheduled tasks with creation, management,
;   and restoration capabilities for portable applications.
; 
; USAGE
;	Add sections [ScheduledTask1], [ScheduledTask2] etc. to Launcher.ini
;
;	ScheduledTask Keys:
;	Name			-	Task name (unique identifier)
;	Command			-	Command/program to execute (supports %PAL:* variables)
;	Arguments		-	Command line arguments (optional)
;	WorkingDir		-	Working directory (optional)
;	Schedule		-	ONCE, MINUTE, HOURLY, DAILY, WEEKLY, MONTHLY, ONIDLE, ONSTART, ONLOGON, ONEVENT
;	Modifier		-	Schedule modifier (depends on schedule type)
;	StartTime		-	Start time (HH:MM format)
;	StartDate		-	Start date (MM/DD/YYYY format, optional)
;	EndDate			-	End date (MM/DD/YYYY format, optional)
;	RunAsUser		-	SYSTEM, current user, or specific username
;	Password		-	Password for specified user (if not SYSTEM)
;	RunLevel		-	HIGHEST, LIMITED (run with highest privileges or not)
;	IfExists		-	skip, backup, replace
;	Enabled			-	true/false (task enabled state)
;	Hidden			-	true/false (task visible in Task Scheduler UI)
;	Required		-	true/false (show error if creation fails)
;	Description		-	Task description
;	IdleTime		-	Idle time in minutes (for ONIDLE schedule)
;	StopOnIdle		-	true/false (stop task when computer not idle)
;	RestartOnIdle	-	true/false (restart task when idle resumes)
;
;	Schedule Modifiers:
;	- MINUTE: 1-1439 (every N minutes)
;	- HOURLY: 1-23 (every N hours)  
;	- DAILY: 1-365 (every N days)
;	- WEEKLY: 1-52 (every N weeks), can specify days: MON,TUE,WED,THU,FRI,SAT,SUN
;	- MONTHLY: 1-12 (months) or specific months: JAN,FEB,MAR,etc.
;
; EXAMPLE
;	[ScheduledTask1]
;	Name=MyAppMaintenance
;	Command=%PAL:AppDir%\maintenance.exe
;	Arguments=--cleanup --temp
;	Schedule=DAILY
;	StartTime=02:00
;	RunAsUser=SYSTEM
;	IfExists=replace
;	Enabled=true
;	Description=Daily maintenance for MyApp
;	Required=true
;

!ifdef TASKSCHEDULER
${IncludeIfNotDefined} LOGICLIB LogicLib.nsh
${IncludeIfNotDefined} WORDREPLACE_NSH_INCLUDED WordReplace.nsh
${IncludeIfNotDefined} STR_LOC_NSH_INCLUDED StrLoc.nsh

; SCHTASKS command path
${DefineIfNotDefined} SCHTASKS `$SYSDIR\schtasks.exe`

; Task priority constants
${DefineIfNotDefined} TASK_PRIORITY_REALTIME 256
${DefineIfNotDefined} TASK_PRIORITY_HIGH 128
${DefineIfNotDefined} TASK_PRIORITY_ABOVE_NORMAL 128
${DefineIfNotDefined} TASK_PRIORITY_NORMAL 32
${DefineIfNotDefined} TASK_PRIORITY_BELOW_NORMAL 16384
${DefineIfNotDefined} TASK_PRIORITY_IDLE 64

; Check if scheduled task exists
!define Task::Exists `!insertmacro _Task::Exists`
!macro _Task::Exists _TASKNAME _RESULT _STATUS _NEXTRUN
	Push $0
	Push $1
	Push $2
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_STATUS} ""
	StrCpy ${_NEXTRUN} ""
	
	; Query task using SCHTASKS
	ExecDos::Exec /TOSTACK `"${SCHTASKS}" /Query /TN "${_TASKNAME}" /FO LIST /V`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		StrCpy ${_RESULT} "true"
		
		; Parse output to get status
		${StrLoc} $R8 "$1" "Status:" ">"
		${If} $R8 != ""
			StrCpy $2 $1 "" $R8
			${WordFind} "$2" "$\n" "1{" $2
			${WordFind} "$2" ":" "2{" $2
			${Trim} $2 $2
			StrCpy ${_STATUS} "$2"
		${EndIf}
		
		; Parse next run time
		${StrLoc} $R8 "$1" "Next Run Time:" ">"
		${If} $R8 != ""
			StrCpy $2 $1 "" $R8
			${WordFind} "$2" "$\n" "1{" $2
			${WordFind} "$2" ":" "+2{" $2
			${Trim} $2 $2
			StrCpy ${_NEXTRUN} "$2"
		${EndIf}
		
		${DebugMsg} "Scheduled task exists: ${_TASKNAME} (Status: ${_STATUS})"
	${Else}
		${DebugMsg} "Scheduled task does not exist: ${_TASKNAME}"
	${EndIf}
	
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Create scheduled task
!define Task::Create `!insertmacro _Task::Create`
!macro _Task::Create _TASKNAME _COMMAND _ARGS _WORKDIR _SCHEDULE _MODIFIER _STARTTIME _STARTDATE _ENDDATE _USER _PASSWORD _RUNLEVEL _ENABLED _HIDDEN _DESCRIPTION _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_COMMAND}" $R8
	
	; Validate command exists
	${IfNot} ${FileExists} "$R8"
		StrCpy ${_ERROR} "Command file not found: $R8"
		${DebugMsg} "Command not found: $R8"
		Goto TaskCreateEnd
	${EndIf}
	
	${DebugMsg} "Creating scheduled task: ${_TASKNAME}"
	
	; Build SCHTASKS CREATE command
	StrCpy $0 `"${SCHTASKS}" /Create /TN "${_TASKNAME}" /TR "$R8"`
	
	; Add arguments if specified
	${If} "${_ARGS}" != ""
		${ParseLocations} "${_ARGS}" $1
		StrCpy $0 `$0 $1`
	${EndIf}
	
	; Add schedule
	StrCpy $0 `$0 /SC ${_SCHEDULE}`
	
	; Add modifier if specified
	${If} "${_MODIFIER}" != ""
		StrCpy $0 `$0 /MO ${_MODIFIER}`
	${EndIf}
	
	; Add start time
	${If} "${_STARTTIME}" != ""
		StrCpy $0 `$0 /ST ${_STARTTIME}`
	${EndIf}
	
	; Add start date
	${If} "${_STARTDATE}" != ""
		StrCpy $0 `$0 /SD ${_STARTDATE}`
	${EndIf}
	
	; Add end date
	${If} "${_ENDDATE}" != ""
		StrCpy $0 `$0 /ED ${_ENDDATE}`
	${EndIf}
	
	; Add user account
	${If} "${_USER}" != ""
	${AndIf} "${_USER}" != "current"
		StrCpy $0 `$0 /RU "${_USER}"`
		
		; Add password if specified and not SYSTEM
		${If} "${_PASSWORD}" != ""
		${AndIf} "${_USER}" != "SYSTEM"
		${AndIf} "${_USER}" != "NT AUTHORITY\SYSTEM"
			StrCpy $0 `$0 /RP "${_PASSWORD}"`
		${EndIf}
	${EndIf}
	
	; Add run level
	${If} "${_RUNLEVEL}" == "HIGHEST"
		StrCpy $0 `$0 /RL HIGHEST`
	${EndIf}
	
	; Add working directory
	${If} "${_WORKDIR}" != ""
		${ParseLocations} "${_WORKDIR}" $1
		StrCpy $0 `$0 /SD "$1"`
	${EndIf}
	
	; Add description
	${If} "${_DESCRIPTION}" != ""
		StrCpy $0 `$0 /DESC "${_DESCRIPTION}"`
	${EndIf}
	
	; Force creation (overwrite existing)
	StrCpy $0 "$0 /F"
	
	${DebugMsg} "Executing: $0"
	
	; Execute the command
	ExecDos::Exec /TOSTACK `$0`
	Pop $1 ; Return code
	Pop $2 ; Output
	
	${Switch} $1
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Scheduled task created successfully: ${_TASKNAME}"
			
			; Set enabled/disabled state
			${If} "${_ENABLED}" == "false"
				${Task::SetState} "${_TASKNAME}" "DISABLE" $R9 $3
			${EndIf}
			
			${Break}
		${Case} "1"
			StrCpy ${_ERROR} "Invalid syntax or parameters"
			${DebugMsg} "Failed to create task: Invalid syntax"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to create task (Error $1)"
			${DebugMsg} "Failed to create task ${_TASKNAME}: Error $1"
			${Break}
	${EndSwitch}
	
	TaskCreateEnd:
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Delete scheduled task
!define Task::Delete `!insertmacro _Task::Delete`
!macro _Task::Delete _TASKNAME _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${DebugMsg} "Deleting scheduled task: ${_TASKNAME}"
	
	ExecDos::Exec /TOSTACK `"${SCHTASKS}" /Delete /TN "${_TASKNAME}" /F`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${Switch} $0
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Scheduled task deleted successfully: ${_TASKNAME}"
			${Break}
		${Case} "1"
			StrCpy ${_ERROR} "Task not found or invalid syntax"
			${DebugMsg} "Task not found for deletion: ${_TASKNAME}"
			; Consider this success since the goal is achieved
			StrCpy ${_RESULT} "true"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to delete task (Error $0)"
			${DebugMsg} "Failed to delete task ${_TASKNAME}: Error $0"
			${Break}
	${EndSwitch}
	
	Pop $2
	Pop $1
	Pop $0
!macroend

; Set task state (enable/disable)
!define Task::SetState `!insertmacro _Task::SetState`
!macro _Task::SetState _TASKNAME _STATE _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${DebugMsg} "Setting task state: ${_TASKNAME} -> ${_STATE}"
	
	ExecDos::Exec /TOSTACK `"${SCHTASKS}" /Change /TN "${_TASKNAME}" /${_STATE}`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${Switch} $0
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Task state changed successfully: ${_TASKNAME}"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to change task state (Error $0)"
			${DebugMsg} "Failed to change task state ${_TASKNAME}: Error $0"
			${Break}
	${EndSwitch}
	
	Pop $2
	Pop $1
	Pop $0
!macroend

; Run scheduled task immediately
!define Task::Run `!insertmacro _Task::Run`
!macro _Task::Run _TASKNAME _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${DebugMsg} "Running scheduled task: ${_TASKNAME}"
	
	ExecDos::Exec /TOSTACK `"${SCHTASKS}" /Run /TN "${_TASKNAME}"`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${Switch} $0
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Task started successfully: ${_TASKNAME}"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to start task (Error $0)"
			${DebugMsg} "Failed to start task ${_TASKNAME}: Error $0"
			${Break}
	${EndSwitch}
	
	Pop $2
	Pop $1
	Pop $0
!macroend

; Backup scheduled task configuration
!define Task::Backup `!insertmacro _Task::Backup`
!macro _Task::Backup _TASKNAME _SECTION _KEY
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	
	; Export task to XML
	StrCpy $R8 "$TEMP\${_TASKNAME}_backup.xml"
	
	ExecDos::Exec /TOSTACK `"${SCHTASKS}" /Query /TN "${_TASKNAME}" /XML`
	Pop $0 ; Return code
	Pop $1 ; XML output
	
	${If} $0 == 0
		; Save XML to file
		FileOpen $2 "$R8" w
		${If} $2 != ""
			FileWrite $2 "$1"
			FileClose $2
			
			${WriteRuntimeData} ${_SECTION} "${_KEY}_XMLFile" "$R8"
			${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "true"
			${DebugMsg} "Backed up scheduled task: ${_TASKNAME}"
		${Else}
			${DebugMsg} "Failed to save task backup: ${_TASKNAME}"
		${EndIf}
	${Else}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "false"
		${DebugMsg} "Scheduled task ${_TASKNAME} did not exist"
	${EndIf}
	
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Restore scheduled task configuration
!define Task::Restore `!insertmacro _Task::Restore`
!macro _Task::Restore _TASKNAME _SECTION _KEY _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	
	StrCpy ${_RESULT} "false"
	
	${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_Existed"
	${If} ${Errors}
		${DebugMsg} "No backup found for task: ${_TASKNAME}"
		Goto TaskRestoreEnd
	${EndIf}
	
	${If} $0 == "true"
		; Restore from XML backup
		${ReadRuntimeData} $1 ${_SECTION} "${_KEY}_XMLFile"
		${IfNot} ${Errors}
			${If} ${FileExists} "$1"
				ExecDos::Exec /TOSTACK `"${SCHTASKS}" /Create /TN "${_TASKNAME}" /XML "$1" /F`
				Pop $2 ; Return code
				Pop $3 ; Output
				
				${If} $2 == 0
					StrCpy ${_RESULT} "true"
					${DebugMsg} "Restored scheduled task: ${_TASKNAME}"
				${Else}
					${DebugMsg} "Failed to restore task ${_TASKNAME}: Error $2"
				${EndIf}
				
				; Clean up backup file
				Delete "$1"
			${EndIf}
		${EndIf}
	${Else}
		; Task didn't exist originally, removal is success
		StrCpy ${_RESULT} "true"
		${DebugMsg} "Task ${_TASKNAME} did not exist originally"
	${EndIf}
	
	TaskRestoreEnd:
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check if user can manage scheduled tasks
!define Task::CanManage `!insertmacro _Task::CanManage`
!macro _Task::CanManage _RESULT
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "false"
	
	; Try to query tasks to test permissions
	ExecDos::Exec /TOSTACK `"${SCHTASKS}" /Query`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		StrCpy ${_RESULT} "true"
		${DebugMsg} "User can manage scheduled tasks"
	${Else}
		${DebugMsg} "User cannot manage scheduled tasks (insufficient privileges)"
	${EndIf}
	
	Pop $1
	Pop $0
!macroend

; Validate schedule parameters
!define Task::ValidateSchedule `!insertmacro _Task::ValidateSchedule`
!macro _Task::ValidateSchedule _SCHEDULE _MODIFIER _STARTTIME _RESULT _ERROR
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "true"
	StrCpy ${_ERROR} ""
	
	; Validate schedule type
	${Switch} "${_SCHEDULE}"
		${Case} "ONCE"
		${Case} "MINUTE"
		${Case} "HOURLY"
		${Case} "DAILY"
		${Case} "WEEKLY"
		${Case} "MONTHLY"
		${Case} "ONIDLE"
		${Case} "ONSTART"
		${Case} "ONLOGON"
		${Case} "ONEVENT"
			; Valid schedule types
			${Break}
		${Default}
			StrCpy ${_RESULT} "false"
			StrCpy ${_ERROR} "Invalid schedule type: ${_SCHEDULE}"
			Goto ValidateScheduleEnd
			${Break}
	${EndSwitch}
	
	; Validate start time format (HH:MM)
	${If} "${_STARTTIME}" != ""
		StrLen $0 "${_STARTTIME}"
		${If} $0 != 5
			StrCpy ${_RESULT} "false"
			StrCpy ${_ERROR} "Invalid time format: ${_STARTTIME} (use HH:MM)"
			Goto ValidateScheduleEnd
		${EndIf}
		
		StrCpy $1 "${_STARTTIME}" 1 2
		${If} $1 != ":"
			StrCpy ${_RESULT} "false"
			StrCpy ${_ERROR} "Invalid time format: ${_STARTTIME} (use HH:MM)"
			Goto ValidateScheduleEnd
		${EndIf}
	${EndIf}
	
	; Validate modifier based on schedule type
	${If} "${_MODIFIER}" != ""
		${Switch} "${_SCHEDULE}"
			${Case} "MINUTE"
				IntCmp "${_MODIFIER}" 1 0 ModifierError 0
				IntCmp "${_MODIFIER}" 1439 0 0 ModifierError
				${Break}
			${Case} "HOURLY"
				IntCmp "${_MODIFIER}" 1 0 ModifierError 0
				IntCmp "${_MODIFIER}" 23 0 0 ModifierError
				${Break}
			${Case} "DAILY"
				IntCmp "${_MODIFIER}" 1 0 ModifierError 0
				IntCmp "${_MODIFIER}" 365 0 0 ModifierError
				${Break}
			${Case} "WEEKLY"
				IntCmp "${_MODIFIER}" 1 0 ModifierError 0
				IntCmp "${_MODIFIER}" 52 0 0 ModifierError
				${Break}
		${EndSwitch}
	${EndIf}
	
	Goto ValidateScheduleEnd
	
	ModifierError:
		StrCpy ${_RESULT} "false"
		StrCpy ${_ERROR} "Invalid modifier for ${_SCHEDULE}: ${_MODIFIER}"
	
	ValidateScheduleEnd:
	Pop $1
	Pop $0
!macroend

; Get list of all tasks
!define Task::List `!insertmacro _Task::List`
!macro _Task::List _RESULT
	Push $0
	Push $1
	
	ExecDos::Exec /TOSTACK `"${SCHTASKS}" /Query /FO TABLE /NH`
	Pop $0 ; Return code
	Pop ${_RESULT} ; Task list
	
	${If} $0 == 0
		${DebugMsg} "Retrieved task list successfully"
	${Else}
		StrCpy ${_RESULT} ""
		${DebugMsg} "Failed to retrieve task list"
	${EndIf}
	
	Pop $1
	Pop $0
!macroend

; Generate scheduled tasks report
!define Task::GenerateReport `!insertmacro _Task::GenerateReport`
!macro _Task::GenerateReport _FILEPATH
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $R0
	
	FileOpen $0 "${_FILEPATH}" w
	${If} $0 != ""
		FileWrite $0 "Scheduled Tasks Report$\r$\n"
		FileWrite $0 "Generated: $DATE $TIME$\r$\n"
		FileWrite $0 "======================$\r$\n$\r$\n"
		
		; List configured tasks
		FileWrite $0 "Configured Tasks:$\r$\n"
		FileWrite $0 "----------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 ScheduledTask$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${Task::Exists} "$1" $2 $3 $4
			${If} $2 == "true"
				FileWrite $0 "$1 -> Status: $3, Next Run: $4$\r$\n"
			${Else}
				FileWrite $0 "$1 -> Not scheduled$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; List all system tasks
		FileWrite $0 "$\r$\nAll System Tasks:$\r$\n"
		FileWrite $0 "-----------------$\r$\n"
		${Task::List} $1
		${If} $1 != ""
			FileWrite $0 "$1$\r$\n"
		${Else}
			FileWrite $0 "Could not retrieve system tasks$\r$\n"
		${EndIf}
		
		FileClose $0
		${DebugMsg} "Scheduled tasks report generated: ${_FILEPATH}"
	${EndIf}
	
	Pop $R0
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

${SegmentFile}

;= Enable task scheduler segment
!define TASKSCHEDULER_ENABLED

;= Check permissions and backup existing tasks
${SegmentPre}
	!ifdef TASKSCHEDULER_ENABLED
		${DebugMsg} "Processing scheduled tasks..."
		
		; Check if user can manage tasks
		${Task::CanManage} $R9
		${If} $R9 == "false"
			${DebugMsg} "Warning: User cannot manage scheduled tasks (insufficient privileges)"
			MessageBox MB_OK|MB_ICONEXCLAMATION "Warning: Task scheduling requires administrator privileges.$\n$\nSome features may not work correctly."
		${EndIf}
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 ScheduledTask$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 ScheduledTask$R0 IfExists
			${ReadLauncherConfig} $2 ScheduledTask$R0 Schedule
			${ReadLauncherConfig} $3 ScheduledTask$R0 Modifier
			${ReadLauncherConfig} $4 ScheduledTask$R0 StartTime
			
			; Set defaults
			${If} $1 == ""
				StrCpy $1 "replace"
			${EndIf}
			
			; Validate schedule configuration
			${Task::ValidateSchedule} "$2" "$3" "$4" $R8 $R7
			${If} $R8 == "false"
				${DebugMsg} "Invalid schedule configuration for task $0: $R7"
				${WriteRuntimeData} TaskState "$0_Failed" "$R7"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${DebugMsg} "Processing scheduled task: $0"
			
			; Check if task exists
			${Task::Exists} "$0" $R8 $R7 $R6
			${If} $R8 == "true"
				${DebugMsg} "Scheduled task exists: $0 (Status: $R7)"
				
				${Switch} $1
					${Case} "skip"
						${DebugMsg} "Skipping existing scheduled task: $0"
						${WriteRuntimeData} TaskState "$0_Action" "skipped"
						${Break}
					${Case} "backup"
					${Case} "replace"
					${CaseElse}
						${Task::Backup} "$0" "TaskBackup" "$0"
						${WriteRuntimeData} TaskState "$0_Action" "backup"
						${Break}
				${EndSwitch}
			${Else}
				${DebugMsg} "Scheduled task does not exist: $0"
				${WriteRuntimeData} TaskState "$0_Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Scheduled tasks processing completed."
	!endif
!macroend

;= Create scheduled tasks
${SegmentPrePrimary}
	!ifdef TASKSCHEDULER_ENABLED
		${DebugMsg} "Creating scheduled tasks..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 ScheduledTask$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we should process this task
			${ReadRuntimeData} $1 TaskState "$0_Action"
			${If} $1 == "skipped"
				${DebugMsg} "Skipping scheduled task as requested: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Check for validation failures
			${ReadRuntimeData} $2 TaskState "$0_Failed"
			${IfNot} ${Errors}
				${DebugMsg} "Skipping task due to validation failure: $0 ($2)"
				${ReadLauncherConfig} $3 ScheduledTask$R0 Required
				${If} $3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Cannot create required scheduled task '$0'$\n$\nReason: $2"
				${EndIf}
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Get configuration
			${ReadLauncherConfig} $1 ScheduledTask$R0 Command
			${ReadLauncherConfig} $2 ScheduledTask$R0 Arguments
			${ReadLauncherConfig} $3 ScheduledTask$R0 WorkingDir
			${ReadLauncherConfig} $4 ScheduledTask$R0 Schedule
			${ReadLauncherConfig} $5 ScheduledTask$R0 Modifier
			${ReadLauncherConfig} $6 ScheduledTask$R0 StartTime
			${ReadLauncherConfig} $7 ScheduledTask$R0 StartDate
			${ReadLauncherConfig} $8 ScheduledTask$R0 EndDate
			${ReadLauncherConfig} $9 ScheduledTask$R0 RunAsUser
			${ReadLauncherConfig} $R7 ScheduledTask$R0 Password
			${ReadLauncherConfig} $R8 ScheduledTask$R0 RunLevel
			${ReadLauncherConfig} $R6 ScheduledTask$R0 Enabled
			${ReadLauncherConfig} $R5 ScheduledTask$R0 Hidden
			${ReadLauncherConfig} $R4 ScheduledTask$R0 Description
			${ReadLauncherConfig} $R3 ScheduledTask$R0 Required
			
			; Set defaults
			${If} $6 == ""
				StrCpy $6 "12:00"
			${EndIf}
			${If} $R6 == ""
				StrCpy $R6 "true"
			${EndIf}
			${If} $R4 == ""
				StrCpy $R4 "Scheduled task for ${PORTABLEAPPNAME}"
			${EndIf}
			
			${DebugMsg} "Creating scheduled task: $0"
			
			; Create the task
			${Task::Create} "$0" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "$R7" "$R8" "$R6" "$R5" "$R4" $R9 $R2
			
			${If} $R9 == "true"
				${WriteRuntimeData} TaskState "$0_Created" "true"
				${DebugMsg} "Scheduled task created successfully: $0"
			${Else}
				${WriteRuntimeData} TaskState "$0_Failed" "$R2"
				${DebugMsg} "Failed to create scheduled task $0: $R2"
				${If} $R3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Failed to create required scheduled task '$0'$\n$\nError: $R2"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Scheduled tasks creation completed."
	!endif
!macroend

;= Remove created scheduled tasks
${SegmentPostPrimary}
	!ifdef TASKSCHEDULER_ENABLED
		${DebugMsg} "Removing created scheduled tasks..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 ScheduledTask$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we created this task
			${ReadRuntimeData} $1 TaskState "$0_Created"
			${IfNot} ${Errors}
				${Task::Delete} "$0" $R8 $R7
				${If} $R8 == "true"
					${DebugMsg} "Scheduled task removed successfully: $0"
				${Else}
					${DebugMsg} "Failed to remove scheduled task $0: $R7"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Scheduled tasks removal completed."
	!endif
!macroend

;= Restore original scheduled tasks
${SegmentUnload}
	!ifdef TASKSCHEDULER_ENABLED
		${DebugMsg} "Restoring original scheduled tasks..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 ScheduledTask$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we need to restore this task
			${ReadRuntimeData} $1 TaskState "$0_Action"
			${If} $1 == "backup"
				${Task::Restore} "$0" "TaskBackup" "$0" $R8
				${If} $R8 == "true"
					${DebugMsg} "Scheduled task restored: $0"
				${Else}
					${DebugMsg} "Failed to restore scheduled task: $0"
				${EndIf}
			${EndIf}
			
			; Clean up runtime data
			${DeleteRuntimeData} TaskState "$0_Action"
			${DeleteRuntimeData} TaskState "$0_Created"
			${DeleteRuntimeData} TaskState "$0_Failed"
			
			; Clean up backup data
			${DeleteRuntimeData} TaskBackup "$0_XMLFile"
			${DeleteRuntimeData} TaskBackup "$0_Existed"
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Scheduled tasks restoration completed."
	!endif
!macroend

!endif
