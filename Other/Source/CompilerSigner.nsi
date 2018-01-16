;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; CompilerSigner.nsi
; 	This file is the source code to the small code signing utility called CompilerSigner.exe.
; 	Make sure that CompilerSigner.exe is in the same folder as LauncherCompiler.nsi
; 

!searchreplace APP "${__FILE__}" .nsi ""

Unicode true
ManifestDPIAware true

;= DEFINES
;= ################
;!define DEBUG	 ; Uncomment for debugging features 
!define CONTRIB  `Contrib\bin`
!define RESHACK  `${CONTRIB}\ResHacker`
!define SIGNDIR  `${CONTRIB}\signtool`
!define SIGNTOOL `${SIGNDIR}\signtool.exe`
!define NEWLINE  `$\r$\n`
!define TAB      `$\t`

!packhdr	"$%TEMP%\exehead.tmp" \
			`"${RESHACK}.exe" -delete "$%TEMP%\exehead.tmp", \
			"$%TEMP%\exehead.tmp", ICONGROUP, 103, 1033 \
			&& del "${RESHACK}.log" && del "${RESHACK}.ini"`

Caption "PorableApps ${APP}"
OutFile ${APP}.exe

;= SWITCHES
;= ################
WindowIcon Off
XPStyle on
RequestExecutionLevel user
SetCompress Auto
SetCompressor /SOLID lzma
SetCompressorDictSize 32
SetDatablockOptimize On

;= INCLUDES
;= ################
!include LogicLib.nsh
!include FileFunc.nsh
!include IsFile.nsh

;= VARIABLES
;= ################
Var PFX
Var TSA
Var HASH
Var TSA_SHA1
Var TSA_SHA2
Var BINARY

;= MACROS
;= ################
!define InvalidSwitchValue `!insertmacro _InvalidSwitchValue`
!macro _InvalidSwitchValue _SWITCH _VALUES
	MessageBox MB_OK|MB_TOPMOST \
		"PAC-MAN CODE-SIGNER ERROR:${NEWLINE}${NEWLINE}\
		The value for the ${_SWITCH} switch is invalid!${NEWLINE}${NEWLINE}\
		Only one of the following values are allowed:${NEWLINE}\
		${_VALUES}"
		Abort
		Quit
!macroend
!define DebugDialog `!insertmacro _DebugDialog`
!macro _DebugDialog _TASK _RETURN
	!ifdef DEBUG
		MessageBox MB_OK|MB_TOPMOST `\
			PAC-MAN CODE-SIGNER : DEBUG${NEWLINE}${NEWLINE}\
			TASK: ${NEWLINE}${_TASK}${NEWLINE}${NEWLINE}\
			${_RETURN}`
	!endif
!macroend

Function .onInit
    SetSilent silent
	${DebugDialog} ".OnInit Function" "SetSilent Silent"
FunctionEnd

