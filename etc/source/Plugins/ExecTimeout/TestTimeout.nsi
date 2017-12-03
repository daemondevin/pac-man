;-----------------------------------------------------------------------------------
; ExecTimeout
;-----------------------------------------------------------------------------------
;
; Usage:
;   ${ExecTimeout} <Commandline> <Timeout> <Terminate> <Var ExitCode>
;
; Arguments:
;   <Commandline> should contain the path to the executable file [string]
;   <Timeout> specifies the timeout in milliseconds [integer]
;   <Terminate> specifies whether the process will be terminated on timeout [0|1]
;
; Return Value:
;   <ExitCode> will return the exit code of the application, "timeout" or "error"
;
;-----------------------------------------------------------------------------------


;-----------------------------------------------------------------------------------
; Include
;-----------------------------------------------------------------------------------

!macro ExecTimeout commandline timeout_ms terminate var_exitcode
  Timeout::ExecTimeout '${commandline}' '${timeout_ms}' '${terminate}'
  Pop ${var_exitcode}
!macroend

!define ExecTimeout "!insertmacro ExecTimeout"


;-----------------------------------------------------------------------------------
; Example
;-----------------------------------------------------------------------------------

Name "TestTimeout"
OutFile "TestTimeout.exe"

ShowInstDetails show

Section
  MessageBox MB_ICONINFORMATION "I will start Notepad now. It will time out after 5 seconds!"
  DetailPrint 'Executing: "$WINDIR\Notepad.exe"'
  
  ${ExecTimeout} '"$WINDIR\Notepad.exe"' 5000 1 $0
  
  DetailPrint "Exit Code: $0"
SectionEnd
