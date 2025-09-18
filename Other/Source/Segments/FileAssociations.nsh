;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; FileAssociations.nsh
;   This file handles file associations, protocol handlers, context menus,
;   and shell integration for portable applications with comprehensive
;   backup and restore capabilities.
; 
; USAGE
;	Add sections [FileAssociation1], [ProtocolHandler1], [ContextMenu1] etc. to Launcher.ini
;
;	FileAssociation Keys:
;	Extension		-	File extension (e.g., .txt, .myfile)
;	ProgID			-	Program identifier (e.g., MyApp.Document)
;	Description		-	File type description
;	DefaultIcon		-	Path to icon file,index
;	OpenCommand		-	Command to open files (%1 = filepath)
;	EditCommand		-	Command to edit files (optional)
;	PrintCommand	-	Command to print files (optional)
;	IfExists		-	skip, backup, replace
;	Priority		-	high, normal, low (for conflicting associations)
;	MimeType		-	MIME type for web integration (optional)
;
;	ProtocolHandler Keys:
;	Protocol		-	Protocol name (e.g., myapp, mailto)
;	ProgID			-	Program identifier
;	Description		-	Protocol description
;	DefaultIcon		-	Path to icon file,index
;	OpenCommand		-	Command to handle protocol (%1 = full URL)
;	IfExists		-	skip, backup, replace
;
;	ContextMenu Keys:
;	Extension		-	File extension or * for all files
;	MenuText		-	Text to show in context menu
;	MenuCommand		-	Command to execute (%1 = filepath)
;	MenuIcon		-	Path to icon file,index (optional)
;	Position		-	top, middle, bottom
;	IfExists		-	skip, backup, replace
;	Condition		-	Registry condition to check (optional)
;
; EXAMPLE
;	[FileAssociation1]
;	Extension=.myfile
;	ProgID=MyPortableApp.Document
;	Description=My Portable App Document
;	DefaultIcon=%PAL:AppDir%\App\myapp.exe,0
;	OpenCommand="%PAL:AppDir%\App\myapp.exe" "%1"
;	EditCommand="%PAL:AppDir%\App\myapp.exe" --edit "%1"
;	IfExists=backup
;	Priority=high
;	MimeType=application/x-myapp-document
;

!ifdef FILEASSOCIATIONS
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
!ifndef STR_CASE_NSH_INCLUDED
	!include StrCase.nsh
!endif
!ifndef WORDREPLACE_NSH_INCLUDED
	!include WordReplace.nsh
!endif

; Shell notification constants
!define SHCNE_ASSOCCHANGED 0x08000000
!define SHCNF_IDLIST 0x0000
!define SHCHANGENOTIFY `Shell32::SHChangeNotify(i ${SHCNE_ASSOCCHANGED}, i ${SHCNF_IDLIST}, i 0, i 0)`

; File association management macros

; Check if file association exists
!define FileAssoc::Exists `!insertmacro _FileAssoc::Exists`
!macro _FileAssoc::Exists _EXTENSION _RESULT _CURRENT_PROGID _CURRENT_COMMAND
	Push $0
	Push $1
	Push $2
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_CURRENT_PROGID} ""
	StrCpy ${_CURRENT_COMMAND} ""
	
	; Check if extension is registered
	ReadRegStr $0 HKCR "${_EXTENSION}" ""
	${IfNot} ${Errors}
		StrCpy ${_RESULT} "true"
		StrCpy ${_CURRENT_PROGID} "$0"
		
		; Get current open command
		ReadRegStr $1 HKCR "$0\shell\open\command" ""
		${IfNot} ${Errors}
			StrCpy ${_CURRENT_COMMAND} "$1"
		${EndIf}
		
		${DebugMsg} "File association exists for ${_EXTENSION}: $0 -> $1"
	${Else}
		${DebugMsg} "No file association found for ${_EXTENSION}"
	${EndIf}
	
	Pop $2
	Pop $1
	Pop $0
!macroend

