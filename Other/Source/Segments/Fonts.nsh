;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; Fonts.nsh
;   This file handles font installation and removal with support for
;   temporary and permanent font registration for portable applications.
; 
; USAGE
;	Add sections [Font1], [Font2] etc. to Launcher.ini
;
;	Font Keys:
;	File			-	Path to font file (TTF, OTF, TTC, FON, etc.)
;	Name			-	Font family name (auto-detected if not specified)
;	Scope			-	User, System, Temporary
;	IfExists		-	skip, replace, backup
;	Required		-	true/false (show error if installation fails)
;	Validate		-	true/false (validate font file before installation)
;
;	Scope Details:
;	- System: Install for all users (requires admin rights)
;	- User: Install for current user only
;	- Temporary: Load for current session only (GDI)
;
; EXAMPLE
;	[Font1]
;	File=%PAL:AppDir%\Fonts\CustomFont.ttf
;	Name=Custom Font Family
;	Scope=User
;	IfExists=skip
;	Required=false
;	Validate=true
;
;	[Font2]
;	File=%PAL:AppDir%\Fonts\LogoFont.otf
;	Name=
;	Scope=Temporary
;	IfExists=replace
;	Required=true
;

!ifdef FONTS_ENABLE
!ifndef LOGICLIB
    !include LogicLib.nsh
!endif

!ifndef WORDREPLACE_NSH_INCLUDED
    !include WordReplace.nsh
!endif


; Font registry locations
!ifndef FONTS_SYSTEM_KEY
    !define FONTS_SYSTEM_KEY "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
!endif

!ifndef FONTS_USER_KEY
    !define FONTS_USER_KEY "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
!endif


; Font file type constants
!ifndef FONT_TRUETYPE
    !define FONT_TRUETYPE 1
!endif

!ifndef FONT_OPENTYPE
    !define FONT_OPENTYPE 2
!endif

!ifndef FONT_BITMAP
    !define FONT_BITMAP 3
!endif

!ifndef FONT_COLLECTION
    !define FONT_COLLECTION 4
!endif


; GDI font functions
!ifndef WM_FONTCHANGE
    !define WM_FONTCHANGE 0x001D
!endif

!ifndef HWND_BROADCAST
    !define HWND_BROADCAST 0xFFFF
!endif


