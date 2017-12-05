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
	${IncludeLang} AFRIKAANS
	${IncludeLang} AZERBAIJANI
	${IncludeLang} BELARUSIAN
	${IncludeLang} BULGARIAN
	${IncludeLang} CATALAN
	${IncludeLang} CZECH
	${IncludeLang} WELSH
	${IncludeLang} DANISH
	${IncludeLang} GERMAN
	${IncludeLang} GREEK
	${IncludeLang} ENGLISH
	${IncludeLang} ESPERANTO
	${IncludeLang} SPANISH
	${IncludeLang} ESTONIAN
	${IncludeLang} BASQUE
	${IncludeLang} FARSI
	${IncludeLang} FINNISH
	${IncludeLang} FRENCH
	${IncludeLang} IRISH
	${IncludeLang} GALICIAN
	${IncludeLang} GUJARATI
	${IncludeLang} HEBREW
	${IncludeLang} HINDI
	${IncludeLang} CROATIAN
	${IncludeLang} HUNGARIAN
	${IncludeLang} ARMENIAN
	${IncludeLang} INDONESIAN
	${IncludeLang} ICELANDIC
	${IncludeLang} ITALIAN
	${IncludeLang} JAPANESE
	${IncludeLang} GEORGIAN
	${IncludeLang} KOREAN
	${IncludeLang} LITHUANIAN
	${IncludeLang} KURDISH
	${IncludeLang} LATVIAN
	${IncludeLang} MACEDONIAN
	${IncludeLang} MONGOLIAN
	${IncludeLang} MARATHI
	${IncludeLang} MALAY
	${IncludeLang} NORWEGIAN
	${IncludeLang} NEPALI
	${IncludeLang} DUTCH
	${IncludeLang} NORWEGIANNYNORSK
	${IncludeLang} PUNJABI
	${IncludeLang} POLISH
	${IncludeLang} PORTUGUESE
	${IncludeLang} PORTUGUESEBR
	${IncludeLang} ROMANIAN
	${IncludeLang} RUSSIAN
	${IncludeLang} SINHALESE
	${IncludeLang} SLOVAK
	${IncludeLang} SLOVENIAN
	${IncludeLang} ALBANIAN
	${IncludeLang} SERBIAN
	${IncludeLang} SERBIANLATIN
	${IncludeLang} SWEDISH
	${IncludeLang} TAMIL
	${IncludeLang} THAI
	${IncludeLang} TURKISH
	${IncludeLang} UKRAINIAN
	${IncludeLang} VALENCIAN
	${IncludeLang} VIETNAMESE
	${IncludeLang} SIMPCHINESE
	${IncludeLang} TRADCHINESE
!macro LanguageCases
	!include "${LangAutoDetectFile}"
	!delfile "${LangAutoDetectFile}"
	!undef LangAutoDetectFile
!macroend