Section Main

    ${GetParameters} $0

	${DebugDialog} "Fetching All Parameters" "$0"

	${GetOptions} `$0` "--PFX="  $1
	${GetOptions} `$0` "--PASS=" $2
	${GetOptions} `$0` "--TSA="  $3
	${GetOptions} `$0` "--HASH=" $4
	${GetOptions} `$0` "--EXE="  $5
	${GetOptions} `$0` "--MODE=" $6

	${DebugDialog} "Loading Switches Individually"  "--PFX=$1 ${NEWLINE}\
													--PASS=$2 ${NEWLINE}\
													 --TSA=$3 ${NEWLINE}\
													--HASH=$4 ${NEWLINE}\
													 --EXE=$5 ${NEWLINE}\
													--MODE=$6"
	
	${If} ${IsFile} "$1"
		StrCpy $PFX $1
	${Else}
		${InvalidSwitchValue} "--PFX" "$1"
	${EndIf}

	${IfNot} $2 == ""
		StrCpy $PFX `"$1" /p "$2"`
	${EndIf}

	${If}   $3 == "Comodo"
	${OrIf} $3 == "Verisign"
	${OrIf} $3 == "GlobalSign"
	${OrIf} $3 == "DigiCert"
	${OrIf} $3 == "Starfield"
	${OrIf} $3 == "Entrust"
	${OrIf} $3 == "SwissSign"
		StrCpy $TSA $3
	${Else}
		${InvalidSwitchValue} "--TSA"   "\
										${TAB}Comodo${NEWLINE}\
										${TAB}Verisign${NEWLINE}\
										${TAB}GlobalSign${NEWLINE}\
										${TAB}DigiCert${NEWLINE}\
										${TAB}Entrust${NEWLINE}\
										${TAB}Starfield${NEWLINE}\
										${TAB}SwissSign"
	${EndIf}

	${If}   $4 == "SHA1"
	${OrIf} $4 == "SHA2"
		StrCpy $HASH $4
	${Else}
		${InvalidSwitchValue} "--HASH" "${TAB}SHA1${NEWLINE}${TAB}SHA2"
	${EndIf}
	
	${If} ${IsFile} "$5"
		StrCpy $BINARY $5
	${Else}
		${InvalidSwitchValue} "--EXE" "${TAB}7-ZipPortable.exe${NEWLINE}\
										${TAB}DiscordPortable.exe"
	${EndIf}
	
	${DebugDialog} "Initializing Variables With Parameters" "CERT: $$PFX == $PFX ${NEWLINE}\
															 PASS: $2 ${NEWLINE} \
															  TSA: $$TSA == $3 ${NEWLINE}\
															 HASH: $$HASH == $4 ${NEWLINE}\
															 FILE: $$BINARY == $5 ${NEWLINE}\
															 MODE: $6"
	

	Dialer::GetConnectedState
	Pop $9

	${DebugDialog} "Checking Network Connection" "Status: $9 ($$9)"

    ${If} $9 != online
	${OrIf} $6 == offline
		Goto __NO_INTERNET
    ${EndIf}

	${Select} $TSA
	
		${Case} Comodo
				
			StrCpy $TSA_SHA1	"http://timestamp.comodoca.com"
			StrCpy $TSA_SHA2	"http://timestamp.comodoca.com/?td=sha256"
		
		${Case} Verisign
		
			StrCpy $TSA_SHA1	"http://timestamp.verisign.com/scripts/timstamp.dll"
			StrCpy $TSA_SHA2	"http://sha256timestamp.ws.symantec.com/sha256/timestamp"
            
		${Case} GlobalSign
		
			StrCpy $TSA_SHA1	"http://timestamp.globalsign.com/scripts/timstamp.dll"
			StrCpy $TSA_SHA2	"http://timestamp.globalsign.com/?signature=sha2"
            
		${Case} DigiCert
		
			StrCpy $TSA_SHA1	"http://timestamp.digicert.com"
			StrCpy $TSA_SHA2	"http://timestamp.digicert.com"
            
		${Case} Entrust
		
			StrCpy $TSA_SHA1	"http://timestamp.entrust.net/TSS/RFC3161sha1TS"
			StrCpy $TSA_SHA2	"http://timestamp.entrust.net/TSS/RFC3161sha2TS"
                        
		${Case} Starfield
		
			StrCpy $TSA_SHA1	"http://tsa.starfieldtech.com"
			StrCpy $TSA_SHA2	"http://tsa.starfieldtech.com"
            
		${Case} SwissSign

			StrCpy $TSA_SHA1	"http://tsa.swisssign.net"
			StrCpy $TSA_SHA2	"http://tsa.swisssign.net"
            
		${Default} 
		
			; Use Comodo as default TSA if no TSA was specified
			StrCpy $TSA_SHA1	"http://timestamp.comodoca.com"
			StrCpy $TSA_SHA2	"http://timestamp.comodoca.com/?td=sha256"
            
	${EndSelect}

	${DebugDialog} "Time-Stamping Authority" \
					"Using: $TSA${NEWLINE}SHA1: $TSA_SHA1${NEWLINE}SHA2: $TSA_SHA2"
	
	${If} ${IsFile} "${SIGNTOOL}"
	
		${DebugDialog} "PRE CODE-SIGNING" "signtool.exe location: ${SIGNTOOL}"
	
		; We can finally sign the binary now!
		${Select} $HASH
		
			${Case} "SHA1"
				ExecDos::Exec /TOSTACK `"${SIGNTOOL}" sign \
					/f $PFX \
					/t "$TSA_SHA1" \
					/v "$BINARY"` $R0 $R1
					
				${DebugDialog} "SHA1 CALL" "CMDLINE:${NEWLINE}\
								${SIGNTOOL} sign /f $PFX /t $TSA_SHA1 /v $BINARY"
					
			${Case} "SHA2"
				ExecDos::Exec /TOSTACK `"${SIGNTOOL}" sign \
					/f $PFX \
					/fd sha256 \
					/tr "$TSA_SHA2" \
					/td sha256 /as \
					/v "$BINARY"` $R0 $R1
					
				${DebugDialog} "SHA2 CALL" "CMDLINE:${NEWLINE}\
								${SIGNTOOL} sign /f $PFX /fd sha256 /tr $TSA_SHA2 /td sha256 /as /v $BINARY"
					
		${EndSelect}
		
		${DebugDialog} "POST CODE-SIGNING" "$$R0 == $R0${NEWLINE}$$R1 == $R1"
		
	${Else}
	
		; Cannot locate the signtool.exe
		MessageBox MB_OK|MB_TOPMOST "PAC-MAN CODE-SIGNER ERROR:${NEWLINE}\
					No Signing Tool${NEWLINE}${NEWLINE}\
					Cannot sign $BINARY without signtool.exe${NEWLINE}${NEWLINE}\
					Be sure to check for it in:${NEWLINE}\
					${TAB}Other\Source\Contrib\bin\signtool"

	${EndIf}
	
	Goto __SIGN_COMPLETE
	
	__NO_INTERNET:
		MessageBox MB_OK|MB_TOPMOST "PAC-MAN CODE-SIGNER WARNING:${NEWLINE}\
					No Internet Connection!${NEWLINE}${NEWLINE}\
					$BINARY will still be signed but without a time-stamp"
	
		${DebugDialog} "PRE CODE-SIGNING" "Signtool.exe location: ${SIGNTOOL}"
	
		${Select} $HASH
		
			${Case} "SHA1"

				ExecDos::Exec /TOSTACK `"${SIGNTOOL}" sign /f $PFX /v "$BINARY"` $R0 $R1
				${DebugDialog} "SHA-1 CALL" "CMDLINE:${NEWLINE}\
								${SIGNTOOL} sign /f $PFX /v $BINARY"
								
			${Case} "SHA2"
			
				ExecDos::Exec /TOSTACK `"${SIGNTOOL}" sign /f $PFX /fd sha256 /td sha256 /as /v "$BINARY"` $R0 $R1
				${DebugDialog} "SHA-2 CALL" "CMDLINE:${NEWLINE}\
								${SIGNTOOL} sign /f $PFX /fd sha256 /td sha256 /as /v $BINARY"
			
		${EndSelect}
		
		${DebugDialog} "POST CODE-SIGNING" "$$R0 == $R0${NEWLINE}$$R1 == $R1"
	
	__SIGN_COMPLETE:
		${DebugDialog} "COMPLETE" "END OF EXECUTION"
		
		; Sign ourselves using both SHA-1 and SHA-2 too
		!finalize `"${SIGNTOOL}" sign /f "Contrib\certificates\daemon.devin.p12" /p "" /v "%1"`
		!finalize `"${SIGNTOOL}" sign /f "Contrib\certificates\daemon.devin.p12" /p "" /fd sha256 /td sha256 /as /v "%1"`
SectionEnd
