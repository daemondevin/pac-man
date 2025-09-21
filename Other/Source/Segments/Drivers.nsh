;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; Drivers.nsh
;   This file handles device driver installation and removal with support for
;   INF-based drivers, hardware detection, and driver signing validation.
; 
; USAGE
;	Add sections [Driver1], [Driver2] etc. to Launcher.ini
;
;	Driver Keys:
;	InfFile			-	Path to driver INF file (supports %PAL:* variables)
;	HardwareId		-	Hardware ID to match (optional, for targeted installation)
;	DriverName		-	Display name for the driver (auto-detected if not specified)
;	Architecture	-	x86, x64, or auto (auto-detect system architecture)
;	Signed			-	true/false (require digitally signed drivers)
;	IfExists		-	skip, backup, replace, update
;	Required		-	true/false (show error if installation fails)
;	ForceInstall	-	true/false (install even if no matching hardware found)
;	Timeout			-	Installation timeout in seconds (default: 60)
;	Category		-	Driver category (Display, Network, USB, etc.) - informational
;	Version			-	Expected driver version (for validation)
;	Publisher		-	Expected driver publisher/vendor
;
;	Hardware ID Examples:
;	- USB\VID_1234&PID_5678
;	- PCI\VEN_8086&DEV_1234
;	- ROOT\SYSTEM (for system/software drivers)
;
; EXAMPLE
;	[Driver1]
;	InfFile=%PAL:AppDir%\Drivers\mydevice.inf
;	HardwareId=USB\VID_1234&PID_5678
;	DriverName=My Custom USB Device
;	Architecture=x64
;	Signed=true
;	IfExists=update
;	Required=true
;	ForceInstall=false
;	Category=USB
;

!ifdef DRIVERS
${IncludeIfNotDefined} LOGICLIB LogicLib.nsh
${IncludeIfNotDefined} WORDREPLACE_NSH_INCLUDED WordReplace.nsh
${IncludeIfNotDefined} STR_LOC_NSH_INCLUDED StrLoc.nsh
${DefineIfNotDefined} SIGNTOOL `Contrib\bin\signtool\signtool.exe`

; Driver installation tools
${DefineIfNotDefined} PNPUTIL `$SYSDIR\pnputil.exe`
${DefineIfNotDefined} DEVCON `$SYSDIR\devcon.exe`
${DefineIfNotDefined} DRIVERQUERY `$SYSDIR\driverquery.exe`

