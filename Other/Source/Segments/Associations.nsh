;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Associations.nsh
;   User-scoped file associations, URL protocol handlers and context menu
;   entries, journaled so none of them outlive the app, even after a crash.
;
;   Everything is written under HKCU\Software\Classes only. UserChoice is
;   never touched, so Windows stays in charge of which app is the default:
;   an extension that already has a handler only gains an "Open with" entry
;   unless IfExists=replace is set.
;
; USAGE
;   [Activate]
;   FileAssociations=true
;
;   [FileAssociation1]
;   Extension=.myfile,.myother
;   ProgID=MyApp.Document
;   Description=My App Document
;   DefaultIcon=%PAL:AppDir%\MyApp\myapp.exe,0
;   OpenCommand="%PAL:AppDir%\MyApp\myapp.exe" "%1"
;   EditCommand="%PAL:AppDir%\MyApp\myapp.exe" /edit "%1"
;   IfExists=skip
;
;   Extension    One extension or a comma separated list. The dot is optional.
;   ProgID       Program identifier. Defaults to <AppID>.<first extension>.
;   Description  Friendly type name shown by Explorer.
;   DefaultIcon  Icon path,index.
;   OpenCommand  Command for the open verb (%1 = file path). Required.
;   EditCommand  Optional command for the edit verb.
;   IfExists     skip (default) or replace. With skip an extension that
;                already has a handler only gets the ProgID added to its
;                OpenWithProgids list (the "Open with" menu), and a ProgID
;                that already exists makes the whole section skip. With
;                replace the extension's default is set and an existing
;                ProgID is backed up and replaced.
;
;   [ProtocolHandler1]
;   Protocol=myapp
;   Description=My App Link
;   DefaultIcon=%PAL:AppDir%\MyApp\myapp.exe,0
;   OpenCommand="%PAL:AppDir%\MyApp\myapp.exe" "%1"
;   IfExists=skip
;
;   Protocol     URL scheme without "://".
;   OpenCommand  Command that handles the URL (%1 = full URL). Required.
;   IfExists     skip (default) leaves a scheme that is already registered
;                anywhere alone; replace overrides it for the current user.
;
;   [ContextMenu1]
;   Target=.txt
;   MenuKey=MyAppOpen
;   MenuText=Open with My App
;   MenuCommand="%PAL:AppDir%\MyApp\myapp.exe" "%1"
;   MenuIcon=%PAL:AppDir%\MyApp\myapp.exe,0
;   Position=Top
;   Extended=false
;   IfExists=skip
;
;   Target       .ext (any file with that extension), * (all files),
;                Directory, Directory\Background, Drive, Folder,
;                AllFilesystemObjects, or a ProgID. Extension is accepted as
;                an older name for this key.
;   MenuKey      Registry key name of the verb. Defaults to <AppID>.<N>.
;   MenuText     Text shown in the menu. Required.
;   MenuCommand  Command to run. Use %1 for files and folders, %V for
;                Directory\Background. Required.
;   MenuIcon     Optional icon path,index.
;   Position     Top or Bottom. Omit for the default position.
;   Extended     true to show the entry only with Shift held down.
;   IfExists     skip (default) or replace.
;
;   The user can turn the segment off with FileAssociations=false in the
;   <AppID>.ini user configuration file.
;
; HOW IT IS UNDONE
;   Every key that did not exist is recorded as REGKEY (deleted on undo) and
;   every parent key created for it as REGEMPTY (deleted only while empty).
;   A key that is replaced is exported with reg.exe first and re-imported on
;   undo. A value written to a key that already existed is recorded as
;   REGVALUE with its previous data. The shell is told about the change on
;   apply and on rollback.
;

!ifdef SEGMENTS_ASSOCIATIONS

!define ASSOC_CLASSES `Software\Classes`
!define /ifndef SHCNE_ASSOCCHANGED 0x08000000

Var AssocKey
Var AssocName
Var AssocData
Var AssocIfExists
Var AssocProgID
Var AssocList
Var AssocItem
Var AssocChanged
Var UserApprovesAssociations

