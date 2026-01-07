;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; Associations.nsh
;   This file handles filetype associations, protocol handlers, context menus,
;   and shell integration with backup and restore capabilities.
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
;	IfExists		-	skip, backup, replace
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
;	IfExists		-	skip, backup, replace
;
; EXAMPLE
;	[FileAssociation1]
;	Extension=.myfile
;	ProgID=MyPortableApp.Document
;	Description=My Portable App Document
;	DefaultIcon=%PAL:AppDir%\App\myapp.exe,0
;	OpenCommand="%PAL:AppDir%\App\myapp.exe" "%1"
;	IfExists=backup
;

!ifdef SEGMENTS_ASSOCIATIONS

; Comment any of the following 3 defines 
; to disable that part of this segment
!define FILETYPE_ENABLED
!define PROTOCOL_ENABLED
!define CONTEXTMENU_ENABLED

;= VARIABLES
!ifdef FILETYPE_ENABLED
Var AssocExtension
Var AssocProgID
Var AssocDescription
Var AssocDefaultIcon
Var AssocOpenCommand
Var AssocIfExists
!endif
!ifdef PROTOCOL_ENABLED
Var ProtoProtocol
Var ProtoProgID
Var ProtoDescription
Var ProtoDefaultIcon
Var ProtoOpenCommand
Var ProtoIfExists
!endif
!ifdef CONTEXTMENU_ENABLED
Var CMenuProgId
Var CMenuKey
Var CMenuText
Var CMenuCommand
Var CMenuIcon
Var CMenuIfExists
!endif

;= INCLUDES
!ifndef LOGICLIB
    !include LogicLib.nsh
!endif
!ifndef STR_CASE_NSH_INCLUDED
    !include StrCase.nsh
!endif

;= DEFINES
!ifndef SHCNE_ASSOCCHANGED
	!define SHCNE_ASSOCCHANGED 0x08000000
!endif
!ifndef SHCNF_IDLIST
	!define SHCNF_IDLIST 0x0000
!endif
!ifndef SHCHANGENOTIFY
	!define SHCHANGENOTIFY `System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v (${SHCNE_ASSOCCHANGED}, ${SHCNF_IDLIST}, 0, 0)'`
!endif
!ifndef ASSOC_ROOT
	!define ASSOC_ROOT HKCU
!endif
!ifndef ASSOC_CLASSES
	!define ASSOC_CLASSES "Software\Classes"
!endif
!ifndef PAF
	!define PAF `HKCU\Software\PortableApps`
!endif
!ifndef PAFKEYS
	!define PAFKEYS `${PAF}\${APPNAME}\AssocBackup`
!endif

;= MACROS/FUNCTIONS
!ifdef FILETYPE_ENABLED
!define FileType::GetProgID "!insertmacro _FileType::GetProgID"
!macro _FileType::GetProgID _EXT
  Push "${_EXT}"
  Call _GetFileTypeProgIDFunc
  Pop $R9
!macroend
Function _GetFileTypeProgIDFunc
  Pop $R0
  ClearErrors
  ReadRegStr $R1 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" ""
  ${If} ${Errors}
    Push ""
  ${Else}
    Push "$R1"
  ${EndIf}
FunctionEnd
!define FileType::CheckExists "!insertmacro _FileType::CheckExists"
!macro _FileType::CheckExists _EXT
  Push "${_EXT}"
  Call _CheckFileTypeExistsFunc
  Pop $R9
!macroend
Function _CheckFileTypeExistsFunc
  Pop $R0 ; Extension
  
  ClearErrors
  ReadRegStr $R1 ${ASSOC_ROOT} "$R0" ""
  ${If} ${Errors}
    Push "0"
  ${Else}
    Push "1"
  ${EndIf}
FunctionEnd
!define FileType::GetInfo "!insertmacro _FileType::GetInfo"
!macro _FileType::GetInfo _EXT
  Push "${_EXT}"
  Call _GetFileTypeInfoFunc
  Pop $R9
  Pop $R8
  Pop $R7
  Pop $R6
!macroend
Function _GetFileTypeInfoFunc
  Pop $R0 ; Extension
  
  ; Get ProgID
  ClearErrors
  ReadRegStr $R1 ${ASSOC_ROOT} "$R0" ""
  ${If} ${Errors}
    Push ""
    Push ""
    Push ""
    Push ""
    Return
  ${EndIf}
  
  ; Get Description
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "$R1" ""
  ${If} ${Errors}
    StrCpy $R2 ""
  ${EndIf}
  
  ; Get Icon
  ClearErrors
  ReadRegStr $R3 ${ASSOC_ROOT} "$R1\DefaultIcon" ""
  ${If} ${Errors}
    StrCpy $R3 ""
  ${EndIf}
  
  ; Get Open Command
  ClearErrors
  ReadRegStr $R4 ${ASSOC_ROOT} "$R1\shell\open\command" ""
  ${If} ${Errors}
    StrCpy $R4 ""
  ${EndIf}
  
  Push "$R4" ; Open Command
  Push "$R3" ; Icon
  Push "$R2" ; Description
  Push "$R1" ; ProgID
