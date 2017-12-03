;=#
; 
; PORTABLEAPPS COMPILER 
; Developed by daemon.devin
;
; For support visit the GitHub project:
; https://github.com/demondevin/pac-man
; 
; SEGMENT
;   Java.nsh
;   This file enables support for using Java or JDK.
; 

${SegmentFile}
${SegmentInit}
	ClearErrors
	${ReadWrapperConfig} $JavaMode Activate Java
	${If} $JavaMode == find
	${OrIf} $JavaMode == require
		!ifmacrodef JAVA
			!insertmacro JAVA
		!else
			StrCpy $JavaDirectory $PortableAppsDirectory\CommonFiles\Java
		!endif
		${IfNot} ${FileExists} $JavaDirectory
			ClearErrors
			ReadRegStr $0 HKLM "Software\JavaSoft\Java Runtime Environment" CurrentVersion
			ReadRegStr $JavaDirectory HKLM "Software\JavaSoft\Java Runtime Environment\$0" JavaHome
			${If} ${Errors}
			${OrIfNot} ${FileExists} $JavaDirectory\bin\java.exe
			${AndIfNot} ${FileExists} $JavaDirectory\bin\javaw.exe
				ClearErrors
				ReadEnvStr $JavaDirectory JAVA_HOME
				${If} ${Errors}
				${OrIfNot} ${FileExists} $JavaDirectory\bin\java.exe
				${AndIfNot} ${FileExists} $JavaDirectory\bin\javaw.exe
					ClearErrors
					SearchPath $JavaDirectory java.exe
					${IfNot} ${Errors}
						${GetParent} $JavaDirectory $JavaDirectory
						${GetParent} $JavaDirectory $JavaDirectory
					${Else}
						StrCpy $JavaDirectory $WINDIR\Java
						${IfNot} ${FileExists} $JavaDirectory\bin\java.exe
						${AndIfNot} ${FileExists} $JavaDirectory\bin\javaw.exe
							StrCpy $JavaDirectory $PortableAppsDirectory\CommonFiles\Java
						${EndIf}
					${EndIf}
				${EndIf}
			${EndIf}
		${EndIf}
		${If} $JavaMode == require
			${IfNot} ${FileExists} $JavaDirectory
				MessageBox MB_OK|MB_ICONSTOP `$(LauncherNoJava)`
				Quit
			${EndIf}
			${IfThen} $ProgramExecutable == java.exe ${|} StrCpy $UsingJavaExecutable true ${|}
			${IfThen} $ProgramExecutable == javaw.exe ${|} StrCpy $UsingJavaExecutable true ${|}
			${If} $UsingJavaExecutable == true
			${AndIfNot} ${FileExists} $JavaDirectory\bin\$ProgramExecutable
				MessageBox MB_OK|MB_ICONSTOP `$(LauncherNoJava)`
				Quit
			${EndIf}
		${EndIf}
		${SetEnvironmentVariablesPath} JAVA_HOME $JavaDirectory
	${ElseIfNot} ${Errors}
		${InvalidValueError} [Activate]:Java $JavaMode
	${EndIf}
!macroend