; Validate font file
!define Font::Validate `!insertmacro _Font::Validate`
!macro _Font::Validate _FONTFILE _RESULT _FONTTYPE
	Push $0
	Push $1
	Push $2
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_FONTTYPE} "unknown"
	
	${If} ${FileExists} "${_FONTFILE}"
		; Check file extension
		${GetFileExt} "${_FONTFILE}" $0
		${StrCase} $0 $0 "L"
		
		${Switch} $0
			${Case} "ttf"
				StrCpy ${_FONTTYPE} "TrueType"
				${Break}
			${Case} "otf"
				StrCpy ${_FONTTYPE} "OpenType"
				${Break}
			${Case} "ttc"
				StrCpy ${_FONTTYPE} "TrueType Collection"
				${Break}
			${Case} "fon"
			${Case} "fnt"
				StrCpy ${_FONTTYPE} "Bitmap"
				${Break}
			${Default}
				${DebugMsg} "Unknown font file type: $0"
				Goto _FONT_VALIDATE_END
				${Break}
		${EndSwitch}
		
		; Basic file validation - check for font signature
		FileOpen $1 "${_FONTFILE}" r
		${If} $1 != ""
			; Read first 4 bytes to check signature
			FileReadByte $1 $R8
			FileReadByte $1 $R8
			FileReadByte $1 $R8
			FileReadByte $1 $R8
			
			; Check for common font signatures
			FileSeek $1 0 SET
			FileRead $1 $2 4
			FileClose $1
			
			; TTF signature: 0x00010000 or 'OTTO' for OTF
			${If} $2 != ""
				StrCpy ${_RESULT} "true"
				${DebugMsg} "Font file validation passed: ${_FONTFILE}"
			${Else}
				${DebugMsg} "Font file validation failed: ${_FONTFILE}"
			${EndIf}
		${Else}
			${DebugMsg} "Cannot open font file for validation: ${_FONTFILE}"
		${EndIf}
	${Else}
		${DebugMsg} "Font file does not exist: ${_FONTFILE}"
	${EndIf}
	
	_FONT_VALIDATE_END:
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Get font name from file
!define Font::GetName `!insertmacro _Font::GetName`
!macro _Font::GetName _FONTFILE _RESULT
	Push $0
	Push $1
	Push $R8
	
	StrCpy ${_RESULT} ""
	
	; Try to extract font name using GDI
	System::Call 'GDI32::AddFontResourceEx(t "${_FONTFILE}", i 0x10, i 0) i .r0'
	${If} $0 > 0
		; Font loaded temporarily, try to get name
		System::Call 'GDI32::CreateFont(i 0, i 0, i 0, i 0, i 0, i 0, i 0, i 0, i 1, i 0, i 0, i 0, i 0, t "") i .r1'
		${If} $1 != 0
			; Get font face name (simplified approach)
			${GetFileName} "${_FONTFILE}" $R8
			${GetBaseName} "$R8" ${_RESULT}
			${DebugMsg} "Extracted font name: ${_RESULT}"
			System::Call 'GDI32::DeleteObject(i r1)'
		${EndIf}
		
		; Remove temporary font
		System::Call 'GDI32::RemoveFontResourceEx(t "${_FONTFILE}", i 0x10, i 0)'
	${EndIf}
	
	; Fallback: use filename as font name
	${If} ${_RESULT} == ""
		${GetFileName} "${_FONTFILE}" $R8
		${GetBaseName} "$R8" ${_RESULT}
		${DebugMsg} "Using filename as font name: ${_RESULT}"
	${EndIf}
	
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Check if font is installed
!define Font::IsInstalled `!insertmacro _Font::IsInstalled`
!macro _Font::IsInstalled _FONTNAME _SCOPE _RESULT _FONTPATH
	Push $0
	Push $1
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_FONTPATH} ""
	
	${Switch} "${_SCOPE}"
		${Case} "System"
			; Check system fonts
			ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME}"
			${IfNot} ${Errors}
				StrCpy ${_RESULT} "true"
				StrCpy ${_FONTPATH} "$0"
				${DebugMsg} "System font found: ${_FONTNAME} -> $0"
			${EndIf}
			${Break}
			
		${Case} "User"
			; Check user fonts
			ReadRegStr $0 HKCU "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME}"
			${IfNot} ${Errors}
				StrCpy ${_RESULT} "true"
				StrCpy ${_FONTPATH} "$0"
				${DebugMsg} "User font found: ${_FONTNAME} -> $0"
			${EndIf}
			${Break}
			
		${Case} "Temporary"
		${CaseElse}
			; For temporary fonts, we can't easily check if loaded
			; so we assume it's not installed
			${DebugMsg} "Cannot check temporary font installation: ${_FONTNAME}"
			${Break}
	${EndSwitch}
	
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Install font
!define Font::Install `!insertmacro _Font::Install`
!macro _Font::Install _FONTFILE _FONTNAME _SCOPE _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_FONTFILE}" $R8
	
	; Validate font file exists
	${IfNot} ${FileExists} "$R8"
		StrCpy ${_ERROR} "Font file not found: $R8"
		${DebugMsg} "Font file not found: $R8"
		Goto _FONT_INSTALL_END
	${EndIf}
	
	${DebugMsg} "Installing font: ${_FONTNAME} from $R8 (Scope: ${_SCOPE})"
	
	${Switch} "${_SCOPE}"
		${Case} "System"
			; Copy font to Windows\Fonts directory
			StrCpy $0 "$FONTS\${_FONTNAME}"
			${GetFileExt} "$R8" $1
			${If} $1 != ""
				StrCpy $0 "$0.$1"
			${EndIf}
			
			CopyFiles /SILENT "$R8" "$0"
			${If} ${Errors}
				StrCpy ${_ERROR} "Failed to copy font to system fonts directory"
				${DebugMsg} "Failed to copy font to: $0"
				Goto _FONT_INSTALL_END
			${EndIf}
			
			; Register font in registry
			${GetFileName} "$0" $1
			WriteRegStr HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME} (TrueType)" "$1"
			${If} ${Errors}
				StrCpy ${_ERROR} "Failed to register system font in registry"
				Delete "$0"
				Goto _FONT_INSTALL_END
			${EndIf}
			
			; Load font into system
			System::Call 'GDI32::AddFontResource(t "$0") i .r2'
			${If} $2 == 0
				StrCpy ${_ERROR} "Failed to load system font"
				DeleteRegValue HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME} (TrueType)"
				Delete "$0"
				Goto _FONT_INSTALL_END
			${EndIf}
			
			${Break}
			
		${Case} "User"
			; For user fonts, we register without copying to system directory
			WriteRegStr HKCU "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME} (TrueType)" "$R8"
			${If} ${Errors}
				StrCpy ${_ERROR} "Failed to register user font in registry"
				Goto _FONT_INSTALL_END
			${EndIf}
			
			; Load font for current user
			System::Call 'GDI32::AddFontResourceEx(t "$R8", i 0x10, i 0) i .r2'
			${If} $2 == 0
				StrCpy ${_ERROR} "Failed to load user font"
				DeleteRegValue HKCU "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME} (TrueType)"
				Goto _FONT_INSTALL_END
			${EndIf}
			
			${Break}
			
		${Case} "Temporary"
		${CaseElse}
			; Load font temporarily (no registry entry)
			System::Call 'GDI32::AddFontResourceEx(t "$R8", i 0x10, i 0) i .r2'
			${If} $2 == 0
				StrCpy ${_ERROR} "Failed to load temporary font"
				Goto _FONT_INSTALL_END
			${EndIf}
			
			${Break}
	${EndSwitch}
	
	; Notify system of font change
	SendMessage ${HWND_BROADCAST} ${WM_FONTCHANGE} 0 0 /TIMEOUT=2000
	
	StrCpy ${_RESULT} "true"
	${DebugMsg} "Font installed successfully: ${_FONTNAME}"
	
	_FONT_INSTALL_END:
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Uninstall font
!define Font::Uninstall `!insertmacro _Font::Uninstall`
!macro _Font::Uninstall _FONTNAME _SCOPE _FONTPATH _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${DebugMsg} "Uninstalling font: ${_FONTNAME} (Scope: ${_SCOPE})"
	
	${Switch} "${_SCOPE}"
		${Case} "System"
			; Remove font resource
			${If} "${_FONTPATH}" != ""
				${If} ${FileExists} "$FONTS\${_FONTPATH}"
					StrCpy $R8 "$FONTS\${_FONTPATH}"
				${Else}
					StrCpy $R8 "${_FONTPATH}"
				${EndIf}
			${Else}
				; Try to find font file
				ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME} (TrueType)"
				${IfNot} ${Errors}
					StrCpy $R8 "$FONTS\$0"
				${Else}
					StrCpy ${_ERROR} "Cannot find system font to remove"
					Goto _FONT_UNINSTALL_END
				${EndIf}
			${EndIf}
			
			; Remove font from system
			System::Call 'GDI32::RemoveFontResource(t "$R8") i .r1'
			
			; Remove registry entry
			DeleteRegValue HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME} (TrueType)"
			
			; Remove font file
			Delete "$R8"
			
			${Break}
			
		${Case} "User"
			; Remove font resource
			${If} "${_FONTPATH}" != ""
				StrCpy $R8 "${_FONTPATH}"
			${Else}
				ReadRegStr $R8 HKCU "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME} (TrueType)"
				${If} ${Errors}
					StrCpy ${_ERROR} "Cannot find user font to remove"
					Goto _FONT_UNINSTALL_END
				${EndIf}
			${EndIf}
			
			; Remove font resource
			System::Call 'GDI32::RemoveFontResourceEx(t "$R8", i 0x10, i 0) i .r1'
			
			; Remove registry entry
			DeleteRegValue HKCU "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" "${_FONTNAME} (TrueType)"
			
			${Break}
			
		${Case} "Temporary"
		${CaseElse}
			; Remove temporary font
			${If} "${_FONTPATH}" != ""
				System::Call 'GDI32::RemoveFontResourceEx(t "${_FONTPATH}", i 0x10, i 0) i .r1'
			${Else}
				${DebugMsg} "No path provided for temporary font removal"
			${EndIf}
			
			${Break}
	${EndSwitch}
	
	; Notify system of font change
	SendMessage ${HWND_BROADCAST} ${WM_FONTCHANGE} 0 0 /TIMEOUT=2000
	
	StrCpy ${_RESULT} "true"
	${DebugMsg} "Font uninstalled successfully: ${_FONTNAME}"
	
	_FONT_UNINSTALL_END:
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Backup font information
!define Font::Backup `!insertmacro _Font::Backup`
!macro _Font::Backup _FONTNAME _SCOPE _SECTION _KEY
	Push $0
	Push $1
	
	${Font::IsInstalled} "${_FONTNAME}" "${_SCOPE}" $0 $1
	${If} $0 == "true"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_FontPath" "$1"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Scope" "${_SCOPE}"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "true"
		${DebugMsg} "Backed up font: ${_FONTNAME} -> $1"
	${Else}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "false"
		${DebugMsg} "Font ${_FONTNAME} did not exist"
	${EndIf}
	
	Pop $1
	Pop $0
