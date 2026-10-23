;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   MissingApp.nsh
;   Tells the user how to finish setting up a package that doesn't include
;   the program itself.
;
;   Some packages can't ship the program they launch: commercial software
;   (WeBuilder, FL Studio, Photoshop), or free software whose license doesn't
;   allow copies to be passed on. The user copies the program folder of an
;   installed copy into App. Until that is done, this segment explains what to
;   copy and where, offers to open the App folder, and quits.
;
;   It runs in .onInit, after the language is chosen and before the RunAsAdmin
;   segment, so the message comes in the user's language, without a UAC
;   prompt, and before the journal, data moves or anything else start.
;
; USAGE
;   [Activate]
;   MissingApp=true
;
;   [MissingApp]
;   Reason=commercial
;   URL=https://www.blumentals.net/webuilder/
;   Folder=WeBuilder
;   RequiredFile1=WeBuilder\webuilder.exe.manifest
;   RequiredFile2=WeBuilder\Data\*.*
;
;   The whole [MissingApp] section is optional.
;
;   Reason         Why the program isn't included: commercial (the default:
;                  commercial software, the user needs their own copy and
;                  license), noredistribute (its license doesn't allow copies
;                  to be passed on), or any other text, shown as it is.
;   URL            Where to get the program, shown in the message.
;   Folder         The folder in App to copy the program into. By default it
;                  is the first folder of the program's path, for example
;                  WeBuilder for WeBuilder\webuilder.exe.
;   RequiredFileN  More files or folders, relative to App, that must be there
;                  too. Wildcards work, so Folder\*.* checks that a folder
;                  isn't empty. Copying only the program file out of a program
;                  folder is a common mistake, and many programs can't start
;                  without the rest.
;
;   The program is the executable the launch itself will use, chosen the same
;   way: ProgramExecutableARM64, ProgramExecutable64 and ProgramExecutable in
;   [Launch] (and their WhenParameters variants when there are parameters),
;   for this computer's architecture. When custom.nsh chooses the executable
;   itself (a ProExecInit macro), only the RequiredFileN entries are checked.
;
;   Nothing is changed on the computer, so there is nothing to journal.
;

!ifdef SEGMENTS_MISSINGAPP

; false when custom.nsh chooses the executable itself (ProExecInit)
Var MissingAppCheckExe

; Sets $R2 to the folder in App the program belongs in (full path).
; $R1 = the program's path relative to App.
Function MissingApp_Folder
	Push $0
	Push $1
	ClearErrors
	${ReadLauncherConfig} $R2 MissingApp Folder
	${If} ${Errors}
	${OrIf} $R2 == ""
		StrCpy $R2 ""
		StrCpy $1 0
		${Do}
			StrCpy $0 $R1 1 $1
			${IfThen} $0 == "" ${|} ${ExitDo} ${|}
			${If} $0 == "\"
				StrCpy $R2 $R1 $1
				${ExitDo}
			${EndIf}
			IntOp $1 $1 + 1
		${Loop}
	${EndIf}
	${If} $R2 == ""
		StrCpy $R2 `$EXEDIR\App`
	${Else}
		StrCpy $R2 `$EXEDIR\App\$R2`
	${EndIf}
	ClearErrors
	Pop $1
	Pop $0
FunctionEnd

; Sets $0 to 1 when App\$1 exists, else 0. With a wildcard, at least one
; real entry has to match, so an empty folder doesn't count for Folder\*.*.
Function MissingApp_Exists
	Push $2
	Push $3
	StrCpy $0 0
	${If} ${FileExists} `$EXEDIR\App\$1`
		StrCpy $0 1
		; $3 = true when the path has a wildcard
		StrCpy $3 false
		StrCpy $2 0
		${Do}
			StrCpy $0 $1 1 $2
			${IfThen} $0 == "" ${|} ${ExitDo} ${|}
			${If} $0 == "*"
			${OrIf} $0 == "?"
				StrCpy $3 true
				${ExitDo}
			${EndIf}
			IntOp $2 $2 + 1
		${Loop}
		StrCpy $0 1
		${If} $3 == true
			StrCpy $0 0
			ClearErrors
			FindFirst $2 $3 `$EXEDIR\App\$1`
			${DoUntil} ${Errors}
				${IfThen} $3 == "" ${|} ${ExitDo} ${|}
				${If} $3 != "."
				${AndIf} $3 != ".."
					StrCpy $0 1
					${ExitDo}
				${EndIf}
				FindNext $2 $3
			${Loop}
			FindClose $2
		${EndIf}
	${EndIf}
	ClearErrors
	Pop $3
	Pop $2
