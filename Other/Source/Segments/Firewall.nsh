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
;	Direction		-	In, Out
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

;= VARIABLES
Var FWName
Var FWDirection
Var FWAction
Var FWProtocol
Var FWGrouping
Var FWLocalPort
Var FWRemotePort
Var FWLocalAddress
Var FWRemoteAddress
Var FWProgram
Var FWService
Var FWProfile
Var FWInterfaceType
Var FWEnabled
Var FWRequired
Var FWDescription
Var FWEdgeTraversal
Var FWSecurity

;= INCLUDES
!ifndef LOGICLIB
    !include LogicLib.nsh
!endif
!ifndef FILEFUNC_INCLUDED
    !include FileFunc.nsh
!endif
!ifndef STRFUNC_NSH_INCLUDED
    !ifdef StrCase
        !undef StrCase
    !endif
    !include StrFunc.nsh
    ${Using:StrFunc} StrRep
    ${Using:StrFunc} StrLoc
    ${Using:StrFunc} StrTrimNewLines
!endif

;= MACROS
!define Firewall::InvalidKeyMsg `!insertmacro _Firewall::InvalidKeyMsg`
!macro _Firewall::InvalidKeyMsg _MSG
    MessageBox MB_ICONSTOP|MB_TOPMOST "Error: Invalid [Firewall$R0] key:$\r$\n${_MSG}"
    Call Unload
    Quit
!macroend

;= FUNCTIONS
Function IsNumeric
    Exch $R0  ; Input string
    Push $R1
    Push $R2
    
    StrCpy $R1 "true"
    StrLen $R2 $R0
    
    ${If} $R2 == 0
        StrCpy $R1 "false"
        Goto _IS_NUMERIC_END
    ${EndIf}
    
    IntOp $R2 $R0 + 0
    IntFmt $R2 "%d" $R2
    
    ${If} $R2 != $R0
        StrCpy $R1 "false"
    ${EndIf}
    
	_IS_NUMERIC_END:
    Pop $R2
    StrCpy $R0 $R1
    Pop $R1
    Exch $R0
FunctionEnd

