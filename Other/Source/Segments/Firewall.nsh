;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; SEGMENT
;   Firewall.nsh
;   Windows Firewall rules that exist only while the app runs, journaled so
;   a crash can never leave a rule behind.
;
;   Every rule is created with "[pac-man:<AppID>]" appended to its name and
;   is only ever deleted by that full name, so rules the launcher did not
;   create are never touched. Needs administrator rights; without them
;   nothing is changed and one warning is shown.
;
; USAGE
;   [Activate]
;   Firewall=true
;
;   [FirewallRule1]
;   Name=MyApp HTTP Server
;   Direction=In
;   Action=Allow
;   Protocol=TCP
;   LocalPort=8080
;   Program=%PAL:AppDir%\MyApp\server.exe
;   Profile=Private,Public
;   Description=Allow HTTP access to MyApp server
;   Required=true
;
;   Name           Rule name (required). Shown as "<Name> [pac-man:<AppID>]".
;   Direction      In (default), Out or Both (two rules with the same name).
;   Action         Allow (default), Block or Bypass.
;   Protocol       Any (default), TCP, UDP, ICMPv4, ICMPv6 or a number.
;   LocalPort      Port, range or list (80, 8000-8080, 80,443). TCP/UDP only.
;   RemotePort     As LocalPort.
;   LocalAddress   Address, range, subnet or keyword (optional).
;   RemoteAddress  As LocalAddress.
;   Program        Executable the rule applies to. Supports %PAL:...% and
;                  environment variables.
;   Service        Service short name the rule applies to (optional).
;   Profile        Any (default) or a comma list of Domain, Private, Public.
;   InterfaceType  Any (default), Wireless, LAN or RAS.
;   Enabled        true (default) or false.
;   EdgeTraversal  true to allow edge traversal (inbound rules only).
;   Security       NotRequired (default), Authenticate, AuthEnc, AuthDynEnc
;                  or AuthNoEncap.
;   Description    Rule description.
;   Required       true to warn when the rule cannot be created.
;
;   Blocking every program in a folder:
;
;   [FirewallRule2]
;   BlockAll=true
;   BlockAllDir=%PAL:AppDir%\MyApp
;   BlockAllRecur=true
;
;   BlockAll       true to add an outbound block rule for every .exe found.
;   BlockAllDir    Folder to scan. Supports %PAL:...% and environment variables.
;   BlockAllRecur  true (default) to include subfolders.
;
;   IfExists is accepted for compatibility and ignored: a rule that already
;   carries this app's tag can only be left over from this app, so it is
;   always replaced and removed again on exit.
;
; HOW IT IS UNDONE
;   Before each rule is added a CMD entry is journaled that deletes it by its
;   full name (exit code 1, "no rules match", counts as done). The entry is
;   marked admin-only, so a launch without admin rights keeps it for a later
;   elevated launch instead of losing it.
;

!ifdef SEGMENTS_FIREWALL

!define FW_TAG `[pac-man:${APPNAME}]`
!define FW_NETSH `"$SYSDIR\netsh.exe" advfirewall firewall`

Var FWName
Var FWDirection
Var FWArgs
Var FWRequired
Var FWCreated
Var FWWarned
Var FWList
Var FWItem

;= HELPERS
;= ################

; Sets $_JT4 to 1 when "|$FWItem|" appears in $FWList ("|a|b|c|"), else 0.
Function FW_InList
	StrCpy $_JT1 $FWList
	StrCpy $_JT2 `|$FWItem|`
	Call Journal_Contains
FunctionEnd
!macro _FW_Check _VALUE _LIST
	StrCpy $FWItem `${_VALUE}`
	StrCpy $FWList `${_LIST}`
	Call FW_InList
!macroend
!define FW_Check `!insertmacro _FW_Check`

; Reads a value, strips one pair of quotes and expands variables.
!macro _FW_Read _VAR _KEY
	${ReadLauncherConfig} ${_VAR} FirewallRule$R0 `${_KEY}`
	StrCpy $_JT1 ${_VAR} 1
	${If} $_JT1 == `"`
		StrCpy $_JT1 ${_VAR} "" -1
		${If} $_JT1 == `"`
			StrCpy ${_VAR} ${_VAR} -1 1
		${EndIf}
	${EndIf}
	ExpandEnvStrings ${_VAR} ${_VAR}
