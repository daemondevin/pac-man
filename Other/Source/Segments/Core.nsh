Var LauncherFile
;${If} ${FilesExists}, ${If} ${DirExists}.
!macro _FilesExists _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	StrCpy $_LOGICLIB_TEMP "0"
	StrCmp `${_b}` `` +4 0 ;if path is not blank, continue to next check
	IfFileExists `${_b}` `0` +3 ;if path exists, continue to next check (IfFileExists returns true if this is a directory)
	IfFileExists `${_b}\*.*` +2 0 ;if path is not a directory, continue to confirm exists
	StrCpy $_LOGICLIB_TEMP "1" ;file exists
	;now we have a definitive value - the file exists or it does not
	StrCmp $_LOGICLIB_TEMP "1" `${_t}` `${_f}`
!macroend
!define FilesExists `"" FilesExists`
!macro _DirExists _a _b _t _f
	!insertmacro _LOGICLIB_TEMP
	StrCpy $_LOGICLIB_TEMP "0"	
	StrCmp `${_b}` `` +3 0 ;if path is not blank, continue to next check
	IfFileExists `${_b}\*.*` 0 +2 ;if directory exists, continue to confirm exists
	StrCpy $_LOGICLIB_TEMP "1"
	StrCmp $_LOGICLIB_TEMP "1" `${_t}` `${_f}`
!macroend
!define DirExists `"" DirExists`
!define xml::Unload `!insertmacro xml::Unload`
!macro xml::Unload
	xml::_Unload
!macroend
Function Get.Parent
	!macro Get.Parent _PATH _RET
		Push `${_PATH}`
		Call Get.Parent
		Pop ${_RET}
	!macroend
	!define Get.Parent "!insertmacro _Get.Parent"
	Exch $0
	Push $1
	Push $2
	StrCpy $2 $0 1 -1
	StrCmp $2 '\' 0 +3
	StrCpy $0 $0 -1
	Goto -3
	StrCpy $1 0
	IntOp $1 $1 - 1
	StrCpy $2 $0 1 $1
	StrCmp $2 '\' +2
	StrCmp $2 '' 0 -3
	StrCpy $0 $0 $1
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
Function SetVariablesPath
	!macro _SetVariablesPath _VAR _PATH
		Push "${_VAR}"
		Push "${_PATH}"
		Call SetVariablesPath
	!macroend
	!define _SetVariablesPath "!insertmacro _SetVariablesPath"
	Exch $R0
	Exch
	Exch $R1
	Push $R2
	Push $R3
	Push $R7
	Push $R8
	Push $R9
	${SetEnvironmentVariable} $R1 $R0
	${WordReplaceS} $R0 \ / + $R2
	${SetEnvironmentVariable} "$R1:Forwardslash" $R2
	${WordReplaceS} $R0 \ \\ + $R3
	${SetEnvironmentVariable} "$R1:DoubleBackslash" $R3
	Pop $R9
	Pop $R8
	Pop $R7
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $R0
FunctionEnd
Function _GetOptions
	!define _GetOptions `!insertmacro _GetOptionsCall`
	!macro _GetOptionsCall _PARAMETERS _OPTION _RESULT
		Push `${_PARAMETERS}`
		Push `${_OPTION}`
		Call _GetOptions
		Pop ${_RESULT}
	!macroend
	Exch $1
	Exch
	Exch $0
	Exch
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $7
	ClearErrors
	StrCpy $2 $1 '' 1
	StrCpy $1 $1 1
	StrLen $3 $2
	StrCpy $7 0
	BEGIN:
	StrCpy $4 -1
	StrCpy $6 ''
	QUOTE:
	IntOp $4 $4 + 1
	StrCpy $5 $0 1 $4
	StrCmp $5$7 '0' NOTFOUND
	StrCmp $5 '' TRIMRIGHT
	StrCmp $5 '"' 0 +7
	StrCmp $6 '' 0 +3
	StrCpy $6 '"'
	Goto QUOTE
	StrCmp $6 '"' 0 +3
	StrCpy $6 ''
	Goto QUOTE
	StrCmp $5 `'` 0 +7
	StrCmp $6 `` 0 +3
	StrCpy $6 `'`
	Goto QUOTE
	StrCmp $6 `'` 0 +3
	StrCpy $6 ``
	Goto QUOTE
	StrCmp $5 '`' 0 +7
	StrCmp $6 '' 0 +3
	StrCpy $6 '`'
	Goto QUOTE
	StrCmp $6 '`' 0 +3
	StrCpy $6 ''
	Goto QUOTE
	StrCmp $6 '"' QUOTE
	StrCmp $6 `'` QUOTE
	StrCmp $6 '`' QUOTE
	StrCmp $5 $1 0 QUOTE
	StrCmp $7 0 TRIMLEFT TRIMRIGHT
	TRIMLEFT:
	IntOp $4 $4 + 1
	StrCpy $5 $0 $3 $4
	StrCmp $5 '' NOTFOUND
	StrCmp $5 $2 0 QUOTE
	IntOp $4 $4 + $3
	StrCpy $0 $0 '' $4
	StrCpy $4 $0 1
	StrCmp $4 ' ' 0 +3
	StrCpy $0 $0 '' 1
	Goto -3
	StrCpy $7 1
	Goto BEGIN
	TRIMRIGHT:
	StrCpy $0 $0 $4
	StrCpy $4 $0 1 -1
	StrCmp $4 ' ' 0 +3
	StrCpy $0 $0 -1
	Goto -3
	StrCpy $3 $0 1
	StrCpy $4 $0 1 -1
	StrCmp $3 $4 0 END
	StrCmp $3 '"' +3
	StrCmp $3 `'` +2
	StrCmp $3 '`' 0 END
	StrCpy $0 $0 -1 1
	Goto END
	NOTFOUND:
	SetErrors
	StrCpy $0 ''
	END:
	Pop $7
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
Function GetVersion
	!macro _GetVersion _FILE _RESULT
		Push `${_FILE}`
		Call GetVersion
		Pop ${_RESULT}
	!macroend
	!define GetVersion `!insertmacro _GetVersion`
	Exch $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	ClearErrors
	GetDLLVersion '$0' $1 $2
	IfErrors +9
	IntOp $3 $1 >> 16
	IntOp $3 $3 & 0x0000FFFF
	IntOp $4 $1 & 0x0000FFFF
	IntOp $5 $2 >> 16
	IntOp $5 $5 & 0x0000FFFF
	IntOp $6 $2 & 0x0000FFFF
	StrCpy $0 '$3.$4.$5.$6'
	Goto +3
	SetErrors
	StrCpy $0 ''
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
!ifdef IsFileLocked
	!macro _LL_FileLocked _a _b _t _f
		!insertmacro _LOGICLIB_TEMP
		System::Call kernel32::GetCurrentProcess()i.s
		System::Call kernel32::IsWow64Process(is,*i.s)
		Pop $_LOGICLIB_TEMP
		StrCmpS $_LOGICLIB_TEMP 0 +3
		IfFileExists "$PLUGINSDIR\LockedList64.dll" +2
		File "/oname=$PLUGINSDIR\LockedList64.dll" `${NSISDIR}\Plugins\LockedList64.dll`
		LockedList::IsFileLocked `${_b}`
		Pop $_LOGICLIB_TEMP
		!insertmacro _== $_LOGICLIB_TEMP true `${_t}` `${_f}`
	!macroend
	!define FileLocked `"" LL_FileLocked`
