!include CallANSIPlugin.nsh

!define PortablePasswords::ImportPasswords `!insertmacro PortablePasswords::ImportPasswords`
!macro PortablePasswords::ImportPasswords _SOURCE _DEST _MASTERPASSWORD
	${PushAsANSI} `${_MASTERPASSWORD}`
	${PushAsUTF8} `${_DEST}`
	${PushAsUTF8} `${_SOURCE}`
	PortablePasswords::ImportPasswords ;/NOUNLOAD
!macroend

!define PortablePasswords::ExportPasswords `!insertmacro PortablePasswords::ExportPasswords`
!macro PortablePasswords::ExportPasswords _SOURCE _DEST _MASTERPASSWORD
	${PushAsANSI} `${_MASTERPASSWORD}`
	${PushAsUTF8} `${_DEST}`
	${PushAsUTF8} `${_SOURCE}`
	PortablePasswords::ExportPasswords ;/NOUNLOAD
!macroend

!define PortablePasswords::HashPassword `!insertmacro PortablePasswords::HashPassword`
!macro PortablePasswords::HashPassword _MASTERPASSWORD
	${PushAsANSI} `${_MASTERPASSWORD}`
	PortablePasswords::HashPassword ;/NOUNLOAD
	System::Call kernel32::MultiByteToWideChar(i${CP_ACP},,ts,i-1,t.s,i${NSIS_MAX_STRLEN})
!macroend

!define KillProc::FindProcesses `!insertmacro KillProc::FindProcesses`
!macro KillProc::FindProcesses
	${VarToUTF8} $0
	KillProc::FindProcesses ;/NOUNLOAD
	${VarFromANSI} $0
!macroend

!define KillProc::KillProcesses `!insertmacro KillProc::KillProcesses`
!macro KillProc::KillProcesses
	${VarToUTF8} $0
	KillProc::KillProcesses ;/NOUNLOAD
	${VarFromANSI} $0
	${VarFromANSI} $1
!macroend