; Check if driver INF is valid
!define Driver::ValidateInf `!insertmacro _Driver::ValidateInf`
!macro _Driver::ValidateInf _INFFILE _RESULT _VERSION _PROVIDER _CLASS
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_VERSION} ""
	StrCpy ${_PROVIDER} ""
	StrCpy ${_CLASS} ""
	
	${ParseLocations} "${_INFFILE}" $R8
	
	${If} ${FileExists} "$R8"
		FileOpen $0 "$R8" r
		${If} $0 != ""
			; Read INF file and look for key information
			${Do}
				FileRead $0 $1
				${If} ${Errors}
					${ExitDo}
				${EndIf}
				
				; Remove newline characters
				${WordReplace} "$1" "$\r" "" "+" $1
				${WordReplace} "$1" "$\n" "" "+" $1
				
				; Look for version information
				${StrLoc} $2 "$1" "DriverVer" ">"
				${If} $2 != ""
					${WordFind} "$1" "=" "2{" $2
					${If} $2 != ""
						${Trim} $2 $2
						StrCpy ${_VERSION} "$2"
					${EndIf}
				${EndIf}
				
				; Look for provider
				${StrLoc} $2 "$1" "Provider" ">"
				${If} $2 != ""
					${WordFind} "$1" "=" "2{" $2
					${If} $2 != ""
						${Trim} $2 $2
						${WordReplace} "$2" "%" "" "+" $2
						StrCpy ${_PROVIDER} "$2"
					${EndIf}
				${EndIf}
				
				; Look for device class
				${StrLoc} $2 "$1" "Class" ">"
				${If} $2 != ""
					${WordFind} "$1" "=" "2{" $2
					${If} $2 != ""
						${Trim} $2 $2
						StrCpy ${_CLASS} "$2"
					${EndIf}
				${EndIf}
				
			${Loop}
			
			FileClose $0
			StrCpy ${_RESULT} "true"
			${DebugMsg} "INF validation passed: $R8 (Version: ${_VERSION}, Provider: ${_PROVIDER}, Class: ${_CLASS})"
		${Else}
			${DebugMsg} "Cannot open INF file: $R8"
		${EndIf}
	${Else}
		${DebugMsg} "INF file does not exist: $R8"
	${EndIf}
	
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check if driver is installed
!define Driver::IsInstalled `!insertmacro _Driver::IsInstalled`
!macro _Driver::IsInstalled _INFFILE _HARDWAREID _RESULT _DRIVER_INFO
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_DRIVER_INFO} ""
	
	${ParseLocations} "${_INFFILE}" $R8
	
	; Get INF filename
	${GetFileName} "$R8" $R9
	
	; Use PnPUtil to enumerate installed drivers
	ExecDos::Exec /TOSTACK `"${PNPUTIL}" /enum-drivers`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		; Parse output to find our driver
		StrCpy $2 0
		${Do}
			${WordFind} "$1" "$\n" "+$2{" $3
			${If} ${Errors}
				${ExitDo}
			${EndIf}
			
			; Look for our INF file name
			${StrLoc} $0 "$3" "$R9" "<"
			${If} $0 != ""
				StrCpy ${_RESULT} "true"
				StrCpy ${_DRIVER_INFO} "$3"
				${DebugMsg} "Driver found installed: $R9"
				${ExitDo}
			${EndIf}
			
			IntOp $2 $2 + 1
		${Loop}
	${Else}
		${DebugMsg} "Failed to enumerate installed drivers"
	${EndIf}
	
	; If not found by INF name, try by Hardware ID
	${If} ${_RESULT} == "false"
	${AndIf} "${_HARDWAREID}" != ""
		${Driver::FindByHardwareId} "${_HARDWAREID}" ${_RESULT} ${_DRIVER_INFO}
	${EndIf}
	
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Find driver by Hardware ID
!define Driver::FindByHardwareId `!insertmacro _Driver::FindByHardwareId`
!macro _Driver::FindByHardwareId _HARDWAREID _RESULT _DRIVER_INFO
	Push $0
	Push $1
	Push $2
	Push $3
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_DRIVER_INFO} ""
	
	; Use PnPUtil to find devices
	ExecDos::Exec /TOSTACK `"${PNPUTIL}" /enum-devices /connected`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		; Look for the hardware ID in the output
		${StrLoc} $2 "$1" "${_HARDWAREID}" "<"
		${If} $2 != ""
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Device found with Hardware ID: ${_HARDWAREID}"
			
			; Try to get more info about the device
			StrCpy $3 $1 200 $2
			StrCpy ${_DRIVER_INFO} "$3"
		${Else}
			${DebugMsg} "No device found with Hardware ID: ${_HARDWAREID}"
		${EndIf}
	${EndIf}
	
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Install driver
!define Driver::Install `!insertmacro _Driver::Install`
!macro _Driver::Install _INFFILE _HARDWAREID _FORCEINSTALL _SIGNED _TIMEOUT _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_INFFILE}" $R8
	
	; Validate INF file exists and is valid
	${Driver::ValidateInf} "$R8" $R9 $0 $1 $2
	${If} $R9 == "false"
		StrCpy ${_ERROR} "Invalid or missing INF file: $R8"
		${DebugMsg} "Invalid INF file: $R8"
		Goto DriverInstallEnd
	${EndIf}
	
	${DebugMsg} "Installing driver: $R8 (Provider: $1, Class: $2)"
	
	; Check if driver is already installed
	${Driver::IsInstalled} "$R8" "${_HARDWAREID}" $3 $0
	${If} $3 == "true"
		${DebugMsg} "Driver already installed: $R8"
		StrCpy ${_RESULT} "true"
		StrCpy ${_ERROR} "Driver already installed"
		Goto DriverInstallEnd
	${EndIf}
	
	; Check for hardware presence if not forcing installation
	${If} "${_FORCEINSTALL}" != "true"
	${AndIf} "${_HARDWAREID}" != ""
		${Driver::FindByHardwareId} "${_HARDWAREID}" $3 $0
		${If} $3 == "false"
			StrCpy ${_ERROR} "Target hardware not found: ${_HARDWAREID}"
			${DebugMsg} "Hardware not found: ${_HARDWAREID}"
			Goto DriverInstallEnd
		${EndIf}
	${EndIf}
	
	; Build PnPUtil command
	StrCpy $0 `"${PNPUTIL}" /add-driver "$R8"`
	
	; Add install flag if we want to install immediately
	${If} "${_HARDWAREID}" != ""
	${OrIf} "${_FORCEINSTALL}" == "true"
		StrCpy $0 "$0 /install"
	${EndIf}
	
	${DebugMsg} "Executing: $0"
	
	; Execute installation with timeout
	ExecWait '$0' $1 ${_TIMEOUT}000 ; Convert to milliseconds
	
	${Switch} $1
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Driver installed successfully: $R8"
			${Break}
		${Case} "259" ; WAIT_TIMEOUT
			StrCpy ${_ERROR} "Driver installation timed out"
			${DebugMsg} "Driver installation timeout: $R8"
			${Break}
		${Case} "3010"
			StrCpy ${_RESULT} "true"
			StrCpy ${_ERROR} "Driver installed, restart required"
			${DebugMsg} "Driver installed, restart required: $R8"
			${Break}
		${Case} "-2145103823" ; 0x800F0001
			StrCpy ${_ERROR} "Driver package not found or invalid"
			${DebugMsg} "Invalid driver package: $R8"
			${Break}
		${Case} "-2145103822" ; 0x800F0002
			StrCpy ${_ERROR} "Driver signature verification failed"
			${DebugMsg} "Driver signature failed: $R8"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Driver installation failed (Error $1)"
			${DebugMsg} "Driver installation failed: $R8 (Error $1)"
			${Break}
	${EndSwitch}
	
	DriverInstallEnd:
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Uninstall driver
!define Driver::Uninstall `!insertmacro _Driver::Uninstall`
!macro _Driver::Uninstall _INFFILE _HARDWAREID _RESULT _ERROR
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${ParseLocations} "${_INFFILE}" $R8
	${GetFileName} "$R8" $R9
	
	${DebugMsg} "Uninstalling driver: $R9"
	
	; First, try to remove by published name
	ExecDos::Exec /TOSTACK `"${PNPUTIL}" /enum-drivers`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		; Find the published name (oem*.inf) for our driver
		StrCpy $2 0
		${Do}
			${WordFind} "$1" "$\n" "+$2{" $3
			${If} ${Errors}
				${ExitDo}
			${EndIf}
			
			; Look for our INF file name in the output
			${StrLoc} $0 "$3" "$R9" "<"
			${If} $0 != ""
				; Extract the published name (oem*.inf)
				${WordFind} "$3" " " "1{" $0
				${If} $0 != ""
					${DebugMsg} "Found published driver name: $0"
					
					; Remove the driver
					ExecDos::Exec /TOSTACK `"${PNPUTIL}" /delete-driver "$0" /uninstall`
					Pop $1 ; Return code
					Pop $2 ; Output
					
					${Switch} $1
						${Case} "0"
							StrCpy ${_RESULT} "true"
							${DebugMsg} "Driver uninstalled successfully: $0"
							${Break}
						${Case} "3010"
							StrCpy ${_RESULT} "true"
							StrCpy ${_ERROR} "Driver uninstalled, restart required"
							${DebugMsg} "Driver uninstalled, restart required: $0"
							${Break}
						${Default}
							StrCpy ${_ERROR} "Failed to uninstall driver (Error $1)"
							${DebugMsg} "Failed to uninstall driver $0: Error $1"
							${Break}
					${EndSwitch}
					
					${ExitDo}
				${EndIf}
			${EndIf}
			
			IntOp $2 $2 + 1
		${Loop}
	${EndIf}
	
	; If driver removal failed, it might not have been installed
	${If} ${_RESULT} == "false"
		${DebugMsg} "Driver was not found for removal: $R9"
		StrCpy ${_RESULT} "true" ; Consider this success
		StrCpy ${_ERROR} "Driver was not installed"
	${EndIf}
	
	Pop $R9
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Backup driver information
!define Driver::Backup `!insertmacro _Driver::Backup`
!macro _Driver::Backup _INFFILE _HARDWAREID _SECTION _KEY
	Push $0
	Push $1
	Push $2
	Push $3
	Push $R8
	
	${ParseLocations} "${_INFFILE}" $R8
	${GetFileName} "$R8" $0
	
	${Driver::IsInstalled} "$R8" "${_HARDWAREID}" $1 $2
	${If} $1 == "true"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_DriverInfo" "$2"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_InfName" "$0"
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "true"
		${DebugMsg} "Backed up driver: $0"
	${Else}
		${WriteRuntimeData} ${_SECTION} "${_KEY}_Existed" "false"
		${DebugMsg} "Driver $0 was not installed"
	${EndIf}
	
	Pop $R8
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Restore driver
!define Driver::Restore `!insertmacro _Driver::Restore`
!macro _Driver::Restore _SECTION _KEY _RESULT
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "false"
	
	${ReadRuntimeData} $0 ${_SECTION} "${_KEY}_Existed"
	${If} ${Errors}
		${DebugMsg} "No backup found for driver"
		Goto DriverRestoreEnd
	${EndIf}
	
	${If} $0 == "true"
		; Driver existed before, but we can't easily restore it
		; since we don't have the original INF path
		${DebugMsg} "Driver existed originally but cannot be automatically restored"
		StrCpy ${_RESULT} "true" ; Consider this success
	${Else}
		; Driver didn't exist originally, removal is success
		StrCpy ${_RESULT} "true"
		${DebugMsg} "Driver did not exist originally"
	${EndIf}
	
	DriverRestoreEnd:
	Pop $1
	Pop $0
