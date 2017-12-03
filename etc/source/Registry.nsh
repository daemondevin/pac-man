;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
;
; Registry.nsh
; This file declares and defines all the macros for registry manipulation.
; 

!define Registry::Open `!insertmacro Registry::Open`
!macro Registry::Open _PATH _OPTIONS _HANDLE
	Registry::_Open /NOUNLOAD `${_PATH}` `${_OPTIONS}`
	Pop ${_HANDLE}
!macroend
!define Registry::Find `!insertmacro Registry::Find`
!macro Registry::Find _HANDLE _PATH _VALUEORKEY _STRING _TYPE
	Registry::_Find /NOUNLOAD `${_HANDLE}`
	Pop ${_PATH}
	Pop ${_VALUEORKEY}
	Pop ${_STRING}
	Pop ${_TYPE}
!macroend
!define Registry::Close `!insertmacro Registry::Close`
!macro Registry::Close _HANDLE
	Registry::_Close /NOUNLOAD `${_HANDLE}`
!macroend
!define Registry::KeyExists `!insertmacro Registry::KeyExists`
!macro Registry::KeyExists _PATH _ERR
	Registry::_KeyExists /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
!macroend
!define Registry::Read `!insertmacro Registry::Read`
!macro Registry::Read _PATH _VALUE _STRING _TYPE
	Registry::_Read /NOUNLOAD `${_PATH}` `${_VALUE}`
	Pop ${_STRING}
	Pop ${_TYPE}
!macroend
!define Registry::Write `!insertmacro Registry::Write`
!macro Registry::Write _PATH _VALUE _STRING _TYPE _ERR
	Registry::_Write /NOUNLOAD `${_PATH}` `${_VALUE}` `${_STRING}` `${_TYPE}`
	Pop ${_ERR}
!macroend
!define Registry::ReadExtra `!insertmacro Registry::ReadExtra`
!macro Registry::ReadExtra _PATH _VALUE _NUMBER _STRING _TYPE
	Registry::_ReadExtra /NOUNLOAD `${_PATH}` `${_VALUE}` `${_NUMBER}`
	Pop ${_STRING}
	Pop ${_TYPE}
!macroend
!define Registry::WriteExtra `!insertmacro Registry::WriteExtra`
!macro Registry::WriteExtra _PATH _VALUE _STRING _ERR
	Registry::_WriteExtra /NOUNLOAD `${_PATH}` `${_VALUE}` `${_STRING}`
	Pop ${_ERR}
!macroend
!define Registry::CreateKey `!insertmacro Registry::CreateKey`
!macro Registry::CreateKey _PATH _ERR
	Registry::_CreateKey /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
!macroend
!define Registry::DeleteValue `!insertmacro Registry::DeleteValue`
!macro Registry::DeleteValue _PATH _VALUE _ERR
	Registry::_DeleteValue /NOUNLOAD `${_PATH}` `${_VALUE}`
	Pop ${_ERR}
!macroend
!define Registry::DeleteKey `!insertmacro Registry::DeleteKey`
!macro Registry::DeleteKey _PATH _ERR
	Registry::_DeleteKey /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
!macroend
!define Registry::DeleteKeyEmpty `!insertmacro Registry::DeleteKeyEmpty`
!macro Registry::DeleteKeyEmpty _PATH _ERR
	Registry::_DeleteKeyEmpty /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
!macroend
!define Registry::CopyValue `!insertmacro Registry::CopyValue`
!macro Registry::CopyValue _PATH_SOURCE _VALUE_SOURCE _PATH_TARGET _VALUE_TARGET _ERR
	Registry::_CopyValue /NOUNLOAD `${_PATH_SOURCE}` `${_VALUE_SOURCE}` `${_PATH_TARGET}` `${_VALUE_TARGET}`
	Pop ${_ERR}
!macroend
!define Registry::MoveValue `!insertmacro Registry::MoveValue`
!macro Registry::MoveValue _PATH_SOURCE _VALUE_SOURCE _PATH_TARGET _VALUE_TARGET _ERR
	Registry::_MoveValue /NOUNLOAD `${_PATH_SOURCE}` `${_VALUE_SOURCE}` `${_PATH_TARGET}` `${_VALUE_TARGET}`
	Pop ${_ERR}
!macroend
!define Registry::CopyKey `!insertmacro Registry::CopyKey`
!macro Registry::CopyKey _PATH_SOURCE _PATH_TARGET _ERR
	Registry::_CopyKey /NOUNLOAD `${_PATH_SOURCE}` `${_PATH_TARGET}`
	Pop ${_ERR}
