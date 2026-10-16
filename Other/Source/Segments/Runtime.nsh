;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Runtime.nsh
;   Visual C++ and .NET runtime checks, run before anything else is changed.
;
;   A runtime that is missing is provided the portable way when possible:
;   app-local Visual C++ DLLs are put on PATH and a portable .NET is made
;   visible through DOTNET_ROOT, for the app's process only. Nothing on the
;   system changes, so there is nothing to journal.
;
;   Installing a runtime system-wide is the one deliberate exception to "no
;   permanent system mutation": a shared runtime can't safely be removed
;   again, because other programs may start using it. It only ever happens
;   when the user agrees to it in a prompt that says it is permanent.
;
; USAGE
;   [Activate]
;   Runtime=true
;
;   [VCRuntime1]
;   Version=2015-2022
;   Architecture=x64
;   MinVersion=14.28.29913
;   Local=%PAL:AppDir%\Runtimes\vc14_x64
;   Installer=vc_redist.x64.exe
;   Required=true
;
;   Version       2015-2022 (also 2015, 2017, 2019, 2022 or 14), 2013, 2012,
;                 2010, 2008 or 2005.
;   Architecture  x86 (default), x64 or arm64 (arm64: 2015-2022 only).
;   MinVersion    Minimum 14.x version (2015-2022 only).
;
;   [NETRuntime1]
;   Framework=net8.0
;   Kind=desktop
;   Architecture=x64
;   MinVersion=8.0.5
;   Local=%PAL:AppDir%\dotnet
;   Required=true
;
;   Framework     .NET Framework: net20, net35, net40, net45, net451, net452,
;                 net46, net461, net462, net47, net471, net472, net48,
;                 net481 (dots allowed: net4.8). .NET 5 and later: net5.0,
;                 net6.0, net8.0 and so on (net8 also works).
;   Kind          .NET 5 and later only: core (default, Microsoft.NETCore.App),
;                 desktop (Microsoft.WindowsDesktop.App) or aspnet
;                 (Microsoft.AspNetCore.App).
;   Architecture  x86 (default) or x64. Ignored for .NET Framework.
;   MinVersion    .NET 5 and later only, e.g. 8.0.5.
;
;   Keys for both:
;   Local         Folder with a portable copy of the runtime. Visual C++: the
;                 runtime DLLs, put in front of PATH. .NET 5 and later: a
;                 dotnet folder (with shared\...), set as DOTNET_ROOT. Only
;                 used when the runtime isn't installed. Not available for
;                 .NET Framework.
;   Installer     Redistributable to offer when the runtime is missing and
;                 Local can't provide it. A bare file name is looked up in
;                 App\Prerequisites. The user is asked first; the runtime
;                 stays installed after the app closes.
;   InstallerArgs Switches for the installer. Default: /install /passive
;                 /norestart (/q for Visual C++ 2005 and 2008, /passive
;                 /norestart for 2010 and .NET Framework).
;   Required      true: when the runtime is still missing the app is not
;                 started. false (default): a warning is shown and the app is
;                 started anyway.
;
;   The old keys still work: Action=skip ignores the section, Action=install
;   or bundle is the same as giving an Installer. Mode is ignored.
;

!ifdef SEGMENTS_RUNTIME

Var RtKind
Var RtVer
Var RtArch
Var RtName
Var RtMin
Var RtFound
Var RtLocal
Var RtInstaller
Var RtArgs
Var RtRequired

;= HELPERS
;= ################

; Sets $0 to the system folder holding $RtArch DLLs, or "" when this Windows
; can't run that architecture.
Function Rt_SysDir
	${If} $RtArch == x86
		${If} $Bit == 64
			StrCpy $0 `$WINDIR\SysWOW64`
		${Else}
			StrCpy $0 `$WINDIR\System32`
		${EndIf}
	${ElseIf} $Bit == 64
		; 32-bit launcher: Sysnative is the real System32 while file system
		; redirection is on; with it off, System32 already is.
		${If} ${FileExists} `$WINDIR\Sysnative\*.*`
			StrCpy $0 `$WINDIR\Sysnative`
		${Else}
			StrCpy $0 `$WINDIR\System32`
		${EndIf}
	${Else}
		StrCpy $0 ""
	${EndIf}