!endif
!ifdef TrimString
	;=== this works better than TrimWhite because this also removes carriage returns.
	Function Trim
		!macro _Trim _RESULT _STRING
			Push `${_STRING}`
			Call Trim
			Pop `${_RESULT}`
		!macroend
		!define Trim `!insertmacro _Trim`
		Exch $R1
		Push $R2
		StrCpy $R2 `$R1` 1
		StrCmpS `$R2` " " +5
		StrCmpS `$R2` `$\r` +4
		StrCmpS `$R2` `$\n` +3
		StrCmpS `$R2` `$\t` +2
		Goto +3
		StrCpy $R1 `$R1` "" 1
		Goto -7
		StrCpy $R2 `$R1` 1 -1
		StrCmpS `$R2` " " +5
		StrCmpS `$R2` `$\r` +4
		StrCmpS `$R2` `$\n` +3
		StrCmpS `$R2` `$\t` +2
		Goto +3
		StrCpy $R1 `$R1` -1
		Goto -7
		Pop $R2
		Exch $R1
	FunctionEnd
!endif
!ifdef CloseProc
	Function CloseX
		!macro _CloseX _PROCESS
			Push `${_PROCESS}`
			Call CloseX
		!macroend
		!define CloseX "!insertmacro _CloseX"
		Exch $0
		Push $1
		CLOSE:
		${If} ${ProcessExists} `$0`
			${CloseProcess} `$0` $1
			${If} ${ProcessExists} `$0`
				${TerminateProcess} `$0` $1
				Sleep 1000
				Goto CLOSE
			${EndIf}
		${EndIf}
		Pop $1
		Pop $0
	FunctionEnd