!macroend
!define Registry::MoveKey `!insertmacro Registry::MoveKey`
!macro Registry::MoveKey _PATH_SOURCE _PATH_TARGET _ERR
	Registry::_MoveKey /NOUNLOAD `${_PATH_SOURCE}` `${_PATH_TARGET}`
	Pop ${_ERR}
!macroend
!define Registry::SaveKey `!insertmacro Registry::SaveKey`
!macro Registry::SaveKey _PATH _FILE _OPTIONS _ERR
	Registry::_SaveKey /NOUNLOAD `${_PATH}` `${_FILE}` `${_OPTIONS}`
	Pop ${_ERR}
!macroend
!define Registry::RestoreKey `!insertmacro Registry::RestoreKey`
!macro Registry::RestoreKey _FILE _ERR
	Registry::_RestoreKey /NOUNLOAD `${_FILE}`
	Pop ${_ERR}
!macroend
!define Registry::StrToHex `!insertmacro Registry::StrToHexA`
!define Registry::StrToHexA `!insertmacro Registry::StrToHexA`
!macro Registry::StrToHexA _STRING _HEX_STRING
	Registry::_StrToHexA /NOUNLOAD `${_STRING}`
	Pop ${_HEX_STRING}
!macroend
!define Registry::StrToHexW `!insertmacro Registry::StrToHexW`
!macro Registry::StrToHexW _STRING _HEX_STRING
	Registry::_StrToHexW /NOUNLOAD `${_STRING}`
	Pop ${_HEX_STRING}
!macroend
!define Registry::HexToStr `!insertmacro Registry::HexToStrA`
!define Registry::HexToStrA `!insertmacro Registry::HexToStrA`
!macro Registry::HexToStrA _HEX_STRING _STRING
	Registry::_HexToStrA /NOUNLOAD `${_HEX_STRING}`
	Pop ${_STRING}
!macroend
!define Registry::HexToStrW `!insertmacro Registry::HexToStrW`
!macro Registry::HexToStrW _HEX_STRING _STRING
	Registry::_HexToStrW /NOUNLOAD `${_HEX_STRING}`
	Pop ${_STRING}
!macroend
!define Reg::BackupKey `!insertmacro Reg::BackupKey`
!macro Reg::BackupKey _PATH _ERR
	registry::_DeleteKey /NOUNLOAD `${_PATH}.BackupBy${APPNAME}`
	Pop ${_ERR}
	registry::_MoveKey /NOUNLOAD `${_PATH}` `${_PATH}.BackupBy${APPNAME}`
	Pop ${_ERR}
!macroend
!define Reg::BackupCopyKey `!insertmacro Reg::BackupCopyKey`
!macro Reg::BackupCopyKey _PATH _ERR
	registry::_DeleteKey /NOUNLOAD `${_PATH}.BackupBy${APPNAME}`
	Pop ${_ERR}
	registry::_CopyKey /NOUNLOAD `${_PATH}` `${_PATH}.BackupBy${APPNAME}`
	Pop ${_ERR}
!macroend
!define Reg::RestoreBackupKey `!insertmacro Reg::RestoreBackupKey`
!macro Reg::RestoreBackupKey _PATH _ERR
	registry::_DeleteKey /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
	registry::_MoveKey /NOUNLOAD `${_PATH}.BackupBy${APPNAME}` `${_PATH}`
	Pop ${_ERR}
!macroend
!define Reg::BackupValue `!insertmacro Reg::BackupValue`
!macro Reg::BackupValue _PATH _VALUE _ERR
	registry::_DeleteValue /NOUNLOAD `${_PATH}` `${_VALUE}.BackupBy${APPNAME}`
	Pop ${_ERR}
	registry::_MoveValue /NOUNLOAD `${_PATH}` `${_VALUE}` `${_PATH}` `${_VALUE}.BackupBy${APPNAME}`
	Pop ${_ERR}
!macroend
!define Reg::BackupCopyValue `!insertmacro Reg::BackupCopyValue`
!macro Reg::BackupCopyValue _PATH _VALUE _ERR
	registry::_DeleteValue /NOUNLOAD `${_PATH}` `${_VALUE}.BackupBy${APPNAME}`
	Pop ${_ERR}
	registry::_CopyValue /NOUNLOAD `${_PATH}` `${_VALUE}` `${_PATH}` `${_VALUE}.BackupBy${APPNAME}`
	Pop ${_ERR}
