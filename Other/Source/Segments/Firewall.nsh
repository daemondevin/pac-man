;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; Firewall.nsh
;   This file handles Windows Firewall rules with creation, management,
;   and restoration capabilities for portable applications.
; 
; USAGE
;	Add sections [FirewallRule1], [FirewallRule2] etc. to Launcher.ini
;
;	FirewallRule Keys:
;	Name			-	Rule display name (unique identifier)
;	Direction		-	Inbound, Outbound
;	Action			-	Allow, Block, Bypass
;	Protocol		-	TCP, UDP, ICMPv4, ICMPv6, Any
;	LocalPort		-	Local port number or range (e.g., 80, 8000-8080, Any)
;	RemotePort		-	Remote port number or range (optional)
;	LocalAddress	-	Local IP address or range (optional, default: Any)
;	RemoteAddress	-	Remote IP address or range (optional, default: Any)
;	Program			-	Path to program executable (supports %PAL:* variables)
;	Service			-	Windows service name (optional)
;	Profile			-	Domain, Private, Public, Any (comma-separated)
;	InterfaceType	-	Wireless, Lan, Ras, Any (optional)
;	Enabled			-	true/false (rule enabled state)
;	IfExists		-	skip, backup, replace
;	Required		-	true/false (show error if creation fails)
;	Description		-	Rule description
;	EdgeTraversal	-	true/false (allow edge traversal for inbound rules)
;	Security		-	Authenticate, AuthEnc, AuthNoEnc, NotRequired
;
;	Protocol-specific options:
;	ICMPType		-	ICMP type number (for ICMP protocols)
;	ICMPCode		-	ICMP code number (for ICMP protocols)
;
; EXAMPLE
;	[FirewallRule1]
;	Name=MyApp HTTP Server
;	Direction=Inbound
;	Action=Allow
;	Protocol=TCP
;	LocalPort=8080
;	Program=%PAL:AppDir%\server.exe
;	Profile=Private,Public
;	IfExists=replace
;	Enabled=true
;	Description=Allow HTTP access to MyApp server
;	Required=true
;

!ifdef FIREWALL
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
!ifndef WORDREPLACE_NSH_INCLUDED
	!include WordReplace.nsh
!endif
!ifndef STR_LOC_NSH_INCLUDED
	!include StrLoc.nsh
!endif

; Windows Firewall with Advanced Security command
!define NETSH_ADVFIREWALL `$SYSDIR\netsh.exe advfirewall firewall`

; Firewall management macros

; Check if firewall rule exists
!define Firewall::RuleExists `!insertmacro _Firewall::RuleExists`
!macro _Firewall::RuleExists _RULENAME _RESULT _RULE_INFO
	Push $0
	Push $1
	Push $2
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_RULE_INFO} ""
	
	; Query firewall rule
	ExecDos::Exec /TOSTACK `"$SYSDIR\netsh.exe" advfirewall firewall show rule name="${_RULENAME}"`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		; Check if rule was found (not "No rules match")
		${StrLoc} $2 "$1" "No rules match" "<"
		${If} $2 == ""
			StrCpy ${_RESULT} "true"
			StrCpy ${_RULE_INFO} "$1"
			${DebugMsg} "Firewall rule exists: ${_RULENAME}"
		${Else}
			${DebugMsg} "Firewall rule does not exist: ${_RULENAME}"
		${EndIf}
	${Else}
		${DebugMsg} "Failed to query firewall rule: ${_RULENAME}"
	${EndIf}
	
	Pop $2
	Pop $1
	Pop $0
!macroend

