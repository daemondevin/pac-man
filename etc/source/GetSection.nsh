/* The Function Description
Based on the method to loop over a buffer of null-terminated strings in function "GetDrives"
 
Loop over all entries of a specified section in an INI file.
 
Syntax:
${GetSection} "File" "Section" "Function"
 
"File"     ; name of the initialization file
"Section"  ; name of the section in the initialization file
"Function" ; Callback function
 
Function "Function"
         ; $9    "key=value"
         ; $R0-$R9  are not used (save data in them).
 
         ; ...
 
         Push $var    ; If $var="StopGetSection" Then exit from function
FunctionEnd

Example1: 
Section
	${GetSection} "c:\test.ini" "MySection" "Example1"
SectionEnd
 
Function Example1
	MessageBox MB_OK "$9"
 
	Push $0
FunctionEnd

Example2: 
Section
	${GetSection} "c:\test.ini" "MySection" "Example2"
SectionEnd
 
Function Example2
	StrCmp $9 $R0 0 +3
	StrCpy $R1 $9
	StrCpy $0 StopGetSection
 
	Push $0
FunctionEnd
*/



	!define GetSection `!insertmacro GetSectionCall`
 
	!macro GetSectionCall _FILE _SECTION _FUNC
		Push $0
		Push `${_FILE}`
		Push `${_SECTION}`
		GetFunctionAddress $0 `${_FUNC}`
		Push `$0`
		Call GetSection
		Pop $0
	!macroend
 
Function GetSection
	Exch $2
        Exch
	Exch $1
	Exch
	Exch 2
	Exch $0
	Exch 2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $8
	Push $9
 
	System::Call *(&t1024)i.r3
;	System::Alloc 1024
;	Pop $3
	StrCpy $4 $3

	System::Call "kernel32::GetPrivateProfileSection(t, i, i, t)i (r1, r4, 1024, r0).r5"
 
	enumok:
	System::Call 'kernel32::lstrlen(t)i (i r4).r6' ; (t) is here to trigger A/W detection
	StrCmp $6 '0' enumex
 
	System::Call '*$4(&t1024 .r9)'
 
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6
	Push $8
	Call $2
	Pop $9
	Pop $8
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
	StrCmp $9 'StopGetSection' enumex

!if "${NSIS_CHAR_SIZE}" > 1
	IntOp $4 $4 * ${NSIS_CHAR_SIZE}
	IntOp $4 $4 + ${NSIS_CHAR_SIZE}
!else
	IntOp $4 $4 + 1
!endif
	IntOp $3 $3 + $5
	goto enumok
 
	enumex:
	System::Free $3
 
	Pop $9
	Pop $8
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd