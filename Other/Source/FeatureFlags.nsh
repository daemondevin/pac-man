;=#
;
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
;
; FeatureFlags.nsh
;	Normalizes every feature flag to one canonical SEGMENTS_* name.
;
;	The wizard (LauncherCompiler.nsi), command-line mode (GlobalCLDefines.nsh),
;	older GlobalDefines.nsh files and individual segments have used different
;	names for the same feature over time. This file is included right after
;	the package defines are loaded and maps every known alias both ways so a
;	segment can test either the canonical name or its legacy alias.
;
;	Canonical flags:
;		SEGMENTS_UAC            SEGMENTS_REGISTRY       SEGMENTS_SERVICES
;		SEGMENTS_REGDLL         SEGMENTS_TASKS          SEGMENTS_JAVA
;		SEGMENTS_XML            SEGMENTS_GHOSTSCRIPT    SEGMENTS_FONTS
;		SEGMENTS_ASSOCIATIONS   SEGMENTS_RUNTIME        SEGMENTS_DRIVERS
;		SEGMENTS_FIREWALL       SEGMENTS_SYMLINKS       SEGMENTS_HOSTS
;		SEGMENTS_DIRECTX        SEGMENTS_DOTNET         SEGMENTS_EXEC_AS_USER
;		SEGMENTS_MISSINGAPP
;

!ifndef FEATURE_FLAGS_NSH_INCLUDED
!define FEATURE_FLAGS_NSH_INCLUDED

; Define the canonical flag when any of its legacy aliases is present.
!macro _FF_Canonical _CANON _ALIAS
	!ifdef ${_ALIAS}
		!ifndef ${_CANON}
			!define ${_CANON}
		!endif
	!endif
!macroend
!define FF_Canonical "!insertmacro _FF_Canonical"

; Define a legacy alias when the canonical flag is present, for segments
; that still test the old name.
!macro _FF_Alias _CANON _ALIAS
	!ifdef ${_CANON}
		!ifndef ${_ALIAS}
			!define ${_ALIAS}
		!endif
	!endif
!macroend
!define FF_Alias "!insertmacro _FF_Alias"

; Legacy names (wizard, command-line mode, old segments) -> canonical
${FF_Canonical} SEGMENTS_UAC            UAC
${FF_Canonical} SEGMENTS_REGISTRY       REGISTRY
${FF_Canonical} SEGMENTS_SERVICES       SERVICES
${FF_Canonical} SEGMENTS_REGDLL         REGISTERDLL
${FF_Canonical} SEGMENTS_TASKS          TASKSCHEDULER
${FF_Canonical} SEGMENTS_JAVA           JAVA
${FF_Canonical} SEGMENTS_XML            XML_PLUGIN
${FF_Canonical} SEGMENTS_XML            XML_ENABLED
${FF_Canonical} SEGMENTS_GHOSTSCRIPT    GHOSTSCRIPT
${FF_Canonical} SEGMENTS_FONTS          FONTS_ENABLE
${FF_Canonical} SEGMENTS_FONTS          FONTS_ENABLED
${FF_Canonical} SEGMENTS_ASSOCIATIONS   ASSOCIATIONS
${FF_Canonical} SEGMENTS_ASSOCIATIONS   FILEASSOCIATIONS
${FF_Canonical} SEGMENTS_DRIVERS        DRIVERS
${FF_Canonical} SEGMENTS_FIREWALL       FIREWALL
${FF_Canonical} SEGMENTS_SYMLINKS       SYMBOLICJUNCTIONS
${FF_Canonical} SEGMENTS_SYMLINKS       SYMLINKSJUNCTIONS
${FF_Canonical} SEGMENTS_DIRECTX        DIRECTX
${FF_Canonical} SEGMENTS_DOTNET         DOTNET
${FF_Canonical} SEGMENTS_EXEC_AS_USER   EXEC_AS_USER
${FF_Canonical} SEGMENTS_EXEC_AS_USER   ExecAsUser

; Canonical -> legacy aliases still tested inside segments
${FF_Alias} SEGMENTS_UAC            UAC
${FF_Alias} SEGMENTS_JAVA           JAVA
${FF_Alias} SEGMENTS_XML            XML_ENABLED
${FF_Alias} SEGMENTS_DRIVERS        DRIVERS
${FF_Alias} SEGMENTS_DIRECTX        DIRECTX
${FF_Alias} SEGMENTS_DOTNET         DOTNET
${FF_Alias} SEGMENTS_EXEC_AS_USER   EXEC_AS_USER
${FF_Alias} SEGMENTS_EXEC_AS_USER   ExecAsUser
${FF_Alias} DISABLEFSR              DisableFSR

; Feature dependencies
!ifdef SEGMENTS_UAC
	!ifndef TrimString
		!define TrimString
	!endif
!endif
!ifdef SEGMENTS_RUNTIME
	!ifndef TrimString
		!define TrimString
	!endif
!endif
; Ghostscript and the journal's registry helpers use the registry plugin macros
!ifdef SEGMENTS_GHOSTSCRIPT
	!ifndef SEGMENTS_REGISTRY
		!define SEGMENTS_REGISTRY
	!endif
!endif

!endif ; FEATURE_FLAGS_NSH_INCLUDED
