;=# 
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin
; 
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; PortableAppsCompilerDefines.nsh
; This file was generated automatically by the PortableApps Compiler.
; It's also created as well as deleted for each new creation process.
; 
!define PORTABLEAPPNAME	`7-Zip Portable`
!define FULLNAME		`7-Zip`
!define APPNAME			`7-ZipPortable`
!define PACKAGE_VERSION	`16.4.0.0`
!define APP				`7-Zip`
!define APPDIR			`$EXEDIR\bin\${APP}`
!define 32				`7-Zip\7zFM.exe`
!define EXE32			`$EXEDIR\bin\${32}`
!define SET32			`Kernel32::SetEnvironmentVariable(t '7-ZIP', t '7-Zip')`
!define APP64			`7-Zip64`
!define APPDIR64		`$EXEDIR\bin\${APP64}`
!define 64				`7-Zip64\7zFM.exe`
!define EXE64			`$EXEDIR\bin\${64}`
!define SET64			`Kernel32::SetEnvironmentVariable(t '7-ZIP', t '7-Zip64')`
!define DEVELOPER		`daemon.devin`
!define PUBLISHER		`Igor Pavlov`
!define OUTFILE			`7-ZipPortable.exe`
!define REPLACE
!define IsFileLocked
!ifndef CloseWindow
	!define CloseWindow
!endif
!define Include_WinMessages
!define TrimString
!define CloseProc
!define 64.nsh
!define UAC
!define HYBRID
!define REGISTRY
!define SYSTEMWIDE_DISABLEREDIR
!define ExecAsUser
!define REGISTERDLL