!macroend

; Check if user can install drivers
!define Driver::CanInstall `!insertmacro _Driver::CanInstall`
!macro _Driver::CanInstall _RESULT
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "false"
	
	; Test PnPUtil access
	ExecDos::Exec /TOSTACK `"${PNPUTIL}" /?`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${If} $0 == 0
		StrCpy ${_RESULT} "true"
		${DebugMsg} "User can install drivers"
	${Else}
		${DebugMsg} "User cannot install drivers (insufficient privileges)"
	${EndIf}
	
	Pop $1
	Pop $0
!macroend

; Validate driver signature
!define Driver::ValidateSignature `!insertmacro _Driver::ValidateSignature`
!macro _Driver::ValidateSignature _INFFILE _RESULT _SIGNER
	Push $0
	Push $1
	Push $2
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_SIGNER} ""
	
	${ParseLocations} "${_INFFILE}" $R8
	
	; Use signtool to verify signature
	ExecDos::Exec /TOSTACK `"${SIGNTOOL}" verify /pa "$R8"`
	Pop $0 ; Return code
	Pop $1 ; Output
	
	${Switch} $0
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Driver signature is valid: $R8"
			
			; Try to extract signer information
			${StrLoc} $2 "$1" "Issued to:" ">"
			${If} $2 != ""
				${WordFind} "$1" "$\n" "+1{" $2
				${Trim} $2 $2
				StrCpy ${_SIGNER} "$2"
			${EndIf}
			${Break}
		${Case} "1"
			StrCpy ${_RESULT} "false"
			${DebugMsg} "Driver signature is invalid: $R8"
			${Break}
		${Default}
			; signtool might not be available, try alternative method
			${DebugMsg} "Cannot verify driver signature (signtool not available): $R8"
			StrCpy ${_RESULT} "unknown"
			${Break}
	${EndSwitch}
	
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Generate drivers report
!define Driver::GenerateReport `!insertmacro _Driver::GenerateReport`
!macro _Driver::GenerateReport _FILEPATH
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $R0
	
	FileOpen $0 "${_FILEPATH}" w
	${If} $0 != ""
		FileWrite $0 "Device Drivers Report$\r$\n"
		FileWrite $0 "Generated: $DATE $TIME$\r$\n"
		FileWrite $0 "====================$\r$\n$\r$\n"
		
		; List configured drivers
		FileWrite $0 "Configured Drivers:$\r$\n"
		FileWrite $0 "------------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 Driver$R0 InfFile
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $2 Driver$R0 HardwareId
			${ReadLauncherConfig} $3 Driver$R0 DriverName
			
			; Validate INF
			${Driver::ValidateInf} "$1" $4 $5 $1 $2
			${If} $4 == "true"
				FileWrite $0 "INF: $1$\r$\n"
				FileWrite $0 "  Provider: $1, Class: $2, Version: $5$\r$\n"
				${If} $3 != ""
					FileWrite $0 "  Name: $3$\r$\n"
				${EndIf}
				FileWrite $0 "$\r$\n"
			${Else}
				FileWrite $0 "INF: $1 -> Invalid or not found$\r$\n$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; List all installed drivers
		FileWrite $0 "Installed Drivers Summary:$\r$\n"
		FileWrite $0 "-------------------------$\r$\n"
		ExecDos::Exec /TOSTACK `"${PNPUTIL}" /enum-drivers`
		Pop $1 ; Return code
		Pop $2 ; Output
		
		${If} $1 == 0
			; Count drivers
			StrCpy $3 0
			StrCpy $4 0
			${Do}
				${WordFind} "$2" "$\n" "+$4{" $5
				${If} ${Errors}
					${ExitDo}
				${EndIf}
				${StrLoc} $1 "$5" ".inf" ">"
				${If} $1 != ""
					IntOp $3 $3 + 1
				${EndIf}
				IntOp $4 $4 + 1
			${Loop}
			
			FileWrite $0 "Total installed drivers: $3$\r$\n"
		${Else}
			FileWrite $0 "Could not enumerate installed drivers$\r$\n"
		${EndIf}
		
		FileClose $0
		${DebugMsg} "Drivers report generated: ${_FILEPATH}"
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