!macroend
!define FW_Read `!insertmacro _FW_Read`

; Adds the rule "$FWName ${FW_TAG}" with the netsh arguments in $FWArgs, for
; direction $FWDirection (in, out or both). $FWArgs must not contain dir=.
; Sets $FWCreated to true when at least one rule was added.
Function FW_AddRule
	Push $0
	Push $1
	Push $2
	Push $3
	StrCpy $FWCreated false
	StrCpy $3 `$FWName ${FW_TAG}`
	; Journal before mutation. One delete by name covers both directions and
	; any stale rule with the same tagged name.
	${Journal::Record} Firewall CMD `${FW_NETSH} delete rule name="$3"` "0,1" admin ""
	nsExec::ExecToStack `${FW_NETSH} delete rule name="$3"`
	Pop $0
	Pop $1
	${If} $FWDirection == both
		StrCpy $2 "in out"
	${Else}
		StrCpy $2 $FWDirection
	${EndIf}
	${Do}
		${IfThen} $2 == "" ${|} ${ExitDo} ${|}
		StrCpy $0 $2 3
		${If} $0 == "in "
		${OrIf} $2 == in
			StrCpy $0 in
			StrCpy $2 $2 "" 3
		${Else}
			StrCpy $0 out
			StrCpy $2 ""
		${EndIf}
		nsExec::ExecToStack `${FW_NETSH} add rule name="$3" dir=$0 $FWArgs`
		Pop $1
		Pop $0
		${If} $1 == 0
			StrCpy $FWCreated true
			${DebugMsg} "Added firewall rule $3."
		${Else}
			${DebugMsg} "netsh add rule failed ($1):$\r$\n$0"
			${If} $FWRequired == true
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"Could not create the firewall rule$\r$\n$3$\r$\n$\r$\n$0"
			${EndIf}
		${EndIf}
	${Loop}
	${If} $FWCreated != true
		; Nothing was added, so there is nothing to undo.
		${Journal::Discard} Firewall
	${EndIf}
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Adds an outbound block rule for every .exe under $FWItem (recursively when
; $FWList is true). Rule names use the path relative to the scanned folder.
Function FW_BlockAll
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	StrCpy $4 $FWItem
	StrCpy $3 $FWList
	; Pending folders, separated by "|", relative to $4 ("" is the root).
	StrCpy $0 "|"
	${Do}
		${IfThen} $0 == "" ${|} ${ExitDo} ${|}
		; Pop the first pending folder.
		StrCpy $0 $0 "" 1
		StrCpy $1 0
		${Do}
			StrCpy $2 $0 1 $1
			${If} $2 == "|"
			${OrIf} $2 == ""
				${ExitDo}
			${EndIf}
			IntOp $1 $1 + 1
		${Loop}
		StrCpy $2 $0 $1
		StrCpy $0 $0 "" $1
		${If} $2 == ""
			StrCpy $FWItem $4
		${Else}
			StrCpy $FWItem `$4\$2`
		${EndIf}
		FindFirst $1 $FWList `$FWItem\*.*`
		${Do}
			${IfThen} $FWList == "" ${|} ${ExitDo} ${|}
			${If} $FWList != "."
			${AndIf} $FWList != ".."
				${If} ${FileExists} `$FWItem\$FWList\*.*`
					${If} $3 != false
						${If} $2 == ""
							StrCpy $0 `$0|$FWList`
						${Else}
							StrCpy $0 `$0|$2\$FWList`
						${EndIf}
					${EndIf}
				${Else}
					${GetFileExt} $FWList $FWName
					${If} $FWName == exe
						${If} $2 == ""
							StrCpy $FWName `Block $FWList`
						${Else}
							StrCpy $FWName `Block $2\$FWList`
						${EndIf}
						StrCpy $FWDirection out
						StrCpy $FWArgs `action=block enable=yes program="$FWItem\$FWList"`
						Call FW_AddRule
					${EndIf}
				${EndIf}
			${EndIf}
			FindNext $1 $FWList
		${Loop}
		FindClose $1
	${Loop}
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Reads [FirewallRule$R0], validates it and builds $FWArgs. Sets the error
; flag when the section is invalid (a message has been shown).
Function FW_ReadRule
	Push $0
	Push $1
	${FW_Read} $FWName Name
	${If} $FWName == ""
		${InvalidValueError} [FirewallRule$R0]:Name "(empty)"
		Goto fw_invalid
	${EndIf}

	${ReadLauncherConfigWithDefault} $FWDirection FirewallRule$R0 Direction in
	${NewStrCase} $FWDirection $FWDirection L
	${IfThen} $FWDirection == inbound ${|} StrCpy $FWDirection in ${|}
	${IfThen} $FWDirection == outbound ${|} StrCpy $FWDirection out ${|}
	${FW_Check} $FWDirection "|in|out|both|"
	${If} $_JT4 != 1
		${InvalidValueError} [FirewallRule$R0]:Direction $FWDirection
		Goto fw_invalid
	${EndIf}

	${ReadLauncherConfigWithDefault} $0 FirewallRule$R0 Action allow
	${NewStrCase} $0 $0 L
	${FW_Check} $0 "|allow|block|bypass|"
	${If} $_JT4 != 1
		${InvalidValueError} [FirewallRule$R0]:Action $0
		Goto fw_invalid
	${EndIf}
	StrCpy $FWArgs `action=$0`

	${ReadLauncherConfigWithDefault} $0 FirewallRule$R0 Enabled true
	${If} $0 == false
		StrCpy $FWArgs `$FWArgs enable=no`
	${Else}
		StrCpy $FWArgs `$FWArgs enable=yes`
	${EndIf}

	${ReadLauncherConfigWithDefault} $1 FirewallRule$R0 Protocol any
	${NewStrCase} $1 $1 L
	${FW_Check} $1 "|any|tcp|udp|icmpv4|icmpv6|"
	${If} $_JT4 != 1
		IntOp $0 $1 + 0
		${If} "$0" != "$1"
		${OrIf} $0 < 0
		${OrIf} $0 > 255
			${InvalidValueError} [FirewallRule$R0]:Protocol $1
			Goto fw_invalid
		${EndIf}
	${EndIf}
	StrCpy $FWArgs `$FWArgs protocol=$1`

	${FW_Read} $0 LocalPort
	${If} $0 != ""
	${AndIf} $0 != any
		${If} $1 != tcp
		${AndIf} $1 != udp
			${InvalidValueError} [FirewallRule$R0]:LocalPort "$0 (needs Protocol=TCP or UDP)"
			Goto fw_invalid
		${EndIf}
		StrCpy $FWArgs `$FWArgs localport=$0`
	${EndIf}
	${FW_Read} $0 RemotePort
	${If} $0 != ""
	${AndIf} $0 != any
		${If} $1 != tcp
		${AndIf} $1 != udp
			${InvalidValueError} [FirewallRule$R0]:RemotePort "$0 (needs Protocol=TCP or UDP)"
			Goto fw_invalid
		${EndIf}
		StrCpy $FWArgs `$FWArgs remoteport=$0`
	${EndIf}

	${FW_Read} $0 LocalAddress
	${IfThen} $0 != "" ${|} StrCpy $FWArgs `$FWArgs localip=$0` ${|}
	${FW_Read} $0 RemoteAddress
	${IfThen} $0 != "" ${|} StrCpy $FWArgs `$FWArgs remoteip=$0` ${|}

	${FW_Read} $0 Program
	${If} $0 != ""
		${IfNot} ${FileExists} $0
			${DebugMsg} "[FirewallRule$R0] program $0 does not exist (yet); adding the rule anyway."
		${EndIf}
		StrCpy $FWArgs `$FWArgs program="$0"`
	${EndIf}
	${FW_Read} $0 Service
	${IfThen} $0 != "" ${|} StrCpy $FWArgs `$FWArgs service="$0"` ${|}

	${ReadLauncherConfigWithDefault} $0 FirewallRule$R0 Profile any
	${NewStrCase} $0 $0 L
	; Check each item of the comma list and rebuild it without spaces.
	StrCpy $1 `$0,`
	StrCpy $0 ""
	${Do}
		${IfThen} $1 == "" ${|} ${ExitDo} ${|}
		StrCpy $FWItem ""
		${Do}
			StrCpy $_JT3 $1 1
			StrCpy $1 $1 "" 1
			${IfThen} $_JT3 == "," ${|} ${ExitDo} ${|}
			${IfThen} $_JT3 != " " ${|} StrCpy $FWItem `$FWItem$_JT3` ${|}
		${Loop}
		StrCpy $FWList "|any|domain|private|public|"
		Call FW_InList
		${If} $_JT4 != 1
			${InvalidValueError} [FirewallRule$R0]:Profile $FWItem
			Goto fw_invalid
		${EndIf}
		${If} $0 == ""
			StrCpy $0 $FWItem
		${Else}
			StrCpy $0 `$0,$FWItem`
		${EndIf}
	${Loop}
	StrCpy $FWArgs `$FWArgs profile=$0`

	${ReadLauncherConfigWithDefault} $0 FirewallRule$R0 InterfaceType any
	${NewStrCase} $0 $0 L
	${FW_Check} $0 "|any|wireless|lan|ras|"
	${If} $_JT4 != 1
		${InvalidValueError} [FirewallRule$R0]:InterfaceType $0
		Goto fw_invalid
	${EndIf}
	StrCpy $FWArgs `$FWArgs interfacetype=$0`

	${ReadLauncherConfig} $0 FirewallRule$R0 Security
	${If} $0 != ""
		${NewStrCase} $0 $0 L
		${FW_Check} $0 "|notrequired|authenticate|authenc|authdynenc|authnoencap|"
		${If} $_JT4 != 1
			${InvalidValueError} [FirewallRule$R0]:Security $0
			Goto fw_invalid
		${EndIf}
		StrCpy $FWArgs `$FWArgs security=$0`
	${EndIf}

	${ReadLauncherConfig} $0 FirewallRule$R0 EdgeTraversal
	${If} $0 == true
		${If} $FWDirection != in
			${InvalidValueError} [FirewallRule$R0]:EdgeTraversal "true (inbound rules only)"
			Goto fw_invalid
		${EndIf}
		StrCpy $FWArgs `$FWArgs edge=yes`
	${EndIf}

	${ReadLauncherConfigWithDefault} $0 FirewallRule$R0 Description "Added by ${PORTABLEAPPNAME} while it runs"
	StrCpy $FWArgs `$FWArgs description="$0"`

	${ReadLauncherConfig} $FWRequired FirewallRule$R0 Required
	ClearErrors
	Goto fw_done

	fw_invalid:
	SetErrors
	fw_done:
	Pop $1
	Pop $0
