;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Fonts.nsh
;   Temporary and user-scoped font availability, journaled so fonts never
;   outlive the app, even after a crash. Font files are never copied into
;   the Windows Fonts folder.
;
; USAGE
;   [Activate]
;   Fonts=true
;
;   [Font1]
;   File=%PAL:AppDir%\Fonts\*.ttf
;   Scope=Temporary
;
;   File      Font file or wildcard. Supports environment variables.
;   Scope     Temporary (default)  loaded for the current session with
;                                  AddFontResource; every program can use
;                                  it until it is removed. No admin rights.
;             User                 also registered under HKCU (per-user
;                                  fonts, Windows 10 1809 and later) so apps
;                                  that look fonts up in the registry find
;                                  it. No admin rights.
;             System               also registered under HKLM. Needs admin
;                                  rights; without them the font is loaded
;                                  temporarily instead.
;   Name      Registry value name for User/System scope. Defaults to the
;             file name plus " (TrueType)" or " (OpenType)". Ignored when
;             File is a wildcard.
;   IfExists  skip (default) or replace, when the registry value already
;             exists. replace backs up the old value and restores it.
;   Required  true to warn when a font cannot be loaded.
;
;   With no [FontN] sections, every font in %PAL:DataDir%\Fonts is loaded
;   temporarily (the old FontsFolder behaviour).
;
; HOW IT IS UNDONE
;   FONT entries call RemoveFontResourceEx, REGVALUE entries put the previous
;   registry value back (or delete it), then WM_FONTCHANGE is broadcast.
;

!ifdef SEGMENTS_FONTS

!define FONTS_REG_KEY `Software\Microsoft\Windows NT\CurrentVersion\Fonts`
!define /ifndef FONTS_WM_FONTCHANGE 0x001D
!define /ifndef FONTS_HWND_BROADCAST 0xFFFF

Var FontFile
Var FontScope
Var FontName
Var FontIfExists
Var FontRequired
Var FontLoaded
Var FontWarned

; Loads one font file ($FontFile) with the settings in $FontScope, $FontName,
; $FontIfExists and $FontRequired.
Function Fonts_LoadOne
	Push $0
	Push $1
	Push $2

	; Registry value for User/System scope.
	${If} $FontScope == user
	${OrIf} $FontScope == system
		StrCpy $1 $FontName
		${If} $1 == ""
			${GetBaseName} $FontFile $1
			${GetFileExt} $FontFile $2
			${NewStrCase} $2 $2 L
			${If} $2 == otf
				StrCpy $1 `$1 (OpenType)`
			${Else}
				StrCpy $1 `$1 (TrueType)`
			${EndIf}
		${EndIf}
		ClearErrors
		${If} $FontScope == system
			ReadRegStr $0 HKLM `${FONTS_REG_KEY}` $1
		${Else}
			ReadRegStr $0 HKCU `${FONTS_REG_KEY}` $1
		${EndIf}
		${If} ${Errors}
			StrCpy $2 ""
		${Else}
			StrCpy $2 `STR:$0`
		${EndIf}
		${If} $2 != ""
		${AndIf} $FontIfExists != replace
			${DebugMsg} "Font registry value '$1' already exists; registry left alone."
		${Else}
			${If} $FontScope == system
				${Journal::Record} Fonts REGVALUE HKLM `${FONTS_REG_KEY}` $1 $2
				WriteRegStr HKLM `${FONTS_REG_KEY}` $1 $FontFile
			${Else}
				${Journal::Record} Fonts REGVALUE HKCU `${FONTS_REG_KEY}` $1 $2
				WriteRegStr HKCU `${FONTS_REG_KEY}` $1 $FontFile
			${EndIf}
		${EndIf}
	${EndIf}

	; Load it for the session. Public (flags 0), so the app can see it.
	${Journal::Record} Fonts FONT $FontFile 0 "" ""
	System::Call `gdi32::AddFontResourceEx(t "$FontFile", i 0, p 0)i .r0`
	${If} $0 = 0
		${Journal::Discard} Fonts
		${If} $FontRequired == true
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"Could not load the font $FontFile.$\r$\n${PORTABLEAPPNAME} may not display correctly."
		${EndIf}
	${Else}
		StrCpy $FontLoaded true
		${DebugMsg} "Loaded font $FontFile ($FontScope)."
	${EndIf}

	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Loads every file matching the pattern in $FontFile.
Function Fonts_LoadPattern
	Push $0
	Push $1
	Push $2
	StrCpy $2 $FontFile
	${GetParent} $2 $1
	FindFirst $0 $FontFile $2
	${DoWhile} $FontFile != ""
		${IfNot} ${FileExists} `$1\$FontFile\*.*`
			StrCpy $FontFile `$1\$FontFile`
			Call Fonts_LoadOne
		${EndIf}
		FindNext $0 $FontFile
	${Loop}
	FindClose $0
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

${SegmentFile}

${SegmentPrePrimary}
	StrCpy $FontLoaded false
	StrCpy $FontWarned ""
	ClearErrors
	${ReadLauncherConfig} $0 Font1 File
	${If} ${Errors}
		; No [FontN] sections: load the Data\Fonts folder temporarily.
		StrCpy $FontScope temporary
		StrCpy $FontName ""
		StrCpy $FontIfExists skip
		StrCpy $FontRequired false
		StrCpy $FontFile `$DataDirectory\Fonts\*.*`
		Call Fonts_LoadPattern
	${Else}
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $FontFile Font$R0 File
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ParseLocations} $FontFile
			${ReadLauncherConfigWithDefault} $FontScope Font$R0 Scope temporary
			${ReadLauncherConfig} $FontName Font$R0 Name
			${ReadLauncherConfigWithDefault} $FontIfExists Font$R0 IfExists skip
			${ReadLauncherConfig} $FontRequired Font$R0 Required
			${NewStrCase} $FontScope $FontScope L
			${NewStrCase} $FontIfExists $FontIfExists L

			${If} $FontScope == system
			${AndIf} $Admin != true
				; Fail closed on the registry part, still make the font usable.
				${If} $FontWarned == ""
					StrCpy $FontWarned true
					${DebugMsg} "System font scope needs admin rights; loading fonts temporarily instead."
				${EndIf}
				StrCpy $FontScope temporary
			${EndIf}
			${If} $FontScope != user
			${AndIf} $FontScope != system
				StrCpy $FontScope temporary
			${EndIf}

			${WordFind} $FontFile "*" "E+1{" $0
			${If} ${Errors}
				; No wildcard.
				${If} ${FileExists} $FontFile
					Call Fonts_LoadOne
				${ElseIf} $FontRequired == true
					MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
						"Font file not found:$\r$\n$FontFile"
				${EndIf}
			${Else}
				StrCpy $FontName ""
				Call Fonts_LoadPattern
			${EndIf}
			IntOp $R0 $R0 + 1
		${Loop}
	${EndIf}
	${If} $FontLoaded == true
		SendMessage ${FONTS_HWND_BROADCAST} ${FONTS_WM_FONTCHANGE} 0 0 /TIMEOUT=2000
	${EndIf}
!macroend

${SegmentPostPrimary}
	${Journal::HasEntries} Fonts $R0
	${If} $R0 > 0
		${Journal::Rollback} Fonts
		SendMessage ${FONTS_HWND_BROADCAST} ${FONTS_WM_FONTCHANGE} 0 0 /TIMEOUT=2000
	${EndIf}
!macroend

!endif ; SEGMENTS_FONTS