FunctionEnd
!define FileType::Backup "!insertmacro _FileType::Backup"
!macro _FileType::Backup _EXT
  Push "${_EXT}"
  Call _BackupFileTypeFunc
!macroend
Function _BackupFileTypeFunc
  Pop $R0
  ClearErrors
  ReadRegStr $R1 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" ""
  ${If} ${Errors}
    Return
  ${EndIf}

  WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\FileTypes\$R0" "ProgID" "$R1"

  ReadRegStr $R2 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\ProgIDs\$R1" "" "$R2"
  ${EndIf}

  ReadRegStr $R2 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1\DefaultIcon" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\ProgIDs\$R1\DefaultIcon" "" "$R2"
  ${EndIf}

  ReadRegStr $R2 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1\shell\open\command" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\ProgIDs\$R1\shell\open\command" "" "$R2"
  ${EndIf}
FunctionEnd
!define FileType::Restore "!insertmacro _FileType::Restore"
!macro _FileType::Restore _EXT
  Push "${_EXT}"
  Call _RestoreFileTypeFunc
!macroend
Function _RestoreFileTypeFunc
  Pop $R0
  ReadRegStr $R1 ${ASSOC_ROOT} "${PAFKEYS}\FileTypes\$R0" "ProgID"
  ${If} ${Errors}
    Return
  ${EndIf}

  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" "" "$R1"

  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\ProgIDs\$R1" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1" "" "$R2"
  ${EndIf}

  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\ProgIDs\$R1\DefaultIcon" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1\DefaultIcon" "" "$R2"
  ${EndIf}

  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\ProgIDs\$R1\shell\open\command" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1\shell\open\command" "" "$R2"
  ${EndIf}

  DeleteRegKey ${ASSOC_ROOT} "${PAFKEYS}\FileTypes\$R0"
  DeleteRegKey ${ASSOC_ROOT} "${PAFKEYS}\ProgIDs\$R1"

  ${NotifyShell}
FunctionEnd
!define FileType::Register "!insertmacro _FileType::Register"
!macro _FileType::Register _EXT _PROGID _DESC _ICON _CMD
  Push "${_EXT}"
  Push "${_PROGID}"
  Push "${_DESC}"
  Push "${_ICON}"
  Push "${_CMD}"
  Call _RegisterFileTypeFunc
!macroend
Function _RegisterFileTypeFunc
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0

  Push "$R0"
  Call _BackupFileTypeFunc

  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" "" "$R1"
  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1" "" "$R2"
  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1\DefaultIcon" "" "$R3"
  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R1\shell\open\command" "" "$R4"

  ${NotifyShell}
FunctionEnd
!define FileType::Unregister "!insertmacro _FileType::Unregister"
!macro _FileType::Unregister _EXT _PROGID
  Push "${_EXT}"
  Push "${_PROGID}"
  Call _UnregisterFileTypeFunc
!macroend
Function _UnregisterFileTypeFunc
  Pop $R1 ; ProgID
  Pop $R0 ; Extension
  
  ; Check if this extension belongs to our ProgID
  ReadRegStr $R2 ${ASSOC_ROOT} "$R0" ""
  ${If} $R2 == "$R1"
    ; This is our registration, restore backup or remove
    Push "$R0"
    Call RestoreFileTypeFunc
  ${EndIf}
  
  ; Remove our ProgID
  DeleteRegKey ${ASSOC_ROOT} "$R1"
  
  ; Notify shell
  System::Call 'shell32.dll::SHChangeNotify(i, i, i, i) v (0x08000000, 0, 0, 0)'
FunctionEnd
!endif
!ifdef PROTOCOL_ENABLED
!define Protocol::GetInfo "!insertmacro _Protocol::GetInfo"
!macro _Protocol::GetInfo _PROTOCOL
  Push "${_PROTOCOL}"
  Call _GetProtocolInfoFunc
  Pop $R9
  Pop $R8
  Pop $R7
!macroend
Function _GetProtocolInfoFunc
  Pop $R0 ; Protocol
  
  ; Check if protocol exists
  ClearErrors
  ReadRegStr $R1 ${ASSOC_ROOT} "$R0" "URL Protocol"
  ${If} ${Errors}
    Push ""
    Push ""
    Push ""
    Return
  ${EndIf}
  
  ; Get Description
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "$R0" ""
  ${If} ${Errors}
    StrCpy $R2 ""
  ${EndIf}
  
  ; Get Icon
  ClearErrors
  ReadRegStr $R3 ${ASSOC_ROOT} "$R0\DefaultIcon" ""
  ${If} ${Errors}
    StrCpy $R3 ""
  ${EndIf}
  
  ; Get Command
  ClearErrors
  ReadRegStr $R4 ${ASSOC_ROOT} "$R0\shell\open\command" ""
  ${If} ${Errors}
    StrCpy $R4 ""
  ${EndIf}
  
  Push "$R4" ; Command
  Push "$R3" ; Icon
  Push "$R2" ; Description