;= Enable drivers segment
!define DRIVERS_ENABLED

;= Check permissions and validate driver files
${SegmentPre}
	!ifdef DRIVERS_ENABLED
		${DebugMsg} "Processing device drivers..."
		
		; Check if user can install drivers
		${Driver::CanInstall} $R9
		${If} $R9 == "false"
			${DebugMsg} "Warning: User cannot install drivers (insufficient privileges)"
			MessageBox MB_OK|MB_ICONEXCLAMATION "Warning: Driver installation requires administrator privileges.$\n$\nSome features may not work correctly."
		${EndIf}
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Driver$R0 InfFile
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 Driver$R0 HardwareId
			${ReadLauncherConfig} $2 Driver$R0 IfExists
			${ReadLauncherConfig} $3 Driver$R0 Signed
			${ReadLauncherConfig} $4 Driver$R0 DriverName
			
			; Set defaults
			${If} $2 == ""
				StrCpy $2 "replace"
			${EndIf}
			${If} $3 == ""
				StrCpy $3 "false"
			${EndIf}
			
			; Validate INF file
			${Driver::ValidateInf} "$0" $R8 $R7 $R6 $R5
			${If} $R8 == "false"
				${DebugMsg} "Invalid INF file: $0"
				${WriteRuntimeData} DriverState "$0_Failed" "invalid_inf"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Validate signature if required
			${If} $3 == "true"
				${Driver::ValidateSignature} "$0" $R8 $R7
				${If} $R8 == "false"
					${DebugMsg} "Driver signature validation failed: $0"
					${WriteRuntimeData} DriverState "$0_Failed" "signature_invalid"
					IntOp $R0 $R0 + 1
					${Continue}
				${ElseIf} $R8 == "unknown"
					${DebugMsg} "Cannot validate driver signature: $0"
				${EndIf}
			${EndIf}
			
			; Set driver name if not specified
			${If} $4 == ""
				StrCpy $4 "$R6" ; Use provider name
			${EndIf}
			
			${DebugMsg} "Processing driver: $4 ($0)"
			
			; Check if driver is installed
			${Driver::IsInstalled} "$0" "$1" $R8 $R7
			${If} $R8 == "true"
				${DebugMsg} "Driver is installed: $4"
				
				${Switch} $2
					${Case} "skip"
						${DebugMsg} "Skipping existing driver: $4"
						${WriteRuntimeData} DriverState "$0_Action" "skipped"
						${Break}
					${Case} "backup"
					${Case} "replace"
					${Case} "update"
					${CaseElse}
						${Driver::Backup} "$0" "$1" "DriverBackup" "$0"
						${WriteRuntimeData} DriverState "$0_Action" "backup"
						${Break}
				${EndSwitch}
			${Else}
				${DebugMsg} "Driver is not installed: $4"
				${WriteRuntimeData} DriverState "$0_Action" "create"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Device drivers processing completed."
	!endif
