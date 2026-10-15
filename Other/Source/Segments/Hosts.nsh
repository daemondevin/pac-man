;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Hosts.nsh
;   Temporary hostname overrides in the Windows hosts file.
;
;   This is the reference segment for the rollback journal: it records its
;   undo operation before touching the system and cleans up with nothing but
;   ${Journal::Rollback}, so normal shutdown and crash recovery run the very
;   same code.
;
; USAGE
;   [Activate]
;   Hosts=true
;
;   [Hosts]
;   1=127.0.0.1 example.local
;   2=::1 example.local
;
;   Every line the launcher adds is tagged with "# [pac-man:<AppID>]". Rollback
;   removes only tagged lines, so edits other programs make to the hosts file
;   while the app runs are preserved. A full copy of the hosts file is also
;   taken before the first change and kept in the journal store until the
;   rollback succeeds, for manual recovery.
;
;   Entries that already exist in the hosts file are left alone and are not
;   added twice.
;
; PRIVILEGES
;   Writing the hosts file requires administrator rights. Without them the
;   segment changes nothing and shows a warning (fail closed). Use
;   [Launch]:RunAsAdmin=try or prompt if the app needs this segment.
;

!ifdef SEGMENTS_HOSTS

!define HOSTS_MARKER `# [pac-man:${APPNAME}]`
!define HOSTS_TCPIP_KEY `SYSTEM\CurrentControlSet\Services\Tcpip\Parameters`

Var HostsFile
Var HostsLine

; Resolves the hosts file from DataBasePath, falling back to the default.
Function Hosts_Locate
	ClearErrors
	ReadRegStr $HostsFile HKLM `${HOSTS_TCPIP_KEY}` "DataBasePath"
	${If} ${Errors}
	${OrIf} $HostsFile == ""
		StrCpy $HostsFile `$WINDIR\System32\drivers\etc`
	${EndIf}
	ExpandEnvStrings $HostsFile $HostsFile
	StrCpy $HostsFile `$HostsFile\hosts`
FunctionEnd

; Sets $R9 to 1 when the hosts file already has a line equal to $HostsLine
; (case-insensitive, surrounding whitespace ignored), else 0.
Function Hosts_LineExists
	Push $0
	Push $1
	StrCpy $R9 0
	ClearErrors
	FileOpen $0 `$HostsFile` r
	${IfNot} ${Errors}
		${Do}
			ClearErrors
			FileRead $0 $1
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${TrimNewLines} $1 $1
			${TrimWhite} $1
			${If} $1 == $HostsLine
				StrCpy $R9 1
				${ExitDo}
			${EndIf}
		${Loop}
		FileClose $0
	${EndIf}
	Pop $1
	Pop $0
FunctionEnd

${SegmentFile}

${SegmentPrePrimary}
	; Nothing to do without entries.
	StrCpy $R2 0
	${ForEachINIPair} Hosts $R0 $R1
		${If} $R1 != ""
			StrCpy $R2 1
		${EndIf}
	${NextINIPair}

	${If} $R2 == 1
		${If} $Admin != true
			MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
				"${PORTABLEAPPNAME} needs administrator rights to add its hosts file entries.$\r$\n$\r$\nThe entries were skipped and the hosts file was not changed."
		${Else}
			Call Hosts_Locate

			; Full snapshot first, kept until rollback succeeds.
			${Journal::BackupFile} Hosts `$HostsFile` $R3
			${If} $R3 != ""
				WriteRegStr HKCU `${JOURNAL_KEY}\Hosts` "Snapshot" `$R3`
			${EndIf}

			; Journal before mutation.
			${Journal::Record} Hosts STRIPLINES `$HostsFile` `${HOSTS_MARKER}` "" ""

			ClearErrors
			FileOpen $R4 `$HostsFile` a
			${If} ${Errors}
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"${PORTABLEAPPNAME} could not open the hosts file for writing:$\r$\n$HostsFile$\r$\n$\r$\nIt may be protected by security software. The entries were skipped."
			${Else}
				; Make sure we start on a fresh line.
				FileSeek $R4 0 END $R5
				${If} $R5 > 0
					FileSeek $R4 -1 END
					FileReadByte $R4 $R5
					FileSeek $R4 0 END
					${If} $R5 != 10
						FileWrite $R4 "$\r$\n"
					${EndIf}
				${EndIf}
				FileClose $R4

				${ForEachINIPair} Hosts $R0 $R1
					ExpandEnvStrings $HostsLine $R1
					${TrimWhite} $HostsLine
					${If} $HostsLine != ""
						Call Hosts_LineExists
						${If} $R9 == 0
							FileOpen $R4 `$HostsFile` a
							FileSeek $R4 0 END
							FileWrite $R4 "$HostsLine ${HOSTS_MARKER}$\r$\n"
							FileClose $R4
						${EndIf}
					${EndIf}
				${NextINIPair}

				nsExec::ExecToStack `"$SYSDIR\ipconfig.exe" /flushdns`
				Pop $R5
				Pop $R5
			${EndIf}
		${EndIf}
	${EndIf}
!macroend

${SegmentPostPrimary}
	${Journal::HasEntries} Hosts $R0
	${If} $R0 > 0
		${Journal::Rollback} Hosts
		nsExec::ExecToStack `"$SYSDIR\ipconfig.exe" /flushdns`
		Pop $R0
		Pop $R0
	${EndIf}
!macroend

!endif ; SEGMENTS_HOSTS