FunctionEnd
!define Protocol::GetHandler "!insertmacro _Protocol::GetHandler"
!macro _Protocol::GetHandler _PROTOCOL
  Push "${_PROTOCOL}"
  Call _GetProtocolHandlerFunc
  Pop $R9
!macroend
Function _GetProtocolHandlerFunc
  Pop $R0 ; Protocol
  
  ClearErrors
  ReadRegStr $R1 ${ASSOC_ROOT} "$R0\shell\open\command" ""
  ${If} ${Errors}
    Push ""
  ${Else}
    Push "$R1"
  ${EndIf}
FunctionEnd
!define Protocol::CheckExists "!insertmacro _Protocol::CheckExists"
!macro _Protocol::CheckExists _PROTOCOL
  Push "${_PROTOCOL}"
  Call _CheckProtocolExistsFunc
  Pop $R9
!macroend
Function _CheckProtocolExistsFunc
  Pop $R0 ; Protocol
  
  ClearErrors
  ReadRegStr $R1 ${ASSOC_ROOT} "$R0" "URL Protocol"
  ${If} ${Errors}
    Push "0"
  ${Else}
    Push "1"
  ${EndIf}
FunctionEnd
!define Protocol::Backup "!insertmacro _Protocol::Backup"
!macro _Protocol::Backup _PROTOCOL
  Push "${_PROTOCOL}"
  Call _BackupProtocolFunc
!macroend
Function _BackupProtocolFunc
  Pop $R0

  ClearErrors
  ReadRegStr $R1 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" "URL Protocol"
  ${If} ${Errors}
    Return
  ${EndIf}

  ReadRegStr $R2 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0" "" "$R2"
  ${EndIf}

  WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0" "URL Protocol" ""

  ReadRegStr $R2 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\DefaultIcon" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0\DefaultIcon" "" "$R2"
  ${EndIf}

  ReadRegStr $R2 ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\open\command" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0\shell\open\command" "" "$R2"
  ${EndIf}
FunctionEnd
!define Protocol::Restore "!insertmacro _Protocol::Restore"
!macro _Protocol::Restore _PROTOCOL
  Push "${_PROTOCOL}"
  Call _RestoreProtocolFunc
!macroend
Function _RestoreProtocolFunc
  Pop $R0

  ReadRegStr $R1 ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0" "URL Protocol"
  ${If} ${Errors}
    DeleteRegKey ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0"
    ${NotifyShell}
    Return
  ${EndIf}

  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" "" "$R2"
  ${EndIf}

  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" "URL Protocol" ""

  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0\DefaultIcon" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\DefaultIcon" "" "$R2"
  ${EndIf}

  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0\shell\open\command" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\open\command" "" "$R2"
  ${EndIf}

  DeleteRegKey ${ASSOC_ROOT} "${PAFKEYS}\Protocols\$R0"
  ${NotifyShell}
FunctionEnd
!define Protocol::Register "!insertmacro _Protocol::Register"
!macro _Protocol::Register _PROTOCOL _DESC _ICON _CMD
  Push "${_PROTOCOL}"
  Push "${_DESC}"
  Push "${_ICON}"
  Push "${_CMD}"
  Call _RegisterProtocolFunc
!macroend
Function _RegisterProtocolFunc
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0

  Push "$R0"
  Call _BackupProtocolFunc

  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" "" "$R1"
  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0" "URL Protocol" ""
  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\DefaultIcon" "" "$R2"
  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\open\command" "" "$R3"
FunctionEnd
!define Protocol::Unregister "!insertmacro _Protocol::Unregister"
!macro _Protocol::Unregister _PROTOCOL
  Push "${_PROTOCOL}"
  Call _UnregisterProtocolFunc
!macroend
Function _UnregisterProtocolFunc
  Pop $R0
  Push "$R0"
  Call _RestoreProtocolFunc
FunctionEnd
!endif
!ifdef CONTEXTMENU_ENABLED
!define ContextMenu::Add "!insertmacro _ContextMenu::Add"
!macro _ContextMenu::Add _PROGID _KEY _TEXT _CMD _ICON
  Push "${_PROGID}"
  Push "${_KEY}"
  Push "${_TEXT}"
  Push "${_CMD}"
  Push "${_ICON}"
  Call _AddContextMenuFunc
!macroend
Function _AddContextMenuFunc
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0

  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\$R1" "" "$R2"
  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\$R1\command" "" "$R3"

  ${If} $R4 != ""
    WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\$R1" "Icon" "$R4"
  ${EndIf}

  ${NotifyShell}
FunctionEnd
!define ContextMenu::Remove "!insertmacro _ContextMenu::Remove"
!macro _ContextMenu::Remove _PROGID _KEY
  Push "${_PROGID}"
  Push "${_KEY}"
  Call _RemoveContextMenuFunc