${SegmentFile}
${SegmentPre}
	
		${DebugMsg} "Processing Windows Firewall rule(s) Pre begin..."

		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $FWName FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $FWDirection FirewallRule$R0 Direction
			${ReadLauncherConfig} $FWAction FirewallRule$R0 Action
			${ReadLauncherConfig} $FWProtocol FirewallRule$R0 Protocol
			${ReadLauncherConfig} $FWLocalPort FirewallRule$R0 LocalPort

            ; --- Validate direction ---
            ${Switch} "$FWDirection"
                ${Case} "Inbound"
                ${Case} "Outbound"
                ${Case} "in"
                ${Case} "out"
                    ; Valid directions
                    ${Break}
                ${Default}
                    ${Firewall::InvalidKeyMsg} "Direction: $FWDirection"
            ${EndSwitch}

            ; --- Validate action ---
            ${Switch} "$FWAction"
                ${Case} "Allow"
                ${Case} "Block"
                ${Case} "Bypass"
                ${Case} "allow"
                ${Case} "block"
                ${Case} "bypass"
                    ; Valid actions
                    ${Break}
                ${Default}
                    ${Firewall::InvalidKeyMsg} "Direction: $FWAction"
            ${EndSwitch}
			
            ; --- Validate protocol ---
            ${If} "$FWProtocol" != ""
            ${AndIf} "$FWProtocol" != "Any"
                ${Switch} "$FWProtocol"
                    ${Case} "TCP"
                    ${Case} "UDP"
                    ${Case} "ICMPv4"
                    ${Case} "ICMPv6"
                    ${Case} "tcp"
                    ${Case} "udp"
                    ${Case} "icmpv4"
                    ${Case} "icmpv6"
                        ; Valid protocol strings
                        ${Break}
                    ${Default}
                        ; Check if it's a valid protocol number (0-255)
                        Push $FWProtocol
                        Call IsNumeric
                        Pop $1
                        ${If} $1 == "true"
                            IntOp $2 $FWProtocol + 0
                            ${If} $2 >= 0
                            ${AndIf} $2 <= 255
                                ; Valid protocol number
                            ${Else}
                                ${Firewall::InvalidKeyMsg} "Protocol number must be 0-255: $FWProtocol"
                            ${EndIf}
                        ${Else}
                            ${Firewall::InvalidKeyMsg} "Protocol: $FWProtocol"
                        ${EndIf}
                ${EndSwitch}
            ${EndIf}

            ; --- Validate port ---
            ${If} "$FWLocalPort" != ""
            ${AndIf} "$FWLocalPort" != "Any"
                ; Check if it's a port range (contains hyphen)
                ${StrLoc} $1 "$FWLocalPort" "-" ">"
                ${If} $1 != ""
                    ; Port range detected - validate both parts
                    StrCpy $2 "$FWLocalPort" $1          ; Get start port
                    IntOp $1 $1 + 1
                    StrCpy $3 "$FWLocalPort" "" $1       ; Get end port
                    
                    ; Validate start port
                    Push $2
                    Call IsNumeric
                    Pop $1
                    ${If} $1 != "true"
                        ${Firewall::InvalidKeyMsg} "Invalid port range start: $FWLocalPort"
                    ${EndIf}
                    IntOp $2 $2 + 0
                    ${If} $2 < 1
                    ${OrIf} $2 > 65535
                        ${Firewall::InvalidKeyMsg} "Port range start must be 1-65535: $FWLocalPort"
                    ${EndIf}
                    
                    ; Validate end port
                    Push $3
                    Call IsNumeric
                    Pop $1
                    ${If} $1 != "true"
                        ${Firewall::InvalidKeyMsg} "Invalid port range end: $3"
                    ${EndIf}
                    IntOp $3 $3 + 0
                    ${If} $3 < 1
                    ${OrIf} $3 > 65535
                        ${Firewall::InvalidKeyMsg}  "Port range end must be 1-65535: $3"
                    ${EndIf}
                    
                    ; Validate range order
                    ${If} $2 >= $3
                        ${Firewall::InvalidKeyMsg} "Port range start must be less than end: $FWLocalPort"
                    ${EndIf}
                ${Else}
                    ; Single port - validate it's a number in valid range
                    Push $FWLocalPort
                    Call IsNumeric
                    Pop $1
                    ${If} $1 != "true"
                        ${Firewall::InvalidKeyMsg} "Invalid port number: $FWLocalPort"
                    ${EndIf}
                    IntOp $2 $FWLocalPort + 0
                    ${If} $2 < 1
                    ${OrIf} $2 > 65535
                        ${Firewall::InvalidKeyMsg} "Port must be 1-65535: $FWLocalPort"
                    ${EndIf}
                ${EndIf}
            ${EndIf}

			${DebugMsg} "Processing firewall rule: $FWName"
			
            StrCpy $4 "$FWName"
            ${StrRep} $4 $4 '"' '\"'  ; Escape any quotes in rule name
            nsExec::ExecToStack `"$SYSDIR\netsh.exe" advfirewall firewall show rule name="$4 Portable" verbose`
            Pop $2 ; Return code
            Pop $3 ; Output text

            ${DebugMsg} "netsh show return code: $2$\r$\nOutput: $3"

			${If} $2 == "0"
				${DebugMsg} "Firewall rule exists: $FWName Portable"
                
                ; Create backup filename
                StrCpy $4 "$TEMP\FirewallRule$R0_BackupBy${APPNAME}.txt"

                ${DebugMsg} "Backup file path: $4"

                ; Write rule details to backup file
                ClearErrors
                FileOpen $R1 "$4" w
                
                ${IfNot} ${Errors}
                    FileWrite $R1 "$3"
                    FileClose $R1
                    
                    ; Verify file was written successfully
                    ${If} ${FileExists} "$4"
                        ; Store backup metadata
                        ${WriteRuntimeData} Firewall$R0 "BackupFile" "$4"
                        ${WriteRuntimeData} Firewall$R0 "RuleExisted" "true"
                        ${DebugMsg} "Successfully backed up firewall rule: $FWName Portable"
                    ${Else}
                        ${DebugMsg} "Error: Backup file was not created: $4"
                        ${WriteRuntimeData} Firewall$R0 "RuleExisted" "false"
                    ${EndIf}
                    ${WriteRuntimeData} Firewall$R0 "RuleName" "$FWName Portable"
                ${Else}
                    ${DebugMsg} "Failed to open backup file for writing: $4"
                    ${WriteRuntimeData} Firewall$R0 "RuleExisted" "false"
                ${EndIf}
				${WriteRuntimeData} Firewall$R0 "Action" "backup"
			${Else}
				${DebugMsg} "Firewall rule does not exist: $FWName Portable"
				${WriteRuntimeData} Firewall$R0 "Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Processing Windows Firewall rule(s) Pre complete."
