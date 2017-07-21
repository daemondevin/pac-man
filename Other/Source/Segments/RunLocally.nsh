Var RunLocally
${SegmentFile}
${SegmentInit}
	${ReadUserConfig} $RunLocally RunLocally
!macroend
${SegmentPre}
	${If} $RunLocally == true
		ReadEnvStr $R0 TMP
		ClearErrors
		${ReadLauncherConfig} $0 LiveMode CopyApp
		${If} $0 == true
		${OrIf} ${Errors}
			StrCmpS $SecondaryLaunch true +3
			CreateDirectory `$R0\${APPNAME}Live`
			CopyFiles /SILENT `$EXEDIR\App` `$R0\${APPNAME}Live`
			StrCpy $AppDirectory `$R0\${APPNAME}Live\App`
		${ElseIf} $0 != false
			${InvalidValueError} [LiveMode]:CopyApp $0
		${EndIf}
		StrCmpS $SecondaryLaunch true +3
		CreateDirectory `$R0\${APPNAME}Live`
		CopyFiles /SILENT `${DATA}` `$R0\${APPNAME}Live`
		StrCpy $DataDirectory `$R0\${APPNAME}Live\Data`
		${If} ${FileExists} `$R0\${APPNAME}Live`
			${SetFileAttributesDirectoryNormal} `$R0\${APPNAME}Live`
		${EndIf}
		${SetEnvironmentVariablesPath} PAL:AppDir $AppDirectory
		${SetEnvironmentVariablesPath} PAL:DataDir $DataDirectory
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