;= HELPERS
;= ################

; Writes string $AssocData to value $AssocName of HKCU\Software\Classes\$AssocKey,
; journaling it first. Sets the error flag when it could not be journaled.
Function Assoc_WriteStr
	Push $0
	Push $1
	ClearErrors
	${Journal::RegKeyExists} HKCU `${ASSOC_CLASSES}\$AssocKey` $0
	${If} $0 == 1
		; Existing key: remember the previous value.
		ClearErrors
		ReadRegStr $1 HKCU `${ASSOC_CLASSES}\$AssocKey` $AssocName
		${If} ${Errors}
			ClearErrors
			ReadRegDWORD $1 HKCU `${ASSOC_CLASSES}\$AssocKey` $AssocName
			${If} ${Errors}
				StrCpy $1 ""
			${Else}
				StrCpy $1 `DWORD:$1`
			${EndIf}
		${Else}
			StrCpy $1 `STR:$1`
		${EndIf}
		${Journal::Record} Associations REGVALUE HKCU `${ASSOC_CLASSES}\$AssocKey` $AssocName $1
	${Else}
		${Journal::RegKey} Associations HKCU `${ASSOC_CLASSES}\$AssocKey` $0
	${EndIf}
	ClearErrors
	${If} $0 == ""
		SetErrors
	${Else}
		WriteRegStr HKCU `${ASSOC_CLASSES}\$AssocKey` $AssocName $AssocData
		StrCpy $AssocChanged true
	${EndIf}
	Pop $1
	Pop $0
FunctionEnd
!macro _Assoc_WriteStr _KEY _NAME _DATA
	StrCpy $AssocKey `${_KEY}`
	StrCpy $AssocName `${_NAME}`
	StrCpy $AssocData `${_DATA}`
	Call Assoc_WriteStr
!macroend
!define Assoc_WriteStr `!insertmacro _Assoc_WriteStr`

; Backs up and removes HKCU\Software\Classes\$AssocKey so it can be written
; from scratch. Sets the error flag when the backup failed (nothing changed).
Function Assoc_ReplaceKey
	Push $0
	ClearErrors
	${Journal::RegKeyExists} HKCU `${ASSOC_CLASSES}\$AssocKey` $0
	${If} $0 == 1
		${Journal::RegKey} Associations HKCU `${ASSOC_CLASSES}\$AssocKey` $0
		ClearErrors
		${If} $0 == existed
			DeleteRegKey HKCU `${ASSOC_CLASSES}\$AssocKey`
			StrCpy $AssocChanged true
		${Else}
			SetErrors
		${EndIf}
	${EndIf}
	Pop $0
FunctionEnd

; Removes the first item of the comma separated list in $AssocList and
; puts it, without surrounding spaces, in $AssocItem.
Function Assoc_PopItem
	Push $0
	Push $1
	StrCpy $0 0
	${Do}
		StrCpy $1 $AssocList 1 $0
		${If} $1 == ","
		${OrIf} $1 == ""
			${ExitDo}
		${EndIf}
		IntOp $0 $0 + 1
	${Loop}
	StrCpy $AssocItem $AssocList $0
	IntOp $0 $0 + 1
	StrCpy $AssocList $AssocList "" $0
	${Do}
		StrCpy $1 $AssocItem 1
		${IfThen} $1 != " " ${|} ${ExitDo} ${|}
		StrCpy $AssocItem $AssocItem "" 1
	${Loop}
	${Do}
		StrCpy $1 $AssocItem "" -1
		${IfThen} $1 != " " ${|} ${ExitDo} ${|}
		StrCpy $AssocItem $AssocItem -1
	${Loop}
	Pop $1
	Pop $0
FunctionEnd

; Reads one config value and expands %PAL:...% and environment variables
; (the launcher publishes the PAL locations as environment variables).
!macro _Assoc_Read _VAR _SECTION _KEY
	${ReadLauncherConfig} ${_VAR} `${_SECTION}` `${_KEY}`
	ExpandEnvStrings ${_VAR} ${_VAR}