FunctionEnd

; Reads the 2015-2022 runtime version for $RtArch from one registry view
; into $1 ("" when not installed).
!macro _Rt_VC14Read _VIEW
	SetRegView ${_VIEW}
	ClearErrors
	ReadRegDWORD $2 HKLM `SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$RtArch` Installed
	${If} $2 = 1
		ReadRegStr $2 HKLM `SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\$RtArch` Version
		StrCpy $3 $2 1
		${IfThen} $3 == v ${|} StrCpy $2 $2 "" 1 ${|}
		${If} $2 != ""
			StrCpy $1 $2
		${EndIf}
	${EndIf}
	SetRegView lastused
!macroend

; Visual C++: sets $RtFound to true when the runtime in $RtVer/$RtArch is
; installed system-wide (and new enough).
Function Rt_VCDetect
	Push $0
	Push $1
	Push $2
	Push $3
	StrCpy $RtFound false
	${If} $RtVer == 14
		StrCpy $1 ""
		!insertmacro _Rt_VC14Read 32
		${If} $1 == ""
			!insertmacro _Rt_VC14Read 64
		${EndIf}
		${If} $1 != ""
			StrCpy $RtFound true
			${If} $RtMin != ""
				${VersionCompare} $1 $RtMin $2
				${If} $2 == 2
					StrCpy $RtFound false
					${DebugMsg} "$RtName $1 is older than $RtMin."
				${EndIf}
			${EndIf}
		${ElseIf} $RtMin == ""
			; No registry entry: an app-local or OS-provided copy still counts.
			Call Rt_SysDir
			${If} $0 != ""
			${AndIf} ${FileExists} `$0\vcruntime140.dll`
			${AndIf} ${FileExists} `$0\msvcp140.dll`
				StrCpy $RtFound true
			${EndIf}
		${EndIf}
	${ElseIf} $RtVer == 9
	${OrIf} $RtVer == 8
		; Side-by-side assemblies.
		${If} $RtArch == x64
			StrCpy $1 amd64
		${Else}
			StrCpy $1 x86
		${EndIf}
		FindFirst $2 $3 `$WINDIR\WinSxS\$1_microsoft.vc$RtVer0.crt_1fc8b3b9a1e18e3b_*`
		FindClose $2
		${IfThen} $3 != "" ${|} StrCpy $RtFound true ${|}
	${Else}
		Call Rt_SysDir
		${If} $0 != ""
		${AndIf} ${FileExists} `$0\msvcr$RtVer0.dll`
		${AndIf} ${FileExists} `$0\msvcp$RtVer0.dll`
			StrCpy $RtFound true
		${EndIf}
	${EndIf}
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; .NET 5 and later: sets $RtFound to true when $0\shared\$1\<major>.* holds
; a version that satisfies $RtMin.
Function Rt_CoreFind
	Push $2
	Push $3
	Push $4
	StrCpy $RtFound false
	FindFirst $2 $3 `$0\shared\$1\$RtVer.*`
	${Do}
		${IfThen} $3 == "" ${|} ${ExitDo} ${|}
		${If} ${FileExists} `$0\shared\$1\$3\*.*`
			${If} $RtMin == ""
				StrCpy $RtFound true
			${Else}
				${VersionCompare} $3 $RtMin $4
				${IfThen} $4 != 2 ${|} StrCpy $RtFound true ${|}
			${EndIf}
			${IfThen} $RtFound == true ${|} ${ExitDo} ${|}
		${EndIf}
		FindNext $2 $3
	${Loop}
	FindClose $2
	Pop $4
	Pop $3
	Pop $2