!macroend
Function _RemoveContextMenuFunc
  Pop $R1
  Pop $R0
  DeleteRegKey ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\$R1"
  ${NotifyShell}
FunctionEnd
!define ContextMenu::AddGlobal "!insertmacro _ContextMenu::AddGlobal"
!macro _ContextMenu::AddGlobal _TARGET _KEY _TEXT _CMD _ICON
  Push "${_TARGET}"
  Push "${_KEY}"
  Push "${_TEXT}"
  Push "${_CMD}"
  Push "${_ICON}"
  Call _AddGlobalContextMenuFunc
!macroend
Function _AddGlobalContextMenuFunc
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0

  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\$R1" "" "$R2"
  WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\$R1\command" "" "$R3"

  ${If} $R4 != ""
    WriteRegStr ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\$R1" "Icon" "$R4"
  ${EndIf}

  ${NotifyShell}
FunctionEnd
!define ContextMenu::RemoveGlobal "!insertmacro _ContextMenu::RemoveGlobal"
!macro _ContextMenu::RemoveGlobal _TARGET _KEY
  Push "${_TARGET}"
  Push "${_KEY}"
  Call _RemoveGlobalContextMenuFunc
!macroend
Function _RemoveGlobalContextMenuFunc
  Pop $R1
  Pop $R0
  DeleteRegKey ${ASSOC_ROOT} "${ASSOC_CLASSES}\$R0\shell\$R1"
  ${NotifyShell}
FunctionEnd
!define ContextMenu::CheckExists "!insertmacro _ContextMenu::CheckExists"
!macro _ContextMenu::CheckExists _PROGID _MENUKEY
  Push "${_PROGID}"
  Push "${_MENUKEY}"
  Call _CheckContextMenuExistsFunc
  Pop $R9
!macroend
Function _CheckContextMenuExistsFunc
  Pop $R1 ; MenuKey
  Pop $R0 ; ProgID
  
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" ""
  ${If} ${Errors}
    Push "0"
  ${Else}
    Push "1"
  ${EndIf}
FunctionEnd
!define ContextMenu::CheckGlobalExists "!insertmacro _ContextMenu::CheckGlobalExists"
!macro _ContextMenu::CheckGlobalExists _TARGET _MENUKEY
  Push "${_TARGET}"
  Push "${_MENUKEY}"
  Call _CheckGlobalContextMenuExistsFunc
  Pop $R9
!macroend
Function _CheckGlobalContextMenuExistsFunc
  Pop $R1 ; MenuKey
  Pop $R0 ; Target
  
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" ""
  ${If} ${Errors}
    Push "0"
  ${Else}
    Push "1"
  ${EndIf}
FunctionEnd
!define ContextMenu::GetInfo "!insertmacro _ContextMenu::GetInfo"
!macro _ContextMenu::GetInfo _PROGID _MENUKEY
  Push "${_PROGID}"
  Push "${_MENUKEY}"
  Call _GetContextMenuInfoFunc
  Pop $R9
  Pop $R8
  Pop $R7
!macroend
Function _GetContextMenuInfoFunc
  Pop $R1 ; MenuKey
  Pop $R0 ; ProgID
  
  ; Check if menu exists
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" ""
  ${If} ${Errors}
    Push ""
    Push ""
    Push ""
    Return
  ${EndIf}
  
  ; Get MenuText
  StrCpy $R3 "$R2"
  
  ; Get Command
  ClearErrors
  ReadRegStr $R4 HKCR "$R0\shell\$R1\command" ""
  ${If} ${Errors}
    StrCpy $R4 ""
  ${EndIf}
  
  ; Get Icon
  ClearErrors
  ReadRegStr $R5 HKCR "$R0\shell\$R1" "Icon"
  ${If} ${Errors}
    StrCpy $R5 ""
  ${EndIf}
  
  Push "$R5" ; Icon
  Push "$R4" ; Command
  Push "$R3" ; MenuText
FunctionEnd
!define ContextMenu::Backup "!insertmacro _ContextMenu::Backup"
!macro _ContextMenu::Backup _PROGID _MENUKEY
  Push "${_PROGID}"
  Push "${_MENUKEY}"
  Call _BackupContextMenuFunc
!macroend
Function _BackupContextMenuFunc
  Pop $R1 ; MenuKey
  Pop $R0 ; ProgID
  
  ; Check if menu exists
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" ""
  ${If} ${Errors}
    ; Nothing to backup
    Return
  ${EndIf}
  
  ; Backup MenuText
  WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1" "" "$R2"
  
  ; Backup Command
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1\command" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1\command" "" "$R2"
  ${EndIf}
  
  ; Backup Icon
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" "Icon"
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1" "Icon" "$R2"
  ${EndIf}
  
  ; Backup MUIVerb (if exists)
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" "MUIVerb"
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1" "MUIVerb" "$R2"
  ${EndIf}
  
  ; Backup Position (if exists)
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" "Position"
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1" "Position" "$R2"
  ${EndIf}
  
  DetailPrint "Backed up context menu: $R0\shell\$R1"
