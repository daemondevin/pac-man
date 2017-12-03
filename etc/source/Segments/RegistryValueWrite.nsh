;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   RegistryValueWrite.nsh
;   This file reads the CompilerWrapper.ini and handles the registry writing just before executing the wrapper.
; 
; ATTENTION
;   When using WriteRegDWORD, it is better to use something like 0x00000409 than it is to use 409. 
;     i.e. WriteRegDWORD HKCU "SOFTWARE\Company\Program\Settings" `Language` 0x00000409
;
;   However, when using [RegistryValueWrite] in the CompilerWrapper.ini file use the decimal system instead.
;     i.e. HKCU\SOFTWARE\Company\Program\Settings\Language=REG_DWORD:1033
;
;   When reading a DWORD entry, it always returns the hexadecimal value which looks like this: 0x409
;   Be sure to only use the decimal system to write a DWORD value to the registry which looks like this: 1033
;

${SegmentFile}
${SegmentPrePrimary}
	!ifmacrodef PreRegWrite
		!insertmacro PreRegWrite
	!endif
	${If} $Registry == true
		${ForEachINIPair} RegistryValueWrite $0 $1
		${ValidateRegistryKey} $0
		${ParseLocations} $0
		StrCpy $2 $0 "" -1
		${If} $2 == `\`
			StrCpy $2 $0 -1
			StrCpy $3 ""
		${Else}
			${GetParent} $0 $2
			${GetFileName} $0 $3
		${EndIf}
		StrLen $4 $1
		StrCpy $5 0
		${Do}
			StrCpy $6 $1 1 $5
			${IfThen} $6 == : ${|} ${ExitDo} ${|}
			IntOp $5 $5 + 1
		${LoopUntil} $5 > $4
		${If} $6 == :
			StrCpy $4 $1 $5
			IntOp $5 $5 + 1
			StrCpy $1 $1 "" $5
		${Else}
			StrCpy $4 REG_SZ
		${EndIf}
		${ParseLocations} $1
		${If} $Admin == true
			${registry::Write} `$2` `$3` `$1` `$4` $R9
		${Else}
			Push $7
			StrCpy $7 $2 4
			StrCpy $2 $2 "" 5
			${If} $4 == REG_SZ
			${OrIf} $4 == REG_MULTI_SZ
				${If} $7 == HKLM
					WriteRegStr HKLM `$2` `$3` `$1`
				${Else}
					WriteRegStr HKCU `$2` `$3` `$1`
				${EndIf}
			${ElseIf} $4 == REG_EXPAND_SZ
				${If} $7 == HKLM
					WriteRegExpandStr HKLM `$2` `$3` $1
				${Else}
					WriteRegExpandStr HKCU `$2` `$3` $1
				${EndIf}
			${ElseIf} $4 == REG_DWORD
				${If} $7 == HKLM
					WriteRegDWORD HKLM `$2` `$3` $1
				${Else}
					WriteRegDWORD HKCU `$2` `$3` $1
				${EndIf}
			${ElseIf} $4 == REG_BINARY
				${If} $7 == HKLM
					${registry::Write} `HKLM\$2` `$3` $1 REG_BINARY $R9
				${Else}
					${registry::Write} `HKCU\$2` `$3` $1 REG_BINARY $R9
				${EndIf}
			${EndIf}
			Pop $7
		${EndIf}
		!ifdef RegSleep
			Sleep ${RegSleep}
		!endif
		${NextINIPair}
	${EndIf}
	!ifmacrodef UnPreRegWrite
		!insertmacro UnPreRegWrite
	!endif
!macroend