FunctionEnd

; .NET: sets $RtFound to true when the runtime in $RtVer is installed.
; $RtKind is framework (with $RtVer = Release threshold, or 20/35/40) or
; one of core, desktop, aspnet.
Function Rt_NETDetect
	Push $0
	Push $1
	StrCpy $RtFound false
	${If} $RtKind == framework
		ClearErrors
		${If} $RtVer == 20
			ReadRegDWORD $0 HKLM `SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727` Install
			${IfThen} $0 = 1 ${|} StrCpy $RtFound true ${|}
		${EndIf}
		${If} $RtVer == 20
		${OrIf} $RtVer == 35
			ReadRegDWORD $0 HKLM `SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5` Install
			${IfThen} $0 = 1 ${|} StrCpy $RtFound true ${|}
		${ElseIf} $RtVer == 40
			ReadRegDWORD $0 HKLM `SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` Install
			${IfThen} $0 = 1 ${|} StrCpy $RtFound true ${|}
		${ElseIf} $RtVer != 20
			ReadRegDWORD $0 HKLM `SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full` Release
			${If} $0 != ""
			${AndIf} $0 >= $RtVer
				StrCpy $RtFound true
			${EndIf}
		${EndIf}
	${Else}
		${If} $RtKind == desktop
			StrCpy $1 Microsoft.WindowsDesktop.App
		${ElseIf} $RtKind == aspnet
			StrCpy $1 Microsoft.AspNetCore.App
		${Else}
			StrCpy $1 Microsoft.NETCore.App
		${EndIf}
		${If} $RtArch == x86
		${AndIf} $Bit == 64
			StrCpy $0 `$PROGRAMFILES32\dotnet`
		${ElseIf} $RtArch == x64
		${AndIf} $Bit != 64
			Goto rt_net_done
		${Else}
			StrCpy $0 `$PROGRAMFILES64\dotnet`
		${EndIf}
		Call Rt_CoreFind
	${EndIf}
	rt_net_done:
	Pop $1
	Pop $0
FunctionEnd

; Makes the portable copy in $RtLocal visible to the app. Sets $RtFound to
; true when it holds the runtime.
Function Rt_UseLocal
	Push $0
	Push $1
	${If} $RtKind == vc
		StrCpy $1 ""
		${If} $RtVer == 14
			${IfThen} ${FileExists} `$RtLocal\vcruntime140.dll` ${|} StrCpy $1 ok ${|}
		${ElseIf} $RtVer == 9
		${OrIf} $RtVer == 8
			${IfThen} ${FileExists} `$RtLocal\msvcr$RtVer0.dll` ${|} StrCpy $1 ok ${|}
		${Else}
			${IfThen} ${FileExists} `$RtLocal\msvcr$RtVer0.dll` ${|} StrCpy $1 ok ${|}
		${EndIf}
		${If} $1 == ok
			ReadEnvStr $0 PATH
			System::Call `kernel32::SetEnvironmentVariable(t "PATH", t "$RtLocal;$0")`
			StrCpy $RtFound true
			${DebugMsg} "$RtName: using the copy in $RtLocal (added to PATH)."
		${EndIf}
	${ElseIf} $RtKind != framework
		StrCpy $0 $RtLocal
		${If} $RtKind == desktop
			StrCpy $1 Microsoft.WindowsDesktop.App
		${ElseIf} $RtKind == aspnet
			StrCpy $1 Microsoft.AspNetCore.App
		${Else}
			StrCpy $1 Microsoft.NETCore.App
		${EndIf}
		Call Rt_CoreFind
		${If} $RtFound == true
			${If} $RtArch == x86
				System::Call `kernel32::SetEnvironmentVariable(t "DOTNET_ROOT_X86", t "$RtLocal")`
				${If} $Bit == 64
					System::Call `kernel32::SetEnvironmentVariable(t "DOTNET_ROOT(x86)", t "$RtLocal")`
				${Else}
					System::Call `kernel32::SetEnvironmentVariable(t "DOTNET_ROOT", t "$RtLocal")`
				${EndIf}
			${Else}
				System::Call `kernel32::SetEnvironmentVariable(t "DOTNET_ROOT_X64", t "$RtLocal")`
				System::Call `kernel32::SetEnvironmentVariable(t "DOTNET_ROOT", t "$RtLocal")`
			${EndIf}
			${DebugMsg} "$RtName: using the copy in $RtLocal (DOTNET_ROOT)."
		${EndIf}
	${EndIf}
	Pop $1
	Pop $0