!macroend
!define Reg::RestoreBackupValue `!insertmacro Reg::RestoreBackupValue`
!macro Reg::RestoreBackupValue _PATH _VALUE _ERR
	registry::_DeleteValue /NOUNLOAD `${_PATH}` `${_VALUE}`
	Pop ${_ERR}
	registry::_MoveValue /NOUNLOAD `${_PATH}` `${_VALUE}.BackupBy${APPNAME}` `${_PATH}` `${_VALUE}`
	Pop ${_ERR}
!macroend
!define registry::BackupKey "!insertmacro registry::BackupKey"
!macro registry::BackupKey _PATH _ERR
	${IfNot} ${RegistryKeyExists} `${TREE}\Keys\${_PATH}`
	${AndIf} ${RegistryKeyExists} `${_PATH}`
		Registry::_MoveKey /NOUNLOAD `${_PATH}` `${TREE}\Keys\${_PATH}`
		Pop ${_ERR}
	${EndIf}
!macroend
!define registry::BackupCopyKey "!insertmacro registry::BackupCopyKey"
!macro registry::BackupCopyKey _PATH _ERR
	${IfNot} ${RegistryKeyExists} `${TREE}\Keys\${_PATH}`
	${AndIf} ${RegistryKeyExists} `${_PATH}`
		Registry::_CopyKey /NOUNLOAD `${_PATH}` `${TREE}\Keys\${_PATH}`
		Pop ${_ERR}
	${EndIf}
!macroend
;===  0  # exists
;=== -1  # doesn't exist
!define registry::RestoreBackupKey "!insertmacro registry::RestoreBackupKey"
!macro registry::RestoreBackupKey _PATH _ERR
	Registry::_DeleteKey /NOUNLOAD `${_PATH}`
	Pop ${_ERR}
	${If} ${RegistryKeyExists} `${TREE}\Keys\${_PATH}`
		Registry::_MoveKey /NOUNLOAD `${TREE}\Keys\${_PATH}` `${_PATH}`
		Pop ${_ERR}
		!insertmacro _LOGICLIB_TEMP
		StrCpy $_LOGICLIB_TEMP `${_PATH}`
		${Do}
			${GetParent} `$_LOGICLIB_TEMP` `$_LOGICLIB_TEMP`
			Registry::_DeleteKeyEmpty /NOUNLOAD `${TREE}\Keys\$_LOGICLIB_TEMP`
			Pop ${_ERR}
		${LoopUntil} `$_LOGICLIB_TEMP` == ""
	${EndIf}
	Registry::_DeleteKeyEmpty /NOUNLOAD ${TREE}\Keys
	Pop ${_ERR}
	Registry::_DeleteKeyEmpty /NOUNLOAD ${TREE}
	Pop ${_ERR}
!macroend
!define registry::BackupValue "!insertmacro registry::BackupValue"
!macro registry::BackupValue _PATH _VALUE _ERR
	Registry::_MoveValue /NOUNLOAD `${_PATH}` `${_VALUE}` `${TREE}\Values` `${_VALUE}`
	Pop ${_ERR}
!macroend
!define registry::BackupCopyValue "!insertmacro registry::BackupCopyValue"
!macro registry::BackupCopyValue _PATH _VALUE _ERR
	Registry::_CopyValue /NOUNLOAD `${_PATH}` `${_VALUE}` `${TREE}\Values` `${_VALUE}`
	Pop ${_ERR}
!macroend
!define registry::RestoreBackupValue "!insertmacro registry::RestoreBackupValue"
!macro registry::RestoreBackupValue _PATH _VALUE _ERR
	Registry::_DeleteValue /NOUNLOAD `${_PATH}` `${_VALUE}`
	Pop ${_ERR}
	Registry::_MoveValue /NOUNLOAD `${TREE}\Values` `${_VALUE}` `${_PATH}` `${_VALUE}`
	Pop ${_ERR}
	Registry::_DeleteKeyEmpty /NOUNLOAD ${TREE}\Values
	Pop ${_ERR}
	Registry::_DeleteKeyEmpty /NOUNLOAD ${TREE}
	Pop ${_ERR}
!macroend
!define Registry::Unload `!insertmacro Registry::Unload`
!macro Registry::Unload
	Registry::_Unload
!macroend
