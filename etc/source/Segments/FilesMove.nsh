;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   FilesMove.nsh
;   This file provides support for moving files that are configured in the CompilerWrapper.ini file.
; 

!define BAK "BackupBy${APPNAME}"
!define File::BackupLocal "!insertmacro File::BackupLocal"
!macro File::BackupLocal _LOCALFILE
	Delete `${_LOCALFILE}.${BAK}`
	Rename `${_LOCALFILE}` `${_LOCALFILE}.${BAK}`
!macroend
!define File::RestoreLocal "!insertmacro File::RestoreLocal"
!macro File::RestoreLocal _LOCALFILE
	Delete `${_LOCALFILE}`
	Rename `${_LOCALFILE}.${BAK}` `${_LOCALFILE}`
!macroend
!define File::BackupPortable "!insertmacro File::BackupPortable"
!macro File::BackupPortable _LOCALFILE _PORTABLEFILE
	Delete `${_PORTABLEFILE}`
	Rename `${_LOCALFILE}` `${_PORTABLEFILE}`
!macroend
!define File::RestorePortable "!insertmacro File::RestorePortable"
!macro File::RestorePortable _LOCALFILE _PORTABLEFILE
	Rename `${_PORTABLEFILE}` `${_LOCALFILE}`
!macroend
!define File::CopyPortable "!insertmacro File::CopyPortable"
!macro File::CopyPortable _LOCALFILE _PORTABLEFILE
	CopyFiles /SILENT `${_PORTABLEFILE}` `${_LOCALFILE}`
!macroend
!define File::BackupLocalCopy "!insertmacro File::BackupLocalCopy"
!macro File::BackupLocalCopy _LOCALFILE
	Delete `${_LOCALFILE}.${BAK}`
	CopyFiles /SILENT `${_LOCALFILE}` `${_LOCALFILE}.${BAK}`
!macroend
!macro _FilesMove_Start
	ExpandEnvStrings $0 $0
	ExpandEnvStrings $1 $1
	${GetFileName} $0 $2
	StrCpy $0 ${SET}\$0
	StrCpy $4 $1
	StrCpy $1 $1\$2
!macroend

${SegmentFile}
${SegmentPrePrimary}
	!ifmacrodef PreFilesMove
		!insertmacro PreFilesMove
	!endif
	${ForEachINIPair} FilesMove $0 $1
		!insertmacro _FilesMove_Start
		StrLen $R0 $EXEDIR
		StrCpy $R0 $1 $R0
		StrCmp $R0 $EXEDIR 0 +3
		StrCpy $7 in-package
		Goto +2
		StrCpy $7 not-in-package
		${If} $7 != in-package
			${ForEachFile} $4 $2 $1
				Delete "$4.${BAK}"
				Rename $4 $4.${BAK}
			${NextFile}
		${Else}
			${ForEachFile} $4 $2 $1
				${Break}
			${NextFile}
			${IfNot} ${Errors}
				${ForEachFile} $4 $2 $0
					Delete $4
				${NextFile}
				StrCpy $7 in-package-done
			${EndIf}
		${EndIf}
		${GetParent} $1 $4
		${IfNot} ${FileExists} $4
			CreateDirectory $4
			${WriteRuntimeData} FilesMove RemoveIfEmpty:$4 true
		${EndIf}
		${If} $7 != in-package-done
			${ForEachFile} $3 $2 $0
				ClearErrors
				Rename $3 $4\$2
				IfErrors 0 +2
				CopyFiles /SILENT $3 $4\$2
			${NextFile}
		${EndIf}
	${NextINIPair}
	!ifmacrodef UnPreFilesMove
		!insertmacro UnPreFilesMove
	!endif
!macroend
${SegmentPostPrimary}
	!ifmacrodef PostFilesMove
		!insertmacro PostFilesMove
	!endif
	${ForEachINIPair} FilesMove $0 $1
		!insertmacro _FilesMove_Start
		StrLen $R0 $EXEDIR
		StrCpy $R0 $1 $R0
		StrCmp $R0 $EXEDIR 0 +2
		StrCpy $7 in-package
		${GetParent} $0 $3
		${ForEachFile} $4 $2 $1
			StrCmp $RunLocally true +8
			ClearErrors
			Delete $3\$2
			Rename $4 $3\$2
			IfErrors 0 +3
			Delete $3\$2
			CopyFiles /SILENT $4 $3\$2
			Delete $4
		${NextFile}
		${GetParent} $1 $4
		${ReadRuntimeData} $2 FilesMove RemoveIfEmpty:$4
			StrCmp $2 true 0 +2
			RMDir $4
		${ForEachFile} $3 $2 $1.${BAK}
			${GetBaseName} $2 $2
			Rename $3 $4\$2
		${NextFile}
	${NextINIPair}
	!ifmacrodef UnPostFilesMove
		!insertmacro UnPostFilesMove
	!endif
!macroend
