;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; DirectX.nsh
; Checks for a local copy of a DirectX DLL and if not found, registers the DLLs in the portable CommonFiles folder.
; 
; Dependancies
;	DirectX Portable Plugins
;		x86 - http://softables.tk/depository/plugins/directx-runtimes-(june-2010)-32-bit-plugin
;		x64 - http://softables.tk/depository/plugins/directx-runtimes-(june-2010)-64-bit-plugin
;

!ifdef DIRECTX
!ifndef REGSVR
	!define REGSVR `$SYSDIR\regsvr32.exe`
!endif

${SegmentFile}
${SegmentPrePrimary}
	${If} ${BitDepth} 64
		FindFirst $0 $1 "$PortableAppsCommonFiles\DirectX64\bin\*.dll"
		${DoUntil} $1 == ""
			System::Call "kernel32::Wow64EnableWow64FsRedirection(i0)"
			${IfNot} ${FileExists} "$SYSDIR\$1"
				ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s "$PortableAppsCommonFiles\DirectX64\bin\$1"` "" ""
			${EndIf}
			System::Call "kernel32::Wow64EnableWow64FsRedirection(i1)"
			FindNext $0 $1
		${Loop}
		FindClose $0
	${EndIf}
	FindFirst $0 $1 "$PortableAppsCommonFiles\DirectX\bin\*.dll"
	${DoUntil} $1 == ""
		${IfNot} ${FileExists} "$SYSDIR\$1"
			ExecDos::Exec /TOSTACK `"${REGSVR}" /s "$PortableAppsCommonFiles\DirectX\bin\$1"` "" ""
		${EndIf}
		FindNext $0 $1
	${Loop}
	FindClose $0
!macroend
${SegmentPostPrimary}
	${If} ${BitDepth} 64
		FindFirst $0 $1 "$PortableAppsCommonFiles\DirectX64\bin\*.dll"
		${DoUntil} $1 == ""
			System::Call "kernel32::Wow64EnableWow64FsRedirection(i0)"
			${IfNot} ${FileExists} "$SYSDIR\$1"
				ExecDos::Exec /TOSTACK /DISABLEFSR `"${REGSVR}" /s /u "$PortableAppsCommonFiles\DirectX64\bin\$1"` "" ""
			${EndIf}
			System::Call "kernel32::Wow64EnableWow64FsRedirection(i1)"
			FindNext $0 $1
		${Loop}
		FindClose $0
	${EndIf}
	FindFirst $0 $1 "$PortableAppsCommonFiles\DirectX\bin\*.dll"
	${DoUntil} $1 == ""
		${IfNot} ${FileExists} "$SYSDIR\$1"
			ExecDos::Exec /TOSTACK `"${REGSVR}" /s /u "$PortableAppsCommonFiles\DirectX\bin\$1"` "" ""
		${EndIf}
		FindNext $0 $1
	${Loop}
	FindClose $0
!macroend
!endif