!macroend

; Restore font
!define Font::Restore `!insertmacro _Font::Restore`
!macro _Font::Restore _FONTNAME _SECTION _KEY _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	
	StrCpy ${_RESULT} "false"
	
	${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_Existed"
	${If} ${Errors}
		${DebugMsg} "No backup found for font: ${_FONTNAME}"
		Goto FontRestoreEnd
	${EndIf}
	
	${If} $0 == "true"
		; Restore original font
		${ReadRuntimeData} $1 ${_SECTION} "${_KEY}_FontPath"
		${ReadRuntimeData} $2 ${_SECTION} "${_KEY}_Scope"
		
		${Font::Install} "$1" "${_FONTNAME}" "$2" $3 $0
		${If} $3 == "true"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Restored font: ${_FONTNAME}"
		${Else}
			${DebugMsg} "Failed to restore font ${_FONTNAME}: $0"
		${EndIf}
	${Else}
		; Font didn't exist originally, removal is success
		StrCpy ${_RESULT} "true"
		${DebugMsg} "Font ${_FONTNAME} did not exist originally"
	${EndIf}
	
	FontRestoreEnd:
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Refresh font cache
!define Font::RefreshCache `!insertmacro _Font::RefreshCache`
!macro _Font::RefreshCache
	Push $0
	
	${DebugMsg} "Refreshing font cache..."
	
	; Flush font cache
	System::Call 'GDI32::RemoveFontMemResourceEx(i 0)'
	
	; Force font cache rebuild
	WriteRegDWORD HKCU "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Font Management" "Auto Font Download" 1
	
	; Notify all applications
	SendMessage ${HWND_BROADCAST} ${WM_FONTCHANGE} 0 0 /TIMEOUT=5000
	
	${DebugMsg} "Font cache refresh completed"
	
	Pop $0
!macroend

; Check if user can install fonts
!define Font::CanInstall `!insertmacro _Font::CanInstall`
!macro _Font::CanInstall _SCOPE _RESULT
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "true"
	
	${Switch} "${_SCOPE}"
		${Case} "System"
			; Test write access to Windows\Fonts directory
			StrCpy $0 "$FONTS\fonttest.tmp"
			FileOpen $1 "$0" w
			${If} $1 != ""
				FileClose $1
				Delete "$0"
				${DebugMsg} "User can install system fonts"
			${Else}
				StrCpy ${_RESULT} "false"
				${DebugMsg} "User cannot install system fonts (insufficient privileges)"
			${EndIf}
			${Break}
			
		${Case} "User"
		${Case} "Temporary"
		${CaseElse}
			; User and temporary fonts don't require special privileges
			${DebugMsg} "User can install ${_SCOPE} fonts"
			${Break}
	${EndSwitch}
	
	Pop $1
	Pop $0
!macroend

; Generate fonts report
!define Font::GenerateReport `!insertmacro _Font::GenerateReport`
!macro _Font::GenerateReport _FILEPATH
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $R0
	
	FileOpen $0 "${_FILEPATH}" w
	${If} $0 != ""
		FileWrite $0 "Fonts Report$\r$\n"
		FileWrite $0 "Generated: $DATE $TIME$\r$\n"
		FileWrite $0 "============$\r$\n$\r$\n"
		
		; List configured fonts
		FileWrite $0 "Configured Fonts:$\r$\n"
		FileWrite $0 "----------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 Font$R0 File
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $2 Font$R0 Name
			${ReadLauncherConfig} $3 Font$R0 Scope
			
			${If} $2 == ""
				${Font::GetName} "$1" $2
			${EndIf}
			${If} $3 == ""
				StrCpy $3 "Temporary"
			${EndIf}
			
			${Font::IsInstalled} "$2" "$3" $4 $1
			${If} $4 == "true"
				FileWrite $0 "$2 ($3) -> $1$\r$\n"
			${Else}
				FileWrite $0 "$2 ($3) -> Not installed$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		FileClose $0
		${DebugMsg} "Fonts report generated: ${_FILEPATH}"
	${EndIf}
	
	Pop $R0
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

${SegmentFile}

;= Check permissions and backup existing fonts
${SegmentPre}
	!ifdef FONTS_ENABLED
		${DebugMsg} "Processing fonts..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Font$R0 File
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 Font$R0 Name
			${ReadLauncherConfig} $2 Font$R0 Scope
			${ReadLauncherConfig} $3 Font$R0 IfExists
			${ReadLauncherConfig} $4 Font$R0 Validate
			
			; Set defaults
			${If} $2 == ""
				StrCpy $2 "Temporary"
			${EndIf}
			${If} $3 == ""
				StrCpy $3 "replace"
			${EndIf}
			
			; Get font name if not specified
			${If} $1 == ""
				${Font::GetName} "$0" $1
			${EndIf}
			
			; Validate font file if requested
			${If} $4 == "true"
				${Font::Validate} "$0" $R8 $R9
				${If} $R8 == "false"
					${DebugMsg} "Font validation failed: $0"
					${WriteRuntimeData} FontState "$1_Failed" "validation_failed"
					IntOp $R0 $R0 + 1
					${Continue}
				${EndIf}
			${EndIf}
			
			; Check permissions
			${Font::CanInstall} "$2" $R8
			${If} $R8 == "false"
				${DebugMsg} "Insufficient privileges to install $2 font: $1"
				${WriteRuntimeData} FontState "$1_Failed" "insufficient_privileges"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${DebugMsg} "Processing font: $1 (Scope: $2)"
			
			; Check if font exists
			${Font::IsInstalled} "$1" "$2" $R8 $R9
			${If} $R8 == "true"
				${DebugMsg} "Font exists: $1 -> $R9"
				
				${Switch} $3
					${Case} "skip"
						${DebugMsg} "Skipping existing font: $1"
						${WriteRuntimeData} FontState "$1_Action" "skipped"
						${Break}
					${Case} "backup"
					${Case} "replace"
					${CaseElse}
						${Font::Backup} "$1" "$2" "FontBackup" "$1"
						${WriteRuntimeData} FontState "$1_Action" "backup"
						${Break}
				${EndSwitch}
			${Else}
				${DebugMsg} "Font does not exist: $1"
				${WriteRuntimeData} FontState "$1_Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Fonts processing completed."
	!endif
!macroend

;= Install fonts
${SegmentPrePrimary}
	!ifdef FONTS_ENABLED
		${DebugMsg} "Installing fonts..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Font$R0 File
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 Font$R0 Name
			${ReadLauncherConfig} $2 Font$R0 Scope
			${ReadLauncherConfig} $3 Font$R0 Required
			
			; Set defaults
			${If} $1 == ""
				${Font::GetName} "$0" $1
			${EndIf}
			${If} $2 == ""
				StrCpy $2 "Temporary"
			${EndIf}
			
			; Check if we should process this font
			${ReadRuntimeData} $4 FontState "$1_Action"
			${If} $4 == "skipped"
				${DebugMsg} "Skipping font as requested: $1"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Check for previous failures
			${ReadRuntimeData} $5 FontState "$1_Failed"
			${IfNot} ${Errors}
				${DebugMsg} "Skipping font due to previous failure: $1 ($5)"
				${If} $3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Cannot install required font '$1'$\n$\nReason: $5"
				${EndIf}
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${DebugMsg} "Installing font: $1 -> $0"
			
			; Install the font
			${Font::Install} "$0" "$1" "$2" $R8 $R9
			
			${If} $R8 == "true"
				${WriteRuntimeData} FontState "$1_Installed" "true"
				${WriteRuntimeData} FontState "$1_FontFile" "$0"
				${WriteRuntimeData} FontState "$1_Scope" "$2"
				${DebugMsg} "Font installed successfully: $1"
			${Else}
				${WriteRuntimeData} FontState "$1_Failed" "$R9"
				${DebugMsg} "Failed to install font $1: $R9"
				${If} $3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Failed to install required font '$1'$\n$\nError: $R9"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Refresh font cache
		${Font::RefreshCache}
		
		${DebugMsg} "Font installation completed."
	!endif
!macroend

;= Uninstall fonts
${SegmentPostPrimary}
	!ifdef FONTS_ENABLED
		${DebugMsg} "Uninstalling fonts..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Font$R0 File
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 Font$R0 Name
			
			; Set defaults
			${If} $1 == ""
				${Font::GetName} "$0" $1
			${EndIf}
			
			; Check if we installed this font
			${ReadRuntimeData} $2 FontState "$1_Installed"
			${IfNot} ${Errors}
				${ReadRuntimeData} $3 FontState "$1_FontFile"
				${ReadRuntimeData} $4 FontState "$1_Scope"
				
				${Font::Uninstall} "$1" "$4" "$3" $R8 $R9
				${If} $R8 == "true"
					${DebugMsg} "Font uninstalled successfully: $1"
				${Else}
					${DebugMsg} "Failed to uninstall font $1: $R9"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Refresh font cache
		${Font::RefreshCache}
		
		${DebugMsg} "Font uninstallation completed."
	!endif
!macroend

;= Restore original fonts
${SegmentUnload}
	!ifdef FONTS_ENABLED
		${DebugMsg} "Restoring original fonts..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Font$R0 File
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 Font$R0 Name
			
			; Set defaults
			${If} $1 == ""
				${Font::GetName} "$0" $1
			${EndIf}
			
			; Check if we need to restore this font
			${ReadRuntimeData} $2 FontState "$1_Action"
			${If} $2 == "backup"
				${Font::Restore} "$1" "FontBackup" "$1" $R8
				${If} $R8 == "true"
					${DebugMsg} "Font restored: $1"
				${Else}
					${DebugMsg} "Failed to restore font: $1"
				${EndIf}
			${EndIf}

			IntOp $R0 $R0 + 1
		${Loop}
		
		; Final font cache refresh
		${Font::RefreshCache}
		
		${DebugMsg} "Font restoration completed."
	!endif
!macroend

!endif
