!macro MyDebug
	!ifdef ?e
		!undef ?e
	!endif
	!ifdef DEBUG
		!define ?e ?e
	!else
		!define ?e ''
	!endif
!macroend

!macro RegTlb ForUser strDll
	!verbose push
	Push `${ForUser}`
	Push `${strDll}`
	${CallArtificialFunction} RegTlb_
	!verbose pop
!macroend
!define RegTlbForUser '!insertmacro RegTlb ForUser'
!define RegTlb '!insertmacro RegTlb ""'
!macro RegTlb_
${!getdebug}
!insertmacro MyDebug
	System::Store sr0r3
	System::Call Oleaut32::LoadTypeLib(wr0,*i.r1)i.r2${?e}
	!insertmacro GetErrorCode LoadTypeLib()
	${If} $2 = 0
		System::Call Oleaut32::RegisterTypeLib$3(ir1,wr0,n)i.r2${?e}
!ifdef DEBUG
		Push $2
!endif
		!insertmacro GetErrorCode RegisterTypeLib$3()ReturnValue
		!insertmacro GetErrorCode RegisterTypeLib$3()ErrorCode
		${If} $2 = 0
			${DebugMsg} 'Success: Registered TLB $3 $0'
		${Else}
			${DebugMsg} 'Error: Failed to register TLB $3 $0'
			SetErrors
		${EndIf}
	${Else}
		${DebugMsg} 'Error: Failed to load TLB $0'
		SetErrors
	${EndIf}
	System::Store l
!macroend

!macro UnRegTlb ForUser strDll
	!verbose push
	Push `${ForUser}`
	Push `${strDll}`
	${CallArtificialFunction} UnRegTlb_
	!verbose pop
!macroend
!define UnRegTlbForUser '!insertmacro UnRegTlb ForUser'
!define UnRegTlb '!insertmacro UnRegTlb ""'
!macro UnRegTlb_
${!getdebug}
!insertmacro MyDebug
	System::Store sr0r3
	System::Call Oleaut32::LoadTypeLibEx(wr0,i${REGKIND_NONE},*i.r1)i.r2${?e}
	!insertmacro GetErrorCode LoadTypeLibEx()
	${If} $2 = 0
		${ITypeLib->GetLibAttr} $1 (.r4).r2${?e}
		!insertmacro GetErrorCode ITypeLib->GetLibAttr
		${If} $2 = 0
			System::Call *$4(&g16.R1,i.R2,i.R3,&i2.R4,&i2.R5,&i2.R6)
			System::Call Oleaut32::UnRegisterTypeLib$3(&g16R1,iR4,iR5,iR2,iR3)i.r2${?e}
!ifdef DEBUG
			Push $2
!endif
			!insertmacro GetErrorCode UnRegisterTypeLib$3()ReturnValue
			!insertmacro GetErrorCode UnRegisterTypeLib$3()ErrorCode
			${If} $2 = 0
				${DebugMsg} 'Success: Unregistered TLB $3 $0'
			${Else}
				${DebugMsg} 'Error: Could not access the OLE registry $0'
				SetErrors
			${EndIf}
			${ITypeLib->ReleaseTLibAttr} $1 (r4)
		${Else}
			${DebugMsg} 'Error: No LibAttr struct in $0'
			SetErrors
		${EndIf}
		${IUnknown->Release} $1 ()
	${Else}
		${DebugMsg} 'Error: Failed to load TLB $0'
		SetErrors
	${EndIf}
	System::Store l
!macroend

!macro LoadProc procName strDll
	!verbose push
	Push `${procName}`
	Push `${strDll}`
	${CallArtificialFunction} LoadProc_
	!verbose pop
!macroend
!define LoadProc `!insertmacro LoadProc`
!define RegDLL `${LoadProc} DllRegisterServer`
!define UnRegDLL `${LoadProc} DllUnregisterServer`
;!define InstallDLL `${LoadProc} DllInstall`
!macro LoadProc_
${!getdebug}
!insertmacro MyDebug
	System::Store sr0r1
