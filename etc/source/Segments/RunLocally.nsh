;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   RunLocally.nsh
;   This file enables support for copying the package to a local directory and executing from there.
; 

Var RunLocally
${SegmentFile}
${SegmentInit}
	${ReadUserConfig} $RunLocally RunLocally
!macroend
${SegmentPre}
	${If} $RunLocally == true
		ReadEnvStr $R0 TMP
		ClearErrors
		${ReadWrapperConfig} $0 LiveMode CopyApp
		${If} $0 == true
		${OrIf} ${Errors}
			StrCmpS $SecondaryLaunch true +3
			CreateDirectory `$R0\${APPNAME}Live`
			CopyFiles /SILENT `$EXEDIR\App` `$R0\${APPNAME}Live`
			StrCpy $AppDirectory `$R0\${APPNAME}Live\bin`
		${ElseIf} $0 != false
			${InvalidValueError} [LiveMode]:CopyApp $0
		${EndIf}
		StrCmpS $SecondaryLaunch true +3
		CreateDirectory `$R0\${APPNAME}Live`
		CopyFiles /SILENT `${SET}` `$R0\${APPNAME}Live`
		StrCpy $DataDirectory `$R0\${APPNAME}Live\bin\Settings`
		${If} ${FileExists} `$R0\${APPNAME}Live`
			${SetFileAttributesDirectoryNormal} `$R0\${APPNAME}Live`
		${EndIf}
		${SetEnvironmentVariablesPath} PAC:AppDir $AppDirectory
		${SetEnvironmentVariablesPath} PAC:DataDir $DataDirectory
		StrCmpS $SecondaryLaunch true +2
		StrCpy $WaitForProgram true
	${EndIf}
	CreateDirectory $DataDirectory
!macroend
${SegmentPostPrimary}
	StrCmp $RunLocally true +3
	ReadEnvStr $R0 TMP
	RMDir /r `$R0\${APPNAME}Live`
!macroend
