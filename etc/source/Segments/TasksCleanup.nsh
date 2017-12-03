;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   TasksCleanup.nsh
;   This file handles removing any Windows Tasks that were created during runtime.
; 

;
; DeleteTask written by daemon.devin
;
Function DeleteTask
    !define TaskGUID    `{148BD52A-A2AB-11CE-B11F-00AA00530503}`
    !define ITaskGUID   `{148BD527-A2AB-11CE-B11F-00AA00530503}`
    !define OLE         `ole32::CoCreateInstance(g"${TaskGUID}",`
    !define OLE32       `${OLE}i0,i11,g "${ITaskGUID}",*i.r1)i.r2`
    !define DeleteTask "!insertmacro _DeleteTask"
    !macro _DeleteTask _RESULT _TASK
        Push ${_Task}
        Call DeleteTask 
        Pop ${_RESULT}
    !macroend
    Exch $0
    Push $0
    Push $1
    Push $2
    Push $3
    StrCpy $3 false
    System::Call `${OLE32}`
    IntCmp $2 0 0 +5
    System::Call "$1->7(w r0)i.r2"
    IntCmp $2 0 0 +3
    System::Call "$1->2()"
    StrCpy $3 true
    Pop $2
    Pop $1
    Pop $0
    Exch $3
FunctionEnd

${SegmentFile}
${SegmentPrePrimary}
	!ifmacrodef PreTaskCleanup
		!insertmacro PreTaskCleanup
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadWrapperConfig} $R1 TaskCleanup $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $R1
		${If} ${FileExists} "$SYSDIR\Tasks\$R1"
			${WriteRuntimeData} LocalTask "$R0" "true"
		${Else}
			${WriteRuntimeData} LocalTask "$R0" "false"
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentPostPrimary}
	!ifmacrodef PostTaskCleanup
		!insertmacro PostTaskCleanup
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadWrapperConfig} $R1 TaskCleanup $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${ParseLocations} $R1
		${ReadRuntimeData} $R2 LocalTask "$R0"
		${If} $R2 == false
			${DeleteTask} $0 "$R1"
			StrCmpS $0 false 0 +3
			${WriteRuntimeData} TaskCleanup "$R0" "false"
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