!macroend
${SegmentPrePrimary}
	
		${DebugMsg} "Creating portable firewall rule(s) PrePrimary begin..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $FWName FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Get configuration
			${ReadLauncherConfig} $FWDirection FirewallRule$R0 Direction
			${ReadLauncherConfig} $FWAction FirewallRule$R0 Action
			${ReadLauncherConfig} $FWProtocol FirewallRule$R0 Protocol
			${ReadLauncherConfig} $FWLocalPort FirewallRule$R0 LocalPort
			${ReadLauncherConfig} $FWRemotePort FirewallRule$R0 RemotePort
			${ReadLauncherConfig} $FWLocalAddress FirewallRule$R0 LocalAddress
			${ReadLauncherConfig} $FWRemoteAddress FirewallRule$R0 RemoteAddress
			${ReadLauncherConfig} $FWProgram FirewallRule$R0 Program
			${ReadLauncherConfig} $FWService FirewallRule$R0 Service
			${ReadLauncherConfig} $FWProfile FirewallRule$R0 Profile
			${ReadLauncherConfig} $FWInterfaceType FirewallRule$R0 InterfaceType
			${ReadLauncherConfig} $FWEnabled FirewallRule$R0 Enabled
			${ReadLauncherConfig} $FWRequired FirewallRule$R0 Required
			${ReadLauncherConfig} $FWDescription FirewallRule$R0 Description
			${ReadLauncherConfig} $FWEdgeTraversal FirewallRule$R0 EdgeTraversal
			${ReadLauncherConfig} $FWSecurity FirewallRule$R0 Security
			
			; Set defaults
			${If} $FWEnabled == ""
				StrCpy $FWEnabled "true"
			${EndIf}
			${If} $FWDescription == ""
				StrCpy $FWDescription "Firewall rule for ${PORTABLEAPPNAME}"
			${EndIf}
			
			${DebugMsg} "Creating firewall rule: $FWName Portable"
			
			; Check if we should process this rule
			${ReadRuntimeData} $1 Firewall$R0 "RuleExisted"
			
			; Delete existing rule if we're replacing
			${If} $1 == "true"
                ${DebugMsg} "Deleting local firewall rule: $FWName Portable"

                ; Escape quotes in rule name
                StrCpy $4 "$FWName"
                ${StrRep} $4 $4 '"' '\"'
                
                ; Execute delete command
                nsExec::ExecToStack `"$SYSDIR\netsh.exe" advfirewall firewall delete rule name="$4 Portable"`
                Pop $2  ; Return code
                Pop $3  ; Output text

                ${DebugMsg} "netsh delete return code: $2"
                
                ${Switch} $2
                    ${Case} 0
                        ; Command succeeded
                        StrCpy $0 "true"
                        ${DebugMsg} "Firewall rule deleted successfully: $FWName Portable"
                        ${Break}
                        
                    ${Case} 1
                        ; netsh returned error code 1
                        ; Check if rule was not found (which is OK for deletion)
                        ${StrLoc} $5 "$3" "No rules match" "<"
                        ${If} $5 == ""
                            ; "No rules match" not found - real error
                            ${DebugMsg} "Failed to delete firewall rule: $FWName Portable"
                            ${DebugMsg} "Output: $3"
                        ${Else}
                            ; "No rules match" found - rule didn't exist
                            ${DebugMsg} "Firewall rule not found (considering as success): $FWName Portable"
                        ${EndIf}
                        ${Break}
                        
                    ${Default}
                        ; Other error code
                        ${DebugMsg} "Failed to delete firewall rule $FWName Portable$\r$\n Error code: $2"
                        ${DebugMsg} "Output: $3"
                        ${Break}
                ${EndSwitch}
                
			${EndIf}

            ; Build netsh command
            StrCpy $R2 `"$SYSDIR\netsh.exe" advfirewall firewall add rule name="$FWName Portable"`
            StrCpy $R2 `$R2 dir=$FWDirection action=$FWAction`
            
            ; Add protocol
            ${If} "$FWProtocol" != ""
            ${AndIf} "$FWProtocol" != "Any"
                StrCpy $R2 `$R2 protocol=$FWProtocol`
            ${EndIf}
            
            ; Add local port
            ${If} "$FWLocalPort" != ""
            ${AndIf} "$FWLocalPort" != "Any"
                StrCpy $R2 `$R2 localport=$FWLocalPort`
            ${EndIf}
            
            ; Add remote port
            ${If} "$FWRemotePort" != ""
            ${AndIf} "$FWRemotePort" != "Any"
                StrCpy $R2 `$R2 remoteport=$FWRemotePort`
            ${EndIf}
            
            ; Add local address
            ${If} "$FWLocalAddress" != ""
            ${AndIf} "$FWLocalAddress" != "Any"
                StrCpy $R2 `$R2 localip=$FWLocalAddress`
            ${EndIf}
            
            ; Add remote address
            ${If} "$FWRemoteAddress" != ""
            ${AndIf} "$FWRemoteAddress" != "Any"
                StrCpy $R2 `$R2 remoteip=$FWRemoteAddress`
            ${EndIf}
            
            ; Add program path
            ${If} "$FWProgram" != ""
                ExpandEnvStrings $6 "$FWProgram"
                ${If} ${FileExists} "$6"
                    StrCpy $R2 `$R2 program="$6"`
                ${Else}
                    ${Firewall::InvalidKeyMsg} "Program not found: $FWProgram"
                ${EndIf}
            ${EndIf}
            
            ; Add service
            ${If} "$FWService" != ""
                StrCpy $R2 `$R2 service=$FWService`
            ${EndIf}
            
            ; Add profile
            ${If} "$FWProfile" != ""
            ${AndIf} "$FWProfile" != "Any"
                StrCpy $R2 `$R2 profile=$FWProfile`
            ${EndIf}
            
            ; Add enabled state
            ${If} "$FWEnabled" == "false"
                StrCpy $R2 `$R2 enable=no`
            ${Else}
                StrCpy $R2 `$R2 enable=yes`
            ${EndIf}
            
            ; Add description
            ${If} "$FWDescription" != ""
                StrCpy $R2 `$R2 description="$FWDescription"`
            ${EndIf}
            
            ${DebugMsg} "Executing: $R2"
            
            ; Execute the command
            nsExec::ExecToStack `$R2`
            Pop $1 ; Return code
            Pop $2 ; Output

            ${DebugMsg} "netsh return code: $1"
            
			${If} $1 == "0"
				${WriteRuntimeData} Firewall$R0 "Created" "true"
				${DebugMsg} "Firewall rule created successfully: $FWName Portable"
			${Else}
				${WriteRuntimeData} Firewall$R0 "Created" "false"
				${DebugMsg} "Failed to create firewall rule $FWName Portable$\r$\nError: $2"
				${If} $FWRequired == "true"
					${Firewall::InvalidKeyMsg} "Error: Failed to create required firewall rule '$FWName Portable'$\n$\nError: $2"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
        ${DebugMsg} "Creating portable firewall rule(s) PrePrimary complete."
