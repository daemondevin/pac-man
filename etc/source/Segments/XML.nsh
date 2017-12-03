;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; XML.nsh
; This file enables supports for allowing XML features. Refer to the segments FileWrite.nsh and Language.nsh.
; 

!ifdef XML_ENABLED
	!include XML.nsh
	!ifndef PLUGINSDIR
		!define PLUGINSDIR
		!AddPluginDir Plugins
	!endif
!endif

${SegmentFile}
!macro XML_WarnNotActivated Section
	MessageBox MB_OK|MB_ICONSTOP "To use the XML features you must set [Activate]:XML=true and then regenerate the wrapper.${NEWLINE}${NEWLINE}Current launch will continue but the ${Section} will not be used."
!macroend