FunctionEnd

; Detects the runtime described by $RtKind/$RtVer/$RtArch, then falls back
; to Local, then (with the user's consent) to Installer.
Function Rt_Resolve
	Push $0
	${If} $RtKind == vc
		Call Rt_VCDetect
	${Else}
		Call Rt_NETDetect
	${EndIf}
	${If} $RtFound == true
		${DebugMsg} "$RtName is installed."
		Goto rt_done
	${EndIf}

	${If} $RtLocal != ""
		Call Rt_UseLocal
		${IfThen} $RtFound == true ${|} Goto rt_done ${|}
	${EndIf}

	${If} $RtInstaller != ""
		${IfNot} ${FileExists} $RtInstaller
			${DebugMsg} "$RtName installer not found: $RtInstaller"
		${Else}
			MessageBox MB_YESNO|MB_ICONQUESTION|MB_TOPMOST \
				"${PORTABLEAPPNAME} needs $RtName, which is not installed.$\r$\n$\r$\nInstall it now? It will stay installed on this computer after ${PORTABLEAPPNAME} closes." \
				IDNO rt_report
			ExecWait `"$RtInstaller" $RtArgs` $0
			${DebugMsg} "$RtName installer exit code: $0"
			${If} $RtKind == vc
				Call Rt_VCDetect
			${Else}
				Call Rt_NETDetect
			${EndIf}
			${IfThen} $RtFound == true ${|} Goto rt_done ${|}
		${EndIf}
	${EndIf}

	rt_report:
	${If} $RtRequired == true
		MessageBox MB_OK|MB_ICONSTOP|MB_TOPMOST \
			"${PORTABLEAPPNAME} can't start because $RtName is not installed."
		Quit
	${Else}
		MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
			"$RtName is not installed.$\r$\n${PORTABLEAPPNAME} may not work correctly."
	${EndIf}

	rt_done:
	Pop $0
FunctionEnd

; Reads the keys both section types share. _SECTION is VCRuntime$R0 or
; NETRuntime$R0. Sets the error flag when the section is to be skipped.
!macro _Rt_ReadCommon _SECTION
	${ReadLauncherConfig} $RtLocal `${_SECTION}` Local
	ExpandEnvStrings $RtLocal $RtLocal
	${ReadLauncherConfig} $RtInstaller `${_SECTION}` Installer
	ExpandEnvStrings $RtInstaller $RtInstaller
	${ReadLauncherConfig} $RtRequired `${_SECTION}` Required
	${ReadLauncherConfig} $RtMin `${_SECTION}` MinVersion
	${ReadLauncherConfig} $RtArgs `${_SECTION}` InstallerArgs
	${If} $RtInstaller != ""
		; A bare file name lives in App\Prerequisites.
		StrCpy $0 $RtInstaller 1 1
		StrCpy $1 $RtInstaller 2
		${If} $0 != ":"
		${AndIf} $1 != "\\"
			StrCpy $RtInstaller `$Prerequisites\$RtInstaller`
		${EndIf}
	${EndIf}
	ClearErrors
	${ReadLauncherConfig} $0 `${_SECTION}` Action
	${NewStrCase} $0 $0 L
	${If} $0 == skip
		SetErrors
	${ElseIf} $0 == install
	${OrIf} $0 == bundle
		${If} $RtInstaller == ""
			${DebugMsg} "[${_SECTION}] Action=$0 without an Installer key."
		${EndIf}
		ClearErrors
	${Else}
		ClearErrors
	${EndIf}
!macroend
!define Rt_ReadCommon `!insertmacro _Rt_ReadCommon`

${SegmentFile}

${SegmentInit}
	${If} ${PrimaryInstance}
		; Visual C++
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $RtVer VCRuntime$R0 Version
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${Rt_ReadCommon} VCRuntime$R0
			${IfNot} ${Errors}
				StrCpy $RtKind vc
				StrCpy $0 $RtVer
				${If} $0 == 2015-2022
				${OrIf} $0 == 2015
				${OrIf} $0 == 2017
				${OrIf} $0 == 2019
				${OrIf} $0 == 2022
				${OrIf} $0 == 14
					StrCpy $RtVer 14
					StrCpy $0 2015-2022
				${ElseIf} $0 == 2013
					StrCpy $RtVer 12
				${ElseIf} $0 == 2012
					StrCpy $RtVer 11
				${ElseIf} $0 == 2010
					StrCpy $RtVer 10
				${ElseIf} $0 == 2008
					StrCpy $RtVer 9
				${ElseIf} $0 == 2005
					StrCpy $RtVer 8
				${Else}
					StrCpy $RtVer ""
				${EndIf}
				${ReadLauncherConfigWithDefault} $RtArch VCRuntime$R0 Architecture x86
				${NewStrCase} $RtArch $RtArch L
				${IfThen} $RtArch == amd64 ${|} StrCpy $RtArch x64 ${|}
				${If} $RtVer == ""
					${InvalidValueError} [VCRuntime$R0]:Version $0
				${ElseIf} $RtArch != x86
				${AndIf} $RtArch != x64
				${AndIf} $RtArch != arm64
					${InvalidValueError} [VCRuntime$R0]:Architecture $RtArch
				${ElseIf} $RtArch == arm64
				${AndIf} $RtVer != 14
					${InvalidValueError} [VCRuntime$R0]:Architecture "arm64 (2015-2022 only)"
				${Else}
					StrCpy $RtName "Microsoft Visual C++ $0 Redistributable ($RtArch)"
					${If} $RtArgs == ""
						${If} $RtVer == 9
						${OrIf} $RtVer == 8
							StrCpy $RtArgs /q
						${ElseIf} $RtVer == 10
							StrCpy $RtArgs "/passive /norestart"
						${Else}
							StrCpy $RtArgs "/install /passive /norestart"
						${EndIf}
					${EndIf}
					Call Rt_Resolve
				${EndIf}
			${EndIf}
			IntOp $R0 $R0 + 1
		${Loop}

		; .NET
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 NETRuntime$R0 Framework
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${Rt_ReadCommon} NETRuntime$R0
			${IfNot} ${Errors}
				${ReadLauncherConfig} $0 NETRuntime$R0 Framework
				${NewStrCase} $0 $0 L
				StrCpy $1 $0 3
				${IfThen} $1 == net ${|} StrCpy $0 $0 "" 3 ${|}
				; "8.0" style: the part before the first dot is the major.
				StrCpy $2 ""
				StrCpy $3 ""
				StrCpy $4 0
				${Do}
					StrCpy $1 $0 1 $4
					${IfThen} $1 == "" ${|} ${ExitDo} ${|}
					${If} $1 == "."
						${IfThen} $3 == "" ${|} StrCpy $3 $2 ${|}
					${Else}
						StrCpy $2 `$2$1`
					${EndIf}
					IntOp $4 $4 + 1
				${Loop}
				; $2 = all digits, $3 = digits before the first dot (if any).
				StrCpy $RtKind ""
				StrCpy $1 $2 1
				${If} $1 == 2
				${OrIf} $1 == 3
				${OrIf} $1 == 4
					StrCpy $RtKind framework
					${Select} $2
						${Case2} 2 20
							StrCpy $RtVer 20
							StrCpy $RtName "Microsoft .NET Framework 2.0"
						${Case2} 35 3
							StrCpy $RtVer 35
							StrCpy $RtName "Microsoft .NET Framework 3.5"
						${Case2} 4 40
							StrCpy $RtVer 40
							StrCpy $RtName "Microsoft .NET Framework 4"
						${Case} 45
							StrCpy $RtVer 378389
						${Case} 451
							StrCpy $RtVer 378675
						${Case} 452
							StrCpy $RtVer 379893
						${Case} 46
							StrCpy $RtVer 393295
						${Case} 461
							StrCpy $RtVer 394254
						${Case} 462
							StrCpy $RtVer 394802
						${Case} 47
							StrCpy $RtVer 460798
						${Case} 471
							StrCpy $RtVer 461308
						${Case} 472
							StrCpy $RtVer 461808
						${Case} 48
							StrCpy $RtVer 528040
						${Case} 481
							StrCpy $RtVer 533320
						${CaseElse}
							StrCpy $RtKind ""
					${EndSelect}
					${If} $RtKind == framework
					${AndIf} $RtVer > 1000
						; "48" -> "4.8", "472" -> "4.7.2"
						StrCpy $1 $2 1
						StrCpy $4 $2 1 1
						StrCpy $RtName "Microsoft .NET Framework $1.$4"
						StrCpy $4 $2 1 2
						${IfThen} $4 != "" ${|} StrCpy $RtName "$RtName.$4" ${|}
					${EndIf}
					StrCpy $RtArch x86
					${If} $RtArgs == ""
						StrCpy $RtArgs "/passive /norestart"
					${EndIf}
				${Else}
					; .NET 5 and later: net8.0, net80 and net8 all mean 8.
					${If} $3 != ""
						StrCpy $RtVer $3
					${ElseIf} $2 >= 50
						StrCpy $RtVer $2 -1
					${Else}
						StrCpy $RtVer $2
					${EndIf}
					${If} $RtVer >= 5
						${ReadLauncherConfigWithDefault} $RtKind NETRuntime$R0 Kind core
						${NewStrCase} $RtKind $RtKind L
						${ReadLauncherConfigWithDefault} $RtArch NETRuntime$R0 Architecture x86
						${NewStrCase} $RtArch $RtArch L
						${IfThen} $RtArch == amd64 ${|} StrCpy $RtArch x64 ${|}
						${IfThen} $RtArch == anycpu ${|} StrCpy $RtArch x86 ${|}
						${If} $RtKind == desktop
							StrCpy $RtName ".NET $RtVer Desktop Runtime ($RtArch)"
						${ElseIf} $RtKind == aspnet
							StrCpy $RtName "ASP.NET Core $RtVer Runtime ($RtArch)"
						${ElseIf} $RtKind == core
							StrCpy $RtName ".NET $RtVer Runtime ($RtArch)"
						${Else}
							${InvalidValueError} [NETRuntime$R0]:Kind $RtKind
							StrCpy $RtKind ""
						${EndIf}
						${If} $RtArch != x86
						${AndIf} $RtArch != x64
							${InvalidValueError} [NETRuntime$R0]:Architecture $RtArch
							StrCpy $RtKind ""
						${EndIf}
						${If} $RtArgs == ""
							StrCpy $RtArgs "/install /passive /norestart"
						${EndIf}
					${EndIf}
				${EndIf}
				${If} $RtKind == ""
					${ReadLauncherConfig} $0 NETRuntime$R0 Framework
					${InvalidValueError} [NETRuntime$R0]:Framework $0
				${Else}
					Call Rt_Resolve
				${EndIf}
			${EndIf}
			IntOp $R0 $R0 + 1
		${Loop}
	${EndIf}
!macroend

!endif ; SEGMENTS_RUNTIME