FunctionEnd
!define ContextMenu::Restore "!insertmacro _ContextMenu::Restore"
!macro _ContextMenu::Restore _PROGID _MENUKEY
  Push "${_PROGID}"
  Push "${_MENUKEY}"
  Call _RestoreContextMenuFunc
!macroend
Function _RestoreContextMenuFunc
  Pop $R1 ; MenuKey
  Pop $R0 ; ProgID
  
  ; Check if we have a backup
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1" ""
  ${If} ${Errors}
    ; No backup exists, just delete our entry
    DeleteRegKey HKCR "$R0\shell\$R1"
    DetailPrint "No backup found for $R0\shell\$R1, removed entry"
    Return
  ${EndIf}
  
  ; Restore MenuText
  WriteRegStr HKCR "$R0\shell\$R1" "" "$R2"
  
  ; Restore Command
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1\command" ""
  ${IfNot} ${Errors}
    WriteRegStr HKCR "$R0\shell\$R1\command" "" "$R2"
  ${EndIf}
  
  ; Restore Icon
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1" "Icon"
  ${IfNot} ${Errors}
    WriteRegStr HKCR "$R0\shell\$R1" "Icon" "$R2"
  ${EndIf}
  
  ; Restore MUIVerb
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1" "MUIVerb"
  ${IfNot} ${Errors}
    WriteRegStr HKCR "$R0\shell\$R1" "MUIVerb" "$R2"
  ${EndIf}
  
  ; Restore Position
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1" "Position"
  ${IfNot} ${Errors}
    WriteRegStr HKCR "$R0\shell\$R1" "Position" "$R2"
  ${EndIf}
  
  ; Clean up backup
  DeleteRegKey ${ASSOC_ROOT} "${PAFKEYS}\ContextMenus\$R0\$R1"
  
  System::Call 'shell32.dll::SHChangeNotify(i,i,i,i)v(${SHCNE_ASSOCCHANGED},${SHCNF_IDLIST},0,0)'
  
  DetailPrint "Restored context menu: $R0\shell\$R1"
FunctionEnd
!define ContextMenu::BackupGlobal "!insertmacro _ContextMenu::BackupGlobal"
!macro _ContextMenu::BackupGlobal _TARGET _MENUKEY
  Push "${_TARGET}"
  Push "${_MENUKEY}"
  Call _BackupGlobalContextMenuFunc
!macroend
Function _BackupGlobalContextMenuFunc
  Pop $R1 ; MenuKey
  Pop $R0 ; Target
  
  ; Normalize target path for backup key (replace \ with _)
  Push $R0
  Push "\"
  Push "_"
  Call _StrRep
  Pop $R6 ; Normalized target
  
  ; Check if menu exists
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" ""
  ${If} ${Errors}
    ; Nothing to backup
    Return
  ${EndIf}
  
  ; Backup MenuText
  WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" "" "$R2"
  WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" "OriginalTarget" "$R0"
  
  ; Backup Command
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1\command" ""
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1\command" "" "$R2"
  ${EndIf}
  
  ; Backup Icon
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" "Icon"
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" "Icon" "$R2"
  ${EndIf}
  
  ; Backup MUIVerb
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" "MUIVerb"
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" "MUIVerb" "$R2"
  ${EndIf}
  
  ; Backup Position
  ClearErrors
  ReadRegStr $R2 HKCR "$R0\shell\$R1" "Position"
  ${IfNot} ${Errors}
    WriteRegStr ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" "Position" "$R2"
  ${EndIf}
  
  DetailPrint "Backed up global context menu: $R0\shell\$R1"
FunctionEnd
!define ContextMenu::RestoreGlobal "!insertmacro _ContextMenu::RestoreGlobal"
!macro _ContextMenu::RestoreGlobal _TARGET _MENUKEY
  Push "${_TARGET}"
  Push "${_MENUKEY}"
  Call _RestoreGlobalContextMenuFunc
!macroend
Function _RestoreGlobalContextMenuFunc
  Pop $R1 ; MenuKey
  Pop $R0 ; Target
  
  ; Normalize target path for backup key
  Push $R0
  Push "\"
  Push "_"
  Call _StrRep
  Pop $R6 ; Normalized target
  
  ; Check if we have a backup
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" ""
  ${If} ${Errors}
    ; No backup exists, just delete our entry
    DeleteRegKey HKCR "$R0\shell\$R1"
    DetailPrint "No backup found for $R0\shell\$R1, removed entry"
    Return
  ${EndIf}
  
  ; Restore MenuText
  WriteRegStr HKCR "$R0\shell\$R1" "" "$R2"
  
  ; Restore Command
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1\command" ""
  ${IfNot} ${Errors}
    WriteRegStr HKCR "$R0\shell\$R1\command" "" "$R2"
  ${EndIf}
  
  ; Restore Icon
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" "Icon"
  ${IfNot} ${Errors}
    WriteRegStr HKCR "$R0\shell\$R1" "Icon" "$R2"
  ${EndIf}
  
  ; Restore MUIVerb
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" "MUIVerb"
  ${IfNot} ${Errors}
    WriteRegStr HKCR "$R0\shell\$R1" "MUIVerb" "$R2"
  ${EndIf}
  
  ; Restore Position
  ClearErrors
  ReadRegStr $R2 ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1" "Position"
  ${IfNot} ${Errors}
    WriteRegStr HKCR "$R0\shell\$R1" "Position" "$R2"
  ${EndIf}
  
  ; Clean up backup
  DeleteRegKey ${ASSOC_ROOT} "${PAFKEYS}\GlobalContextMenus\$R6\$R1"
  
  System::Call 'shell32.dll::SHChangeNotify(i,i,i,i)v(${SHCNE_ASSOCCHANGED},${SHCNF_IDLIST},0,0)'
  
  DetailPrint "Restored global context menu: $R0\shell\$R1"
