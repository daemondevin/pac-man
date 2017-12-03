;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   DirectoriesMove.nsh
;   This file provides support for moving folders that are configured in the CompilerWrapper.ini file.
; 

Function Root
	!macro _Root _PATH _RET
		Push `${_PATH}`
		Call Root
		Pop ${_RET}
	!macroend
	!define Root `!insertmacro _Root`
	Exch $0
	Push $1
	Push $2
	Push $3
	StrCpy $1 $0 2
	StrCmp $1 '\\' +5
	StrCpy $2 $1 1 1
	StrCmp $2 ':' 0 +16
	StrCpy $0 $1
	Goto +15
	StrCpy $2 1
	StrCpy $3 ''
	IntOp $2 $2 + 1
	StrCpy $1 $0 1 $2
	StrCmp $1$3 '' +9
	StrCmp $1 '' +5
	StrCmp $1 '\' 0 -4
	StrCmp $3 '1' +3
	StrCpy $3 '1'
	Goto -7
	StrCpy $0 $0 $2
	StrCpy $2 $0 1 -1
	StrCmp $2 '\' 0 +2
	StrCpy $0 ''
	Pop $3
	Pop $2
	Pop $1
	Exch $0
FunctionEnd
!define Directory::BackupLocal `!insertmacro Directory::BackupLocal`
!macro Directory::BackupLocal _LOCALDIR _SUBDIR
	RMDir /r `${_LOCALDIR}\${_SUBDIR}.BackupBy${APPNAME}`
	Rename `${_LOCALDIR}\${_SUBDIR}` `${_LOCALDIR}\${_SUBDIR}.BackupBy${APPNAME}`
!macroend
!define Directory::RestoreLocal `!insertmacro Directory::RestoreLocal`
!macro Directory::RestoreLocal _LOCALDIR _SUBDIR
	RMDir /r `${_LOCALDIR}\${_SUBDIR}`
	Rename `${_LOCALDIR}\${_SUBDIR}.BackupBy${APPNAME}` `${_LOCALDIR}\${_SUBDIR}`
	RMDir `${_LOCALDIR}`
!macroend
!define Directory::BackupPortable `!insertmacro Directory::BackupPortable`
!macro Directory::BackupPortable _LOCALDIR _SUBDIR _PORTABLEDIR _VAR1 _VAR2
	IfFileExists `${_LOCALDIR}\${_SUBDIR}` 0 +17
	Push `${_PORTABLEDIR}`
	Call Root
	Pop ${_VAR1}
	Push `${_LOCALDIR}`
	Call Root
	Pop ${_VAR2}
	RMDir /r `${_PORTABLEDIR}`
	RMDir `${_LOCALDIR}\${_SUBDIR}`
	IfFileExists `${_LOCALDIR}\${_SUBDIR}` 0 +7
	StrCmp ${_VAR1} ${_VAR2} 0 +4
	ClearErrors
	Rename `${_LOCALDIR}\${_SUBDIR}` `${_PORTABLEDIR}`
	IfErrors 0 +3
	CreateDirectory `${_PORTABLEDIR}`
	CopyFiles /SILENT `${_LOCALDIR}\${_SUBDIR}\*.*` `${_PORTABLEDIR}`
	RMDir `${_LOCALDIR}`
!macroend
!define Directory::RestorePortable `!insertmacro Directory::RestorePortable`
!macro Directory::RestorePortable _LOCALDIR _SUBDIR _PORTABLEDIR _VAR1 _VAR2
	IfFileExists `${_PORTABLEDIR}` 0 +14
	Push `${_PORTABLEDIR}`
	Call Root
	Pop ${_VAR1}
	Push `${_LOCALDIR}`
	Call Root
	Pop ${_VAR2}
	StrCmp ${_VAR1} ${_VAR2} 0 +5
	CreateDirectory `${_LOCALDIR}`
	ClearErrors
	Rename `${_PORTABLEDIR}` `${_LOCALDIR}\${_SUBDIR}`
	IfErrors 0 +3
	CreateDirectory `${_LOCALDIR}\${_SUBDIR}`
	CopyFiles /SILENT `${_PORTABLEDIR}\*.*` `${_LOCALDIR}\${_SUBDIR}`
