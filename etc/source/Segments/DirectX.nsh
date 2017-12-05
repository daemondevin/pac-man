;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; DirectX.nsh
; Checks for a local copy of a DirectX DLL and if not found, registers the DLLs in the portable CommonFiles folder.
;

; ${FindRegDirectXRuntimes} "DLL"
!define FindRegDirectXRuntimes `!insertmacro _FindRegDirectXRuntimes`
!macro _FindRegDirectXRuntimes _DLL
	StrCmpS $Bit 64 0 +6
	${DISABLEREDIR}
	IfFileExists "$SYSDIR\${_DLL}" +3 0
	IfFileExists "$PortableAppsCommonFiles\DirectX64\bin\${_DLL}" 0 +7
	ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s "$PortableAppsCommonFiles\DirectX64\bin\${_DLL}"` "" ""
	${ENABLEREDIR}
	IfFileExists "$SYSDIR\${_DLL}" +3 0
	IfFileExists "$PortableAppsCommonFiles\DirectX\bin\${_DLL}" 0 +4
	ExecDos::Exec /TOSTACK `"${REGSVR}" /s "$PortableAppsCommonFiles\DirectX\bin\${_DLL}"` "" ""
	Goto +5
	${ENABLEREDIR}
	MessageBox MB_ICONSTOP|MB_TOPMOST "The ${_DLL} runtime DLL was not found locally or portably!$\r$\n$\r$\nPlease install the DirectX Runtimes Portable plugin to play ${APPNAME}. Aborting!$\r$\n$\r$\nBoth x86/x64 DirectX plugins can be found at:$\r$\nhttp://softables.tk/depository/plugins"
	Call Unload
	Quit
!macroend
; ${UnRegDirectXRuntimes} "DLL"
!define UnRegDirectXRuntimes `!insertmacro _UnRegDirectXRuntimes`
!macro _UnRegDirectXRuntimes _DLL
	${IfThen} $Bit == 64 ${|} ${DISABLEREDIR} ${|}
	${IfNot} ${FileExists} "$SYSDIR\${_DLL}"
		${If} $Bit == 64
			ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s /u "$PortableAppsCommonFiles\DirectX64\bin\${_DLL}"` "" ""
		${Else}
			ExecDos::Exec /TOSTACK `"${REGSVR}" /s /u "$PortableAppsCommonFiles\DirectX64\bin\${_DLL}"` "" ""
		${EndIf}
	${EndIf}
	${IfThen} $Bit == 64 ${|} ${ENABLEREDIR} ${|}
!macroend

${SegmentFile}
${SegmentInit}
	; ${If} ${FileExists} "$PortableAppsDirectory\CommonFiles\DirectX64\bin\*.*"
		; FindFirst $0 $1 "$PortableAppsDirectory\CommonFiles\DirectX64\bin\*.dll"
	; ${ElseIf} ${FileExists} "$PortableAppsDirectory\CommonFiles\DirectX\bin\*.*"
		; FindFirst $0 $1 "$PortableAppsDirectory\CommonFiles\DirectX\bin\*.dll"
	; ${EndIf}
	; ${DoUntil} $1 == ""
		; ${FindRegDirectXRuntimes} "$1"
		; FindNext $0 $1
	; ${Loop}
	; FindClose $0

	${FindRegDirectXRuntimes} "xactengine2_0.dll"
	${FindRegDirectXRuntimes} "xactengine2_1.dll"
	${FindRegDirectXRuntimes} "xactengine2_2.dll"
	${FindRegDirectXRuntimes} "xactengine2_3.dll"
	${FindRegDirectXRuntimes} "xactengine2_4.dll"
	${FindRegDirectXRuntimes} "xactengine2_5.dll"
	${FindRegDirectXRuntimes} "xactengine2_6.dll"
	${FindRegDirectXRuntimes} "xactengine2_7.dll"
	${FindRegDirectXRuntimes} "xactengine2_8.dll"
	${FindRegDirectXRuntimes} "xactengine2_9.dll"
	${FindRegDirectXRuntimes} "xactengine2_10.dll"
	${FindRegDirectXRuntimes} "xactengine3_0.dll"
	${FindRegDirectXRuntimes} "xactengine3_1.dll"
	${FindRegDirectXRuntimes} "xactengine3_2.dll"
	${FindRegDirectXRuntimes} "xactengine3_3.dll"
	${FindRegDirectXRuntimes} "xactengine3_4.dll"
	${FindRegDirectXRuntimes} "xactengine3_5.dll"
	${FindRegDirectXRuntimes} "xactengine3_6.dll"
	${FindRegDirectXRuntimes} "xactengine3_7.dll"
	${FindRegDirectXRuntimes} "XAudio2_0.dll"
	${FindRegDirectXRuntimes} "XAudio2_1.dll"
	${FindRegDirectXRuntimes} "XAudio2_2.dll"
	${FindRegDirectXRuntimes} "XAudio2_3.dll"
	${FindRegDirectXRuntimes} "XAudio2_4.dll"
	${FindRegDirectXRuntimes} "XAudio2_5.dll"
	${FindRegDirectXRuntimes} "XAudio2_6.dll"
	${FindRegDirectXRuntimes} "XAudio2_7.dll"