FunctionEnd
Function _StrRep
  Exch $R4 ; new
  Exch 1
  Exch $R3 ; old
  Exch 2
  Exch $R1 ; string
  Push $R2 ; current position
  Push $R5 ; temp
  
  StrCpy $R2 0
  StrLen $R5 $R3
  
  loop:
    StrCpy $R6 $R1 $R5 $R2
    StrCmp $R6 "" done
    StrCmp $R6 $R3 replace
    IntOp $R2 $R2 + 1
    Goto loop
    
  replace:
    StrCpy $R6 $R1 $R2
    IntOp $R2 $R2 + $R5
    StrCpy $R5 $R1 "" $R2
    StrCpy $R1 $R6$R4$R5
    StrLen $R5 $R3
    Goto loop
    
  done:
    StrCpy $R3 $R1
    Pop $R5
    Pop $R2
    Pop $R1
    Pop $R4
    Exch $R3
FunctionEnd
!endif

${SegmentFile}

${SegmentPre}
	!ifdef FILETYPE_ENABLED
		${DebugMsg} "Pre file associations..."
		${ReadUserConfigWithDefault} $0 FileAssociations true
    	${If} $0 == true
			; Process file associations
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $AssocExtension FileAssociation$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}

				${ReadLauncherConfig} $AssocProgID FileAssociation$R0 ProgID
				${ReadLauncherConfig} $AssocDescription FileAssociation$R0 Description
				${ReadLauncherConfig} $AssocDefaultIcon FileAssociation$R0 DefaultIcon
				${ReadLauncherConfig} $AssocOpenCommand FileAssociation$R0 OpenCommand
				${ReadLauncherConfig} $AssocEditCommand FileAssociation$R0 EditCommand
				${ReadLauncherConfig} $AssocPriority FileAssociation$R0 Priority
				${ReadLauncherConfig} $AssocIfExists FileAssociation$R0 IfExists

				${DebugMsg} "Processing file association: $AssocExtension -> $AssocProgID"
                
                ${If} $AssocDescription == ""
                    StrCpy $AssocDescription "$AppNamePortable File"
                ${EndIf}
                ${If} $AssocDefaultIcon == ""
                    StrCpy $AssocDefaultIcon "$ProgramExecutable,0"
                ${EndIf}
                ${If} $AssocOpenCommand == ""
                    StrCpy $AssocOpenCommand `"$ProgramExecutable" "%1"`
                ${EndIf}
                ${If} "$AssocProgID" == ""
                    ${FileType::GetProgID} "$AssocProgID" $AssocExtension
                    ${If} "$AssocProgID" == ""
                        StrCpy $AssocProgID "$AppID$AssocExtensionFile"
                    ${EndIf}
                ${EndIf}
                
                ${DebugMsg} "Checking conflicts for: $AssocExtension"
                ${FileType::CheckExists} "$AssocExtension"
                ${If} $R9 == "1"
                    ${Switch} $AssocIfExists
                    ${Case} "skip"
                        ${DebugMsg} "Skipping file association due to conflict: $AssocExtension"
                        ${WriteRuntimeData} FileAssociation$R0 Action "skipped"
                        ${Break}
                    ${Case} "backup"
                    ${CaseElse}
                        ${DebugMsg} "Backing up and adding portable filetype association for conflicting extension: $AssocExtension"
                        ${FileType::Register} "$AssocExtension" "$AssocProgID" "$AssocDescription" "$AssocDefaultIcon" `$AssocOpenCommand`
                        ${WriteRuntimeData} FileAssociation$R0 Action "backup"
                        ${Break}
                    ${EndSwitch}
                ${Else}
                    ${DebugMsg} "No conflicts. Adding filetype association: $AssocExtension"
                    ${FileType::Register} "$AssocExtension" "$AssocProgID" "$AssocDescription" "$AssocDefaultIcon" `$AssocOpenCommand`
                    ${WriteRuntimeData} FileAssociation$R0 Action "created"
                ${EndIf}
                			
				IntOp $R0 $R0 + 1
			${Loop}
        ${EndIf}
        ${DebugMsg} "Pre file associations completed"
    !endif
    !ifdef PROTOCOL_ENABLED
        ${DebugMsg} "Pre protocol handler..."
		${ReadUserConfigWithDefault} $0 ProtocolHandlers true
    	${If} $0 == true
			; Process protocol handlers
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $ProtoProtocol ProtocolHandler$R0 Protocol
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				${ReadLauncherConfig} $ProtoProgID ProtocolHandler$R0 ProgId
                ${ReadLauncherConfig} $ProtoDescription ProtocolHandler$R0 Description
                ${ReadLauncherConfig} $ProtoDefaultIcon ProtocolHandler$R0 DefaultIcon
                ${ReadLauncherConfig} $ProtoOpenCommand ProtocolHandler$R0 OpenCommand
				${ReadLauncherConfig} $ProtoIfExists ProtocolHandler$R0 IfExists
 
				${DebugMsg} "Processing protocol: $ProtoProtocol -> $ProtoProgID"

                ${If} $ProtoDescription == ""
                    StrCpy $ProtoDescription "$AppNamePortable Protocol"
                ${EndIf}
                ${If} $ProtoDefaultIcon == ""
                    StrCpy $ProtoDefaultIcon "$ProgramExecutable,0"
                ${EndIf}
                ${If} $ProtoOpenCommand == ""
                    StrCpy $ProtoOpenCommand `"$ProgramExecutable" --url "%1"`
                ${EndIf}
                ${If} "$ProtoProgID" == ""
                    ${Protocol::GetProgID} "$ProtoProgID" $ProtoProtocol
                    ${If} "$ProtoProgID" == ""
                        StrCpy $ProtoProgID "$AppID.$ProtoProtocol"
                    ${EndIf}
                ${EndIf}
                
                ${DebugMsg} "Checking conflicts for: $ProtoProtocol"
                ${Protocol::CheckExists} "$ProtoProtocol"
                ${If} $R9 == "1"
                    ${Switch} $ProtoIfExists
                    ${Case} "skip"
                        ${DebugMsg} "Skipping protocol handler due to conflict: $ProtoProtocol"
                        ${WriteRuntimeData} ProtocolHandler$R0 Action "skipped"
                        ${Break}
                    ${Case} "backup"
                    ${CaseElse}
                        ${DebugMsg} "Backing up and adding portable protocol for conflicting handler: $ProtoProtocol"
                        ${Protocol::Register} "$ProtoProtocol" "$ProtoProgID" "$ProtoDescription" "$ProtoDefaultIcon" `$ProtoOpenCommand`
                        ${WriteRuntimeData} ProtocolHandler$R0 Action "backup"
                        ${Break}
                    ${EndSwitch}
                ${Else}
                    ${DebugMsg} "No conflicts. Adding protocol handler: $ProtoProtocol"
                    ${Protocol::Register} "$ProtoProtocol" "$ProtoProgID" "$ProtoDescription" "$ProtoDefaultIcon" `$ProtoOpenCommand`
                    ${WriteRuntimeData} ProtocolHandler$R0 Action "created"
                ${EndIf}
				
				IntOp $R0 $R0 + 1
			${Loop}
		${EndIf}
		${DebugMsg} "Pre Protocol Handlers completed"
	!endif
	!ifdef CONTEXTMENU_ENABLED
		${DebugMsg} "Pre file associations..."
		${ReadUserConfigWithDefault} $0 ShellIntegration true
    	${If} $0 == true
			; Process file associations
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $CMenuProgId ContextMenu$R0 ProgId
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
                
                ${ReadLauncherConfig} $CMenuKey ContextMenu$R0 MenuKey
                ${ReadLauncherConfig} $CMenuText ContextMenu$R0 MenuText
                ${ReadLauncherConfig} $CMenuCommand ContextMenu$R0 MenuCommand
                ${ReadLauncherConfig} $CMenuIcon ContextMenu$R0 MenuIcon
                ${ReadLauncherConfig} $CMenuIfExists ContextMenu$R0 IfExists

				${DebugMsg} "Processing shell integration: $CMenuProgId"

                ${If} $CMenuIcon == ""
                    StrCpy $CMenuIcon "$ProgramExecutable,0"
                ${EndIf}
                ${If} $CMenuCommand == ""
                    StrCpy $CMenuCommand `"$ProgramExecutable" "%1"`
                ${EndIf}
                
                ${DebugMsg} "Checking conflicts for: $CMenuProgId"
                ${ContextMenu::CheckExists} "$AssocExtension"
                ${If} $R9 == "1"
                    ${Switch} $AssocIfExists
                    ${Case} "skip"
                        ${DebugMsg} "Skipping shell integration due to conflict: $CMenuProgId"
                        ${WriteRuntimeData} ContextMenu$R0 Action "skipped"
                        ${Break}
                    ${Case} "backup"
                    ${CaseElse}
                        ${DebugMsg} "Backing up context menu entries for conflicting shell integration: $CMenuProgId"
                        ${ContextMenu::Backup} "$CMenuProgId" "$CMenuKey"
                        ${DebugMsg} "Adding portable context menu entries for: $CMenuProgId"
                        ${ContextMenu::Add} "$CMenuProgId" "$CMenuKey" "$CMenuText" `$CMenuCommand` "$CMenuIcon"
                        ${WriteRuntimeData} ContextMenu$R0 Action "backup"
                        ${Break}
                    ${EndSwitch}
                ${Else}
                    ${DebugMsg} "No conflicts. Adding context menu entries: $CMenuProgId"
                    ${ContextMenu::Add} "$CMenuProgId" "$CMenuKey" "$CMenuText" `$CMenuCommand` "$CMenuIcon"
                    ${WriteRuntimeData} ContextMenu$R0 Action "created"
                ${EndIf}
                			
				IntOp $R0 $R0 + 1
			${Loop}
        ${EndIf}
        ${DebugMsg} "Pre file associations completed"
    !endif