;	StrCpy $2 0 ; module handle
	System::Call 'Kernel32::GetModuleHandle(tr0)i.r2${?e}'
	!insertmacro GetErrorCode GetModuleHandle()
	${If} $2 = 0 
		System::Call "Kernel32::LoadLibraryEx(tr0,n,i${LOAD_WITH_ALTERED_SEARCH_PATH})i.r2${?e}"
		!insertmacro GetErrorCode LoadLibraryEx()
	${EndIf}
	${If} $2 <> 0
		System::Call 'Kernel32::GetProcAddress(ir2,mr1)i.r4${?e}'
		!insertmacro GetErrorCode GetProcAddress()
		${If} $4 <> 0
			System::Call "::$4()i.r3${?e}"
			!insertmacro GetErrorCode ::ADDR()
			${If} $3 = 0
				${DebugMsg} 'Success: $1 $0'
			${Else}
				${DebugMsg} "Error: Failed to execute $1 in $0"
				SetErrors
			${EndIf}
		${Else}
			${DebugMsg} 'Error: $1 not implemented in $0'
			SetErrors
		${EndIf}
		System::Call 'Kernel32::FreeLibrary(ir2)'
	${Else}
		${DebugMsg} 'Error: Failed to load DLL $0'
		SetErrors
	${EndIf}
	System::Store l
!macroend
 
!macro GetPathToLib PATH ADMIN USER
	!verbose push
	Push `${PATH}`
	${CallArtificialFunction} GetPathToLib_
	Pop ${User}
	Pop ${Admin}
	!verbose pop
!macroend
!define GetPathToLib `!insertmacro GetPathToLib`
!macro GetPathToLib_
${!getdebug}
!insertmacro MyDebug
	System::Store sR0
	System::Call 'Oleaut32::LoadTypeLib(w R0,*i.r1)i.r0${?e}'
	!insertmacro GetErrorCode LoadTypeLib()
	${If} $0 = 0
		${ITypeLib->GetLibAttr} $1 '(.R0).r0${?e}'
		!insertmacro GetErrorCode ITypeLib->GetLibAttr
		${If} $0 = 0
			System::Call '*$R0(&g16.R1,i.R2,i.R3,&i2.R4,&i2.R5,&i2.R6)'
			${ITypeLib->ReleaseTLibAttr} $1 (R0)
			IntFmt $R2 "%X" $R2
			${IfThen} $R3 = ${SYS_WIN16}  ${|} StrCpy $R3 Win16 ${|}
			${IfThen} $R3 = ${SYS_WIN32}  ${|} StrCpy $R3 Win32 ${|}
			${IfThen} $R3 = ${SYS_MAC}    ${|} StrCpy $R3 MAC   ${|} ; ???
			StrCpy $R7 ''
			IntOp $R8 $R6 & ${LIBFLAG_FRESTRICTED}
			${IfThen} $R8 = ${LIBFLAG_FRESTRICTED}   ${|} StrCpy $R7    |LIBFLAG_FRESTRICTED    ${|}
			IntOp $R8 $R6 & ${LIBFLAG_FCONTROL}
			${IfThen} $R8 = ${LIBFLAG_FCONTROL}      ${|} StrCpy $R7 $R7|LIBFLAG_FCONTROL       ${|}
			IntOp $R8 $R6 & ${LIBFLAG_FHIDDEN}
			${IfThen} $R8 = ${LIBFLAG_FHIDDEN}       ${|} StrCpy $R7 $R7|LIBFLAG_FHIDDEN        ${|}
			IntOp $R8 $R6 & ${LIBFLAG_FHASDISKIMAGE}
			${IfThen} $R8 = ${LIBFLAG_FHASDISKIMAGE} ${|} StrCpy $R7 $R7|LIBFLAG_FHASDISKIMAGE  ${|}
			StrCpy $R6 $R7 '' 1
/*			DetailPrint 'TLIBATTR structure'
			DetailPrint GUID=$R1
			DetailPrint CLID=0x$R2
			DetailPrint SYSKIND=$R3
			DetailPrint MajorVerNum=$R4
			DetailPrint MinorVerNum=$R5
			DetailPrint LibFlags=$R6*/
			${DebugMsg} LibFlags=$R6
		${EndIf}
		${IUnknown->Release} $1 ()
	${EndIf}
	ReadRegStr $0 HKLM SOFTWARE\Classes\TypeLib\$R1\$R4.$R5\$R2\$R3 ''
	ReadRegStr $1 HKCU SOFTWARE\Classes\TypeLib\$R1\$R4.$R5\$R2\$R3 ''
	ClearErrors
	System::Store p0p1l
!macroend

!macro _GetErrorCode dwMessageId
	System::Call Kernel32::FormatMessage(i0x00000100|0x00001000|0x00000200,,i${dwMessageId},i0x0400,*i.r1,,)i.r0
	System::Call *$1(&t$0.r0)
	System::Call Kernel32::LocalFree(ir1)