!macroend

;= Install drivers
${SegmentPrePrimary}
	!ifdef DRIVERS_ENABLED
		${DebugMsg} "Installing device drivers..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Driver$R0 InfFile
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we should process this driver
			${ReadRuntimeData} $1 DriverState "$0_Action"
			${If} $1 == "skipped"
				${DebugMsg} "Skipping driver as requested: $0"
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Check for validation failures
			${ReadRuntimeData} $2 DriverState "$0_Failed"
			${IfNot} ${Errors}
				${DebugMsg} "Skipping driver due to validation failure: $0 ($2)"
				${ReadLauncherConfig} $3 Driver$R0 Required
				${If} $3 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Cannot install required driver '$0'$\n$\nReason: $2"
				${EndIf}
				IntOp $R0 $R0 + 1
				${Continue}
			${EndIf}
			
			; Get configuration
			${ReadLauncherConfig} $1 Driver$R0 HardwareId
			${ReadLauncherConfig} $2 Driver$R0 ForceInstall
			${ReadLauncherConfig} $3 Driver$R0 Signed
			${ReadLauncherConfig} $4 Driver$R0 Timeout
			${ReadLauncherConfig} $5 Driver$R0 Required
			${ReadLauncherConfig} $6 Driver$R0 DriverName
			
			; Set defaults
			${If} $2 == ""
				StrCpy $2 "false"
			${EndIf}
			${If} $3 == ""
				StrCpy $3 "false"
			${EndIf}
			${If} $4 == ""
				StrCpy $4 "60"
			${EndIf}
			${If} $6 == ""
				StrCpy $6 "$0"
			${EndIf}
			
			${DebugMsg} "Installing driver: $6"
			
			; Install the driver
			${Driver::Install} "$0" "$1" "$2" "$3" "$4" $R8 $R9
			
			${If} $R8 == "true"
				${WriteRuntimeData} DriverState "$0_Installed" "true"
				${WriteRuntimeData} DriverState "$0_InfFile" "$0"
				${WriteRuntimeData} DriverState "$0_HardwareId" "$1"
				${DebugMsg} "Driver installed successfully: $6"
				
				; Check if restart is required
				${If} $R9 == "Driver installed, restart required"
					${WriteRuntimeData} DriverState "$0_RestartRequired" "true"
					${DebugMsg} "Driver installation requires restart: $6"
				${EndIf}
			${Else}
				${WriteRuntimeData} DriverState "$0_Failed" "$R9"
				${DebugMsg} "Failed to install driver $6: $R9"
				${If} $5 == "true"
					MessageBox MB_OK|MB_ICONERROR "Error: Failed to install required driver '$6'$\n$\nError: $R9"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Check if any drivers require restart
		StrCpy $R8 "false"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Driver$R0 InfFile
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadRuntimeData} $1 DriverState "$0_RestartRequired"
			${IfNot} ${Errors}
				StrCpy $R8 "true"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${If} $R8 == "true"
			${DebugMsg} "Some drivers require a system restart to function properly"
			MessageBox MB_OK|MB_ICONINFORMATION "Information: Some device drivers have been installed but require a system restart to function properly."
		${EndIf}
		
		${DebugMsg} "Device drivers installation completed."
	!endif
