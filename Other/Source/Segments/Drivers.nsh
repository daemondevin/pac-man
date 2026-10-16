;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Drivers.nsh
;   Driver packages that are in the Windows driver store only while the app
;   runs, journaled so a crash can never leave one behind.
;
;   Uses pnputil /add-driver and /delete-driver (Windows 10 1607 and later).
;   Needs administrator rights; without them nothing is changed and one
;   warning is shown.
;
; USAGE
;   [Activate]
;   Drivers=true
;
;   [Driver1]
;   InfFile=%PAL:AppDir%\Drivers\x64\mydevice.inf
;   Architecture=x64
;   Install=true
;   Required=true
;
;   InfFile       The driver package's INF. The package has to be signed the
;                 way Windows requires; pnputil refuses it otherwise.
;                 Supports %PAL:...% and environment variables.
;   Architecture  x86, x64 or any (default). The section is skipped on
;                 Windows of the other bitness, so a package can be listed
;                 once per architecture.
;   Install       true (default) also installs the driver on matching
;                 devices that are present (pnputil /install). false only
;                 adds the package to the driver store.
;   Required      true to warn when the package cannot be added.
;
;   A package that is already in the driver store before launch belongs to
;   someone else: it is left alone and never removed.
;
; HOW IT IS UNDONE
;   A DRIVER entry holding a copy of the INF is journaled before pnputil
;   runs. The undo finds the driver store's oemNN.inf with the same content
;   and removes the package with pnputil /delete-driver /uninstall /force,
;   so devices that were using it fall back to their previous driver.
;   Published names (oemNN.inf) are never read from pnputil's output, which
;   is localized.
;

!ifdef SEGMENTS_DRIVERS

Var DrvInf
Var DrvCopy
Var DrvRequired
Var DrvWarned

; Adds the driver package in [Driver$R0].
Function Drv_Add
	Push $0
	Push $1
	Push $2

	${ReadLauncherConfig} $DrvInf Driver$R0 InfFile
	StrCpy $0 $DrvInf 1
	${If} $0 == `"`
		StrCpy $DrvInf $DrvInf -1 1
	${EndIf}
	ExpandEnvStrings $DrvInf $DrvInf
	${ReadLauncherConfig} $DrvRequired Driver$R0 Required

	${ReadLauncherConfigWithDefault} $0 Driver$R0 Architecture any
	${NewStrCase} $0 $0 L
	${If} $0 == x86
	${OrIf} $0 == x64
	${OrIf} $0 == amd64
		${IfThen} $0 == amd64 ${|} StrCpy $0 x64 ${|}
		${If} $0 == x64
		${AndIf} $Bit != 64
			${DebugMsg} "[Driver$R0] is for x64 Windows; skipped."
			Goto drv_done
		${EndIf}
		${If} $0 == x86
		${AndIf} $Bit == 64
			${DebugMsg} "[Driver$R0] is for x86 Windows; skipped."
			Goto drv_done
		${EndIf}
	${ElseIf} $0 != any
		${InvalidValueError} [Driver$R0]:Architecture $0
		Goto drv_done
	${EndIf}

	${IfNot} ${FileExists} $DrvInf
		${If} $DrvRequired == true
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"Driver package not found:$\r$\n$DrvInf"
		${EndIf}
		Goto drv_done
	${EndIf}

	; Someone else's package: leave it alone, never remove it.
	${Journal::FindStagedInf} $DrvInf $0
	${If} $0 != ""
		${DebugMsg} "[Driver$R0] is already in the driver store as $0; left alone."
		Goto drv_done
	${EndIf}

	; Journal before mutation: keep a copy of the INF so the package can be
	; found again even when the portable drive is gone.
	${Journal::BackupFile} Drivers $DrvInf $DrvCopy
	${If} $DrvCopy == ""
		${DebugMsg} "[Driver$R0] could not copy $DrvInf to the journal store; skipped."
		Goto drv_done
	${EndIf}
	${Journal::Record} Drivers DRIVER $DrvCopy "" "" ""

	${Journal::PnPUtil} $2
	${ReadLauncherConfig} $0 Driver$R0 Install
	${If} $0 == false
		nsExec::ExecToStack `"$2" /add-driver "$DrvInf"`
	${Else}
		nsExec::ExecToStack `"$2" /add-driver "$DrvInf" /install`
	${EndIf}
	Pop $0
	Pop $1

	; Trust the driver store over exit codes: pnputil also reports failure
	; when the package was added but no device needed it.
	${Journal::FindStagedInf} $DrvCopy $2
	${If} $2 == ""
		${Journal::Discard} Drivers
		Delete $DrvCopy
		${DebugMsg} "pnputil could not add $DrvInf ($0):$\r$\n$1"
		${If} $DrvRequired == true
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"Could not add the driver package$\r$\n$DrvInf$\r$\n$\r$\n$1"
		${EndIf}
	${Else}
		${DebugMsg} "[Driver$R0] added as $2 (pnputil exit code $0)."
	${EndIf}

	drv_done:
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

${SegmentFile}

${SegmentPrePrimary}
	StrCpy $DrvWarned ""
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 Driver$R0 InfFile
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${If} $Admin != true
			; Fail closed: no driver without the rights to remove it again.
			${If} $DrvWarned == ""
				StrCpy $DrvWarned true
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"${PORTABLEAPPNAME} needs administrator rights to add its drivers.$\r$\nNo drivers were added."
			${EndIf}
			${ExitDo}
		${EndIf}
		Call Drv_Add
		IntOp $R0 $R0 + 1
	${Loop}
!macroend

${SegmentPostPrimary}
	${Journal::HasEntries} Drivers $R0
	${If} $R0 > 0
		${Journal::Rollback} Drivers
	${EndIf}
!macroend

!endif ; SEGMENTS_DRIVERS
