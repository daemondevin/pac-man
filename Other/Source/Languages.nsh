;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
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
${IncludeLang} English
${IncludeLang} Armenian
${IncludeLang} Bulgarian
${IncludeLang} Danish
${IncludeLang} Dutch
${IncludeLang} Estonian
${IncludeLang} Finnish
${IncludeLang} French
${IncludeLang} Galician
${IncludeLang} German
${IncludeLang} Hebrew
${IncludeLang} Hungarian
${IncludeLang} Indonesian
${IncludeLang} Italian
${IncludeLang} Japanese
${IncludeLang} Polish
${IncludeLang} Portuguese
${IncludeLang} PortugueseBR
${IncludeLang} Romanian
${IncludeLang} SimpChinese
${IncludeLang} Slovenian
${IncludeLang} Spanish
${IncludeLang} Sundanese
${IncludeLang} Swedish
${IncludeLang} Thai
${IncludeLang} TradChinese
${IncludeLang} Turkish
${IncludeLang} Vietnamese

; Use the Case statements formed above.
; Used in Segments/Language.nsh
!macro LanguageCases
	!include "${LangAutoDetectFile}"
	!delfile "${LangAutoDetectFile}"
	!undef LangAutoDetectFile
!macroend
