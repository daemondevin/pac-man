;=== WriteRegDWORD HKLM "Software\My Company\My Software" "DWORD Value" 0xDEADBEEF
;=== below works properly from XP through 8.1. ( 0x00000001 works better than 1 or 0 )
;=== WriteRegDWORD HKCU `${KEY}` `${INT}` 0x00000001
################################################################################
# WRITE DWORD USING DECIMAL ! (NOT HEXIDECIMAL)
;=== NOTE: to write correctly for DWORD (dword:00000409)
	;=== must use decimal for writing.
	;=== I.E. Read from file is dword:00000409
	;=== but when writing.. must use decimal which is 1033.
	;=== make sure NOT to use hexadecimal which looks like this: 409
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