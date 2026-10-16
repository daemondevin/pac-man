;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Symlinks.nsh
;   Junctions, symbolic links and hard links from places an app insists on
;   using (e.g. %APPDATA%\Vendor) into the portable Data folder, journaled so
;   a crash can never leave a link behind or lose what was there before.
;
; USAGE
;   [Activate]
;   Symlinks=true
;
;   [Symlink1]
;   Type=junction
;   Source=Settings
;   Target=%APPDATA%\Vendor\App
;
;   Type    junction  directory junction (no admin rights needed)
;           soft      directory symbolic link (falls back to a junction when
;                     Windows refuses an unprivileged symlink)
;           symbolic  file symbolic link (needs admin rights or Developer Mode)
;           hard      file hard link (no admin rights, same volume only)
;   Source  File or folder inside the Data folder that the link points to.
;           Folders are created when missing; files must exist.
;   Target  Where the link is created. Supports environment variables.
;
;   The user can turn the segment off with Symlinks=false in the
;   <AppID>.ini user configuration file.
;
; HOW IT IS UNDONE
;   Whatever already exists at Target is renamed to
;   "<Target>.BackupBy<AppID>" (on the same volume, so nothing is copied) and
;   journaled with the link as one LINK entry. Rollback removes the link only
;   when it provably is ours (a reparse point, or a hard link to Source) and
;   then renames the original back. Missing parent folders created for the
;   link are journaled as DIR entries and removed only if still empty.
;

!ifdef SEGMENTS_SYMLINKS

Var LinkType
Var LinkSource
Var LinkTarget
Var LinkBackup
Var UserApprovesSymlinks

;= HELPERS
;= ################

; Creates the missing parent folders of $LinkTarget top-down, journaling each
; one so rollback can remove them (deepest first, only when empty).
Function Symlinks_MakeParents
	Push $0
	Push $1
	Push $2
	; Collect the missing ancestors, deepest first, as "|a|b|c".
	StrCpy $1 ""
	${GetParent} $LinkTarget $0
	${Do}
		${IfThen} $0 == "" ${|} ${ExitDo} ${|}
		${IfThen} ${FileExists} `$0\*.*` ${|} ${ExitDo} ${|}
		StrCpy $1 `$1|$0`
		${GetParent} $0 $0
	${Loop}
	; Create them top-down: walk the list from its end.
	${Do}
		${IfThen} $1 == "" ${|} ${ExitDo} ${|}
		StrLen $2 $1
		${Do}
			IntOp $2 $2 - 1
			StrCpy $0 $1 1 $2
			${IfThen} $0 == "|" ${|} ${ExitDo} ${|}
		${Loop}
		IntOp $0 $2 + 1
		StrCpy $0 $1 "" $0
		StrCpy $1 $1 $2
		${Journal::Record} Symlinks DIR $0 "" "" ""
		CreateDirectory $0
	${Loop}
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Creates the link $LinkTarget -> $LinkSource of type $LinkType.
; Sets $0 to 0 on success.
Function Symlinks_Create
	Push $1
	${Select} $LinkType
		${Case} junction
			nsExec::ExecToStack `"$SYSDIR\cmd.exe" /c mklink /J "$LinkTarget" "$LinkSource"`
			Pop $0
			Pop $1
		${Case} soft
			; SYMBOLIC_LINK_FLAG_DIRECTORY | SYMBOLIC_LINK_FLAG_ALLOW_UNPRIVILEGED_CREATE
			System::Call `kernel32::CreateSymbolicLinkW(w "$LinkTarget", w "$LinkSource", i 3)i .r0 ?e`
			Pop $1
			${If} $0 <> 0
				StrCpy $0 0
			${Else}
				${DebugMsg} "Directory symlink refused (error $1); using a junction instead."
				nsExec::ExecToStack `"$SYSDIR\cmd.exe" /c mklink /J "$LinkTarget" "$LinkSource"`
				Pop $0
				Pop $1
			${EndIf}
		${Case} symbolic
			System::Call `kernel32::CreateSymbolicLinkW(w "$LinkTarget", w "$LinkSource", i 2)i .r0 ?e`
			Pop $1
			${If} $0 <> 0
				StrCpy $0 0
			${Else}
				StrCpy $0 $1
			${EndIf}
		${Case} hard
			System::Call `kernel32::CreateHardLinkW(w "$LinkTarget", w "$LinkSource", p 0)i .r0 ?e`
			Pop $1
			${If} $0 <> 0
				StrCpy $0 0
			${Else}
				StrCpy $0 $1
			${EndIf}
	${EndSelect}
	; Trust the file system over exit codes.
	${If} $0 == 0
		System::Call `kernel32::GetFileAttributes(t "$LinkTarget")i .r1`
		${IfThen} $1 = -1 ${|} StrCpy $0 2 ${|}
	${EndIf}
	Pop $1
