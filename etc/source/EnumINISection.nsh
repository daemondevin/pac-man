/* The Function Description
   Based on the method to loop over a buffer of null-terminated strings in function "GetDrives"
   Loop over all available sections in an INI file.

	Syntax \\
		${GetSectionNames} "File" "Function"

		File     > name of the initialization file
		Function > Callback function

		Function "Function"
			; $9    "section name"
			; $R0-$R9  are not used (save data in them).
			; ...
			Push $var    ; If $var="StopGetSectionNames" Then exit from function
		FunctionEnd

	Example1 \\
		Section
			${GetSectionNames} "c:\test.ini" "Example1"
		SectionEnd

		Function Example1
			MessageBox MB_OK "$9"
			Push $0
		FunctionEnd

	Example2 \\
		Section
			${GetSectionNames} "c:\test.ini" "Example2"
		SectionEnd

		Function Example2
			StrCmp $9 $R0 0 +3
			StrCpy $R1 $9
			StrCpy $0 StopGetSectionNames
			Push $0
		FunctionEnd
*/

!define GetSectionNames `!insertmacro GetSectionNamesCall`
!macro GetSectionNamesCall _FILE _FUNC
	Push $0
	Push `${_FILE}`
	GetFunctionAddress $0 `${_FUNC}`
	Push `$0`
	Call GetSectionNames
	Pop $0
!macroend

Function GetSectionNames
	Exch $1
	Exch
	Exch $0
	Exch
	Push $2
	Push $3
	Push $4
	Push $5
	Push $8
	Push $9
	System::Call *(&t1024)i.r2
	StrCpy $3 $2
	System::Call "kernel32::GetPrivateProfileSectionNames(i, i, t)i (r3, 1024, r0).r4"
	enumok:
	System::Call 'kernel32::lstrlen(t)i (i r3).r5' ; (t) is here to trigger A/W detection
	StrCmp $5 '0' enumex
	System::Call '*$3(&t1024 .r9)'
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $8
	Call $1
	Pop $9
	Pop $8
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
	StrCmp $9 'StopGetSectionNames' enumex
	enumnext:
		!if "${NSIS_CHAR_SIZE}" > 1
			IntOp $5 $5 * ${NSIS_CHAR_SIZE}
			IntOp $5 $5 + ${NSIS_CHAR_SIZE}
		!else
			IntOp $5 $5 + 1
		!endif
		IntOp $3 $3 + $5
		Goto enumok
	enumex:
		System::Free $2
	Pop $9
	Pop $8
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

!ifndef GetSectionNames_BufferSize
	!define GetSectionNames_BufferSize 1024
!endif

/* ANSI ONLY
Function GetSectionNames
  Exch $1
  Exch
  Exch $0
  Exch
  Push $2
  Push $3
  Push $4
  Push $5
  Push $9
 
  System::Call `*(&m${GetSectionNames_BufferSize}) i .r2`
  StrCpy $3 $2
 
  System::Call `kernel32::GetPrivateProfileSectionNamesA(i r3, i ${GetSectionNames_BufferSize}, m r0) i .r4`
 
  Next:
  System::Call `kernel32::lstrlenA(i r3) i .r5`
  StrCmp $5 0 Done
 
  System::Call `*$3(&m${NSIS_MAX_STRLEN} .r9)`
 
  Push $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Call $1
  Pop $9
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
  StrCmp $9 StopGetSectionNames Done
 
  IntOp $5 $5 + 1
  IntOp $3 $3 + $5
  GoTo Next
 
  Done:
  System::Free $2
 
  Pop $9
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd
*/