!macroend
!define Assoc_Read `!insertmacro _Assoc_Read`

; Reads a command line. Windows strips one pair of outer quotes from INI
; values, so OpenCommand="C:\App\app.exe" "%1" arrives as
; C:\App\app.exe" "%1. A first quote that closes a word (no space before
; it, a space or the end after it) means that happened, and the quotes are
; put back.
Function Assoc_FixQuotes
	Push $0
	Push $1
	Push $2
	StrCpy $1 $AssocData 1
	${If} $1 != `"`
		StrCpy $0 0
		${Do}
			StrCpy $1 $AssocData 1 $0
			${IfThen} $1 == "" ${|} ${ExitDo} ${|}
			${If} $1 == `"`
				${If} $0 > 0
					IntOp $2 $0 - 1
					StrCpy $2 $AssocData 1 $2
					IntOp $0 $0 + 1
					StrCpy $1 $AssocData 1 $0
					${If} $1 == ""
						StrCpy $1 " "
					${EndIf}
					${If} $2 != " "
					${AndIf} $1 == " "
						StrCpy $AssocData `"$AssocData"`
					${EndIf}
				${EndIf}
				${ExitDo}
			${EndIf}
			IntOp $0 $0 + 1
		${Loop}
	${EndIf}
	Pop $2
	Pop $1
	Pop $0
FunctionEnd
!macro _Assoc_ReadCommand _VAR _SECTION _KEY
	${Assoc_Read} $AssocData `${_SECTION}` `${_KEY}`
	Call Assoc_FixQuotes
	StrCpy ${_VAR} $AssocData
!macroend
!define Assoc_ReadCommand `!insertmacro _Assoc_ReadCommand`

;= FILE ASSOCIATIONS
;= ################

; Applies [FileAssociation$R0].
Function Assoc_FileType
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6

	${Assoc_Read} $1 FileAssociation$R0 Extension
	${Assoc_ReadCommand} $2 FileAssociation$R0 OpenCommand
	${If} $1 == ""
	${OrIf} $2 == ""
		${DebugMsg} "[FileAssociation$R0] needs Extension and OpenCommand; skipped."
		Goto assoc_ft_done
	${EndIf}
	${ReadLauncherConfig} $AssocProgID FileAssociation$R0 ProgID
	${If} $AssocProgID == ""
		StrCpy $AssocList $1
		Call Assoc_PopItem
		StrCpy $3 $AssocItem 1
		${IfThen} $3 == "." ${|} StrCpy $AssocItem $AssocItem "" 1 ${|}
		StrCpy $AssocProgID `${APPNAME}.$AssocItem`
	${EndIf}
	${Assoc_Read} $3 FileAssociation$R0 Description
	${Assoc_Read} $4 FileAssociation$R0 DefaultIcon
	${Assoc_ReadCommand} $5 FileAssociation$R0 EditCommand
	${ReadLauncherConfigWithDefault} $AssocIfExists FileAssociation$R0 IfExists skip
	${NewStrCase} $AssocIfExists $AssocIfExists L
	${IfThen} $AssocIfExists == backup ${|} StrCpy $AssocIfExists replace ${|}

	; The ProgID.
	${Journal::RegKeyExists} HKCU `${ASSOC_CLASSES}\$AssocProgID` $0
	${If} $0 == 1
		${If} $AssocIfExists != replace
			${DebugMsg} "[FileAssociation$R0] ProgID $AssocProgID already exists; skipped."
			Goto assoc_ft_done
		${EndIf}
		StrCpy $AssocKey $AssocProgID
		Call Assoc_ReplaceKey
		${If} ${Errors}
			${DebugMsg} "[FileAssociation$R0] could not back up $AssocProgID; skipped."
			Goto assoc_ft_done
		${EndIf}
	${EndIf}
	${Assoc_WriteStr} $AssocProgID "" $3
	${IfThen} ${Errors} ${|} Goto assoc_ft_done ${|}
	${If} $3 != ""
		${Assoc_WriteStr} $AssocProgID FriendlyTypeName $3
	${EndIf}
	${If} $4 != ""
		${Assoc_WriteStr} `$AssocProgID\DefaultIcon` "" $4
	${EndIf}
	${Assoc_WriteStr} `$AssocProgID\shell\open\command` "" $2
	${If} $5 != ""
		${Assoc_WriteStr} `$AssocProgID\shell\edit\command` "" $5
	${EndIf}

	; Each extension.
	StrCpy $AssocList $1
	${Do}
		${IfThen} $AssocList == "" ${|} ${ExitDo} ${|}
		Call Assoc_PopItem
		StrCpy $0 $AssocItem
		${If} $0 != ""
			StrCpy $3 $0 1
			${IfThen} $3 != "." ${|} StrCpy $0 `.$0` ${|}
			; Always offer it in "Open with".
			${Assoc_WriteStr} `$0\OpenWithProgids` $AssocProgID ""
			; Only become the handler when there is none, or when asked to.
			ClearErrors
			ReadRegStr $3 HKCR $0 ""
			${If} $3 == ""
			${OrIf} $AssocIfExists == replace
				${Assoc_WriteStr} $0 "" $AssocProgID
				${DebugMsg} "[FileAssociation$R0] $0 -> $AssocProgID."
			${Else}
				${DebugMsg} "[FileAssociation$R0] $0 is handled by $3; added to Open with only."
			${EndIf}
		${EndIf}
	${Loop}

	assoc_ft_done:
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