!macroend
!macro GetErrorCode MESSAGE
${!getdebug}
!ifdef DEBUG
	System::Store sR0
	!insertmacro _GetErrorCode R0
	${DebugMsg} '${MESSAGE}=$R0$\r$\n$0'
	System::Store l
!endif
!macroend

!define COM_CallMethod "!insertmacro _COM_CallMethod "
!macro _COM_CallMethod _vto _ParamsDecl _IFacePtr _Params
	System::Call `${_IFacePtr}->${_vto}${_ParamsDecl} ${_Params}`
!macroend

!define IUnknown->Release "${COM_CallMethod}2 ()i. "
!define ITypeLib->GetLibAttr "${COM_CallMethod}7 (*i)i. "
!define ITypeLib->ReleaseTLibAttr "${COM_CallMethod}12 (i)i. "

; dwFlags defines for LoadLibraryEx()
!define DONT_RESOLVE_DLL_REFERENCES			0x00000001
!define LOAD_LIBRARY_AS_DATAFILE			0x00000002
!define LOAD_WITH_ALTERED_SEARCH_PATH		0x00000008
!define LOAD_LIBRARY_AS_IMAGE_RESOURCE		0x00000020
!define LOAD_LIBRARY_AS_DATAFILE_EXCLUSIVE	0x00000040

;LoadTypeLib Return Values
!define S_OK 					0
!define E_OUTOFMEMORY			0x8007000E ; -2147024882
!define E_INVALIDARG			0x80070057 ; -2147024809
!define TYPE_E_IOERROR			0x80028CA2 ; -2147316574
!define TYPE_E_INVALIDSTATE		0x80028029 ; -2147319767
!define TYPE_E_INVDATAREAD		0x80028018 ; -2147319784
!define TYPE_E_UNSUPFORMAT		0x80028019 ; -2147319783
!define TYPE_E_UNKNOWNLCID		0x8002802E ; -2147319762
!define TYPE_E_CANTLOADLIBRARY	0x80029C4A ; -2147312566
!define FACILITY_STORAGE		3

/*ITypeLib::GetLibAttr Return Values (equal to the LoadTypeLib Return Values)
S_OK = 0
E_OUTOFMEMORY = -2147024882
E_INVALIDARG = -2147024809
TYPE_E_IOERROR = -2147316574
TYPE_E_INVDATAREAD = -2147319784
TYPE_E_UNSUPFORMAT = -2147319783
TYPE_E_INVALIDSTATE = -2147319767 */

;LIBFLAGS Enumeration
!define LIBFLAG_FRESTRICTED		1
!define LIBFLAG_FCONTROL		2
!define LIBFLAG_FHIDDEN			4
!define LIBFLAG_FHASDISKIMAGE	8

;REGKIND Enumeration
!define REGKIND_DEFAULT			0
!define REGKIND_REGISTER		1
!define REGKIND_NONE			2

;SYSKIND Enumeration
!define SYS_WIN16				0
!define SYS_WIN32				1
!define SYS_MAC					2
/*
ITypeLib index count
ITypeLib::GetTypeInfoCount	= 3		This method retrieves the number of type descriptions in the library.
ITypeLib::GetTypeInfo		= 4		This method retrieves the specified type description in the library.
ITypeLib::GetTypeInfoType	= 5		This method retrieves the type of a type description.
ITypeLib::GetTypeInfoOfGuid	= 6		This method retrieves the type description that corresponds to the specified globally unique identifier (GUID).
ITypeLib::GetLibAttr		= 7 	This method retrieves the structure that contains the library's attributes.
ITypeLib::GetTypeComp		= 8		This method retrieves a pointer to the ITypeComp for a type library. This enables a client compiler to bind to the library's types, variables, constants, and global functions.
ITypeLib::GetDocumentation	= 9 	This method retrieves the library's documentation string, the complete Help file name and path, and the context identifier for the library Help topic.
ITypeLib::IsName			= 10	This method indicates whether a passed-in string contains the name of a type or a member described in the library.
ITypeLib::FindName			= 11 	This method finds occurrences of a type description in a type library. This may be used to verify that a name exists in a type library.
ITypeLib::ReleaseTLibAttr	= 12

 TYPE TLIBATTR DWORD   ' // Must be DWORD aligned
   rguid AS GUID
   lcid AS DWORD
   syskind AS DWORD
   wMajorVerNum AS WORD
   wMinorVerNum AS WORD
   wLibFlags AS WORD
 END TYPE
*/