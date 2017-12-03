;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   RegistryValueBackupDelete.nsh
;   This file reads the CompilerWrapper.ini file and handles the registry values that get backed up and restored later.
; 

${SegmentFile}
${SegmentPrePrimary}
	!ifmacrodef PreRegistryValue
		!insertmacro PreRegistryValue
	!endif
	${If} $Registry == true
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadWrapperConfig} $R1 RegistryValueBackupDelete $R0
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ValidateRegistryKey} $R1
			${ParseLocations} $R1
			${GetParent} $R1 $R2
			${GetFilename} $R1 $R3
			${registry::MoveValue} $R2 $R3 HKCU\Software\PortableApps\Values $R1 $R4
			IntOp $R0 $R0 + 1
		${Loop}
	${EndIf}
	!ifmacrodef UnPreRegistryValue
		!insertmacro UnPreRegistryValue
	!endif
!macroend
${SegmentPostPrimary}
	!ifmacrodef PostRegistryValue
		!insertmacro PostRegistryValue
	!endif
	${If} $Registry == true
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadWrapperConfig} $R1 RegistryValueBackupDelete $R0
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			${ValidateRegistryKey} $R1
			${ParseLocations} $R1
			${GetParent} $R1 $R2
			${GetFilename} $R1 $R3
			${registry::DeleteValue} $R2 $R3 $R4
			${registry::MoveValue} HKCU\Software\PortableApps\Values $R1 $R2 $R3 $R4
			IntOp $R0 $R0 + 1
		${Loop}
		${registry::DeleteKeyEmpty} HKCU\Software\PortableApps\Values $R4
		${registry::DeleteKeyEmpty} HKCU\Software\PortableApps $R4
	${EndIf}
	!ifmacrodef UnPostRegistryValue
		!insertmacro UnPostRegistryValue
	!endif
!macroend