;= PROTOCOL HANDLERS
;= ################

; Applies [ProtocolHandler$R0].
Function Assoc_Protocol
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4

	${ReadLauncherConfig} $1 ProtocolHandler$R0 Protocol
	${Assoc_ReadCommand} $2 ProtocolHandler$R0 OpenCommand
	; Accept "myapp:" and "myapp://" as well.
	StrCpy $0 0
	${Do}
		StrCpy $3 $1 1 $0
		${If} $3 == ":"
		${OrIf} $3 == ""
			${ExitDo}
		${EndIf}
		IntOp $0 $0 + 1
	${Loop}
	StrCpy $1 $1 $0
	${If} $1 == ""
	${OrIf} $2 == ""
		${DebugMsg} "[ProtocolHandler$R0] needs Protocol and OpenCommand; skipped."
		Goto assoc_pr_done
	${EndIf}
	${Assoc_Read} $3 ProtocolHandler$R0 Description
	${IfThen} $3 == "" ${|} StrCpy $3 `URL:$1 Protocol` ${|}
	${Assoc_Read} $4 ProtocolHandler$R0 DefaultIcon
	${ReadLauncherConfigWithDefault} $AssocIfExists ProtocolHandler$R0 IfExists skip
	${NewStrCase} $AssocIfExists $AssocIfExists L
	${IfThen} $AssocIfExists == backup ${|} StrCpy $AssocIfExists replace ${|}

	; Registered anywhere (user or machine)?
	${Journal::RegKeyExists} HKCR $1 $0
	${If} $0 == 1
		${If} $AssocIfExists != replace
			${DebugMsg} "[ProtocolHandler$R0] $1: is already registered; skipped."
			Goto assoc_pr_done
		${EndIf}
		StrCpy $AssocKey $1
		Call Assoc_ReplaceKey
		${If} ${Errors}
			${DebugMsg} "[ProtocolHandler$R0] could not back up $1:; skipped."
			Goto assoc_pr_done
		${EndIf}
	${EndIf}
	${Assoc_WriteStr} $1 "" $3
	${IfThen} ${Errors} ${|} Goto assoc_pr_done ${|}
	${Assoc_WriteStr} $1 "URL Protocol" ""
	${If} $4 != ""
		${Assoc_WriteStr} `$1\DefaultIcon` "" $4
	${EndIf}
	${Assoc_WriteStr} `$1\shell\open\command` "" $2
	${DebugMsg} "[ProtocolHandler$R0] $1: -> $2."

	assoc_pr_done:
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

;= CONTEXT MENUS
;= ################

