; Internal PortableApps.com Launcher languages for message boxes etc.
; The language is set in Segments/Language.nsh (but all the addition of
; languages is done in this file).

!tempfile LangAutoDetectFile
!macro IncludeLang _LANG
	LoadLanguageFile "${NSISDIR}\Contrib\Language files\${_LANG}.nlf"
	!insertmacro LANGFILE_INCLUDE_WITHDEFAULT Languages\${_LANG}.nsh Languages\English.nsh
	!appendfile "${LangAutoDetectFile}" "${Case} ${LANG_${_LANG}}$\n"
!macroend
!define IncludeLang "!insertmacro IncludeLang"
	${IncludeLang} ARABIC
	${IncludeLang} CATALAN
	${IncludeLang} CZECH
	${IncludeLang} ENGLISH
	${IncludeLang} FRENCH
	${IncludeLang} GERMAN
	${IncludeLang} GREEK
	${IncludeLang} HEBREW
	${IncludeLang} HUNGARIAN
	${IncludeLang} ITALIAN
	${IncludeLang} KOREAN
	${IncludeLang} POLISH
	${IncludeLang} PORTUGUESE
	${IncludeLang} RUSSIAN
	${IncludeLang} SIMPCHINESE
	${IncludeLang} SLOVENIAN
	${IncludeLang} SPANISH
	${IncludeLang} SWEDISH
	${IncludeLang} TRADCHINESE
	${IncludeLang} TURKISH
	${IncludeLang} UKRAINIAN
!macro LanguageCases
	!include "${LangAutoDetectFile}"
	!delfile "${LangAutoDetectFile}"
	!undef LangAutoDetectFile
!macroend
