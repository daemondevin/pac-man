;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Languages.nsh
;   This file handles the internal languages for message boxes, etc.
; 
; NOTE
;   The language is set in the Language.nsh segment.
;   However, the addition of languages is done using this file.
; 
 
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
	${IncludeLang} DUTCH
	${IncludeLang} ENGLISH
	${IncludeLang} FARSI
	${IncludeLang} FINNISH
	${IncludeLang} FRENCH
	${IncludeLang} GERMAN
	${IncludeLang} GREEK
	${IncludeLang} HUNGARIAN
	${IncludeLang} ITALIAN
	${IncludeLang} JAPANESE
	${IncludeLang} KOREAN
	${IncludeLang} POLISH
	${IncludeLang} PORTUGUESE
	${IncludeLang} PORTUGUESEBR
	${IncludeLang} RUSSIAN
	${IncludeLang} SIMPCHINESE
	${IncludeLang} SLOVENIAN
	${IncludeLang} SPANISH
	${IncludeLang} SWEDISH
	${IncludeLang} TRADCHINESE
	${IncludeLang} TURKISH
	${IncludeLang} VIETNAMESE
!macro LanguageCases
	!include "${LangAutoDetectFile}"
	!delfile "${LangAutoDetectFile}"
	!undef LangAutoDetectFile
!macroend