; Backup file association
!define FileAssoc::Backup `!insertmacro _FileAssoc::Backup`
!macro _FileAssoc::Backup _EXTENSION _SECTION _KEY
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	
	${DebugMsg} "Backing up file association for: ${_EXTENSION}"
	
	; Backup main extension registration
	ReadRegStr $0 HKCR "${_EXTENSION}" ""
	${IfNot} ${Errors}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_ProgID" "$0"
		
		; Backup ProgID details
		ReadRegStr $1 HKCR "$0" ""
		${IfNot} ${Errors}
			${WriteRuntimeData} ${_SECTION} "${_KEY}_Description" "$1"
		${EndIf}
		
		; Backup default icon
		ReadRegStr $2 HKCR "$0\DefaultIcon" ""
		${IfNot} ${Errors}
			${WriteRuntimeData} ${_SECTION} "${_KEY}_DefaultIcon" "$2"
		${EndIf}
		
		; Backup shell commands
		ReadRegStr $3 HKCR "$0\shell\open\command" ""
		${IfNot} ${Errors}
			${WriteRuntimeData} ${_SECTION} "${_KEY}_OpenCommand" "$3"
		${EndIf}
		
		ReadRegStr $4 HKCR "$0\shell\edit\command" ""
		${IfNot} ${Errors}
			${WriteRuntimeData} ${_SECTION} "${_KEY}_EditCommand" "$4"
		${EndIf}
		
		ReadRegStr $5 HKCR "$0\shell\print\command" ""
		${IfNot} ${Errors}
			${WriteRuntimeData} ${_SECTION} "${_KEY}_PrintCommand" "$5"
		${EndIf}
		
		; Backup MIME type if exists
		ReadRegStr $1 HKCR "${_EXTENSION}" "Content Type"
		${IfNot} ${Errors}
			${WriteRuntimeData} ${_SECTION} "${_KEY}_MimeType" "$1"
		${EndIf}
		
		; Backup perceived type
		ReadRegStr $2 HKCR "${_EXTENSION}" "PerceivedType"
		${IfNot} ${Errors}
			${WriteRuntimeData} ${_SECTION} "${_KEY}_PerceivedType" "$2"
		${EndIf}
		
		${WriteRuntimeData} ${_SECTION} "${_KEY}_BackupComplete" "true"
		${DebugMsg} "File association backup completed for ${_EXTENSION}"
	${Else}
		${DebugMsg} "No existing file association to backup for ${_EXTENSION}"
	${EndIf}
	
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Create file association
!define FileAssoc::Create `!insertmacro _FileAssoc::Create`
!macro _FileAssoc::Create _EXTENSION _PROGID _DESCRIPTION _ICON _OPENCOMMAND _EDITCOMMAND _PRINTCOMMAND _MIMETYPE _RESULT
	Push $0
	Push $1
	Push $R8
	
	StrCpy ${_RESULT} "true"
	${DebugMsg} "Creating file association: ${_EXTENSION} -> ${_PROGID}"
	
	; Register extension to ProgID
	WriteRegStr HKCR "${_EXTENSION}" "" "${_PROGID}"
	${If} ${Errors}
		StrCpy ${_RESULT} "false"
		${DebugMsg} "Failed to register extension ${_EXTENSION}"
		Goto FileAssocCreateEnd
	${EndIf}
	
	; Set MIME type if provided
	${If} "${_MIMETYPE}" != ""
		WriteRegStr HKCR "${_EXTENSION}" "Content Type" "${_MIMETYPE}"
	${EndIf}
	
	; Create ProgID description
	WriteRegStr HKCR "${_PROGID}" "" "${_DESCRIPTION}"
	
	; Set default icon if provided
	${If} "${_ICON}" != ""
		${ParseLocations} "${_ICON}" $0
		WriteRegStr HKCR "${_PROGID}\DefaultIcon" "" "$0"
	${EndIf}
	
	; Set open command
	${If} "${_OPENCOMMAND}" != ""
		${ParseLocations} "${_OPENCOMMAND}" $0
		WriteRegStr HKCR "${_PROGID}\shell\open\command" "" "$0"
	${EndIf}
	
	; Set edit command if provided
	${If} "${_EDITCOMMAND}" != ""
		${ParseLocations} "${_EDITCOMMAND}" $0
		WriteRegStr HKCR "${_PROGID}\shell\edit\command" "" "$0"
	${EndIf}
	
	; Set print command if provided
	${If} "${_PRINTCOMMAND}" != ""
		${ParseLocations} "${_PRINTCOMMAND}" $0
		WriteRegStr HKCR "${_PROGID}\shell\print\command" "" "$0"
	${EndIf}
	
	; Add to "Open With" list
	WriteRegStr HKCR "Applications\${_PROGID}" "" "${_DESCRIPTION}"
	WriteRegStr HKCR "Applications\${_PROGID}\shell\open\command" "" "${_OPENCOMMAND}"
	
	${DebugMsg} "File association created successfully: ${_EXTENSION}"
	
	FileAssocCreateEnd:
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Restore file association
!define FileAssoc::Restore `!insertmacro _FileAssoc::Restore`
!macro _FileAssoc::Restore _EXTENSION _SECTION _KEY _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	
	StrCpy ${_RESULT} "true"
	
	; Check if we have a backup
	${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_BackupComplete"
	${If} ${Errors}
		${DebugMsg} "No backup found for ${_EXTENSION}"
		StrCpy ${_RESULT} "false"
		Goto FileAssocRestoreEnd
	${EndIf}
	
	${DebugMsg} "Restoring file association for: ${_EXTENSION}"
	
	; Restore main ProgID
	${ReadRuntimeData} $1 ${_SECTION} "${_KEY}_ProgID"
	${IfNot} ${Errors}
		WriteRegStr HKCR "${_EXTENSION}" "" "$1"
		
		; Restore ProgID description
		${ReadRuntimeData} $2 ${_SECTION} "${_KEY}_Description"
		${IfNot} ${Errors}
			WriteRegStr HKCR "$1" "" "$2"
		${EndIf}
		
		; Restore default icon
		${ReadRuntimeData} $3 ${_SECTION} "${_KEY}_DefaultIcon"
		${IfNot} ${Errors}
			WriteRegStr HKCR "$1\DefaultIcon" "" "$3"
		${EndIf}
		
		; Restore shell commands
		${ReadRuntimeData} $4 ${_SECTION} "${_KEY}_OpenCommand"
		${IfNot} ${Errors}
			WriteRegStr HKCR "$1\shell\open\command" "" "$4"
		${EndIf}
		
		${ReadRuntimeData} $5 ${_SECTION} "${_KEY}_EditCommand"
		${IfNot} ${Errors}
			WriteRegStr HKCR "$1\shell\edit\command" "" "$5"
		${EndIf}
		
		${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_PrintCommand"
		${IfNot} ${Errors}
			WriteRegStr HKCR "$1\shell\print\command" "" "$0"
		${EndIf}
		
		; Restore MIME type
		${ReadRuntimeData} $2 ${_SECTION} "${_KEY}_MimeType"
		${IfNot} ${Errors}
			WriteRegStr HKCR "${_EXTENSION}" "Content Type" "$2"
		${EndIf}
		
		; Restore perceived type
		${ReadRuntimeData} $3 ${_SECTION} "${_KEY}_PerceivedType"
		${IfNot} ${Errors}
			WriteRegStr HKCR "${_EXTENSION}" "PerceivedType" "$3"
		${EndIf}
		
		${DebugMsg} "File association restored successfully: ${_EXTENSION}"
	${Else}
		; Remove association if no original existed
		DeleteRegKey HKCR "${_EXTENSION}"
		${DebugMsg} "Removed file association (no original): ${_EXTENSION}"
	${EndIf}
	
	FileAssocRestoreEnd:
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Remove file association
!define FileAssoc::Remove `!insertmacro _FileAssoc::Remove`
!macro _FileAssoc::Remove _EXTENSION _PROGID
	Push $0
	
	${DebugMsg} "Removing file association: ${_EXTENSION}"
	
	; Remove extension registration
	DeleteRegKey HKCR "${_EXTENSION}"
	
	; Remove ProgID registration
	DeleteRegKey HKCR "${_PROGID}"
	
	; Remove from Applications list
	DeleteRegKey HKCR "Applications\${_PROGID}"
	
	Pop $0
!macroend

; Protocol handler management
!define Protocol::Exists `!insertmacro _Protocol::Exists`
!macro _Protocol::Exists _PROTOCOL _RESULT _CURRENT_COMMAND
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_CURRENT_COMMAND} ""
	
	ReadRegStr $0 HKCR "${_PROTOCOL}" "URL Protocol"
	${IfNot} ${Errors}
		StrCpy ${_RESULT} "true"
		ReadRegStr $1 HKCR "${_PROTOCOL}\shell\open\command" ""
		${IfNot} ${Errors}
			StrCpy ${_CURRENT_COMMAND} "$1"
		${EndIf}
		${DebugMsg} "Protocol handler exists for ${_PROTOCOL}: $1"
	${Else}
		${DebugMsg} "No protocol handler found for ${_PROTOCOL}"
	${EndIf}
	
	Pop $1
	Pop $0
!macroend

!define Protocol::Create `!insertmacro _Protocol::Create`
!macro _Protocol::Create _PROTOCOL _PROGID _DESCRIPTION _ICON _OPENCOMMAND _RESULT
	Push $0
	
	StrCpy ${_RESULT} "true"
	${DebugMsg} "Creating protocol handler: ${_PROTOCOL}"
	
	; Register protocol
	WriteRegStr HKCR "${_PROTOCOL}" "" "${_DESCRIPTION}"
	WriteRegStr HKCR "${_PROTOCOL}" "URL Protocol" ""
	
	; Set default icon if provided
	${If} "${_ICON}" != ""
		${ParseLocations} "${_ICON}" $0
		WriteRegStr HKCR "${_PROTOCOL}\DefaultIcon" "" "$0"
	${EndIf}
	
	; Set open command
	${ParseLocations} "${_OPENCOMMAND}" $0
	WriteRegStr HKCR "${_PROTOCOL}\shell\open\command" "" "$0"
	
	${DebugMsg} "Protocol handler created: ${_PROTOCOL}"
	
	Pop $0
!macroend

!define Protocol::Remove `!insertmacro _Protocol::Remove`
!macro _Protocol::Remove _PROTOCOL
	${DebugMsg} "Removing protocol handler: ${_PROTOCOL}"
	DeleteRegKey HKCR "${_PROTOCOL}"
!macroend

; Context menu management
!define ContextMenu::Create `!insertmacro _ContextMenu::Create`
!macro _ContextMenu::Create _EXTENSION _MENUTEXT _MENUCOMMAND _MENUICON _POSITION _RESULT
	Push $0
	Push $1
	Push $R8
	
	StrCpy ${_RESULT} "true"
	
	; Determine registry location based on extension
	${If} "${_EXTENSION}" == "*"
		StrCpy $R8 "*\shell"
	${Else}
		StrCpy $R8 "${_EXTENSION}\shell"
	${EndIf}
	
	; Create unique menu key based on app name and menu text
	${WordReplace} "${_MENUTEXT}" " " "_" "+" $0
	StrCpy $1 "${PORTABLEAPPNAME}_$0"
	
	${DebugMsg} "Creating context menu: ${_MENUTEXT} for ${_EXTENSION}"
	
	; Create menu entry
	WriteRegStr HKCR "$R8\$1" "" "${_MENUTEXT}"
	
	; Set icon if provided
	${If} "${_MENUICON}" != ""
		${ParseLocations} "${_MENUICON}" $0
		WriteRegStr HKCR "$R8\$1" "Icon" "$0"
	${EndIf}
	
	; Set command
	${ParseLocations} "${_MENUCOMMAND}" $0
	WriteRegStr HKCR "$R8\$1\command" "" "$0"
	
	; Set position
	${Switch} "${_POSITION}"
		${Case} "top"
			WriteRegStr HKCR "$R8\$1" "Position" "Top"
			${Break}
		${Case} "bottom"
			WriteRegStr HKCR "$R8\$1" "Position" "Bottom"
			${Break}
	${EndSwitch}
	
	; Store the key name for later removal
	${WriteRuntimeData} ContextMenus "${_EXTENSION}_${_MENUTEXT}" "$1"
	
	Pop $R8
	Pop $1
	Pop $0
!macroend

!define ContextMenu::Remove `!insertmacro _ContextMenu::Remove`
!macro _ContextMenu::Remove _EXTENSION _MENUTEXT
	Push $0
	Push $1
	Push $R8
	
	; Get stored key name
	${ReadRuntimeData} $0 ContextMenus "${_EXTENSION}_${_MENUTEXT}"
	${IfNot} ${Errors}
		${If} "${_EXTENSION}" == "*"
			StrCpy $R8 "*\shell"
		${Else}
			StrCpy $R8 "${_EXTENSION}\shell"
		${EndIf}
		
		${DebugMsg} "Removing context menu: ${_MENUTEXT} for ${_EXTENSION}"
		DeleteRegKey HKCR "$R8\$0"
	${EndIf}
	
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Priority management for file associations
!define FileAssoc::SetPriority `!insertmacro _FileAssoc::SetPriority`
!macro _FileAssoc::SetPriority _EXTENSION _PROGID _PRIORITY
	Push $0
	Push $1
	Push $R8
	
	; Add to OpenWithProgids for priority handling
	${Switch} "${_PRIORITY}"
		${Case} "high"
			StrCpy $R8 "0"
			${Break}
		${Case} "normal"
			StrCpy $R8 "1"
			${Break}
		${Case} "low"
			StrCpy $R8 "2"
			${Break}
		${Default}
			StrCpy $R8 "1"
			${Break}
	${EndSwitch}
	
	WriteRegStr HKCR "${_EXTENSION}\OpenWithProgids" "${_PROGID}" ""
	WriteRegDWORD HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\${_EXTENSION}\OpenWithProgids" "${_PROGID}" $R8
	
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Check file association conflicts
!define FileAssoc::CheckConflicts `!insertmacro _FileAssoc::CheckConflicts`
!macro _FileAssoc::CheckConflicts _EXTENSION _OURPROGID _RESULT _CONFLICTING_APP
	Push $0
	Push $1
	Push $2
	
	StrCpy ${_RESULT} "none"
	StrCpy ${_CONFLICTING_APP} ""
	
	${FileAssoc::Exists} "${_EXTENSION}" $0 $1 $2
	${If} $0 == "true"
		${If} $1 != "${_OURPROGID}"
			StrCpy ${_RESULT} "conflict"
			StrCpy ${_CONFLICTING_APP} "$1"
			
			; Try to get friendly name
			ReadRegStr $0 HKCR "$1" ""
			${IfNot} ${Errors}
				StrCpy ${_CONFLICTING_APP} "$0"
			${EndIf}
			
			${DebugMsg} "File association conflict for ${_EXTENSION}: ${_CONFLICTING_APP}"
		${Else}
			StrCpy ${_RESULT} "ours"
		${EndIf}
	${EndIf}
	
	Pop $2
	Pop $1
	Pop $0
!macroend

; Advanced file association utilities

; Check if current user can modify file associations
!define FileAssoc::CanModify `!insertmacro _FileAssoc::CanModify`
!macro _FileAssoc::CanModify _RESULT
	Push $0
	
	StrCpy ${_RESULT} "true"
	
	; Try to write a test key
	WriteRegStr HKCR "PortableAppTest" "" "Test"
	${If} ${Errors}
		StrCpy ${_RESULT} "false"
		${DebugMsg} "User cannot modify file associations (no admin rights)"
	${Else}
		DeleteRegKey HKCR "PortableAppTest"
		${DebugMsg} "User can modify file associations"
	${EndIf}
	
	Pop $0
!macroend

; Get default application for extension
!define FileAssoc::GetDefault `!insertmacro _FileAssoc::GetDefault`
!macro _FileAssoc::GetDefault _EXTENSION _RESULT _PROGID _COMMAND
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_PROGID} ""
	StrCpy ${_COMMAND} ""
	
	; Check user choice first
	ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\${_EXTENSION}\UserChoice" "ProgId"
	${IfNot} ${Errors}
		StrCpy ${_PROGID} "$0"
		ReadRegStr $1 HKCR "$0\shell\open\command" ""
		${IfNot} ${Errors}
			StrCpy ${_COMMAND} "$1"
			StrCpy ${_RESULT} "true"
		${EndIf}
	${Else}
		; Fall back to HKCR registration
		ReadRegStr $0 HKCR "${_EXTENSION}" ""
		${IfNot} ${Errors}
			StrCpy ${_PROGID} "$0"
			ReadRegStr $1 HKCR "$0\shell\open\command" ""
			${IfNot} ${Errors}
				StrCpy ${_COMMAND} "$1"
				StrCpy ${_RESULT} "true"
			${EndIf}
		${EndIf}
	${EndIf}
	
	Pop $1
	Pop $0