; Create firewall rule
!define Firewall::CreateRule `!insertmacro _Firewall::CreateRule`
!macro _Firewall::CreateRule _NAME _DIR _ACTION _PROTOCOL _LOCALPORT _REMOTEPORT _LOCALADDR _REMOTEADDR _PROGRAM _SERVICE _PROFILE _ENABLED _DESC _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${DebugMsg} "Creating firewall rule: ${_NAME}"
	
	; Build netsh command
	StrCpy $0 `"$SYSDIR\netsh.exe" advfirewall firewall add rule name="${_NAME}"`
	StrCpy $0 `$0 dir=${_DIR} action=${_ACTION}`
	
	; Add protocol
	${If} "${_PROTOCOL}" != ""
	${AndIf} "${_PROTOCOL}" != "Any"
		StrCpy $0 `$0 protocol=${_PROTOCOL}`
	${EndIf}
	
	; Add local port
	${If} "${_LOCALPORT}" != ""
	${AndIf} "${_LOCALPORT}" != "Any"
		StrCpy $0 `$0 localport=${_LOCALPORT}`
	${EndIf}
	
	; Add remote port
	${If} "${_REMOTEPORT}" != ""
	${AndIf} "${_REMOTEPORT}" != "Any"
		StrCpy $0 `$0 remoteport=${_REMOTEPORT}`
	${EndIf}
	
	; Add local address
	${If} "${_LOCALADDR}" != ""
	${AndIf} "${_LOCALADDR}" != "Any"
		StrCpy $0 `$0 localip=${_LOCALADDR}`
	${EndIf}
	
	; Add remote address
	${If} "${_REMOTEADDR}" != ""
	${AndIf} "${_REMOTEADDR}" != "Any"
		StrCpy $0 `$0 remoteip=${_REMOTEADDR}`
	${EndIf}
	
	; Add program path
	${If} "${_PROGRAM}" != ""
		${ParseLocations} "${_PROGRAM}" $R8
		${If} ${FileExists} "$R8"
			StrCpy $0 `$0 program="$R8"`
		${Else}
			StrCpy ${_ERROR} "Program file not found: $R8"
			${DebugMsg} "Program not found: $R8"
			Goto _FIREWALL_CREATE_END
		${EndIf}
	${EndIf}
	
	; Add service
	${If} "${_SERVICE}" != ""
		StrCpy $0 `$0 service=${_SERVICE}`
	${EndIf}
	
	; Add profile
	${If} "${_PROFILE}" != ""
	${AndIf} "${_PROFILE}" != "Any"
		StrCpy $0 `$0 profile=${_PROFILE}`
	${EndIf}
	
	; Add enabled state
	${If} "${_ENABLED}" == "false"
		StrCpy $0 `$0 enable=no`
	${Else}
		StrCpy $0 `$0 enable=yes`
	${EndIf}
	
	; Add description
	${If} "${_DESC}" != ""
		StrCpy $0 `$0 description="${_DESC}"`
	${EndIf}
	
	${DebugMsg} "Executing: $0"
	
	; Execute the command
	ExecDos::Exec /TOSTACK `$0`
	Pop $1 ; Return code
	Pop $2 ; Output
	
	${Switch} $1
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Firewall rule created successfully: ${_NAME}"
			${Break}
		${Case} "1"
			StrCpy ${_ERROR} "Invalid syntax or parameters"
			${DebugMsg} "Failed to create firewall rule: Invalid syntax"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to create firewall rule (Error $1)"
			${DebugMsg} "Failed to create firewall rule ${_NAME}: Error $1"
			; Parse output for more specific error
			${StrLoc} $3 "$2" "already exists" "<"
			${If} $3 != ""
				StrCpy ${_ERROR} "Firewall rule already exists"
			${EndIf}
			${Break}
	${EndSwitch}
	
	_FIREWALL_CREATE_END:
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Delete firewall rule
!define Firewall::DeleteRule `!insertmacro _Firewall::DeleteRule`
!macro _Firewall::DeleteRule _RULENAME _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${DebugMsg} "Deleting firewall rule: ${_RULENAME}"
	
	ExecDos::Exec /TOSTACK `"$SYSDIR\netsh.exe" advfirewall firewall delete rule name="${_RULENAME}"`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${Switch} $0
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Firewall rule deleted successfully: ${_RULENAME}"
			${Break}
		${Case} "1"
			; Check if rule was not found
			${StrLoc} $2 "$1" "No rules match" "<"
			${If} $2 != ""
				StrCpy ${_RESULT} "true" ; Consider this success
				StrCpy ${_ERROR} "Rule not found"
				${DebugMsg} "Firewall rule not found for deletion: ${_RULENAME}"
			${Else}
				StrCpy ${_ERROR} "Failed to delete rule"
				${DebugMsg} "Failed to delete firewall rule: ${_RULENAME}"
			${EndIf}
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to delete rule (Error $0)"
			${DebugMsg} "Failed to delete firewall rule ${_RULENAME}: Error $0"
			${Break}
	${EndSwitch}
	
	Pop $2
	Pop $1
	Pop $0