FunctionEnd

${SegmentFile}

${SegmentPrePrimary}
	${ReadUserConfigWithDefault} $UserApprovesSymlinks Symlinks true
	${If} $UserApprovesSymlinks != false
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $LinkSource Symlink$R0 Source
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ReadLauncherConfig} $LinkTarget Symlink$R0 Target
			${ReadLauncherConfigWithDefault} $LinkType Symlink$R0 Type junction
			${NewStrCase} $LinkType $LinkType L

			${If} $LinkType != junction
			${AndIf} $LinkType != soft
			${AndIf} $LinkType != symbolic
			${AndIf} $LinkType != hard
				${InvalidValueError} [Symlink$R0]:Type $LinkType
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}

			; Strip optional quotes, expand variables.
			StrCpy $0 $LinkTarget 1
			${If} $0 == `"`
				StrCpy $LinkTarget $LinkTarget -1 1
			${EndIf}
			StrCpy $0 $LinkSource 1
			${If} $0 == `"`
				StrCpy $LinkSource $LinkSource -1 1
			${EndIf}
			ExpandEnvStrings $LinkTarget $LinkTarget
			StrCpy $LinkSource `$DataDirectory\$LinkSource`

			; Make sure the source exists.
			${If} $LinkType == junction
			${OrIf} $LinkType == soft
				${IfNot} ${FileExists} `$LinkSource\*.*`
					CreateDirectory $LinkSource
				${EndIf}
			${ElseIfNot} ${FileExists} $LinkSource
				${DebugMsg} "[Symlink$R0] source file $LinkSource does not exist yet; skipped."
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}

			; Anything already at the target is moved aside, never deleted.
			StrCpy $LinkBackup ""
			System::Call `kernel32::GetFileAttributes(t "$LinkTarget")i .r0`
			${If} $0 <> -1
				StrCpy $LinkBackup `$LinkTarget.BackupBy${APPNAME}`
				System::Call `kernel32::GetFileAttributes(t "$LinkBackup")i .r0`
				${If} $0 <> -1
					MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
						"[Symlink$R0] cannot link $LinkTarget:$\r$\n$LinkBackup already exists from an earlier run.$\r$\n$\r$\nCheck it, then remove or rename it. The link was skipped."
					IntOp $R0 $R0 + 1
					${Continue}
				${EndIf}
			${EndIf}

			Call Symlinks_MakeParents

			; Journal before mutation: one entry covers the backup rename and
			; the link, and its undo is safe at every point in between.
			${Journal::Record} Symlinks LINK $LinkTarget $LinkBackup $LinkSource ""
			${If} $LinkBackup != ""
				ClearErrors
				Rename $LinkTarget $LinkBackup
				${If} ${Errors}
					${Journal::Discard} Symlinks
					MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
						"[Symlink$R0] could not move $LinkTarget out of the way (is it in use?).$\r$\nThe link was skipped."
					IntOp $R0 $R0 + 1
					${Continue}
				${EndIf}
			${EndIf}

			Call Symlinks_Create
			${If} $0 != 0
				; Put things back the way they were right away.
				${Journal::Discard} Symlinks
				${If} $LinkBackup != ""
					Rename $LinkBackup $LinkTarget
				${EndIf}
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"Could not create the $LinkType link (error $0):$\r$\n$LinkTarget -> $LinkSource$\r$\n$\r$\n${PORTABLEAPPNAME} may not work correctly."
			${Else}
				${DebugMsg} "Created $LinkType link $LinkTarget -> $LinkSource."
			${EndIf}

			IntOp $R0 $R0 + 1
		${Loop}
	${EndIf}
!macroend

${SegmentPostPrimary}
	${Journal::HasEntries} Symlinks $R0
	${If} $R0 > 0
		${Journal::Rollback} Symlinks
	${EndIf}
!macroend

!endif ; SEGMENTS_SYMLINKS