!endif
!ifdef RMEMPTYDIRECTORIES
	Function RMEmptyDir
		!macro _RMEmptyDir _DIR _SUBDIR
			Push `${_SUBDIR}`
			Push `${_DIR}`
			Call RMEmptyDir
		!macroend
		!define RMEmptyDir `!insertmacro _RMEmptyDir`
		Exch $0 ; dir
		Exch
		Exch $1 ; subdir
		Push $2
		Push $3
		FindFirst $2 $3 `$0\*.*`
		StrCmpS $2 "" +9
		StrCmpS $3 "" +8
		StrCmpS $3 "." +5
		StrCmpS $3 ".." +4
		RMDir `$0\$3\$1`
		RMDir `$0\$3`
		RMDir `$0`
		FindNext $2 $3
		Goto -7
		FindClose $2
		Pop $3
		Pop $2
		Pop $1
		Pop $0
	FunctionEnd
!endif
!ifdef NTFS
	!define FILE_SUPPORTS_REPARSE_POINTS 0x00000080
	!macro YESNO _FLAGS _BIT _VAR
		IntOp ${_VAR} ${_FLAGS} & ${_BIT}
		${IfThen} ${_VAR} <> 0 ${|} StrCpy ${_VAR} 1 ${|}
		${IfThen} ${_VAR} == 0 ${|} StrCpy ${_VAR} 0 ${|}
	!macroend
	Function ValidateFS
		!macro _ValidateFS _PATH _RETURN
			Push `${_PATH}`
			Call ValidateFS
			Pop ${_RETURN}
		!macroend
		!define ValidateFS `!insertmacro _ValidateFS`
		Exch $0
		Push $1
		Push $2
		StrCpy $0 $0 3
		System::Call `Kernel32::GetVolumeInformation(t "$0",t,i ${NSIS_MAX_STRLEN},*i,*i,*i.r1,t,i ${NSIS_MAX_STRLEN})i.r0`
		${If} $0 <> 0
			!insertmacro YESNO $1 ${FILE_SUPPORTS_REPARSE_POINTS} $2
		${EndIf}
		Pop $0
		Pop $1
		Exch $2
	FunctionEnd
!endif
!ifdef ACL
	!define SetACL::Key `!insertmacro SetACL::Key`
	!macro SetACL::Key _ROOT _KEY
		AccessControl::SetRegKeyOwner ${_ROOT} `${_KEY}` (S-1-5-32-545)
		AccessControl::ClearOnRegKey ${_ROOT} `${_KEY}` EVERYONE FULLACCESS
		AccessControl::SetRegKeyOwner ${_ROOT} `${_KEY}` (S-1-5-32-545)
		AccessControl::GrantOnRegKey ${_ROOT} `${_KEY}` EVERYONE FULLACCESS
	!macroend
;	Function SetACL::Key
;		!macro _SetACL::Key _ROOT _KEY
;			Push `${_KEY}`
;			Push ${_ROOT}
;			Call SetACL::Key
;		!macroend
;		!define SetACL::Key `!insertmacro _SetACL::Key`
;		Exch $0 ; root
;		Exch
;		Exch $1 ; key
;		Push $2
;		AccessControl::SetRegKeyOwner $0 `$1` (S-1-5-32-545)
;		Pop $2
;		AccessControl::ClearOnRegKey $0 `$1` EVERYONE FULLACCESS
;		Pop $2
;		AccessControl::SetRegKeyOwner $0 `$1` (S-1-5-32-545)
;		Pop $2
;		AccessControl::GrantOnRegKey $0 `$1` EVERYONE FULLACCESS
;		Pop $2
;		Pop $1
;		Pop $0
;	FunctionEnd
!endif
!ifdef ACL_DIR
;	!define SetACL::Dir `!insertmacro SetACL::Dir`
;	!macro SetACL::Dir _DIR
;		Push $R0
;		ReadEnvStr $R0 UserName
;		AccessControl::GrantOnFile `${_DIR}` `$R0` FULLACCESS
;		AccessControl::GrantOnFile `${_DIR}` (S-1-5-32-545) FULLACCESS
;		Pop $R0
;	!macroend
	Function SetACL::Dir
		!macro _SetACL::Dir _DIR
			Push `${_DIR}`
			Call SetACL::Dir
		!macroend
		!define SetACL::Dir `!insertmacro _SetACL::Dir`
		Exch $R9
		Push $R8
		ReadEnvStr $R8 UserName
		AccessControl::GrantOnFile `$R9` `$R8` FULLACCESS
		AccessControl::GrantOnFile `$R9` (S-1-5-32-545) FULLACCESS
		SetFileAttributes `$R9` NORMAL
		Pop $R8
		Pop $R9
	FunctionEnd
