/*CmdExec
http://nsis.sourceforge.net/CmdExec

Description
Macro that uses the windows default command line interpreter 
(usually $sysdir\cmd.exe) to execute a command and its parameters, 
with working directory, optional pause, stay-in-prompt and execwait.

Example:
${CmdPause} `$ParentFolder` `"d:\tools\free_upx\upx.exe" -v --brute $FileNames`
*/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Execute a command with cmd.exe 
;;  P1 :in: Working directory (""=$outdir) 
;;  P2 :in: Command and parameters 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
!define CmdNoWait    "!insertmacro _CmdExec 0"  ; nopause/nowait
!define CmdWait      "!insertmacro _CmdExec 1"  ; wait for end of execution
!define CmdPause     "!insertmacro _CmdExec 2"  ; pause before exiting
!define CmdPauseWait "!insertmacro _CmdExec 3"  ; pause + execwait
!define CmdStay      "!insertmacro _CmdExec 4"  ; stay in command prompt
!define CmdStayWait  "!insertmacro _CmdExec 5"  ; stay + execwait
!macro _CmdExec _Mode_ _WorkDir_ _CommandAndParams_
	Push $R0
	ExpandEnvStrings $R0 '%COMSPEC%'
	StrCmp "${_WorkDir_}" "" +3
	Push $OutDir
	SetOutPath "${_WorkDir_}"
	!if '${_Mode_}' = 1
		Exec `"$R0" /c "${_CommandAndParams_}" & echo. & echo. & pause`
	!else if '${_Mode_}' = 2
		ExecWait `"$R0" /c "${_CommandAndParams_}"`
	!else if '${_Mode_}' = 3
		ExecWait `"$R0" /c "${_CommandAndParams_}" & echo. & echo. & pause`
	!else if '${_Mode_}' = 4
		Exec `"$R0" /k "${_CommandAndParams_}"`
	!else if '${_Mode_}' = 5
		ExecWait `"$R0" /k "${_CommandAndParams_}"`
	!else
		Exec `"$R0" /c "${_CommandAndParams_}"`
	!endif
	StrCmp "${_WorkDir_}" "" +3
	Pop $R0
	SetOutPath "$R0"
	Pop $R0
!macroend