; Applies [ContextMenu$R0].
Function Assoc_ContextMenu
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6

	ClearErrors
	${ReadLauncherConfig} $1 ContextMenu$R0 Target
	${If} ${Errors}
		${ReadLauncherConfig} $1 ContextMenu$R0 Extension
	${EndIf}
	${ReadLauncherConfig} $5 ContextMenu$R0 MenuText
	${Assoc_ReadCommand} $2 ContextMenu$R0 MenuCommand
	${If} $1 == ""
	${OrIf} $2 == ""
	${OrIf} $5 == ""
		${DebugMsg} "[ContextMenu$R0] needs Target, MenuText and MenuCommand; skipped."
		Goto assoc_cm_done
	${EndIf}
	${ReadLauncherConfigWithDefault} $3 ContextMenu$R0 MenuKey `${APPNAME}.$R0`
	${Assoc_Read} $4 ContextMenu$R0 MenuIcon
	${ReadLauncherConfig} $6 ContextMenu$R0 Position
	${ReadLauncherConfigWithDefault} $AssocIfExists ContextMenu$R0 IfExists skip
	${NewStrCase} $AssocIfExists $AssocIfExists L
	${IfThen} $AssocIfExists == backup ${|} StrCpy $AssocIfExists replace ${|}

	; Extensions go through SystemFileAssociations, which works whatever
	; program currently owns the extension.
	StrCpy $0 $1 1
	${If} $0 == "."
		StrCpy $1 `SystemFileAssociations\$1`
	${EndIf}
	StrCpy $1 `$1\shell\$3`

	${Journal::RegKeyExists} HKCR $1 $0
	${If} $0 == 1
		${If} $AssocIfExists != replace
			${DebugMsg} "[ContextMenu$R0] $1 already exists; skipped."
			Goto assoc_cm_done
		${EndIf}
		StrCpy $AssocKey $1
		Call Assoc_ReplaceKey
		${If} ${Errors}
			${DebugMsg} "[ContextMenu$R0] could not back up $1; skipped."
			Goto assoc_cm_done
		${EndIf}
	${EndIf}
	${Assoc_WriteStr} $1 "" $5
	${IfThen} ${Errors} ${|} Goto assoc_cm_done ${|}
	${Assoc_WriteStr} $1 MUIVerb $5
	${If} $4 != ""
		${Assoc_WriteStr} $1 Icon $4
	${EndIf}
	${NewStrCase} $6 $6 L
	${If} $6 == top
		${Assoc_WriteStr} $1 Position Top
	${ElseIf} $6 == bottom
		${Assoc_WriteStr} $1 Position Bottom
	${EndIf}
	${ReadLauncherConfig} $6 ContextMenu$R0 Extended
	${If} $6 == true
		${Assoc_WriteStr} $1 Extended ""
	${EndIf}
	${Assoc_WriteStr} `$1\command` "" $2
	${DebugMsg} "[ContextMenu$R0] added $1."

	assoc_cm_done:
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

Function Assoc_NotifyShell
	System::Call `shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i 0, p 0, p 0)`
FunctionEnd

${SegmentFile}

${SegmentPrePrimary}
	${ReadUserConfigWithDefault} $UserApprovesAssociations FileAssociations true
	${If} $UserApprovesAssociations != false
		StrCpy $AssocChanged false
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 FileAssociation$R0 Extension
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			Call Assoc_FileType
			IntOp $R0 $R0 + 1
		${Loop}
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 ProtocolHandler$R0 Protocol
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			Call Assoc_Protocol
			IntOp $R0 $R0 + 1
		${Loop}
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 ContextMenu$R0 MenuCommand
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			Call Assoc_ContextMenu
			IntOp $R0 $R0 + 1
		${Loop}
		${If} $AssocChanged == true
			Call Assoc_NotifyShell
		${EndIf}
	${EndIf}
!macroend

${SegmentPostPrimary}
	${Journal::HasEntries} Associations $R0
	${If} $R0 > 0
		${Journal::Rollback} Associations
		Call Assoc_NotifyShell
	${EndIf}
!macroend

!endif ; SEGMENTS_ASSOCIATIONS
