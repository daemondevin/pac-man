;= VARIABLES 
;= ################
;Var $App

;= DEFINES
;= ################
;=# App Specs
!define APP  			``
!define APP64			``
!define APPDIR			`$EXEDIR\App\${APP}`
!define APPDIR64		`$EXEDIR\App\${APP64}`
!define DATA			`$EXEDIR\Data`
!define SET				`${DATA}\settings`
!define DEFDATA			`$EXEDIR\App\DefaultData`
!define DEFSET			`${DEFDATA}\settings`
!define SETINI			`${SET}\${APPNAME}Settings.ini`
;=# Registry
!define REG				`${SET}\${APP}.reg`
!define DEFREG			`${DEFSET}\${APP}.reg`
;=# Register DLL
!define GUID			{00000000-0000-0000-0000-000000000000}
!define KEY				SOFTWARE\Classes\CLSID
!define CLSID			InprocServer32
!define DLL				`${APPDIR}\`
!define REGSVR			`$SYSDIR\regsvr32.exe`
;=# Services
!define SVC				`${APPDIR}\`
!define SVCKEY			SYSTEM\CurrentControlSet\services\
!define HKLM			HKLM\${SVCKEY}
!define SC				`$SYSDIR\sc.exe`
;=# Scheduled Tasks
!define TASK			``
!define SCH				`$SYSDIR\schtasks.exe`
;=# File System
!define GETWOW64		`kernel32::GetSystemWow64Directory(t .r0, i ${NSIS_MAX_STRLEN})` ;= System::Call ${GETWOW64} #SYSDIR used by WOW64
!define DISABLEFSR		`kernel32::Wow64EnableWow64FsRedirection(i0)`	;= System::Call ${DISABLEFSR} #Stops file system redirect
!define ENABLEFSR		`kernel32::Wow64EnableWow64FsRedirection(i1)`	;= System::Call ${ENABLEFSR} #Enables file system redirect
!define GETCURRPROC		`kernel32::GetCurrentProcess()i.s`
!define WOW				`kernel32::IsWow64Process(is,*i.r0)`
!define PAL				PortableApps.comLauncher
;=# dotNET
;= The .NET Framework installer writes registry keys when installation is successful. 
;= You can test whether the .NET Framework 4.5 or later is installed by checking the 
;= HKLM\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full folder in the registry for
;= a DWORD value named Release. The existence of this key indicates that the .NET 
;= Framework 4.5 or a later version has been installed on that computer. The value of 
;= Release indicates which version of the .NET Framework is installed. Use the values 
;= below for version checking in ${Segment.OnInit} depending on your applications needs.
;=
;= Version: 											Value of Release DWORD:
;= 4.6.2 on Win10 Anniversary										394802
;= 4.6.2 on all OS but not Win10 Anniversary						394806
;= 4.6.1 on Win10 November Update									394254
;= 4.6.1 on all OS but not Win10 November Update					394271
;= 4.6   on Win10													393295
;= 4.6   on all OS but not Win10									393297
;= 4.5.2															379893
;= 4.5.1 on Windows 8.1 or Windows Server 2012 R2					378675
;= 4.5.1 on Windows 8, Windows 7									378758
;= 4.5																378389
!define DOTNET			`378389`

;= FUNCTIONS
;= ################
Function IsWOW64
	!macro _IsWOW64 _RETURN
		Push ${_RETURN}
		Call IsWOW64
		Pop ${_RETURN}
	!macroend
	!define IsWOW64 `!insertmacro _IsWOW64`
	Exch $0
	System::Call `${GETCURRPROC}`
	System::Call `${WOW}`
	Exch $0
FunctionEnd
;=# dotNET
Function dotNETCheck
	!define CheckDOTNET "!insertmacro _CheckDOTNET"
	!macro _CheckDOTNET _RESULT _VALUE
		Push `${_VALUE}`
		Call dotNETCheck
		Pop ${_RESULT}
	!macroend
	Exch $1
	Push $0
	Push $1
    ${If} $1 >= 460798
		StrCpy $0 4.7
    ${ElseIf} $1 >= 394802
		StrCpy $0 4.6.2   
    ${ElseIf} $1 >= 394254
		StrCpy $0 4.6.1
    ${ElseIf} $1 >= 393295
		StrCpy $0 4.6
    ${ElseIf} $1 >= 379893
		StrCpy $0 4.5.2
    ${ElseIf} $1 >= 378675
		StrCpy $0 4.5.1
    ${ElseIf} $1 >= 378389
		StrCpy $0 4.5
	${Else}
		StrCpy $0 ""
		SetErrors
	${EndIf}
	Pop $1
	Exch $0
FunctionEnd

;= MACROS
;= ################
;=# Register DLLs
!define DLL::Backup "!insertmacro _DLL::Backup"
!macro _DLL::Backup _GUID _FSR _SECTION _KEY _ERR1 _ERR2
	ClearErrors
	ReadRegStr $0 HKLM `SOFTWARE\Classes\CLSID\${_GUID}\InprocServer32` ""
	${IfNot} ${Errors}
		StrCmpS $Bit 64 0 +6
		StrCmp ${_FSR} /DISABLEFSR 0 +5
		${WriteRuntimeData} ${_SECTION} ${_KEY} `$0`
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s /u "$0"`
		Goto +2
		ExecDos::Exec /TOSTACK `"${REGSVR}" /s /u "$0"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	${EndIf}
!macroend
!define DLL::Restore "!insertmacro _DLL::Restore"
!macro _DLL::Restore _FSR _SECTION _KEY _ERR1 _ERR2
	ClearErrors
	${ReadRuntimeData} $0 ${_SECTION} ${_KEY}
	${IfNot} ${Errors}
		StrCmpS $Bit 64 0 +4
		StrCmp ${_FSR} /DISABLEFSR 0 +3
		ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s "$0"`
		Goto +2
		ExecDos::Exec /TOSTACK `"${REGSVR}" /s "$0"`
		Pop ${_ERR1}
		Pop ${_ERR2}
	${EndIf}