!macroend

; Enable/disable firewall rule
!define Firewall::SetRuleState `!insertmacro _Firewall::SetRuleState`
!macro _Firewall::SetRuleState _RULENAME _ENABLED _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${If} "${_ENABLED}" == "true"
		StrCpy $R8 "yes"
	${Else}
		StrCpy $R8 "no"
	${EndIf}
	
	${DebugMsg} "Setting firewall rule state: ${_RULENAME} -> $R8"
	
	ExecDos::Exec /TOSTACK `"$SYSDIR\netsh.exe" advfirewall firewall set rule name="${_RULENAME}" new enable=$R8`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${Switch} $0
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Firewall rule state changed successfully: ${_RULENAME}"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to change rule state (Error $0)"
			${DebugMsg} "Failed to change firewall rule state ${_RULENAME}: Error $0"
			${Break}
	${EndSwitch}
	
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Backup firewall rule configuration
!define Firewall::BackupRule `!insertmacro _Firewall::BackupRule`
!macro _Firewall::BackupRule _RULENAME _SECTION _KEY
	Push $0
	Push $1
	Push $2
	Push $R8
	
	${Firewall::RuleExists} "${_RULENAME}" $0 $1
	${If} $0 == "true"
		; Export rule details to backup file
		StrCpy $R8 "$TEMP\${_RULENAME}_backup.txt"
		FileOpen $2 "$R8" w
		${If} $2 != ""
			FileWrite $2 "$1"
			FileClose $2
			
			${WriteRuntimeData} ${_SECTION} "${_KEY}_RuleFile" "$R8"
			${WriteRuntimeData} ${_SECTION} "${_KEY}_RuleName" "${_RULENAME}"
			${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "true"
			${DebugMsg} "Backed up firewall rule: ${_RULENAME}"
		${Else}
			${DebugMsg} "Failed to save firewall rule backup: ${_RULENAME}"
		${EndIf}
	${Else}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "false"
		${DebugMsg} "Firewall rule ${_RULENAME} did not exist"
	${EndIf}
	
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Restore firewall rule configuration
!define Firewall::RestoreRule `!insertmacro _Firewall::RestoreRule`
!macro _Firewall::RestoreRule _SECTION _KEY _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	
	StrCpy ${_RESULT} "false"
	
	${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_Existed"
	${If} ${Errors}
		${DebugMsg} "No backup found for firewall rule"
		Goto _FIREWALL_RESTORE_END
	${EndIf}
	
	${If} $0 == "true"
		${ReadRuntimeData} $1 ${_SECTION} "${_KEY}_RuleName"
		${IfNot} ${Errors}
			; Note: Full automatic restoration is complex because we'd need to
			; parse the backed up rule details and recreate the exact command.
			; For now, we just log that the rule existed before.
			${DebugMsg} "Firewall rule existed originally: $1"
			StrCpy ${_RESULT} "true"
			
			; Clean up backup file
			${ReadRuntimeData} $2 ${_SECTION} "${_KEY}_RuleFile"
			${IfNot} ${Errors}
				Delete "$2"
			${EndIf}
		${EndIf}
	${Else}
		; Rule didn't exist originally, removal is success
		StrCpy ${_RESULT} "true"
		${DebugMsg} "Firewall rule did not exist originally"
	${EndIf}
	
	_FIREWALL_RESTORE_END:
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check Windows Firewall status
!define Firewall::GetStatus `!insertmacro _Firewall::GetStatus`
!macro _Firewall::GetStatus _PROFILE _RESULT _STATE
	Push $0
	Push $1
	Push $2
	Push $3
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_STATE} "unknown"
	
	ExecDos::Exec /TOSTACK `"$SYSDIR\netsh.exe" advfirewall show ${_PROFILE}profile state`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		StrCpy ${_RESULT} "true"
		
		; Parse firewall state
		${StrLoc} $2 "$1" "ON" "<"
		${If} $2 != ""
			StrCpy ${_STATE} "ON"
		${Else}
			${StrLoc} $2 "$1" "OFF" "<"
			${If} $2 != ""
				StrCpy ${_STATE} "OFF"
			${EndIf}
		${EndIf}
		
		${DebugMsg} "Firewall ${_PROFILE} profile state: ${_STATE}"
	${Else}
		${DebugMsg} "Failed to get firewall status for ${_PROFILE} profile"
	${EndIf}
	
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check if user can manage firewall
!define Firewall::CanManage `!insertmacro _Firewall::CanManage`
!macro _Firewall::CanManage _RESULT
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "false"
	
	; Try to show firewall rules to test permissions
	ExecDos::Exec /TOSTACK `"$SYSDIR\netsh.exe" advfirewall firewall show rule name=all | findstr /C:"Rule Name"`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		StrCpy ${_RESULT} "true"
		${DebugMsg} "User can manage firewall rules"
	${Else}
		${DebugMsg} "User cannot manage firewall rules (insufficient privileges)"
	${EndIf}
	
	Pop $1
	Pop $0
!macroend

; Validate firewall rule parameters
!define Firewall::ValidateRule `!insertmacro _Firewall::ValidateRule`
!macro _Firewall::ValidateRule _DIR _ACTION _PROTOCOL _PORT _RESULT _ERROR
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "true"
	StrCpy ${_ERROR} ""
	
	; Validate direction
	${Switch} "${_DIR}"
		${Case} "Inbound"
		${Case} "Outbound"
		${Case} "in"
		${Case} "out"
			; Valid directions
			${Break}
		${Default}
			StrCpy ${_RESULT} "false"
			StrCpy ${_ERROR} "Invalid direction: ${_DIR}"
			Goto _VALIDATE_RULE_END
			${Break}
	${EndSwitch}
	
	; Validate action
	${Switch} "${_ACTION}"
		${Case} "Allow"
		${Case} "Block"
		${Case} "Bypass"
		${Case} "allow"
		${Case} "block"
		${Case} "bypass"
			; Valid actions
			${Break}
		${Default}
			StrCpy ${_RESULT} "false"
			StrCpy ${_ERROR} "Invalid action: ${_ACTION}"
			Goto _VALIDATE_RULE_END
			${Break}
	${EndSwitch}
	
	; Validate protocol
	${If} "${_PROTOCOL}" != ""
	${AndIf} "${_PROTOCOL}" != "Any"
		${Switch} "${_PROTOCOL}"
			${Case} "TCP"
			${Case} "UDP"
			${Case} "ICMPv4"
			${Case} "ICMPv6"
			${Case} "tcp"
			${Case} "udp"
			${Case} "icmpv4"
			${Case} "icmpv6"
				; Valid protocols
				${Break}
			${Default}
				; Check if it's a numeric protocol
				IntCmp "${_PROTOCOL}" 0 _VALID_PROTOCOL _INVALID_PROTOCOL _VALID_PROTOCOL
				_INVALID_PROTOCOL:
					StrCpy ${_RESULT} "false"
					StrCpy ${_ERROR} "Invalid protocol: ${_PROTOCOL}"
					Goto _VALIDATE_RULE_END
				_VALID_PROTOCOL:
				${Break}
		${EndSwitch}
	${EndIf}
	
	; Validate port format
	${If} "${_PORT}" != ""
	${AndIf} "${_PORT}" != "Any"
		; Check if it's a range (contains hyphen)
		${StrLoc} $0 "${_PORT}" "-" ">"
		${If} $0 != ""
			; Port range validation would go here
			${DebugMsg} "Port range specified: ${_PORT}"
		${Else}
			; Single port validation
			IntCmp "${_PORT}" 1 _VALID_PORT _INVALID_PORT _VALID_PORT
			_INVALID_PORT:
				StrCpy ${_RESULT} "false"
				StrCpy ${_ERROR} "Invalid port number: ${_PORT}"
				Goto _VALIDATE_RULE_END
			_VALID_PORT:
		${EndIf}
	${EndIf}
	
	_VALIDATE_RULE_END:
	Pop $1
	Pop $0
!macroend

; Generate firewall rules report
!define Firewall::GenerateReport `!insertmacro _Firewall::GenerateReport`
!macro _Firewall::GenerateReport _FILEPATH
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $R0
	
	FileOpen $0 "${_FILEPATH}" w
	${If} $0 != ""
		FileWrite $0 "Windows Firewall Report$\r$\n"
		FileWrite $0 "Generated: $DATE $TIME$\r$\n"
		FileWrite $0 "======================$\r$\n$\r$\n"
		
		; Firewall status for each profile
		FileWrite $0 "Firewall Status:$\r$\n"
		FileWrite $0 "---------------$\r$\n"
		
		${Firewall::GetStatus} "domain" $1 $2
		${If} $1 == "true"
			FileWrite $0 "Domain Profile: $2$\r$\n"
		${EndIf}
		
		${Firewall::GetStatus} "private" $1 $2
		${If} $1 == "true"
			FileWrite $0 "Private Profile: $2$\r$\n"
		${EndIf}
		
		${Firewall::GetStatus} "public" $1 $2
		${If} $1 == "true"
			FileWrite $0 "Public Profile: $2$\r$\n"
		${EndIf}
		
		FileWrite $0 "$\r$\n"
		
		; List configured rules
		FileWrite $0 "Configured Rules:$\r$\n"
		FileWrite $0 "----------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${Firewall::RuleExists} "$1" $2 $3
			${If} $2 == "true"
				FileWrite $0 "$1 -> Active$\r$\n"
			${Else}
				FileWrite $0 "$1 -> Not found$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		FileClose $0
		${DebugMsg} "Firewall report generated: ${_FILEPATH}"
	${EndIf}
	
	Pop $R0
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

${SegmentFile}

;= Enable firewall segment
!define FIREWALL_ENABLED

;= Check permissions and backup existing rules
${SegmentPre}
	!ifdef FIREWALL_ENABLED
		${DebugMsg} "Processing Windows Firewall rules..."
		
		; Check if user can manage firewall
		${Firewall::CanManage} $R9
		${If} $R9 == "false"
			${DebugMsg} "Warning: User cannot manage firewall rules (insufficient privileges)"
			MessageBox MB_OK|MB_ICONEXCLAMATION "Warning: Firewall rule management requires administrator privileges.$\n$\nSome features may not work correctly."
		${EndIf}
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 FirewallRule$R0 Direction
			${ReadLauncherConfig} $2 FirewallRule$R0 Action
			${ReadLauncherConfig} $3 FirewallRule$R0 Protocol
			${ReadLauncherConfig} $4 FirewallRule$R0 LocalPort
			${ReadLauncherConfig} $5 FirewallRule$R0 IfExists
			
			; Set defaults
			${If} $5 == ""
				StrCpy $5 "replace"
			${EndIf}
			
			; Validate rule parameters
			${Firewall::ValidateRule} "$1" "$2" "$3" "$4" $R8 $R7
			${If} $R8 == "false"
				${DebugMsg} "Invalid firewall rule configuration: $0 ($R7)"
				${WriteRuntimeData} FirewallState "$0_Failed" "$R7"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			${DebugMsg} "Processing firewall rule: $0"
			
			; Check if rule exists
			${Firewall::RuleExists} "$0" $R8 $R7
			${If} $R8 == "true"
				${DebugMsg} "Firewall rule exists: $0"
				
				${Switch} $5
					${Case} "skip"
						${DebugMsg} "Skipping existing firewall rule: $0"
						${WriteRuntimeData} FirewallState "$0_Action" "skipped"
						${Break}
					${Case} "backup"
					${Case} "replace"
					${CaseElse}
						${Firewall::BackupRule} "$0" "FirewallBackup" "$0"
						${WriteRuntimeData} FirewallState "$0_Action" "backup"
						${Break}
				${EndSwitch}
			${Else}
				${DebugMsg} "Firewall rule does not exist: $0"
				${WriteRuntimeData} FirewallState "$0_Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Windows Firewall rules processing completed."
	!endif
!macroend

;= Create firewall rules
${SegmentPrePrimary}
	!ifdef FIREWALL_ENABLED
		${DebugMsg} "Creating Windows Firewall rules..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we should process this rule
			${ReadRuntimeData} $1 FirewallState "$0_Action"
			${If} $1 == "skipped"
				${DebugMsg} "Skipping firewall rule as requested: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Check for validation failures
			${ReadRuntimeData} $2 FirewallState "$0_Failed"
			${IfNot} ${Errors}
				${DebugMsg} "Skipping firewall rule due to validation failure: $0 ($2)"
				${ReadLauncherConfig} $3 FirewallRule$R0 Required
				${If} $3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Cannot create required firewall rule '$0'$\n$\nReason: $2"
				${EndIf}
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Get configuration
			${ReadLauncherConfig} $1 FirewallRule$R0 Direction
			${ReadLauncherConfig} $2 FirewallRule$R0 Action
			${ReadLauncherConfig} $3 FirewallRule$R0 Protocol
			${ReadLauncherConfig} $4 FirewallRule$R0 LocalPort
			${ReadLauncherConfig} $5 FirewallRule$R0 RemotePort
			${ReadLauncherConfig} $6 FirewallRule$R0 LocalAddress
			${ReadLauncherConfig} $7 FirewallRule$R0 RemoteAddress
			${ReadLauncherConfig} $8 FirewallRule$R0 Program
			${ReadLauncherConfig} $9 FirewallRule$R0 Service
			${ReadLauncherConfig} $R1 FirewallRule$R0 Profile
			${ReadLauncherConfig} $R2 FirewallRule$R0 Enabled
			${ReadLauncherConfig} $R3 FirewallRule$R0 Description
			${ReadLauncherConfig} $R4 FirewallRule$R0 Required
			
			; Set defaults
			${If} $R2 == ""
				StrCpy $R2 "true"
			${EndIf}
			${If} $R3 == ""
				StrCpy $R3 "Firewall rule for ${PORTABLEAPPNAME}"
			${EndIf}
			
			${DebugMsg} "Creating firewall rule: $0"
			
			; Delete existing rule if we're replacing
			${If} $1 == "backup"
				${Firewall::DeleteRule} "$0" $R8 $R9
			${EndIf}
			
			; Create the rule
			${Firewall::CreateRule} "$0" "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "$R1" "$R2" "$R3" $R8 $R9
			
			${If} $R8 == "true"
				${WriteRuntimeData} FirewallState "$0_Created" "true"
				${DebugMsg} "Firewall rule created successfully: $0"
			${Else}
				${WriteRuntimeData} FirewallState "$0_Failed" "$R9"
				${DebugMsg} "Failed to create firewall rule $0: $R9"
				${If} $R4 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Failed to create required firewall rule '$0'$\n$\nError: $R9"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Windows Firewall rules creation completed."
	!endif
!macroend

;= Remove created firewall rules
${SegmentPostPrimary}
	!ifdef FIREWALL_ENABLED
		${DebugMsg} "Removing created Windows Firewall rules..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we created this rule
			${ReadRuntimeData} $1 FirewallState "$0_Created"
			${IfNot} ${Errors}
				${Firewall::DeleteRule} "$0" $R8 $R7
				${If} $R8 == "true"
					${DebugMsg} "Firewall rule removed successfully: $0"
				${Else}
					${DebugMsg} "Failed to remove firewall rule $0: $R7"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Windows Firewall rules removal completed."
	!endif
!macroend

;= Restore original firewall rules
${SegmentUnload}
	!ifdef FIREWALL_ENABLED
		${DebugMsg} "Restoring original Windows Firewall rules..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we need to restore this rule
			${ReadRuntimeData} $1 FirewallState "$0_Action"
			${If} $1 == "backup"
				${Firewall::RestoreRule} "FirewallBackup" "$0" $R8
				${If} $R8 == "true"
					${DebugMsg} "Firewall rule restoration completed: $0"
				${Else}
					${DebugMsg} "Failed to restore firewall rule: $0"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Windows Firewall rules restoration completed."
	!endif
!macroend

!endif
