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
Icon ..\..\App\AppInfo\${APP}.ico

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
Var TSA_URL
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

	${If}   $3 == "Sectigo"
	${OrIf} $3 == "GlobalSign"
	${OrIf} $3 == "ACCV"
	${OrIf} $3 == "Starfield"
	${OrIf} $3 == "Entrust"
	${OrIf} $3 == "SwissSign"
	${OrIf} $3 == "Symantec"
	${OrIf} $3 == "IDnomic"
	${OrIf} $3 == "IZENPE"
	${OrIf} $3 == "CERTUM"
	${OrIf} $3 == "CatCert"
	${OrIf} $3 == "Apple"
		StrCpy $TSA $3
	${Else}
		${InvalidSwitchValue} "--TSA"   "\
										${TAB}Sectigo${NEWLINE}\
										${TAB}Verisign${NEWLINE}\
										${TAB}GlobalSign${NEWLINE}\
										${TAB}Entrust${NEWLINE}\
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

		${Case} Sectigo

			StrCpy $TSA_URL	"http://timestamp.sectigo.com/"

		${Case} GlobalSign

			StrCpy $TSA_URL	"http://aatl-timestamp.globalsign.com/tsa/aohfewat2389535fnasgnlg5m23"

		${Case} ACCV

			StrCpy $TSA_URL	"http://tss.accv.es:8318/tsa"

		${Case} Symantec

			StrCpy $TSA_URL	"http://sha256timestamp.ws.symantec.com/sha256/timestamp"

		${Case} Entrust

			StrCpy $TSA_URL	"http://timestamp.entrust.net/TSS/RFC3161sha2TS"

		${Case} IDnomic

			StrCpy $TSA_URL	"http://kstamp.keynectis.com/KSign/"

		${Case} SwissSign

			StrCpy $TSA_URL	"http://tsa.swisssign.net/"

		${Case} IZENPE

			StrCpy $TSA_URL	"http://tsa.izenpe.com/"

		${Case} CERTUM

			StrCpy $TSA_URL	"http://time.certum.pl/"

		${Case} CatCert

			StrCpy $TSA_URL	"http://psis.catcert.cat/psis/catcert/tsp"

		${Case} Apple

			StrCpy $TSA_URL	"http://timestamp.apple.com/ts01"

		${Default}

			; Use Sectigo as default TSA if no TSA was specified
			StrCpy $TSA_URL	"http://timestamp.sectigo.com/"

	${EndSelect}

	${DebugDialog} "Time-Stamping Authority" \
					"Using: $TSA${NEWLINE}SHA1: $TSA_SHA1${NEWLINE}SHA2: $TSA_SHA2"

	${If} ${IsFile} "${SIGNTOOL}"

		${DebugDialog} "PRE CODE-SIGNING" "signtool.exe location: ${SIGNTOOL}"

		; We can finally sign the binary now!
        ExecDos::Exec /TOSTACK `"${SIGNTOOL}" sign \
            /f $PFX \
            /fd $HASH \
            /t "$TSA_URL" \
            /v "$BINARY"` $R0 $R1

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

        ExecDos::Exec /TOSTACK `"${SIGNTOOL}" sign \
            /f $PFX \
            /fd $HASH \
            /t "$TSA_URL" \
            /v "$BINARY"` $R0 $R1

		${DebugDialog} "POST CODE-SIGNING" "$$R0 == $R0${NEWLINE}$$R1 == $R1"
	
	__SIGN_COMPLETE:
		${DebugDialog} "COMPLETE" "END OF EXECUTION"
		
		; Sign ourselves
		!finalize `"${SIGNTOOL}" sign /f "Contrib\certificates\daemon.devin.pfx" /fd sha512 /t "http://timestamp.sectigo.com/" /v "%1"`
SectionEnd
