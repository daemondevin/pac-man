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

LangString LauncherTaskCleanupFailed ${LANG_ENGLISH}      "The Windows Task "$R1" was created during your use of ${PORTABLEAPPNAME} and has failed to be removed.${NewLine}${NewLine}Manual removal is required."
LangString LauncherTaskCleanupFailed ${LANG_SIMPCHINESE}  "Windows任务“$R1”是在您使用${PORTABLEAPPNAME}期间创建的，并且无法被删除。${NewLine}${NewLine}需要手动删除。"
LangString LauncherTaskCleanupFailed ${LANG_FRENCH}       "La tâche de Windows "$R1" a été créée pendant votre utilisation de ${PORTABLEAPPNAME} et n'a pas été supprimé. ${NewLine}${NewLine}L'enlèvement manuel est requis."
LangString LauncherTaskCleanupFailed ${LANG_GERMAN}       "Die Windows-Task "$R1" wurde während deiner Benutzung von ${PORTABLEAPPNAME} erstellt und konnte nicht entfernt werden.${NewLine}${NewLine}Manuelle Entfernung ist erforderlich."
LangString LauncherTaskCleanupFailed ${LANG_ITALIAN}      "L'operazione di Windows "$R1" è stata creata durante l'utilizzo di ${PORTABLEAPPNAME} e non è stato rimosso. ${NewLine}${NewLine}Rimozione manuale è necessaria."
LangString LauncherTaskCleanupFailed ${LANG_JAPANESE}     "${PABLEABLEAPPNAME}の使用中にWindowsタスク "$R1"が作成され、削除に失敗しました${NewLine}${NewLine}手動での削除が必要です。"
LangString LauncherTaskCleanupFailed ${LANG_PORTUGUESEBR} "A Tarefa do Windows "$R1" foi criada durante o uso de ${PORTABLEAPPNAME} e não foi removida.${NewLine}${NewLine}A remoção manual é necessária."
LangString LauncherTaskCleanupFailed ${LANG_SPANISH}      "La tarea de Windows "$R1" se creó durante el uso de ${PORTABLEAPPNAME} y no se ha podido eliminar.${NewLine}${NewLine}Se requiere la eliminación manual."

${SegmentFile}
${SegmentPostPrimary}
	!ifmacrodef TaskCleanup
		!insertmacro TaskCleanup
	!endif
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $R1 TaskCleanup $R0
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${DeleteTask} $0 "$R1"
		StrCmpS $0 false 0 +3
		${WriteRuntimeData} TaskCleanup "Failed[$R0]" "$R1"
		IntOp $R0 $R0 + 1
	${Loop}
!macroend
${SegmentUnload}
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadRuntimeData} $R1 TaskCleanup "Failed[$R0]"
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		MessageBox MB_ICONEXCLAMATION|MB_TOPMOST \ 
			"$(LauncherTaskCleanupFailed)"
		IntOp $R0 $R0 + 1
	${Loop}
!macroend