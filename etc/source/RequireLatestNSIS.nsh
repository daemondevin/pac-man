;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
;
; RequireLatestNSIS.nsh
; This file will make sure the latest build of NSIS is being used.
; 

!searchparse /noerrors "${NSIS_VERSION}" v _RLNSIS_TEMP b _RLNSIS_TEMP
!searchparse /noerrors "${_RLNSIS_TEMP}" "" _RLNSIS_TEMP - _RLNSIS_TEMP
!searchparse /noerrors "${_RLNSIS_TEMP}" "" _RLNSIS_TEMP . _RLNSIS_TEMP
!if "${_RLNSIS_TEMP}" < 3
	!searchparse /noerrors "${NSIS_VERSION}" v _RLNSIS_TEMP b _RLNSIS_TEMP
	!searchparse /noerrors "${_RLNSIS_TEMP}" "" _RLNSIS_TEMP - _RLNSIS_TEMP
	!error "ERROR: You only have NSIS ${_RLNSIS_TEMP}! NSIS 3.0 or later is required. Please upgrade your NSIS package to atleast version 3.0."
!endif
!undef _RLNSIS_TEMP
