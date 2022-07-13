/*
 * AddCertToStore.nsh v1.0
 *
 * Silently import certificates into the Windows stores. 
 * Not to be abused. Please use it wisely.
 * 
 * Example:
 * ${AddCertToStore} $0 certificate.crt
 * 
 * Returns 0 on success
 *
 * Returns one of the following error levels on failure
 * 	3 = Unable to add certificate to certificate store
 * 	2 = Unable to open certificate store
 * 	1 = Unable to open certificate file
 *
 */

; --- Defines
!ifndef ADDCERTTOSTORE_NSH_INCLUDED
!define ADDCERTTOSTORE_NSH_INCLUDED
; --- Includes
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
Function AddCertToStore
	!define CERT_QUERY_OBJECT_FILE 1
	!define CERT_QUERY_CONTENT_FLAG_ALL 16382
	!define CERT_QUERY_FORMAT_FLAG_ALL 14
	!define CERT_STORE_PROV_SYSTEM 10
	!define CERT_STORE_OPEN_EXISTING_FLAG 0x4000
	!define CERT_SYSTEM_STORE_LOCAL_MACHINE 0x20000
	!define CERT_STORE_ADD_ALWAYS 4
	!define AddCertToStore "!insertmacro _AddCertToStore"
	!macro _AddCertToStore _RESULT _CERT
		Push `${_CERT}`
		Call AddCertToStore
		Pop `${_RESULT}`	;= 0 = success | 1-3 on failure
	!macroend
	Exch $0
	Push $1
	Push $R0
	System::Call "crypt32::CryptQueryObject(i ${CERT_QUERY_OBJECT_FILE}, w r0, \
		i ${CERT_QUERY_CONTENT_FLAG_ALL}, i ${CERT_QUERY_FORMAT_FLAG_ALL}, \
		i 0, i 0, i 0, i 0, i 0, i 0, *i .r0) i .R0"
	${If} $R0 <> 0
		System::Call "crypt32::CertOpenStore(i ${CERT_STORE_PROV_SYSTEM}, i 0, i 0, \
			i ${CERT_STORE_OPEN_EXISTING_FLAG}|${CERT_SYSTEM_STORE_LOCAL_MACHINE}, \
			w 'ROOT') i .r1"
		${If} $1 <> 0
			System::Call "crypt32::CertAddCertificateContextToStore(i r1, i r0, \
				i ${CERT_STORE_ADD_ALWAYS}, i 0) i .R0"
			System::Call "crypt32::CertFreeCertificateContext(i r0)"
			${If} $R0 = 0
				StrCpy $0 3
			${Else}
				StrCpy $0 0
			${EndIf}
			System::Call "crypt32::CertCloseStore(i r1, i 0)"
		${Else}
			System::Call "crypt32::CertFreeCertificateContext(i r0)"
			StrCpy $0 2
		${EndIf}
	${Else}
		StrCpy $0 1
	${EndIf}
	Pop $R0
	Pop $1
	Exch $0
FunctionEnd
!endif ; ADDCERTTOSTORE_NSH_INCLUDED