!macroend
${SegmentPostPrimary}
	
		${DebugMsg} "Removing portable firewall rule(s) PostPrimary begin..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $FWName FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we created this rule
			${ReadRuntimeData} $1 Firewall$R0 "Created"
			${IfNot} ${Errors}
                ; Execute delete command
                nsExec::ExecToStack `"$SYSDIR\netsh.exe" advfirewall firewall delete rule name="$FWName Portable"`
                Pop $2  ; Return code
                Pop $3  ; Output text

				${If} $2 == "0"
					${DebugMsg} "Portable firewall rule removed successfully: $FWName Portable"
				${Else}
					${DebugMsg} "Failed to remove portable firewall rule $FWName Portable$r$\nError: $3"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Removing portable firewall rule(s) PostPrimary complete."
!macroend
${SegmentPost}
	
		${DebugMsg} "Restoring original Windows Firewall rule(s) Post begin..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $FWName FirewallRule$R0 Name
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we need to restore this rule
			${ReadRuntimeData} $1 Firewall$R0 "Action"
			${If} $1 == "backup"
            
                ; Check if we have backup metadata
                ClearErrors
                ${ReadRuntimeData} $0 FirewallRule$R0 "RuleExisted"
                ${If} ${Errors}
                    ${DebugMsg} "No backup metadata found for firewall rule"
                    Goto _FIREWALL_RESTORE_END
                ${EndIf}
                
                ${DebugMsg} "Backup metadata found. Rule existed: $FWName Portable"
                
                ${If} $0 == "true"
                    ; Rule existed before - need to restore it
                    ${DebugMsg} "Attempting restoration of rule: $FWName Portable"
                    
                    ClearErrors
                    ${ReadRuntimeData} $2 FirewallRule$R0 "BackupFile"
                    ${If} ${Errors}
                        ${DebugMsg} "Error: Cannot read backup file path: $2"
                        Goto _FIREWALL_RESTORE_END
                    ${EndIf}
                    
                    ${DebugMsg} "Backup file: $2"
                    
                    ; Verify backup file exists
                    ${IfNot} ${FileExists} "$2"
                        ${DebugMsg} "Error: Backup file not found: $2"
                        Goto _FIREWALL_RESTORE_END
                    ${EndIf}
                    
                    ; Parse backup file and recreate rule
                    ClearErrors
                    FileOpen $3 "$2" r
                    ${If} ${Errors}
                        ${DebugMsg} "Error: Cannot open backup file"
                        Goto _FIREWALL_RESTORE_END
                    ${EndIf}
                    
                    ; Parse the backup file line by line
                    ${Do}
                        ClearErrors
                        FileRead $3 $4
                        ${If} ${Errors}
                            ${Break}
                        ${EndIf}
                        
                        ; Trim line
                        ${StrTrimNewLines} $4 $4
                        
                        ; Parse key-value pairs from netsh output
                        ; Format: "Direction:              In"
                        ${StrLoc} $5 "$4" ":" ">"
                        ${If} $5 != ""
                            IntOp $6 $5 + 1
                            StrCpy $5 "$4" $5          ; Key
                            StrCpy $6 "$4" "" $6       ; Value
                            
                            ; Trim whitespace
                            ${TRIM} $5 $5
                            ${TRIM} $6 $6
                            
                            ; Map netsh output to parameters
                            ${Switch} "$5"
                                ${Case} "Direction"
                                    StrCpy $FWDirection "$6"
                                    ${Break}
                                ${Case} "Action"
                                    StrCpy $FWAction "$6"
                                    ${Break}
                                ${Case} "Protocol"
                                    StrCpy $FWProtocol "$6"
                                    ${Break}
                                ${Case} "Grouping"
                                    StrCpy $FWGrouping "$6"
                                    ${Break}
                                ${Case} "LocalPort"
                                    StrCpy $FWLocalPort "$6"
                                    ${Break}
                                ${Case} "RemotePort"
                                    StrCpy $FWRemotePort "$6"
                                    ${Break}
                                ${Case} "LocalIP"
                                    StrCpy $FWLocalAddress "$6"
                                    ${Break}
                                ${Case} "RemoteIP"
                                    StrCpy $FWRemoteAddress "$6"
                                    ${Break}
                                ${Case} "Program"
                                    StrCpy $FWProgram "$6"
                                    ${Break}
                                ${Case} "Service"
                                    StrCpy $FWService "$6"
                                    ${Break}
                                ${Case} "Profiles"
                                    StrCpy $FWProfile "$6"
                                    ${Break}
                                ${Case} "Enabled"
                                    StrCpy $FWEnabled "$6"
                                    ${Break}
                                ${Case} "Description"
                                    StrCpy $FWDescription "$6"
                                    ${Break}
                                ${Case} "Security"
                                    StrCpy $FWSecurity "$6"
                                    ${Break}
                                ${Case} "InterfaceTypes"
                                    StrCpy $FWInterfaceType "$6"
                                    ${Break}
                                ${Case} "Edge traversal"
                                    StrCpy $FWEdgeTraversal "$6"
                                    ${Break}
                                ; Add more cases as needed for complete restoration
                            ${EndSwitch}
                        ${EndIf}
                    ${Loop}
                    
                    FileClose $2
                    
                    ; Recreate the rule with parsed parameters
                    ; Note: This is simplified - full implementation would need to parse all parameters
                    ${If} "$FWDirection" != ""
                    ${AndIf} "$FWAction" != ""
                        ${DebugMsg} "Recreating rule: $FWName Portable (--dir $FWDirection, --action $FWAction)"
                        
                        ; Build netsh command
                        StrCpy $R2 `"$SYSDIR\netsh.exe" advfirewall firewall add rule name="$FWName Portable"`
                        StrCpy $R2 `$R2 dir=$FWDirection action=$FWAction`
                        
                        ; Add protocol
                        ${If} "$FWProtocol" != ""
                        ${AndIf} "$FWProtocol" != "Any"
                            StrCpy $R2 `$R2 protocol=$FWProtocol`
                        ${EndIf}
                        
                        ; Add local port
                        ${If} "$FWLocalPort" != ""
                        ${AndIf} "$FWLocalPort" != "Any"
                            StrCpy $R2 `$R2 localport=$FWLocalPort`
                        ${EndIf}
                        
                        ; Add remote port
                        ${If} "$FWRemotePort" != ""
                        ${AndIf} "$FWRemotePort" != "Any"
                            StrCpy $R2 `$R2 remoteport=$FWRemotePort`
                        ${EndIf}
                        
                        ; Add local address
                        ${If} "$FWLocalAddress" != ""
                        ${AndIf} "$FWLocalAddress" != "Any"
                            StrCpy $R2 `$R2 localip=$FWLocalAddress`
                        ${EndIf}
                        
                        ; Add remote address
                        ${If} "$FWRemoteAddress" != ""
                        ${AndIf} "$FWRemoteAddress" != "Any"
                            StrCpy $R2 `$R2 remoteip=$FWRemoteAddress`
                        ${EndIf}
                        
                        ; Add program path
                        ${If} "$FWProgram" != ""
                            StrCpy $R2 `$R2 program="$FWProgram"`
   
                        ${EndIf}
                        
                        ; Add service
                        ${If} "$FWService" != ""
                            StrCpy $R2 `$R2 service=$FWService`
                        ${EndIf}
                        
                        ; Add profile
                        ${If} "$FWProfile" != ""
                        ${AndIf} "$FWProfile" != "Any"
                            StrCpy $R2 `$R2 profile=$FWProfile`
                        ${EndIf}
                        
                        ; Add enabled state
                        ${If} "$FWEnabled" == "false"
                            StrCpy $R2 `$R2 enable=no`
                        ${Else}
                            StrCpy $R2 `$R2 enable=yes`
                        ${EndIf}
                        
                        ; Add description
                        ${If} "$FWDescription" != ""
                            StrCpy $R2 `$R2 description="$FWDescription"`
                        ${EndIf}
                        
                        ${DebugMsg} "Executing: $R2"
                        
                        ; Execute the command
                        nsExec::ExecToStack `$R2`
                        Pop $8 ; Return code
                        Pop $9 ; Output

                        ${DebugMsg} "netsh return code: $1"
                        
                        
                        ${If} $8 == "0"
                            ${DebugMsg} "Rule recreated successfully"
                        ${Else}
                            ${DebugMsg} "Failed to recreate rule: $9"
                        ${EndIf}
                    ${Else}
                        ${DebugMsg} "Error: Could not parse required parameters from backup file"
                    ${EndIf}
                    
                    ; Clean up backup file regardless of restoration result
                    ClearErrors
                    ${ReadRuntimeData} $2 FirewallRule$R0 "BackupFile"
                    ${IfNot} ${Errors}
                        ${If} ${FileExists} "$2"
                            Delete "$2"
                            ${DebugMsg} "Deleted backup file: $2"
                        ${EndIf}
                    ${EndIf}
                    
                ${EndIf}
                _FIREWALL_RESTORE_END:
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Restoring Windows Firewall rule(s) Post complete."
!macroend