!macroend

${SegmentPost}
	!ifdef CONTEXTMENU_ENABLED
		${DebugMsg} "Cleaning up context menu entries..."
		
		${ReadUserConfigWithDefault} $0 ShellIntegration= true
		${If} $0 == true
			; Remove context menus first
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $CMenuProgId ContextMenu$R0 ProgId
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				${ReadLauncherConfig} $CMenuKey ContextMenu$R0 MenuKey
				${ReadLauncherConfig} $CMenuText ContextMenu$R0 MenuText
				
				; Check if we created this context menu entry
				${ReadRuntimeData} $2 ContextMenu$R0 "Action"
                ${Switch} $2
                ${Case} "skip"
                    ${DebugMsg} "Skipped: $CMenuProgId"
                    ${Break}
                ${Case} "created"
					${ContextMenu::Remove} "$CMenuProgId" "$CMenuKey"
					${DebugMsg} "Portable context menu entries removed: $CMenuProgId"
                    ${Break}
                ${Case} "backup"
                ${CaseElse}
					${DebugMsg} "Portable context menu entries removed: $CMenuProgId"
                    ${ContextMenu::Remove} "$CMenuProgId" "$CMenuKey"
                    ${DebugMsg} "Restoring context menu entries: $CMenuProgId"
                    ${ContextMenu::Restore} "$CMenuProgId" "$CMenuKey"
                    ${Break}
                ${EndSwitch}
				
				IntOp $R0 $R0 + 1
			${Loop}
            ${DebugMsg} "Finished cleaning up context menu entries..."
        ${EndIf}
    !endif
    !ifdef PROTOCOL_ENABLED
        ${DebugMsg} "Cleaning up protocol entries..."
        
    	${ReadUserConfigWithDefault} $0 ProtocolHandlers true
    	${If} $0 == true
			; Remove protocol handlers
			StrCpy $R0 1
			${Do}
				ClearErrors              
				${ReadLauncherConfig} $ProtoProtocol ProtocolHandler$R0 Protocol
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}
				
				; Check if we created this protocol entry
                ${ReadRuntimeData} $2 ProtocolHandler$R0 "Action"
                ${Switch} $2
                ${Case} "skip"
                    ${DebugMsg} "Skipped: $ProtoProtocol"
                    ${Break}
                ${Case} "created"
                ${Case} "backup"
                ${CaseElse}
                    ${Protocol::Unregister} "$ProtoProtocol"
					${DebugMsg} "Portable context menu entries removed: $ProtoProtocol"
                    ${Break}
                ${EndSwitch}
				
				IntOp $R0 $R0 + 1
			${Loop}
			${DebugMsg} "Finished cleaning up context menu entries..."
        ${EndIf}
    !endif
    !ifdef FILETYPE_ENABLED
		${DebugMsg} "Cleaning up filetype associations..."
		${ReadUserConfigWithDefault} $0 FileAssociations true
    	${If} $0 == true
			; Remove file associations
			StrCpy $R0 1
			${Do}
				ClearErrors
				${ReadLauncherConfig} $AssocExtension FileAssociation$R0 Extension
				${IfThen} ${Errors} ${|} ${ExitDo} ${|}

				${ReadLauncherConfig} $AssocProgID FileAssociation$R0 ProgID
				
				; Check if we created this file association
                ${ReadRuntimeData} $2 FileAssociation$R0 "Action"
                ${Switch} $2
                ${Case} "skip"
                    ${DebugMsg} "Skipped: $AssocExtension"
                    ${Break}
                ${Case} "created"
                ${Case} "backup"
                ${CaseElse}
					${Filetype::Unregister} "$AssocExtension" "$AssocProgID"
					${DebugMsg} "Portable file associations removed: $AssocExtension"
                    ${Break}
                ${EndSwitch}
				
				IntOp $R0 $R0 + 1
			${Loop}
		${EndIf}
    !endif
    ; Notify explorer of changes
    ${SHCHANGENOTIFY}
    ${DebugMsg} "Filetype associations cleanup completed."
!macroend

!endif ; SEGMENT_ASSOCIATIONS