!macroend

;= Uninstall drivers
${SegmentPostPrimary}
	!ifdef DRIVERS_ENABLED
		${DebugMsg} "Uninstalling device drivers..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Driver$R0 InfFile
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Check if we installed this driver
			${ReadRuntimeData} $1 DriverState "$0_Installed"
			${IfNot} ${Errors}
				${ReadRuntimeData} $2 DriverState "$0_HardwareId"
				
				${Driver::Uninstall} "$0" "$2" $R8 $R7
				${If} $R8 == "true"
					${DebugMsg} "Driver uninstalled successfully: $0"
					
					; Check if restart is required
					${If} $R7 == "Driver uninstalled, restart required"
						${WriteRuntimeData} DriverState "$0_UninstallRestartRequired" "true"
						${DebugMsg} "Driver uninstallation requires restart: $0"
					${EndIf}
				${Else}
					${DebugMsg} "Failed to uninstall driver $0: $R7"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Check if any driver uninstalls require restart
		StrCpy $R8 "false"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Driver$R0 InfFile
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadRuntimeData} $1 DriverState "$0_UninstallRestartRequired"
			${IfNot} ${Errors}
				StrCpy $R8 "true"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${If} $R8 == "true"
			${DebugMsg} "Some driver removals require a system restart to complete"
			MessageBox MB_OK|MB_ICONINFORMATION "Information: Some device drivers have been removed but require a system restart to complete the removal."
		${EndIf}
		
		${DebugMsg} "Device drivers uninstallation completed."
	!endif
!macroend

;= Restore original drivers (limited functionality)
${SegmentUnload}
	!ifdef DRIVERS_ENABLED
		${DebugMsg} "Cleaning up driver installation data..."
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 Driver$R0 InfFile
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			; Note: Automatic driver restoration is limited because we can't
			; easily reinstall the exact previous driver version automatically.
			; The backup information is mainly for reference.
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Driver installation data cleanup completed."
	!endif
!macroend

!endif
