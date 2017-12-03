;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Fonts.nsh
;   This file provides support for handling importing/restoring of fonts.
; 

!define FNTDIR    `${SET}\Fonts`
!define FNTXT     `${FNTDIR}\.Portable.Fonts.txt`
!define DEFFNTXT  `${DEFSET}\Fonts\.Portable.Fonts.txt`
!define FNT1      `• Font(s) added in here are portabilized and are available for usage during runtime.$\r$\n`
!define FNT2      `• Supported: .fon, .fnt, .ttf, .ttc, .fot, .otf, .mmm, .pfb, .pfm.`
Function Fonts::Import
	!macro _Fonts::Import _DIR
		Push `${_DIR}`
		Call Fonts::Import
	!macroend
	!define Fonts::Import `!insertmacro _Fonts::Import`
	Exch $0
	Push $1
	Push $2
	Push $3
	FindFirst $1 $2 `$0\*`
	StrCmpS $1 "" +19
	StrCmpS $2 "" +18
	StrCmpS $2 "." +15
	StrCmpS $2 ".." +14
	StrCpy $3 $2 "" -4
	StrCmp $3 .fon +10
	StrCmp $3 .fnt +9
	StrCmp $3 .ttf +8
	StrCmp $3 .ttc +7
	StrCmp $3 .fot +6
	StrCmp $3 .otf +5
	StrCmp $3 .mmm +4
	StrCmp $3 .pfb +3
	StrCmp $3 .pfm +2
	Goto +3
	System::Call `GDI32::AddFontResource(t"$0\$2").R3`
	SendMessage 0xFFFF 0x001D 0 0 /TIMEOUT=1
	FindNext $1 $2
	Goto -17
	FindClose $1
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd
Function Fonts::Restore
	!macro _Fonts::Restore _DIR
		Push `${_DIR}`
		Call Fonts::Restore
	!macroend
	!define Fonts::Restore `!insertmacro _Fonts::Restore`
	Exch $0
	Push $1
	Push $2
	Push $3
	FindFirst $1 $2 `$0\*`
	StrCmpS $1 "" +19
	StrCmpS $2 "" +18
	StrCmpS $2 "." +15
	StrCmpS $2 ".." +14
	StrCpy $3 $2 "" -4
	StrCmp $3 .fon +10
	StrCmp $3 .fnt +9
	StrCmp $3 .ttf +8
	StrCmp $3 .ttc +7
	StrCmp $3 .fot +6
	StrCmp $3 .otf +5
	StrCmp $3 .mmm +4
	StrCmp $3 .pfb +3
	StrCmp $3 .pfm +2
	Goto +3
	System::Call `GDI32::RemoveFontResource(t"$0\$2").R3`
	SendMessage 0xFFFF 0x001D 0 0 /TIMEOUT=1
	FindNext $1 $2
	Goto -17
	FindClose $1
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

${SegmentFile}
${SegmentPrePrimary}
	IfFileExists `${FNTXT}` +3
	CreateDirectory `${FNTDIR}`	
	CopyFiles /SILENT `${DEFFNTXT}` `${FNTXT}`
	Push `${FNTDIR}`
	Call Fonts::Import
!macroend
${SegmentUnload}
	Push `${FNTDIR}`
	Call Fonts::Restore
!macroend