!macroend
!macro _DirectoriesMove_Start
	StrCmpS $0 - +3
	ExpandEnvStrings $0 $0
	StrCpy $0 ${SET}\$0
	ExpandEnvStrings $1 $1
!macroend

${SegmentFile}
${SegmentPrePrimary}
	!ifmacrodef PreDirMove
		!insertmacro PreDirMove
	!endif
	${ForEachINIPair} DirectoriesMove $0 $1
		!insertmacro _DirectoriesMove_Start
		StrCmp $0 ${CONF} 0 +2
		MessageBox MB_ICONSTOP|MB_TOPMOST `You cannot [DirectoriesMove] settings`
		StrLen $R0 $EXEDIR
		StrCpy $R0 $1 $R0
		StrCmp $R0 $EXEDIR 0 +3
		StrCpy $7 in-package
		Goto +2
		StrCpy $7 not-in-package
		${If} $7 != in-package
			${ForEachDirectory} $4 $3 $1
				RMDir /r $4.BackupBy${APPNAME}
				Rename $4 $4.BackupBy${APPNAME}
			${NextDirectory}
		${ElseIf} $0 != -
			${ForEachDirectory} $4 $3 $1
				${Break}
			${NextDirectory}
			${IfNot} ${Errors}
				${ForEachDirectory} $4 $3 $0
					RMDir /r $4
				${NextDirectory}
				StrCpy $7 in-package-done
			${EndIf}
		${EndIf}
		${If} $0 == -
			${IfNot} ${WildCardFlag}
				CreateDirectory $1
			${EndIf}
		${ElseIf} $7 != in-package-done
			${GetParent} $1 $4
			IfFileExists $4 +4
			CreateDirectory $4
			${WriteRuntimeData} DirectoriesMove RemoveIfEmpty:$4 true
			${ForEachDirectory} $3 $2 $0
				${IfNot} ${WildCardFlag}
					${GetFileName} $1 $2
				${EndIf}
				${GetRoot} $0 $5
				${GetRoot} $1 $6
				StrCmp $5 $6 0 +3
				Rename $3 $4\$2
				Goto +3
				CreateDirectory $4\$2
				CopyFiles /SILENT $3\*.* $4\$2
			${NextDirectory}
			${If} ${Errors}
				${IfNot} ${WildCardFlag}
					CreateDirectory $1
				${EndIf}
			${EndIf}
		${EndIf}
	${NextINIPair}
	!ifmacrodef UnPreDirMove
		!insertmacro UnPreDirMove
	!endif
!macroend
${SegmentPostPrimary}
	!ifmacrodef PostDirMove
		!insertmacro PostDirMove
	!endif
	${ForEachINIPair} DirectoriesMove $0 $1
		!insertmacro _DirectoriesMove_Start
		StrLen $R0 $EXEDIR
		StrCpy $R0 $1 $R0
		StrCmp $R0 $EXEDIR 0 +2
		StrCpy $7 in-package
		${GetParent} $0 $3
		${ForEachDirectory} $4 $2 $1
			${IfNot} ${WildCardFlag}
				${GetFileName} $0 $2
			${EndIf}
			StrCmpS $0 - +16
			StrCmpS $RunLocally true +15
			Push $0
			Call Root
			Pop $5
			Push $1
			Call Root
			Pop $6
			RMDir $4
			IfFileExists $4 0 +7
			StrCmp $5 $6 0 +4
			ClearErrors
			Rename $4 $3\$2
			IfErrors 0 +3
			CreateDirectory $3\$2
			CopyFiles /SILENT $4\*.* $3\$2
			RMDir /r $4
		${NextDirectory}
		${GetParent} $1 $4
		${ReadRuntimeData} $2 DirectoriesMove RemoveIfEmpty:$4
		StrCmpS $2 true 0 +2
		RMDir $4
		${ForEachDirectory} $3 $2 $1.BackupBy${APPNAME}
			${GetBaseName} $2 $2
			Rename $3 $4\$2
		${NextDirectory}
	${NextINIPair}
	!ifmacrodef UnPostDirMove
		!insertmacro UnPostDirMove
	!endif
!macroend