!endif
!ifdef CloseWindow
	!define CABW         CabinetWClass
	Function Close
		!macro _Close _CLASS _TITLE
			Push `${_TITLE}`
			Push `${_CLASS}`
			Call Close
		!macroend
		!define Close `!insertmacro _Close`
		Exch $2
		Exch
		Exch $1
		Push $0
		FindWindow $0 `$2` `$1`
		IntCmp $0 0 +5 0 0
		IsWindow $0 0 +4
		System::Call `user32::PostMessage(i,i,i,i) i($0,0x0010,0,0)`
		Sleep 100
		Goto -5
		Pop $0
		Pop $1
		Pop $2
	FunctionEnd
!endif
Function GetLongPathName
	!macro _GetLongPathName _PATH
		Push `${_PATH}`
		Call GetLongPathName
		Pop `${_PATH}`
	!macroend
	!define GetLongPathName `!insertmacro _GetLongPathName`
	Exch $0
	Push $1
	Push $2
	System::Call 'kernel32::GetLongPathName(t r0, t .r1, i ${NSIS_MAX_STRLEN}) i .r2'
	StrCmpS $2 error 0 +3
	StrCpy $0 error
	Goto +2
	StrCpy $0 $1
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
!ifdef FONTS_ENABLE
	!define FNTDIR    `${DATA}\Fonts`
	!define FNTXT     `${FNTDIR}\.Portable.Fonts.txt`
	!define DEFFNTXT  `${DEFDATA}\Fonts\.Portable.Fonts.txt`
	!define FNT1      `• Font(s) added in here are portabilized and are available for usage during runtime.$\r$\n`
	!define FNT2      `• Supported: .fon, .fnt, .ttf, .ttc, .fot, .otf, .mmm, .pfb, .pfm.`
	Function Fonts::Import
		!macro _Fonts::Import _DIR
			Push `${_DIR}`
			Call Fonts::Import
		!macroend
		!define Fonts::Import `!insertmacro _Fonts::Import`
		Exch $0
		Push $1
		Push $2
		Push $3
		FindFirst $1 $2 `$0\*`
		StrCmpS $1 "" +19
		StrCmpS $2 "" +18
		StrCmpS $2 "." +15
		StrCmpS $2 ".." +14
		StrCpy $3 $2 "" -4
		StrCmp $3 .fon +10
		StrCmp $3 .fnt +9
		StrCmp $3 .ttf +8
		StrCmp $3 .ttc +7
		StrCmp $3 .fot +6
		StrCmp $3 .otf +5
		StrCmp $3 .mmm +4
		StrCmp $3 .pfb +3
		StrCmp $3 .pfm +2
		Goto +3
		System::Call `GDI32::AddFontResource(t"$0\$2").R3`
		SendMessage 0xFFFF 0x001D 0 0 /TIMEOUT=1
		FindNext $1 $2
		Goto -17
		FindClose $1
		Pop $3
		Pop $2
		Pop $1
		Pop $0
	FunctionEnd
	Function Fonts::Restore
		!macro _Fonts::Restore _DIR
			Push `${_DIR}`
			Call Fonts::Restore
		!macroend
		!define Fonts::Restore `!insertmacro _Fonts::Restore`
		Exch $0
		Push $1
		Push $2
		Push $3
		FindFirst $1 $2 `$0\*`
		StrCmpS $1 "" +19
		StrCmpS $2 "" +18
		StrCmpS $2 "." +15
		StrCmpS $2 ".." +14
		StrCpy $3 $2 "" -4
		StrCmp $3 .fon +10
		StrCmp $3 .fnt +9
		StrCmp $3 .ttf +8
		StrCmp $3 .ttc +7
		StrCmp $3 .fot +6
		StrCmp $3 .otf +5
		StrCmp $3 .mmm +4
		StrCmp $3 .pfb +3
		StrCmp $3 .pfm +2
		Goto +3
		System::Call `GDI32::RemoveFontResource(t"$0\$2").R3`
		SendMessage 0xFFFF 0x001D 0 0 /TIMEOUT=1
		FindNext $1 $2
		Goto -17
		FindClose $1
		Pop $3
		Pop $2
		Pop $1
		Pop $0
	FunctionEnd