!macroend

; Create "Open With" menu entry
!define FileAssoc::AddOpenWith `!insertmacro _FileAssoc::AddOpenWith`
!macro _FileAssoc::AddOpenWith _EXTENSION _PROGID _APPNAME _COMMAND _ICON
	Push $0
	
	; Add to OpenWithProgids
	WriteRegStr HKCR "${_EXTENSION}\OpenWithProgids" "${_PROGID}" ""
	
	; Create application registration
	WriteRegStr HKCR "Applications\${_PROGID}.exe" "" "${_APPNAME}"
	WriteRegStr HKCR "Applications\${_PROGID}.exe\shell\open\command" "" "${_COMMAND}"
	
	${If} "${_ICON}" != ""
		${ParseLocations} "${_ICON}" $0
		WriteRegStr HKCR "Applications\${_PROGID}.exe\DefaultIcon" "" "$0"
	${EndIf}
	
	Pop $0
!macroend

; Generate file association report
!define FileAssoc::GenerateReport `!insertmacro _FileAssoc::GenerateReport`
!macro _FileAssoc::GenerateReport _FILEPATH
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $R0
	
	FileOpen $0 "${_FILEPATH}" w
	${If} $0 != ""
		FileWrite $0 "File Associations Report$\r$\n"
		FileWrite $0 "Generated: $DATE $TIME$\r$\n"
		FileWrite $0 "=======================$\r$\n$\r$\n"
		
		; File associations
		FileWrite $0 "File Associations:$\r$\n"
		FileWrite $0 "------------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 FileAssociation$R0 Extension
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${FileAssoc::GetDefault} "$1" $2 $3 $4
			${If} $2 == "true"
				FileWrite $0 "$1 -> $3$\r$\n"
				FileWrite $0 "  Command: $4$\r$\n"
			${Else}
				FileWrite $0 "$1 -> Not associated$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Protocol handlers
		FileWrite $0 "$\r$\nProtocol Handlers:$\r$\n"
		FileWrite $0 "------------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 ProtocolHandler$R0 Protocol
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${Protocol::Exists} "$1" $2 $3
			${If} $2 == "true"
				FileWrite $0 "$1 -> Registered$\r$\n"
				FileWrite $0 "  Command: $3$\r$\n"
			${Else}
				FileWrite $0 "$1 -> Not registered$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		FileClose $0
		${DebugMsg} "File associations report generated: ${_FILEPATH}"
	${EndIf}
	
	Pop $R0
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend
${SegmentFile}

