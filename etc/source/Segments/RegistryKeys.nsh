;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   RegistryKeys.nsh
;   This file handles the importing/restoring of registry keys that are declared in the CompilerWrapper.ini file.
; 

!ifndef TREE
	!define TREE `HKCU\Software\${PAC}`
!endif
!ifndef TREEKEYS
	!define TREEKEYS `${TREE}\Keys`
!endif

${SegmentFile}
${SegmentPrePrimary}
	!ifmacrodef PreReg
		!insertmacro PreReg
	!endif
	${If} $Registry == true
		${ForEachINIPair} RegistryKeys $R0 $R1
			${ValidateRegistryKey} $R1
			ExpandEnvStrings $R1 $R1
			${IfNot} ${RegistryKeyExists} `${TREEKEYS}\$R1`
			${AndIf} ${RegistryKeyExists} $R1
				StrCpy $R2 $R1 4
				StrCmp $R2 HKLM 0 +2
				StrCmpS $ADMIN true 0 +3
				Registry::_MoveKey /NOUNLOAD $R1 `${TREEKEYS}\$R1`
				Pop $R2
			${EndIf}
			StrCmpS $R0 - +11
			ExpandEnvStrings $R0 $R0
			IfFileExists `${CONF}\$R0.reg` 0 +9
			IfFileExists `${REGEDIT}` 0 +5
			!ifdef DisableFSR
				ExecDos::exec /TOSTACK /DISABLEFSR `"${REGEDIT}" /s "${CONF}\$R0.reg"`
			!else
				ExecDos::exec /TOSTACK `"${REGEDIT}" /s "${CONF}\$R0.reg"`
			!endif
			Pop $R1
			Pop $R2
			StrCmp $R1 0 +4
			!ifdef DisableFSR
				ExecDos::exec /TOSTACK /DISABLEFSR `"${REGEXE}" IMPORT "${CONF}\$R0.reg"`
			!else
				ExecDos::exec /TOSTACK `"${REGEXE}" IMPORT "${CONF}\$R0.reg"`
			!endif
			Pop $R1
			Pop $R2
		${NextINIPair}
	${EndIf}
	!ifmacrodef UnPreReg
		!insertmacro UnPreReg
	!endif
!macroend
${SegmentPostPrimary}
	!ifmacrodef PostReg
		!insertmacro PostReg
	!endif
	${If} $REGISTRY == true
		${ForEachINIPair} RegistryKeys $R0 $R1
			${ValidateRegistryKey} $R1
			ExpandEnvStrings $R1 $R1
			StrCmpS $R0 - +14
			StrCmpS $RunLocally true +13
			ExpandEnvStrings $R0 $R0
			Registry::_SaveKey /NOUNLOAD $R1 `${CONF}\$R0.reg` ""
			Pop $R2
			StrCmpS $R2 0 +9
			IfFileExists `${REGEDIT}` 0 +5
			!ifdef DisableFSR
				ExecDos::exec /TOSTACK /DISABLEFSR `"${REGEDIT}" /e "${CONF}\$R0.reg" "$R1"`
			!else
				ExecDos::exec /TOSTACK `"${REGEDIT}" /e "${CONF}\$R0.reg" "$R1"`
			!endif
			Pop $R2
			Pop $R3
			StrCmpS $R2 0 +4
			!ifdef DisableFSR
				ExecDos::exec /TOSTACK /DISABLEFSR `"${REGEXE}" SAVE "$R1" "${CONF}\$R0.reg"`
			!else
				ExecDos::exec /TOSTACK `"${REGEXE}" SAVE "$R1" "${CONF}\$R0.reg"`
			!endif
			Pop $R2
			Pop $R3
			Registry::_DeleteKey /NOUNLOAD $R1
			Pop $R2
			${If} ${RegistryKeyExists} `${TREEKEYS}\$R1`
				Registry::_MoveKey /NOUNLOAD `${TREEKEYS}\$R1` $R1
				Pop $R2
				${Do}
					${GetParent} $R1 $R1
					Registry::_DeleteKeyEmpty /NOUNLOAD `${TREEKEYS}\$R1`
					Pop $R2
				${LoopUntil} $R1 == ""
			${EndIf}
		${NextINIPair}
		Registry::_DeleteKeyEmpty /NOUNLOAD `${TREE}`
		Pop $R2
	${EndIf}
	!ifmacrodef UnPostReg
		!insertmacro UnPostReg
	!endif
!macroend
