
!ifndef _XML_LIB_
	!define _XML_LIB_

	!define XMLWriteText "!insertmacro _XMLWriteText"
	!macro _XMLWriteText _FILE _XPATH _VALUE
		nsisXML::create
		nsisXML::load `${_FILE}`
		nsisXML::select `${_XPATH}`
		IntCmp $2 0 0 +3 +3
			SetErrors
			Goto +5
		nsisXML::setText `${_VALUE}`
		nsisXML::release $1
		nsisXML::save `${_FILE}`
		nsisXML::release $0
	!macroend

	!define XMLReadText "!insertmacro _XMLReadText"
	!macro _XMLReadText _FILE _XPATH _RETURN
		nsisXML::create
		nsisXML::load `${_FILE}`
		nsisXML::select `${_XPATH}`
		IntCmp $2 0 0 +4 +4
			StrCpy `${_RETURN}` error
			SetErrors
			Goto +6
		nsisXML::GetText
		StrCpy `${_RETURN}` $3
		nsisXML::release $1
		nsisXML::save `${_FILE}`
		nsisXML::release $0
	!macroend

	!define XMLWriteAttrib "!insertmacro _XMLWriteAttrib"
	!macro _XMLWriteAttrib _FILE _XPATH _ATTRIBUTE _VALUE
		nsisXML::create
		nsisXML::load `${_FILE}`
		nsisXML::select `${_XPATH}`
		IntCmp $2 0 0 +3 +3
			SetErrors
			Goto +5
		nsisXML::setAttribute `${_ATTRIBUTE}` `${_VALUE}`
		nsisXML::release $1
		nsisXML::save `${_FILE}`
		nsisXML::release $0
	!macroend

	!define XMLReadAttrib "!insertmacro _XMLReadAttrib"
	!macro _XMLReadAttrib _FILE _XPATH _ATTRIBUTE _RETURN
		nsisXML::create
		nsisXML::load `${_FILE}`
		nsisXML::select `${_XPATH}`
		IntCmp $2 0 0 +4 +4
			StrCpy `${_RETURN}` error
			SetErrors
			Goto +6
		nsisXML::getAttribute `${_ATTRIBUTE}`
		StrCpy `${_RETURN}` $3
		nsisXML::release $1
		nsisXML::save `${_FILE}`
		nsisXML::release $0
	!macroend
	
!endif ; _XML_LIB_