;= Enable file associations segment
!define FILEASSOCIATIONS_ENABLED

;= Backup existing file associations
${SegmentPre}
	!ifdef FILEASSOCIATIONS_ENABLED
		${DebugMsg} "Backing up existing file associations..."
		
		${ReadUserConfigWithDefault} $0 Associations= true
    	${If} $0 == true
			; Process file associations
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 FileAssociation$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				${ReadLauncherConfig} $1 FileAssociation$R0 ProgID
				${ReadLauncherConfig} $2 FileAssociation$R0 IfExists
				
				${DebugMsg} "Processing file association: $0 -> $1"
				
				; Check for conflicts
				${FileAssoc::CheckConflicts} "$0" "$1" $R8 $R9
				${If} $R8 == "conflict"
					${DebugMsg} "File association conflict detected: $0 is associated with $R9"
					
					${Switch} $2
						${Case} "skip"
							${DebugMsg} "Skipping file association due to conflict: $0"
							${WriteRuntimeData} FileAssocState "$0_Action" "skipped"
							${Break}
						${Case} "backup"
							${DebugMsg} "Backing up conflicting file association: $0"
							${FileAssoc::Backup} "$0" "FileAssocBackup" "$0"
							${WriteRuntimeData} FileAssocState "$0_Action" "backup"
							${Break}
						${Case} "replace"
						${CaseElse}
							${DebugMsg} "Will replace conflicting file association: $0"
							${FileAssoc::Backup} "$0" "FileAssocBackup" "$0"
							${WriteRuntimeData} FileAssocState "$0_Action" "replace"
							${Break}
					${EndSwitch}
				${ElseIf} $R8 == "ours"
					${DebugMsg} "File association already belongs to us: $0"
					${WriteRuntimeData} FileAssocState "$0_Action" "ours"
				${Else}
					${DebugMsg} "No existing file association for: $0"
					${WriteRuntimeData} FileAssocState "$0_Action" "create"
				${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
			
			; Process protocol handlers
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 ProtocolHandler$R0 Protocol
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				${ReadLauncherConfig} $1 ProtocolHandler$R0 IfExists
				
				${Protocol::Exists} "$0" $R8 $R9
				${If} $R8 == "true"
					${DebugMsg} "Protocol handler exists for: $0"
					${Switch} $1
						${Case} "skip"
							${WriteRuntimeData} ProtocolState "$0_Action" "skipped"
							${Break}
						${Case} "backup"
						${CaseElse}
							; Backup existing protocol handler
							ReadRegStr $2 HKCR "$0" ""
							${WriteRuntimeData} ProtocolBackup "$0_Description" "$2"
							ReadRegStr $3 HKCR "$0\shell\open\command" ""
							${WriteRuntimeData} ProtocolBackup "$0_Command" "$3"
							${WriteRuntimeData} ProtocolBackup "$0_BackupComplete" "true"
							${WriteRuntimeData} ProtocolState "$0_Action" "replace"
							${Break}
					${EndSwitch}
				${Else}
					${WriteRuntimeData} ProtocolState "$0_Action" "create"
				${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
		${EndIf}
		
		${DebugMsg} "File association backup completed."
	!endif
!macroend

;= Create file associations and protocol handlers
${SegmentPrePrimary}
	!ifdef FILEASSOCIATIONS_ENABLED
		${DebugMsg} "Creating file associations and protocol handlers..."
		
		${ReadUserConfigWithDefault} $0 Associations= true
		${If} $0 == true
			; Create file associations
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 FileAssociation$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				; Check if we should process this association
				${ReadRuntimeData} $1 FileAssocState "$0_Action"
				${If} $1 == "skipped"
					${DebugMsg} "Skipping file association as requested: $0"
					IntOp $R0 $R0 + 1
					${Continue}
				${EndIf}
				
				; Get configuration
				${ReadLauncherConfig} $1 FileAssociation$R0 ProgID
				${ReadLauncherConfig} $2 FileAssociation$R0 Description
				${ReadLauncherConfig} $3 FileAssociation$R0 DefaultIcon
				${ReadLauncherConfig} $4 FileAssociation$R0 OpenCommand
				${ReadLauncherConfig} $5 FileAssociation$R0 EditCommand
				${ReadLauncherConfig} $6 FileAssociation$R0 PrintCommand
				${ReadLauncherConfig} $7 FileAssociation$R0 MimeType
				${ReadLauncherConfig} $8 FileAssociation$R0 Priority
				
				${DebugMsg} "Creating file association: $0 -> $1"
				
				; Create the file association
				${FileAssoc::Create} "$0" "$1" "$2" "$3" "$4" "$5" "$6" "$7" $R8
				${If} $R8 == "true"
					${WriteRuntimeData} FileAssocState "$0_Created" "true"
					${DebugMsg} "File association created successfully: $0"
					
					; Set priority if specified
					${If} $8 != ""
						${FileAssoc::SetPriority} "$0" "$1" "$8"
					${EndIf}
				${Else}
					${DebugMsg} "Failed to create file association: $0"
					${WriteRuntimeData} FileAssocState "$0_Failed" "true"
				${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
			
			; Create protocol handlers
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 ProtocolHandler$R0 Protocol
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				; Check if we should process this protocol
				${ReadRuntimeData} $1 ProtocolState "$0_Action"
				${If} $1 == "skipped"
					${DebugMsg} "Skipping protocol handler as requested: $0"
					IntOp $R0 $R0 + 1
					${Continue}
				${EndIf}
				
				; Get configuration
				${ReadLauncherConfig} $1 ProtocolHandler$R0 ProgID
				${ReadLauncherConfig} $2 ProtocolHandler$R0 Description
				${ReadLauncherConfig} $3 ProtocolHandler$R0 DefaultIcon
				${ReadLauncherConfig} $4 ProtocolHandler$R0 OpenCommand
				
				${DebugMsg} "Creating protocol handler: $0"
				
				${Protocol::Create} "$0" "$1" "$2" "$3" "$4" $R8
				${If} $R8 == "true"
					${WriteRuntimeData} ProtocolState "$0_Created" "true"
					${DebugMsg} "Protocol handler created successfully: $0"
				${Else}
					${DebugMsg} "Failed to create protocol handler: $0"
				${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
			
			; Create context menu entries
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 ContextMenu$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				${ReadLauncherConfig} $1 ContextMenu$R0 MenuText
				${ReadLauncherConfig} $2 ContextMenu$R0 MenuCommand
				${ReadLauncherConfig} $3 ContextMenu$R0 MenuIcon
				${ReadLauncherConfig} $4 ContextMenu$R0 Position
				${ReadLauncherConfig} $5 ContextMenu$R0 IfExists
				
				${DebugMsg} "Creating context menu: $1 for $0"
				
				; Check if we should create this context menu
				${If} $5 != "skip"
					${ContextMenu::Create} "$0" "$1" "$2" "$3" "$4" $R8
					${If} $R8 == "true"
						${WriteRuntimeData} ContextMenuState "$0_$1_Created" "true"
						${DebugMsg} "Context menu created successfully: $1"
					${EndIf}
				${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
		${EndIf}
		
		; Notify shell of changes
		${SHCHANGENOTIFY}
		${DebugMsg} "File associations and protocol handlers creation completed."
	!endif
!macroend

;= Remove created associations and context menus
${SegmentPostPrimary}
	!ifdef FILEASSOCIATIONS_ENABLED
		${DebugMsg} "Cleaning up file associations and protocol handlers..."
		
		${ReadUserConfigWithDefault} $0 Associations= true
		${If} $0 == true
			; Remove context menus first
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 ContextMenu$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				${ReadLauncherConfig} $1 ContextMenu$R0 MenuText
				
				; Check if we created this context menu
				${ReadRuntimeData} $2 ContextMenuState "$0_$1_Created"
				${IfNot} ${Errors}
					${ContextMenu::Remove} "$0" "$1"
					${DebugMsg} "Context menu removed: $1"
				${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
			
			; Remove protocol handlers
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 ProtocolHandler$R0 Protocol
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				; Check if we created this protocol handler
				${ReadRuntimeData} $1 ProtocolState "$0_Created"
				${IfNot} ${Errors}
					${Protocol::Remove} "$0"
					${DebugMsg} "Protocol handler removed: $0"
				${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
			
			; Remove file associations
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 FileAssociation$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				; Check if we created this file association
				${ReadRuntimeData} $1 FileAssocState "$0_Created"
				${IfNot} ${Errors}
					${ReadLauncherConfig} $2 FileAssociation$R0 ProgID
					${FileAssoc::Remove} "$0" "$2"
					${DebugMsg} "File association removed: $0"
				${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
		${EndIf}
		
		; Notify shell of changes
		${SHCHANGENOTIFY}
		${DebugMsg} "File associations cleanup completed."
	!endif
!macroend

;= Restore original file associations
${SegmentUnload}
	!ifdef FILEASSOCIATIONS_ENABLED
		${DebugMsg} "Restoring original file associations..."
		
		${ReadUserConfigWithDefault} $0 Associations= true
		${If} $0 == true
			; Restore file associations
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 FileAssociation$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				; Check what action we took
				${ReadRuntimeData} $1 FileAssocState "$0_Action"
				${If} $1 == "backup"
				${OrIf} $1 == "replace"
					${FileAssoc::Restore} "$0" "FileAssocBackup" "$0" $R8
					${If} $R8 == "true"
						${DebugMsg} "File association restored: $0"
					${Else}
						${DebugMsg} "Failed to restore file association: $0"
					${EndIf}
				${EndIf}
				
				; Clean up state data
				${DeleteRuntimeData} FileAssocState "$0_Action"
				${DeleteRuntimeData} FileAssocState "$0_Created"
				${DeleteRuntimeData} FileAssocState "$0_Failed"
				
				; Clean up backup data
				${DeleteRuntimeData} FileAssocBackup "$0_ProgID"
				${DeleteRuntimeData} FileAssocBackup "$0_Description"
				${DeleteRuntimeData} FileAssocBackup "$0_DefaultIcon"
				${DeleteRuntimeData} FileAssocBackup "$0_OpenCommand"
				${DeleteRuntimeData} FileAssocBackup "$0_EditCommand"
				${DeleteRuntimeData} FileAssocBackup "$0_PrintCommand"
				${DeleteRuntimeData} FileAssocBackup "$0_MimeType"
				${DeleteRuntimeData} FileAssocBackup "$0_PerceivedType"
				${DeleteRuntimeData} FileAssocBackup "$0_BackupComplete"
				
				IntOp $R0 $R0 + 1
			${Loop}
			
			; Restore protocol handlers
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 ProtocolHandler$R0 Protocol
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				; Check if we have a backup to restore
				${ReadRuntimeData} $1 ProtocolBackup "$0_BackupComplete"
				${IfNot} ${Errors}
					${ReadRuntimeData} $2 ProtocolBackup "$0_Description"
					${ReadRuntimeData} $3 ProtocolBackup "$0_Command"
					
					; Restore original protocol handler
					WriteRegStr HKCR "$0" "" "$2"
					WriteRegStr HKCR "$0" "URL Protocol" ""
					WriteRegStr HKCR "$0\shell\open\command" "" "$3"
					
					${DebugMsg} "Protocol handler restored: $0"
					
					; Clean up backup data
					${DeleteRuntimeData} ProtocolBackup "$0_Description"
					${DeleteRuntimeData} ProtocolBackup "$0_Command"
					${DeleteRuntimeData} ProtocolBackup "$0_BackupComplete"
				${EndIf}
				
				; Clean up state data
				${DeleteRuntimeData} ProtocolState "$0_Action"
				${DeleteRuntimeData} ProtocolState "$0_Created"
				
				IntOp $R0 $R0 + 1
			${Loop}
			
			; Clean up context menu data
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $0 ContextMenu$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				${ReadLauncherConfig} $1 ContextMenu$R0 MenuText
				
				; Clean up state data
				${DeleteRuntimeData} ContextMenuState "$0_$1_Created"
				${DeleteRuntimeData} ContextMenus "$0_$1"
				
				IntOp $R0 $R0 + 1
			${Loop}
		${EndIf}
		
		; Final shell notification
		${SHCHANGENOTIFY}
		${DebugMsg} "File associations restoration completed."
	!endif
!macroend

!endif