!macroend
!define DLL::Register `!insertmacro _DLL::Register`
!macro _DLL::Register _DLL _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp ${_FSR} /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s "${_DLL}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${REGSVR}" /s "${_DLL}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define DLL::UnRegister `!insertmacro _DLL::UnRegister`
!macro _DLL::UnRegister _DLL _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp ${_FSR} /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s /u "${_DLL}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${REGSVR}" /s /u "${_DLL}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
;=# Services
!define Service::Query `!insertmacro _Service::Query`
!macro _Service::Query _SVC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" query "${_SVC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" query "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
	StrCmp ${_ERR1} "1060" 0 +3
	SetErrors
	Goto +2
	${WriteRuntimeData} "${_SVC}Service" LocalService true
!macroend
!define Service::QueryConfig `!insertmacro _Service::QueryConfig`
!macro _Service::QueryConfig _SVC _FSR _ERR1 _ERR2
	ReadEnvStr $R0 COMSPEC
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"$R0" /c "${SC} qc "${_SVC}" | FIND "BINARY_PATH_NAME""`
	Goto +2
	ExecDos::Exec /TOSTACK `"$R0" /c "${SC} qc "${_SVC}" | FIND "BINARY_PATH_NAME""`
	Pop ${_ERR1}
	Pop ${_ERR2}
	StrCmpS ${_ERR1} 0 0 +4
	StrCpy $R1 ${_ERR2} "" 29
	${WriteRuntimeData} "${_SVC}Service" LocalPath "$R1"
	ReadRegStr $R1 HKLM `SYSTEM\CurrentControlSet\services\${_SVC}` ImagePath
	${WriteRuntimeData} "${_SVC}Service" LocalPath "$R1"
!macroend
!define Service::State `!insertmacro _Service::State`
!macro _Service::State _SVC _FSR _ERR1 _ERR2
	ReadEnvStr $R0 COMSPEC
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"$R0" /c "${SC} query "${_SVC}" | find /C "RUNNING""`
	Goto +2
	ExecDos::Exec /TOSTACK `"$R0" /c "${SC} query "${_SVC}" | find /C "RUNNING""`
	Pop ${_ERR1}
	Pop ${_ERR2}
	StrCmpS ${_ERR1} 1 0 +4
	StrCmpS ${_ERR2} 1 0 +3
	${WriteRuntimeData} "${_SVC}Service" LocalState Running
!macroend
!define Service::Start `!insertmacro _Service::Start`
!macro _Service::Start _SVC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" start "${_SVC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" start "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define Service::Stop `!insertmacro _Service::Stop`
!macro _Service::Stop _SVC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" stop "${_SVC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" stop "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define Service::Remove `!insertmacro _Service::Remove`
!macro _Service::Remove _SVC _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +4
	StrCmp "${_FSR}" /DISABLEFSR 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" delete "${_SVC}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" delete "${_SVC}"`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
!define Service::Create `!insertmacro _Service::Create`
!macro _Service::Create _SVC _PATH _TYPE _START _DEPEND _FSR _ERR1 _ERR2
	StrCmpS $Bit 64 0 +7
	StrCmp "${_FSR}" /DISABLEFSR 0 +6
	StrCmp "${_DEPEND}" "" 0 +3
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" create "${_SVC}" DisplayName= "${FULLNAME}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}"`
	Goto +7
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${SC}" create "${_SVC}" DisplayName= "${FULLNAME}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}" depend= ""${_DEPEND}""`
	Goto +5
	StrCmp "${_DEPEND}" "" 0 +3
	ExecDos::Exec /TOSTACK `"${SC}" create "${_SVC}" DisplayName= "${FULLNAME}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}"`
	Goto +2
	ExecDos::Exec /TOSTACK `"${SC}" create "${_SVC}" DisplayName= "${FULLNAME}" binpath= "${_PATH}" type= "${_TYPE}" start= "${_START}" depend= ""${_DEPEND}""`
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
;=# Scheduled Tasks
!define QueryTask `!insertmacro _QueryTask` 	;= ${QueryTask} `ApplicationTask` $0 $1
!macro _QueryTask _TASK _ERR1 _ERR2
	ExecDos::Exec /TOSTACK `"${SCH}" /c schtasks /query /fo csv | find /c "${_TASK}"`  		;= Checks for a task by name
	Pop ${_ERR1}
	Pop ${_ERR2}
	StrCmpS ${_ERR1} 1 0 +3
	StrCmpS ${_ERR2} 1 0 +2
	${WriteRuntimeData} ${PAL} ${_TASK} true 	;= Writes true for TaskName to runtime ini 
!macroend
!define RemoveTask "!insertmacro _RemoveTask" 	;= ${RemoveTask} `ApplicationTask` $0 $1
!macro _RemoveTask _TASK _ERR1 _ERR2
	${ReadRuntimeData} $0 ${PAL} ${_TASK} 		;= Reads runtime ini for task
	${If} $0 == true
		ExecDos::Exec /TOSTACK `"${SCH}" /end /tn "${_TASK}"` ;= Stops the scheduled task
		Pop ${_ERR1}
		Pop ${_ERR2}
		ExecDos::Exec /TOSTACK `"${SCH}" /delete /tn "${_TASK}" /f` ;= Deletes the scheduled task
	${EndIf}
	Pop ${_ERR1}
	Pop ${_ERR2}
!macroend
 
;= CUSTOM 
;= ################
${SegmentFile}
${Segment.OnInit}
	Push $0
	${IsWOW64} $0
	StrCmp $0 0 0 +3
	WriteINIStr `${SETINI}` ${APPNAME}Settings Architecture 32
		Goto END
	System::Call ${DISABLEFSR}
	SetRegView 64	;= NSIS Installers are 32bit processes so set this to write to the 64bit registry
	WriteINIStr `${SETINI}` ${APPNAME}Settings Architecture 64
	END:
	Pop $0
;=# OS check if ${APP} is able to run on host file system
	${If} ${IsNT}
		${If} ${IsWinXP}	;= Win2000, WinXP, Win2003, WinVista, Win2008, Win7, Win8, Win2008R2
			${IfNot} ${AtLeastServicePack} 3
				MessageBox MB_ICONSTOP|MB_TOPMOST `${PORTABLEAPPNAME} requires Service Pack 3 or newer`
				Call Unload
				Quit
			${EndIf}
		${ElseIfNot} ${AtLeastWinXP}
			MessageBox MB_ICONSTOP|MB_TOPMOST `${PORTABLEAPPNAME} requires Windows XP or newer`
			Call Unload
			Quit
		${EndIf}
	${Else}
		MessageBox MB_ICONSTOP|MB_TOPMOST `${PORTABLEAPPNAME} requires Windows XP or newer`
		Call Unload
		Quit
	${EndIf}
;=# dotNET Check
	ClearErrors
	${CheckDOTNET} $0 ${DOTNET} ;= Checks for .NET v4.5
	IfErrors 0 +4 ;= If there is no errors then jump 4 lines down.
	MessageBox MB_ICONSTOP|MB_TOPMOST `You must have v$0 or greater of the .NET Framework installed. Launcher aborting!` ;= If the check failed then we alert the user the required version wasn't found.
	Call Unload ;= We call the Unload function here because we failed the .NET check.
	Quit ;= Closes the Launcher
!macroend
${SegmentInit}
;=# Set any %VAR% for use in ${APP}Portable.ini
	SetShellVarContext all	;= Set All for all users scope; Set Current for current user scope
	StrCpy $1 $APPDATA	;= Copies the path to AllUsersAppData instead of current users AppData
	${SetEnvironmentVariablesPath} PROGRAMDATA $1	;= Can use %PROGRAMDATA% in ${APP}Portable.ini now
	SetShellVarContext current	;= Be sure to set the context back
	${SetEnvironmentVariablesPath} SYSDIR $SYSDIR
!macroend
${SegmentPre}
;=# Register DLLs
	${DLL::Backup} `${GUID}` "" "" DLL ;=  Uninstall Local DLL
;=# Services
	ClearErrors
	${Service::Query} ${SVC} /DISABLEFSR $0 $1
	StrCmp $0 "1060" NONE LOCAL
	LOCAL:
		${WriteRuntimeData} "${SVC}Service" LocalService true
		${Service::QueryConfig} ${SVC} /DISABLEFSR $0 $1
		${Registry::CopyKey} `${HKLM}` `${PAF}\Keys\${HKLM}` $0
		${Service::State} ${SVC} /DISABLEFSR $0 $1
		${If} $0 == 1
		${AndIf} $1 == 1
			${Service::Stop} ${SVC} /DISABLEFSR $0 $1
		${EndIf}
		${Service::Remove} ${SVC} /DISABLEFSR $0 $1
	NONE:
!macroend
${SegmentPrePrimary}
;=# Register DLLs
	${DLL::Register} `${DLL}` /DISABLEFSR $0 $1
;=# Services
	${Service::Create} ${SVC} `` own demand "" /DISABLEFSR $0 $1
	${Registry::CopyKey} `${PAFKEYS}\${HKLM}` `${HKLM}` $0
	WriteRegStr HKLM "${SVCKEY}" "ImagePath" ""
	Sleep 50
	${Service::Start} ${SVC} /DISABLEFSR $0 $1
;=# Scheduled Tasks
	${QueryTask} ${TASK} $0 $1 	;= Checks for a scheduled task
!macroend
${SegmentPostPrimary}
;=# Registry DLLs
	${DLL::UnRegister} `${DLL}` /DISABLEFSR $0 $1
;=# Services
	${Service::Stop} ${SVC} /DISABLEFSR $0 $1
	Sleep 50
	${Service::Remove} ${SVC} /DISABLEFSR $0 $1
	DeleteRegKey HKLM `${SVCKEY}`
;=# Scheduled Tasks
	${RemoveTask} ${TASK} $0 $1 ;= Removes scheduled task
!macroend
${SegmentUnload}
;=# Register DLLs
	${DLL::Restore} "" "" DLL
;=# Services
	${ReadRuntimeData} $0 "${SVC}Service" LocalService
	${IfNot} ${Errors}
	${AndIf} $0 == true
		${Registry::RestoreBackupKey} `${HKLM}` $0
		${ReadRuntimeData} $R0 "${SVC}Service" LocalPath
		${IfNot} ${Errors}
			${Service::Create} ${SVC} `$R0` own demand "" /DISABLEFSR $0 $1
			Sleep 50
			${Service::Start} ${SVC} /DISABLEFSR $1 $2
		${EndIf}
	${EndIf}
;=# dotNET apps may have Usage Logs; Get rid of them using following
	FindFirst $0 $1 `$LOCALAPPDATA\Microsoft\*` 
	StrCmpS $0 "" +12
	StrCmpS $1 "" +11
	StrCmpS $1 "." +8
	StrCmpS $1 ".." +7
	StrCpy $2 $1 3
	StrCmpS $2 CLR 0 +5
	IfFileExists `$LOCALAPPDATA\Microsoft\$1\UsageLogs\${APP}.exe.log` 0 +2
	Delete `$LOCALAPPDATA\Microsoft\$1\UsageLogs\*.log`
	RMDir `$LOCALAPPDATA\Microsoft\$1\UsageLogs`
	RMDir `$LOCALAPPDATA\Microsoft\$1`
	FindNext $0 $1
	Goto -10
	FindClose $0
!macroend