FunctionEnd

${SegmentFile}

${SegmentPrePrimary}
	StrCpy $FWWarned ""
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $0 FirewallRule$R0 Name
		${If} ${Errors}
			ClearErrors
			${ReadLauncherConfig} $0 FirewallRule$R0 BlockAll
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		${EndIf}

		${If} $Admin != true
			; Fail closed: no rule without the rights to remove it again.
			${If} $FWWarned == ""
				StrCpy $FWWarned true
				MessageBox MB_OK|MB_ICONEXCLAMATION|MB_TOPMOST \
					"${PORTABLEAPPNAME} needs administrator rights to add its firewall rules.$\r$\nNo firewall rules were added."
			${EndIf}
			${ExitDo}
		${EndIf}

		${ReadLauncherConfig} $0 FirewallRule$R0 BlockAll
		${If} $0 == true
			${FW_Read} $FWItem BlockAllDir
			ClearErrors
			${ReadLauncherConfig} $FWList FirewallRule$R0 BlockAllRecur
			${If} ${Errors}
				${ReadLauncherConfigWithDefault} $FWList FirewallRule$R0 Recursive true
			${EndIf}
			${ReadLauncherConfig} $FWRequired FirewallRule$R0 Required
			${If} ${FileExists} `$FWItem\*.*`
				Call FW_BlockAll
			${Else}
				${InvalidValueError} [FirewallRule$R0]:BlockAllDir $FWItem
			${EndIf}
		${Else}
			Call FW_ReadRule
			${IfNot} ${Errors}
				Call FW_AddRule
			${EndIf}
		${EndIf}
		IntOp $R0 $R0 + 1
	${Loop}
!macroend

${SegmentPostPrimary}
	${Journal::HasEntries} Firewall $R0
	${If} $R0 > 0
		${Journal::Rollback} Firewall
	${EndIf}
!macroend

!endif ; SEGMENTS_FIREWALL