!macroend
${SegmentUnload}
	; ${If} ${FileExists} "$PortableAppsDirectory\CommonFiles\DirectX64\bin\*.*"
		; FindFirst $0 $1 "$PortableAppsDirectory\CommonFiles\DirectX64\bin\*.dll"
	; ${ElseIf} ${FileExists} "$PortableAppsDirectory\CommonFiles\DirectX\bin\*.*"
		; FindFirst $0 $1 "$PortableAppsDirectory\CommonFiles\DirectX\bin\*.dll"
	; ${EndIf}
	; ${DoUntil} $1 == ""
		; ${UnRegDirectXRuntimes} "$1"
		; FindNext $0 $1
	; ${Loop}
	; FindClose $0
	
	${UnRegDirectXRuntimes} "xactengine2_0.dll"
	${UnRegDirectXRuntimes} "xactengine2_1.dll"
	${UnRegDirectXRuntimes} "xactengine2_2.dll"
	${UnRegDirectXRuntimes} "xactengine2_3.dll"
	${UnRegDirectXRuntimes} "xactengine2_4.dll"
	${UnRegDirectXRuntimes} "xactengine2_5.dll"
	${UnRegDirectXRuntimes} "xactengine2_6.dll"
	${UnRegDirectXRuntimes} "xactengine2_7.dll"
	${UnRegDirectXRuntimes} "xactengine2_8.dll"
	${UnRegDirectXRuntimes} "xactengine2_9.dll"
	${UnRegDirectXRuntimes} "xactengine2_10.dll"
	${UnRegDirectXRuntimes} "xactengine3_0.dll"
	${UnRegDirectXRuntimes} "xactengine3_1.dll"
	${UnRegDirectXRuntimes} "xactengine3_2.dll"
	${UnRegDirectXRuntimes} "xactengine3_3.dll"
	${UnRegDirectXRuntimes} "xactengine3_4.dll"
	${UnRegDirectXRuntimes} "xactengine3_5.dll"
	${UnRegDirectXRuntimes} "xactengine3_6.dll"
	${UnRegDirectXRuntimes} "xactengine3_7.dll"
	${UnRegDirectXRuntimes} "XAudio2_0.dll"
	${UnRegDirectXRuntimes} "XAudio2_1.dll"
	${UnRegDirectXRuntimes} "XAudio2_2.dll"
	${UnRegDirectXRuntimes} "XAudio2_3.dll"
	${UnRegDirectXRuntimes} "XAudio2_4.dll"
	${UnRegDirectXRuntimes} "XAudio2_5.dll"
	${UnRegDirectXRuntimes} "XAudio2_6.dll"
	${UnRegDirectXRuntimes} "XAudio2_7.dll"
!macroend