FunctionEnd

; Sets $R3 to the RequiredFileN entries that don't exist, one per line, and
; $R4 to how many there are.
Function MissingApp_RequiredFiles
	Push $0
	Push $1
	Push $2
	StrCpy $R3 ""
	StrCpy $R4 0
	StrCpy $2 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $1 MissingApp RequiredFile$2
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${If} $1 != ""
			Call MissingApp_Exists
			${If} $0 == 0
				IntOp $R4 $R4 + 1
				; The first ten are listed; a longer list wouldn't fit.
				${If} $R4 <= 10
					${If} $R3 == ""
						StrCpy $R3 `$EXEDIR\App\$1`
					${Else}
						StrCpy $R3 `$R3$\r$\n$EXEDIR\App\$1`
					${EndIf}
				${EndIf}
			${EndIf}
		${EndIf}
		IntOp $2 $2 + 1
	${Loop}
	${If} $R4 > 10
		IntOp $0 $R4 - 10
		StrCpy $R3 `$R3$\r$\n(+$0)`
	${EndIf}
	ClearErrors
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Shows the message in $R0, adding the download link and the offer to open
; the App folder, then quits.
Function MissingApp_Tell
	Push $3
	ClearErrors
	${ReadLauncherConfig} $3 MissingApp URL
	${If} ${Errors}
		StrCpy $3 ""
	${EndIf}
	${If} $3 != ""
		StrCpy $R0 `$R0$\r$\n$\r$\n$(LauncherMissingAppDownload)`
	${EndIf}
	StrCpy $R0 `$R0$\r$\n$\r$\n$(LauncherMissingAppOpen)`
	MessageBox MB_YESNO|MB_ICONINFORMATION|MB_TOPMOST $R0 IDNO MissingApp_Quit
	CreateDirectory `$EXEDIR\App`
	ExecShell open `$EXEDIR\App`
	MissingApp_Quit:
	Pop $3
	Quit
FunctionEnd

Function MissingApp_Check
	Push $0
	Push $1
	Push $2
	Push $R0
	Push $R1
	Push $R2
	Push $R3
	Push $R4

	; $R1 = the program the launch will look for, "" when it's there (or
	; chosen by custom code, or a Java runtime that isn't in App).
	StrCpy $R1 ""
	${If} $MissingAppCheckExe == true
		Call Core_LaunchParameters
		StrCpy $1 $0
		Call Core_SelectProgramExecutable
		${If} $ProgramExecutable == ""
		${OrIfNot} ${FileExists} `$EXEDIR\App\$ProgramExecutable`
			; Named as the package expects it for this computer: the x64
			; build on 64-bit Windows, even when only x86 is configured too.
			StrCpy $R1 $CoreWantedExecutable
			${GetFileName} $R1 $0
			${If} $0 == java.exe
			${OrIf} $0 == javaw.exe
				StrCpy $R1 ""
			${EndIf}
		${EndIf}
		; Core chooses it again in Init, with the full launch state.
		StrCpy $ProgramExecutable ""
	${EndIf}

	Call MissingApp_RequiredFiles

	${If} $R1 != ""
		Call MissingApp_Folder
		ClearErrors
		${ReadLauncherConfig} $0 MissingApp Reason
		${If} ${Errors}
		${OrIf} $0 == ""
		${OrIf} $0 == commercial
			StrCpy $0 "$(LauncherMissingAppCommercial)"
		${ElseIf} $0 == noredistribute
			StrCpy $0 "$(LauncherMissingAppNoRedistribute)"
		${EndIf}
		StrCpy $1 $R2
		StrCpy $2 `$EXEDIR\App\$R1`
		StrCpy $R0 "$(LauncherMissingApp)"
		Call MissingApp_Tell
	${ElseIf} $R4 > 0
		StrCpy $R1 $CoreWantedExecutable
		Call MissingApp_Folder
		StrCpy $1 $R2
		StrCpy $2 $R3
		StrCpy $R0 "$(LauncherMissingAppIncomplete)"
		Call MissingApp_Tell
	${EndIf}

	Pop $R4
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $R0
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

${SegmentFile}
${Segment.onInit}
	; Decided here rather than in the function: custom.nsh is included after
	; the segments, so its macros only exist where hooks are inserted.
	!ifmacrodef ProExecInit
		StrCpy $MissingAppCheckExe false
	!else
		StrCpy $MissingAppCheckExe true
	!endif
	Call MissingApp_Check
!macroend

!endif