!endif
Function FileName
	!macro _FileName _STRING _RESULT
		Push `${_STRING}`
		Call FileName
		Pop ${_RESULT}
	!macroend
	!define FileName "!insertmacro _FileName"
	Exch $0
	Push $1
	Push $2
	StrCpy $2 $0 1 -1
	StrCmp $2 '\' 0 +3
	StrCpy $0 $0 -1
	Goto -3
	StrCpy $1 0
	IntOp $1 $1 - 1
	StrCpy $2 $0 1 $1
	StrCmp $2 '' +4
	StrCmp $2 '\' 0 -3
	IntOp $1 $1 + 1
	StrCpy $0 $0 '' $1
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
Function GetAfterChar
	!macro _GetAfterChar _STR _CHAR _RET
		Push `${_STR}`
		Push `${_CHAR}`
		Call GetAfterChar
		Pop `${_RET}`
	!macroend
	!define GetAfterChar "!insertmacro _GetAfterChar"
	Exch $0
	Exch
	Exch $1
	Push $2
	Push $3
	StrCpy $2 0
	IntOp $2 $2 - 1
	StrCpy $3 $1 1 $2
	StrCmpS $3 "" 0 +3
	StrCpy $0 ""
	Goto +5
	StrCmp $3 $0 +2
	Goto -6
	IntOp $2 $2 + 1
	StrCpy $0 $1 "" $2
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
${SegmentFile}
${Segment.onInit}
	${GetBaseName} $EXEFILE $BaseName
	StrCpy $LauncherFile `${LAUNCHER}`
	StrCpy $AppID `${APPNAME}`
	StrCpy $AppName `${FULLNAME}`
	StrCpy $AppNamePortable `${PORTABLEAPPNAME}`
!macroend
${SegmentInit}
	IfFileExists `${LAUNCHER}` 0 +5
	InitPluginsDir
	CopyFiles /SILENT `${LAUNCHER}` `${LAUNCHER2}`
	StrCpy $LauncherFile `${LAUNCHER2}`
	Goto +5
	StrCpy $MissingFileOrPath `${LAUNCHER}`
	MessageBox MB_OK|MB_ICONSTOP `$(LauncherFileNotFound)`
	Call Unload
	Quit
	!ifndef DisableProgramExecSegment
		${GetParameters} $0
		!ifdef UAC
			${GetOptions} $0 /UAC $1
			${IfNot} ${Errors}
				${WordReplace} $0 /UAC$1 "" + $0
				${Trim} $0 $0
			${EndIf}
			${GetOptions} $0 /NCRC $1
			${IfNot} ${Errors}
				${WordReplace} $0 /NCRC$1 "" + $0
				${Trim} $0 $0
			${EndIf}
		!endif
		!ifmacrodef ProExecInit
			!insertmacro ProExecInit
		!else
			StrCpy $ProgramExecutable ""
			StrCmpS $Bit 64 0 +5
			StrCmpS $0 "" +2
			${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutableWhenParameters64
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutable64
			StrCmpS $0 "" +3
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutableWhenParameters
			StrCmpS $ProgramExecutable "" 0 +2
			${ReadLauncherConfig} $ProgramExecutable Launch ProgramExecutable
		!endif
	!endif
	StrCmpS $ProgramExecutable "" 0 +3
	MessageBox MB_OK|MB_ICONSTOP `${RUNTIME} is missing [Launch]:ProgramExecutable - what am I to launch?`
	Quit
	!ifmacrodef UnProExecInit
		!insertmacro UnProExecInit
	!endif
!macroend
${SegmentPreExecPrimary}
	${WriteRuntimeData} ${PAL} PluginsDir $PLUGINSDIR
!macroend
${SegmentUnload}
	!ifmacrodef UnloadEXE
		!insertmacro UnloadEXE
	!endif
	!ifmacrodef Unload
		!insertmacro Unload
	!endif
	!ifdef REGISTRY
		StrCmpS $Registry true 0 +2
		Registry::_Unload
	!endif
	SetOutPath `$TEMP` ;=== prevents $PLUGINSDIR from being locked.
	FileClose $_FEIP_FileHandle
	Delete `$PLUGINSDIR\launcher.ini`
	Delete `${LAUNCHER2}`
	StrCmpS $SecondaryLaunch true +10
	${ReadRuntimeData} $0 ${PAL} PluginsDir
	StrCmpS $0 "" +3
	StrCmp `$0` `$PLUGINSDIR` +2
	RMDir /r `$0`
	Delete `${RUNTIME}`
	Delete `$TEMP\*.tmp`
	Delete `${RUNTIME2}`
	Delete `$TEMP\*.tmp`
	System::Free 0
!macroend
