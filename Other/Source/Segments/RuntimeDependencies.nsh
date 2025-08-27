;=#
; 
; PORTABLEAPPS COMPILER
; Developed by daemon.devin (daemon.devin@gmail.com)
;
; For support, visit the GitHub project:
; https://github.com/daemondevin/pac-man
; 
; SEGMENT
; RuntimeDependencies.nsh
;   This file handles Visual C++ Redistributables and .NET Framework/Core dependencies
;   with automatic detection, installation, and cleanup for portable applications.
; 
; USAGE
;	Add sections [VCRuntime1], [NETRuntime1] etc. to Launcher.ini
;
; VCRuntime Keys:
;	Version         -	VC++ version (2005, 2008, 2010, 2012, 2013, 2015, 2017, 2019, 2022)
;	Architecture    -	x86, x64, or both
;	Mode            -	detect, install, or bundle
;	Action          -	skip, warn, install, or bundle
;	Source          -	Path to redistributable installer (for bundle mode)
;	MinVersion      -	Minimum acceptable version (optional)
;	Required        -	true/false - whether app requires this runtime
;
; NETRuntime Keys:
;	Framework       -	net20, net35, net40, net45, net46, net47, net48, net50, net60, net70, net80
;	Architecture    -	x86, x64, anycpu, or both
;	Mode            -	detect, install, or bundle  
;	Action          -	skip, warn, install, or bundle
;	Source          -	Path to .NET installer (for bundle mode)
;	MinVersion      -	Minimum acceptable version (optional)
;	Required        -	true/false - whether app requires this runtime
;
; EXAMPLE
;	[VCRuntime1]
;	Version=2019
;	Architecture=x64
;	Mode=detect
;	Action=warn
;	Required=true
;	MinVersion=14.28.29913
;
;	[NETRuntime1]
;	Framework=net48
;	Architecture=anycpu
;	Mode=detect
;	Action=install
;	Required=true
;	MinVersion=4.8.04084
;

!ifdef RUNTIMEDEPENDENCIES
!ifndef LOGICLIB
	!include LogicLib.nsh
!endif
!ifndef WORDREPLACE_NSH_INCLUDED
	!include WordReplace.nsh
!endif
!ifndef STR_CASE_NSH_INCLUDED
	!include StrCase.nsh
!endif

; Runtime detection and management macros

; Check if specific VC++ runtime is installed
!define VCRuntime::IsInstalled `!insertmacro _VCRuntime::IsInstalled`
!macro _VCRuntime::IsInstalled _VERSION _ARCH _RESULT _INSTALLED_VERSION
	Push $0
	Push $1
	Push $2
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_INSTALLED_VERSION} ""
	
	; Determine registry key based on version and architecture
	${Switch} "${_VERSION}"
		${Case} "2005"
			${If} "${_ARCH}" == "x86"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{7299052b-02a4-4627-81f2-1818da5d550d}"
				StrCpy $R9 "8.0.56336"
			${ElseIf} "${_ARCH}" == "x64"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{071c9b48-7c32-4621-a0ac-3f809523288f}"
				StrCpy $R9 "8.0.56336"
			${EndIf}
			${Break}
			
		${Case} "2008"
			${If} "${_ARCH}" == "x86"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{9A25302D-30C0-39D9-BD6F-21E6EC160475}"
				StrCpy $R9 "9.0.30729"
			${ElseIf} "${_ARCH}" == "x64"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8220EEFE-38CD-377E-8595-13398D740ACE}"
				StrCpy $R9 "9.0.30729"
			${EndIf}
			${Break}
			
		${Case} "2010"
			${If} "${_ARCH}" == "x86"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{196BB40D-1578-3D01-B289-BEFC77A11A1E}"
				StrCpy $R9 "10.0.40219"
			${ElseIf} "${_ARCH}" == "x64"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{DA5E371C-6333-3D8A-93A4-6FD5B20BCC6E}"
				StrCpy $R9 "10.0.40219"
			${EndIf}
			${Break}
			
		${Case} "2012"
			${If} "${_ARCH}" == "x86"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{33d1fd90-4274-48a1-9bc1-97e33d9c2d6f}"
				StrCpy $R9 "11.0.61030"
			${ElseIf} "${_ARCH}" == "x64"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{ca67548a-5ebe-413a-b50c-4b9ceb6d66c6}"
				StrCpy $R9 "11.0.61030"
			${EndIf}
			${Break}
			
		${Case} "2013"
			${If} "${_ARCH}" == "x86"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{f65db027-aff3-4070-886a-0d87064aabb1}"
				StrCpy $R9 "12.0.40664"
			${ElseIf} "${_ARCH}" == "x64"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{050d4fc8-5d48-4b8f-8972-47c82c46020f}"
				StrCpy $R9 "12.0.40664"
			${EndIf}
			${Break}
			
		${Case} "2015"
		${Case} "2017"
		${Case} "2019"
		${Case} "2022"
			; Universal C Runtime (these versions use the same redistributable)
			${If} "${_ARCH}" == "x86"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{e2803110-78b3-4664-a479-3611a381656a}"
				StrCpy $R9 "14.0.24215"
			${ElseIf} "${_ARCH}" == "x64"
				StrCpy $R8 "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{d992c12e-cab2-426f-bde3-fb8c53950b0d}"
				StrCpy $R9 "14.0.24215"
			${EndIf}
			${Break}
			
		${Default}
			${DebugMsg} "Unknown VC++ runtime version: ${_VERSION}"
			Goto VCRuntimeCheckEnd
			${Break}
	${EndSwitch}
	
	; Check if the runtime is installed
	ClearErrors
	ReadRegStr $0 HKLM "$R8" "DisplayVersion"
	${IfNot} ${Errors}
		StrCpy ${_RESULT} "true"
		StrCpy ${_INSTALLED_VERSION} "$0"
		${DebugMsg} "VC++ ${_VERSION} ${_ARCH} runtime found: version $0"
	${Else}
		; Try alternative registry locations
		ClearErrors
		ReadRegStr $0 HKLM "SOFTWARE\Microsoft\VisualStudio\${_VERSION}\VC\Runtimes\${_ARCH}" "Version"
		${IfNot} ${Errors}
			StrCpy ${_RESULT} "true"
			StrCpy ${_INSTALLED_VERSION} "$0"
			${DebugMsg} "VC++ ${_VERSION} ${_ARCH} runtime found via alternative method: version $0"
		${Else}
			${DebugMsg} "VC++ ${_VERSION} ${_ARCH} runtime not found"
		${EndIf}
	${EndIf}
	
	VCRuntimeCheckEnd:
	Pop $R9
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check if .NET Framework/Core is installed
!define NETRuntime::IsInstalled `!insertmacro _NETRuntime::IsInstalled`
!macro _NETRuntime::IsInstalled _FRAMEWORK _ARCH _RESULT _INSTALLED_VERSION
	Push $0
	Push $1
	Push $2
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_INSTALLED_VERSION} ""
	
	${Switch} "${_FRAMEWORK}"
		${Case} "net20"
			ReadRegStr $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Version"
			${IfNot} ${Errors}
				StrCpy ${_RESULT} "true"
				StrCpy ${_INSTALLED_VERSION} "$0"
				${DebugMsg} ".NET Framework 2.0 found: version $0"
			${EndIf}
			${Break}
			
		${Case} "net35"
			ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Install"
			${If} $0 == 1
				ReadRegStr $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Version"
				StrCpy ${_RESULT} "true"
				StrCpy ${_INSTALLED_VERSION} "$1"
				${DebugMsg} ".NET Framework 3.5 found: version $1"
			${EndIf}
			${Break}
			
		${Case} "net40"
			ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Install"
			${If} $0 == 1
				ReadRegStr $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Version"
				StrCpy ${_RESULT} "true"
				StrCpy ${_INSTALLED_VERSION} "$1"
				${DebugMsg} ".NET Framework 4.0 found: version $1"
			${EndIf}
			${Break}
			
		${Case} "net45"
		${Case} "net46"
		${Case} "net47"
		${Case} "net48"
			; .NET Framework 4.5+ detection via release number
			ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release"
			${If} $0 >= 378389
				ReadRegStr $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Version"
				StrCpy ${_RESULT} "true"
				StrCpy ${_INSTALLED_VERSION} "$1"
				${DebugMsg} ".NET Framework 4.5+ found: version $1, release $0"
			${EndIf}
			${Break}
			
		${Case} "net50"
		${Case} "net60"
		${Case} "net70"
		${Case} "net80"
			; .NET Core/.NET 5+ detection
			${WordReplace} "${_FRAMEWORK}" "net" "" "+" $R8
			${If} "${_ARCH}" == "x64"
			${OrIf} "${_ARCH}" == "anycpu"
				ReadRegStr $0 HKLM "SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedhost" "Version"
			${Else}
				ReadRegStr $0 HKLM "SOFTWARE\dotnet\Setup\InstalledVersions\x86\sharedhost" "Version"
			${EndIf}
			${IfNot} ${Errors}
				; Check if version matches or is higher
				${VersionCheck} $0 "$R8.0" $R9
				${If} $R9 >= 0
					StrCpy ${_RESULT} "true"
					StrCpy ${_INSTALLED_VERSION} "$0"
					${DebugMsg} ".NET $R8+ found: version $0"
				${EndIf}
			${EndIf}
			${Break}
			
		${Default}
			${DebugMsg} "Unknown .NET framework: ${_FRAMEWORK}"
			${Break}
	${EndSwitch}
	
	Pop $R9
	Pop $R8
	Pop $2
	Pop $1
	Pop $0
!macroend

; Compare version strings
!define VersionCheck `!insertmacro _VersionCheck`
!macro _VersionCheck _VER1 _VER2 _RESULT
	Push $0
	Push $1
	Push $2
	Push $3
	Push $4
	Push $5
	
	; Split versions into components
	${WordReplace} "${_VER1}" "." "$\n" "+" $0
	${WordReplace} "${_VER2}" "." "$\n" "+" $1
	
	StrCpy $2 0 ; Index
	StrCpy ${_RESULT} 0 ; Equal by default
	
	${Do}
		; Get next component from both versions
		${WordFind} "$0" "$\n" "+$2" $3
		${If} ${Errors}
			StrCpy $3 "0"
		${EndIf}
		
		${WordFind} "$1" "$\n" "+$2" $4
		${If} ${Errors}
			StrCpy $4 "0"
		${EndIf}
		
		; Compare components
		IntCmp $3 $4 0 _VERSION_LESS _VERSION_GREATER
		IntOp $2 $2 + 1
		
		; Continue if components are equal and we have more to compare
		${If} $3 == 0
		${AndIf} $4 == 0
			${ExitDo}
		${EndIf}
		
	${Loop}
	
	Goto _VERSION_CHECK_END
	
	_VERSION_LESS:
		StrCpy ${_RESULT} -1
		Goto _VERSION_CHECK_END
		
	_VERSION_GREATER:
		StrCpy ${_RESULT} 1
		Goto _VERSION_CHECK_END
	
	_VERSION_CHECK_END:
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Install VC++ runtime
!define VCRuntime::Install `!insertmacro _VCRuntime::Install`
!macro _VCRuntime::Install _VERSION _ARCH _SOURCE _RESULT _ERROR
	Push $0
	Push $1
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	; Validate source file exists
	${If} ${FileExists} "${_SOURCE}"
		${DebugMsg} "Installing VC++ ${_VERSION} ${_ARCH} runtime from: ${_SOURCE}"
		
		; Determine installation parameters based on version
		${Switch} "${_VERSION}"
			${Case} "2005"
			${Case} "2008"
			${Case} "2010"
				StrCpy $R8 "/q"
				${Break}
			${Case} "2012"
			${Case} "2013"
			${Case} "2015"
			${Case} "2017"
			${Case} "2019"
			${Case} "2022"
				StrCpy $R8 "/install /quiet /norestart"
				${Break}
			${Default}
				StrCpy $R8 "/install /quiet /norestart"
				${Break}
		${EndSwitch}
		
		; Execute installation
		ExecWait '"${_SOURCE}" $R8' $0
		
		${Switch} $0
			${Case} "0"
				StrCpy ${_RESULT} "true"
				${DebugMsg} "VC++ runtime installed successfully"
				${Break}
			${Case} "3010"
				StrCpy ${_RESULT} "true"
				StrCpy ${_ERROR} "Installation successful, restart required"
				${DebugMsg} "VC++ runtime installed, restart required"
				${Break}
			${Case} "1638"
				StrCpy ${_RESULT} "true"
				StrCpy ${_ERROR} "Another version already installed"
				${DebugMsg} "VC++ runtime: another version already installed"
				${Break}
			${Default}
				StrCpy ${_ERROR} "Installation failed with error code $0"
				${DebugMsg} "VC++ runtime installation failed: $0"
				${Break}
		${EndSwitch}
	${Else}
		StrCpy ${_ERROR} "Source file not found: ${_SOURCE}"
		${DebugMsg} "VC++ runtime source not found: ${_SOURCE}"
	${EndIf}
	
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Install .NET runtime
!define NETRuntime::Install `!insertmacro _NETRuntime::Install`
!macro _NETRuntime::Install _FRAMEWORK _ARCH _SOURCE _RESULT _ERROR
	Push $0
	Push $1
	Push $R8
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${If} ${FileExists} "${_SOURCE}"
		${DebugMsg} "Installing .NET ${_FRAMEWORK} runtime from: ${_SOURCE}"
		
		; Determine installation parameters based on framework
		${Switch} "${_FRAMEWORK}"
			${Case} "net20"
			${Case} "net35"
			${Case} "net40"
			${Case} "net45"
			${Case} "net46"
			${Case} "net47"
			${Case} "net48"
				StrCpy $R8 "/q /norestart"
				${Break}
			${Case} "net50"
			${Case} "net60"
			${Case} "net70"
			${Case} "net80"
				StrCpy $R8 "/install /quiet /norestart"
				${Break}
			${Default}
				StrCpy $R8 "/q /norestart"
				${Break}
		${EndSwitch}
		
		; Execute installation
		ExecWait '"${_SOURCE}" $R8' $0
		
		${Switch} $0
			${Case} "0"
				StrCpy ${_RESULT} "true"
				${DebugMsg} ".NET runtime installed successfully"
				${Break}
			${Case} "3010"
				StrCpy ${_RESULT} "true"
				StrCpy ${_ERROR} "Installation successful, restart required"
				${DebugMsg} ".NET runtime installed, restart required"
				${Break}
			${Case} "1638"
				StrCpy ${_RESULT} "true"
				StrCpy ${_ERROR} "Same or newer version already installed"
				${DebugMsg} ".NET runtime: same or newer version already installed"
				${Break}
			${Default}
				StrCpy ${_ERROR} "Installation failed with error code $0"
				${DebugMsg} ".NET runtime installation failed: $0"
				${Break}
		${EndSwitch}
	${Else}
		StrCpy ${_ERROR} "Source file not found: ${_SOURCE}"
		${DebugMsg} ".NET runtime source not found: ${_SOURCE}"
	${EndIf}
	
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Download runtime from Microsoft
!define Runtime::Download `!insertmacro _Runtime::Download`
!macro _Runtime::Download _TYPE _VERSION _ARCH _DESTINATION _RESULT
	Push $0
	Push $1
	Push $R8
	Push $R9
	
	StrCpy ${_RESULT} "false"
	
	; Determine download URL based on runtime type and version
	${If} "${_TYPE}" == "vcruntime"
		${Switch} "${_VERSION}"
			${Case} "2015"
			${Case} "2017"
			${Case} "2019"
			${Case} "2022"
				${If} "${_ARCH}" == "x86"
					StrCpy $R8 "https://aka.ms/vs/17/release/vc_redist.x86.exe"
				${ElseIf} "${_ARCH}" == "x64"
					StrCpy $R8 "https://aka.ms/vs/17/release/vc_redist.x64.exe"
				${EndIf}
				${Break}
			${Default}
				${DebugMsg} "No download URL available for VC++ ${_VERSION}"
				Goto _DOWNLOAD_END
				${Break}
		${EndSwitch}
	${ElseIf} "${_TYPE}" == "dotnet"
		${Switch} "${_FRAMEWORK}"
			${Case} "net48"
				StrCpy $R8 "https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP48-x86-x64-AllOS-ENU.exe"
				${Break}
			${Case} "net60"
				${If} "${_ARCH}" == "x64"
					StrCpy $R8 "https://download.microsoft.com/download/c/6/0/c60c6e9e-11a9-43cf-b9e9-4d48b8b8eeae/dotnet-runtime-6.0-win-x64.exe"
				${Else}
					StrCpy $R8 "https://download.microsoft.com/download/c/6/0/c60c6e9e-11a9-43cf-b9e9-4d48b8b8eeae/dotnet-runtime-6.0-win-x86.exe"
				${EndIf}
				${Break}
			${Default}
				${DebugMsg} "No download URL available for .NET ${_FRAMEWORK}"
				Goto _DOWNLOAD_END
				${Break}
		${EndSwitch}
	${EndIf}
	
	${DebugMsg} "Downloading runtime from: $R8"
	
	; Use NSISdl or inetc to download
	NSISdl::download "$R8" "${_DESTINATION}"
	Pop $0
	${If} $0 == "success"
		StrCpy ${_RESULT} "true"
		${DebugMsg} "Runtime downloaded successfully to: ${_DESTINATION}"
	${Else}
		${DebugMsg} "Download failed: $0"
	${EndIf}
	
	_DOWNLOAD_END:
	Pop $R9
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Generate user-friendly error messages
!define Runtime::ShowMessage `!insertmacro _Runtime::ShowMessage`
!macro _Runtime::ShowMessage _TYPE _VERSION _ARCH _ACTION _ERROR
	Push $0
	Push $1
	
	${If} "${_TYPE}" == "vcruntime"
		StrCpy $0 "Visual C++ ${_VERSION} ${_ARCH} Redistributable"
	${Else}
		StrCpy $0 ".NET ${_VERSION} Runtime"
	${EndIf}
	
	${Switch} "${_ACTION}"
		${Case} "missing"
			MessageBox MB_OK|MB_ICONEXCLAMATION "Missing Runtime Dependency$\n$\nThe application requires $0 which is not installed on this system.$\n$\nPlease install this runtime and try again."
			${Break}
		${Case} "version"
			MessageBox MB_OK|MB_ICONEXCLAMATION "Outdated Runtime Version$\n$\nThe application requires $0 version ${_ERROR} or newer.$\n$\nPlease update this runtime and try again."
			${Break}
		${Case} "install_failed"
			MessageBox MB_OK|MB_ICONERROR "Runtime Installation Failed$\n$\nFailed to install $0.$\n$\nError: ${_ERROR}$\n$\nPlease install manually and try again."
			${Break}
		${Case} "download_failed"
			MessageBox MB_OK|MB_ICONERROR "Runtime Download Failed$\n$\nFailed to download $0.$\n$\nPlease check your internet connection or install manually."
			${Break}
		${Default}
			MessageBox MB_OK|MB_ICONINFORMATION "Runtime Information$\n$\n$0: ${_ERROR}"
			${Break}
	${EndSwitch}
	
	Pop $1
	Pop $0
!macroend

; Advanced runtime management macros

; Check if Windows Feature needs to be enabled (e.g., .NET 3.5 on Windows 10+)
!define Runtime::CheckWindowsFeature `!insertmacro _Runtime::CheckWindowsFeature`
!macro _Runtime::CheckWindowsFeature _FEATURE _RESULT
	Push $0
	Push $1
	Push $R8
	
	StrCpy ${_RESULT} "unknown"
	
	; Use DISM to check Windows feature status
	ExecWait 'dism /online /get-featureinfo /featurename:"${_FEATURE}"' $0
	${Switch} $0
		${Case} "0"
			; Feature command succeeded, need to parse output
			StrCpy ${_RESULT} "available"
			${Break}
		${Case} "87"
			; Feature not found
			StrCpy ${_RESULT} "not_available"
			${Break}
		${Default}
			; Other error
			StrCpy ${_RESULT} "error"
			${Break}
	${EndSwitch}
	
	Pop $R8
	Pop $1
	Pop $0
!macroend

; Enable Windows Feature
!define Runtime::EnableWindowsFeature `!insertmacro _Runtime::EnableWindowsFeature`
!macro _Runtime::EnableWindowsFeature _FEATURE _RESULT _ERROR
	Push $0
	Push $1
	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${DebugMsg} "Enabling Windows feature: ${_FEATURE}"
	ExecWait 'dism /online /enable-feature /featurename:"${_FEATURE}" /all /norestart' $0
	
	${Switch} $0
		${Case} "0"
			StrCpy ${_RESULT} "true"
			${DebugMsg} "Windows feature enabled successfully: ${_FEATURE}"
			${Break}
		${Case} "3010"
			StrCpy ${_RESULT} "true"
			StrCpy ${_ERROR} "Feature enabled, restart required"
			${DebugMsg} "Windows feature enabled, restart required: ${_FEATURE}"
			${Break}
		${Default}
			StrCpy ${_ERROR} "Failed to enable feature, error code: $0"
			${DebugMsg} "Failed to enable Windows feature ${_FEATURE}: $0"
			${Break}
	${EndSwitch}
	
	Pop $1
	Pop $0
!macroend

; Detect Windows version for compatibility checking
!define Runtime::GetWindowsVersion `!insertmacro _Runtime::GetWindowsVersion`
!macro _Runtime::GetWindowsVersion _MAJOR _MINOR _BUILD _PRODUCT
	Push $0
	Push $1
	Push $2
	Push $3
	
	ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentVersion"
	ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
	ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName"
	
	; Parse major.minor version
	${WordFind} "$0" "." "1{" $3
	StrCpy ${_MAJOR} "$3"
	${WordFind} "$0" "." "2{" $3
	StrCpy ${_MINOR} "$3"
	StrCpy ${_BUILD} "$1"
	StrCpy ${_PRODUCT} "$2"
	
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Check runtime compatibility with Windows version
!define Runtime::CheckCompatibility `!insertmacro _Runtime::CheckCompatibility`
!macro _Runtime::CheckCompatibility _TYPE _VERSION _RESULT _REASON
	Push $0
	Push $1
	Push $2
	Push $3
	
	StrCpy ${_RESULT} "compatible"
	StrCpy ${_REASON} ""
	
	; Get Windows version
	${Runtime::GetWindowsVersion} $0 $1 $2 $3
	
	${If} "${_TYPE}" == "vcruntime"
		; VC++ 2005-2008 might have issues on Windows 11
		${If} $0 >= 10
		${AndIf} $2 >= 22000
			${If} "${_VERSION}" == "2005"
			${OrIf} "${_VERSION}" == "2008"
				StrCpy ${_RESULT} "warning"
				StrCpy ${_REASON} "Older VC++ runtimes may have compatibility issues on Windows 11"
			${EndIf}
		${EndIf}
	${ElseIf} "${_TYPE}" == "dotnet"
		; .NET Framework 1.x-3.x compatibility issues on Windows 10+
		${If} $0 >= 10
			${If} "${_VERSION}" == "net20"
			${OrIf} "${_VERSION}" == "net35"
				${If} $2 >= 10240 ; Windows 10 build
					StrCpy ${_RESULT} "warning"
					StrCpy ${_REASON} ".NET 2.0/3.5 requires Windows Features to be enabled on Windows 10+"
				${EndIf}
			${EndIf}
		${EndIf}
		
		; .NET 5+ doesn't support older Windows versions
		${If} "${_VERSION}" == "net50"
		${OrIf} "${_VERSION}" == "net60"
		${OrIf} "${_VERSION}" == "net70"
		${OrIf} "${_VERSION}" == "net80"
			${If} $0 < 10
				StrCpy ${_RESULT} "incompatible"
				StrCpy ${_REASON} ".NET 5+ requires Windows 10 or later"
			${ElseIf} $0 == 10
			${AndIf} $2 < 17763 ; Windows 10 1809
				StrCpy ${_RESULT} "warning"
				StrCpy ${_REASON} ".NET 5+ works best on Windows 10 1809 or later"
			${EndIf}
		${EndIf}
	${EndIf}
	
	Pop $3
	Pop $2
	Pop $1
	Pop $0
!macroend

; Generate runtime summary report
!define Runtime::GenerateReport `!insertmacro _Runtime::GenerateReport`
!macro _Runtime::GenerateReport _FILEPATH
	Push $0
	Push $1
	Push $2
	Push $R0
	Push $R8
	Push $R9
	
	FileOpen $0 "${_FILEPATH}" w
	${If} $0 != ""
		FileWrite $0 "Runtime Dependencies Report$\r$\n"
		FileWrite $0 "Generated: $DATE $TIME$\r$\n"
		FileWrite $0 "================================$\r$\n$\r$\n"
		
		; VC++ Runtime Report
		FileWrite $0 "Visual C++ Runtimes:$\r$\n"
		FileWrite $0 "-------------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 VCRuntime$R0 Version
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $2 VCRuntime$R0 Architecture
			
			${If} $2 == "both"
				${VCRuntime::IsInstalled} $1 "x86" $R8 $R9
				${If} $R8 == "true"
					FileWrite $0 "VC++ $1 x86: $R9$\r$\n"
				${Else}
					FileWrite $0 "VC++ $1 x86: Not installed$\r$\n"
				${EndIf}
				
				${VCRuntime::IsInstalled} $1 "x64" $R8 $R9
				${If} $R8 == "true"
					FileWrite $0 "VC++ $1 x64: $R9$\r$\n"
				${Else}
					FileWrite $0 "VC++ $1 x64: Not installed$\r$\n"
				${EndIf}
			${Else}
				${VCRuntime::IsInstalled} $1 $2 $R8 $R9
				${If} $R8 == "true"
					FileWrite $0 "VC++ $1 $2: $R9$\r$\n"
				${Else}
					FileWrite $0 "VC++ $1 $2: Not installed$\r$\n"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		FileWrite $0 "$\r$\n.NET Runtimes:$\r$\n"
		FileWrite $0 "-------------$\r$\n"
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $1 NETRuntime$R0 Framework
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $2 NETRuntime$R0 Architecture
			
			${If} $2 == "anycpu"
				${If} ${RunningX64}
					StrCpy $2 "x64"
				${Else}
					StrCpy $2 "x86"
				${EndIf}
			${EndIf}
			
			${NETRuntime::IsInstalled} $1 $2 $R8 $R9
			${If} $R8 == "true"
				FileWrite $0 ".NET $1: $R9$\r$\n"
			${Else}
				FileWrite $0 ".NET $1: Not installed$\r$\n"
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		FileClose $0
		${DebugMsg} "Runtime report generated: ${_FILEPATH}"
	${Else}
		${DebugMsg} "Failed to create runtime report file: ${_FILEPATH}"
	${EndIf}
	
	Pop $R9
	Pop $R8
	Pop $R0
	Pop $2
	Pop $1
	Pop $0
!macroend
${SegmentFile}

;= Enable runtime dependencies segment
!define RUNTIMEDEPENDENCIES_ENABLED

;= Check and handle VC++ Runtime dependencies
${SegmentPre}
	!ifdef RUNTIMEDEPENDENCIES_ENABLED
		${DebugMsg} "Checking Visual C++ runtime dependencies..."
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 VCRuntime$R0 Version
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 VCRuntime$R0 Architecture
			${ReadLauncherConfig} $2 VCRuntime$R0 Mode
			${ReadLauncherConfig} $3 VCRuntime$R0 Action
			${ReadLauncherConfig} $4 VCRuntime$R0 Required
			${ReadLauncherConfig} $5 VCRuntime$R0 MinVersion
			${ReadLauncherConfig} $6 VCRuntime$R0 Source
			
			${DebugMsg} "Processing VC++ runtime: $0 $1"
			
			; Handle both architectures if specified
			${If} $1 == "both"
				StrCpy $R7 "x86"
				Goto _PROCESS_VCRUNTIME
				StrCpy $R7 "x64"
				Goto _PROCESS_VCRUNTIME
			${Else}
				StrCpy $R7 $1
				Goto _PROCESS_VCRUNTIME
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		Goto _VCRUNTIME_COMPLETE
		
		_PROCESS_VCRUNTIME:
			${VCRuntime::IsInstalled} $0 $R7 $R8 $R9
			
			${If} $R8 == "true"
				${DebugMsg} "VC++ $0 $R7 is installed: version $R9"
				
				; Check minimum version if specified
				${If} $5 != ""
					${VersionCheck} $R9 $5 $R6
					${If} $R6 < 0
						${DebugMsg} "Installed version $R9 is older than required $5"
						${If} $3 == "warn"
							${Runtime::ShowMessage} "vcruntime" $0 $R7 "version" $5
						${ElseIf} $3 == "install"
						${OrIf} $3 == "bundle"
							; Attempt to upgrade
							${If} $6 != ""
								${ParseLocations} $6
								${VCRuntime::Install} $0 $R7 $6 $R8 $R6
								${If} $R8 != "true"
									${Runtime::ShowMessage} "vcruntime" $0 $R7 "install_failed" $R6
									${If} $4 == "true"
										${WriteRuntimeData} RuntimeErrors VCRuntime$R0 "version_failed"
									${EndIf}
								${EndIf}
							${EndIf}
						${EndIf}
					${EndIf}
				${EndIf}
			${Else}
				${DebugMsg} "VC++ $0 $R7 is not installed"
				
				${Switch} $3
					${Case} "skip"
						${DebugMsg} "Skipping missing VC++ runtime as requested"
						${Break}
					${Case} "warn"
						${If} $4 == "true"
							${Runtime::ShowMessage} "vcruntime" $0 $R7 "missing" ""
						${EndIf}
						${Break}
					${Case} "install"
						${If} $6 != ""
							${ParseLocations} $6
							${VCRuntime::Install} $0 $R7 $6 $R8 $R6
							${If} $R8 != "true"
								${Runtime::ShowMessage} "vcruntime" $0 $R7 "install_failed" $R6
								${If} $4 == "true"
									${WriteRuntimeData} RuntimeErrors VCRuntime$R0 "install_failed"
								${EndIf}
							${EndIf}
						${Else}
							${DebugMsg} "No source specified for VC++ runtime installation"
							${If} $4 == "true"
								${Runtime::ShowMessage} "vcruntime" $0 $R7 "missing" ""
							${EndIf}
						${EndIf}
						${Break}
					${Case} "bundle"
						${If} $6 != ""
							${ParseLocations} $6
							${VCRuntime::Install} $0 $R7 $6 $R8 $R6
							${If} $R8 != "true"
								${Runtime::ShowMessage} "vcruntime" $0 $R7 "install_failed" $R6
								${If} $4 == "true"
									${WriteRuntimeData} RuntimeErrors VCRuntime$R0 "install_failed"
								${EndIf}
							${EndIf}
						${Else}
							; Try to download and install
							StrCpy $R6 "$TEMP\vcredist_$0_$R7.exe"
							${If} $R8 == "true"
								${VCRuntime::Install} $0 $R7 $R6 $R8 $R9
								Delete "$R6" ; Clean up downloaded file
								${If} $R8 != "true"
									${Runtime::ShowMessage} "vcruntime" $0 $R7 "install_failed" $R9
									${If} $4 == "true"
										${WriteRuntimeData} RuntimeErrors VCRuntime$R0 "download_install_failed"
									${EndIf}
								${EndIf}
							${Else}
								${Runtime::ShowMessage} "vcruntime" $0 $R7 "download_failed" ""
								${If} $4 == "true"
									${WriteRuntimeData} RuntimeErrors VCRuntime$R0 "download_failed"
								${EndIf}
							${EndIf}
						${EndIf}
						${Break}
					${Default}
						${DebugMsg} "Unknown action for VC++ runtime: $3"
						${Break}
				${EndSwitch}
			${EndIf}
			Return
		
		_VCRUNTIME_COMPLETE:
		${DebugMsg} "VC++ runtime dependency check completed."
	!endif
!macroend

;= Check and handle .NET Runtime dependencies
${SegmentPrePrimary}
	!ifdef RUNTIMEDEPENDENCIES_ENABLED
		${DebugMsg} "Checking .NET runtime dependencies..."
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 NETRuntime$R0 Framework
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 NETRuntime$R0 Architecture
			${ReadLauncherConfig} $2 NETRuntime$R0 Mode
			${ReadLauncherConfig} $3 NETRuntime$R0 Action
			${ReadLauncherConfig} $4 NETRuntime$R0 Required
			${ReadLauncherConfig} $5 NETRuntime$R0 MinVersion
			${ReadLauncherConfig} $6 NETRuntime$R0 Source
			
			${DebugMsg} "Processing .NET runtime: $0 $1"
			
			; Handle architecture-specific checks
			${If} $1 == "both"
				StrCpy $R7 "x86"
				Goto _PROCESS_NETRUNTIME
				StrCpy $R7 "x64"
				Goto _PROCESS_NETRUNTIME
			${ElseIf} $1 == "anycpu"
				; Check the native architecture
				${If} ${BitDepth} 64
					StrCpy $R7 "x64"
				${Else}
					StrCpy $R7 "x86"
				${EndIf}
				Goto _PROCESS_NETRUNTIME
			${Else}
				StrCpy $R7 $1
				Goto _PROCESS_NETRUNTIME
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		Goto _NETRUNTIME_COMPLETE
		
		_PROCESS_NETRUNTIME:
			${NETRuntime::IsInstalled} $0 $R7 $R8 $R9
			
			${If} $R8 == "true"
				${DebugMsg} ".NET $0 is installed: version $R9"
				
				; Check minimum version if specified
				${If} $5 != ""
					${VersionCheck} $R9 $5 $R6
					${If} $R6 < 0
						${DebugMsg} "Installed .NET version $R9 is older than required $5"
						${If} $3 == "warn"
							${Runtime::ShowMessage} "dotnet" $0 $R7 "version" $5
						${ElseIf} $3 == "install"
						${OrIf} $3 == "bundle"
							; Attempt to upgrade
							${If} $6 != ""
								${ParseLocations} $6
								${NETRuntime::Install} $0 $R7 $6 $R8 $R6
								${If} $R8 != "true"
									${Runtime::ShowMessage} "dotnet" $0 $R7 "install_failed" $R6
									${If} $4 == "true"
										${WriteRuntimeData} RuntimeErrors NETRuntime$R0 "version_failed"
									${EndIf}
								${EndIf}
							${EndIf}
						${EndIf}
					${EndIf}
				${EndIf}
			${Else}
				${DebugMsg} ".NET $0 is not installed"
				
				${Switch} $3
					${Case} "skip"
						${DebugMsg} "Skipping missing .NET runtime as requested"
						${Break}
					${Case} "warn"
						${If} $4 == "true"
							${Runtime::ShowMessage} "dotnet" $0 $R7 "missing" ""
						${EndIf}
						${Break}
					${Case} "install"
						${If} $6 != ""
							${ParseLocations} $6
							${NETRuntime::Install} $0 $R7 $6 $R8 $R6
							${If} $R8 != "true"
								${Runtime::ShowMessage} "dotnet" $0 $R7 "install_failed" $R6
								${If} $4 == "true"
									${WriteRuntimeData} RuntimeErrors NETRuntime$R0 "install_failed"
								${EndIf}
							${EndIf}
						${Else}
							${DebugMsg} "No source specified for .NET runtime installation"
							${If} $4 == "true"
								${Runtime::ShowMessage} "dotnet" $0 $R7 "missing" ""
							${EndIf}
						${EndIf}
						${Break}
					${Case} "bundle"
						${If} $6 != ""
							${ParseLocations} $6
							${NETRuntime::Install} $0 $R7 $6 $R8 $R6
							${If} $R8 != "true"
								${Runtime::ShowMessage} "dotnet" $0 $R7 "install_failed" $R6
								${If} $4 == "true"
									${WriteRuntimeData} RuntimeErrors NETRuntime$R0 "install_failed"
								${EndIf}
							${EndIf}
						${Else}
							; Try to download and install
							StrCpy $R6 "$TEMP\dotnet_$0_$R7.exe"
							${Runtime::Download} "dotnet" $0 $R7 $R6 $R8
							${If} $R8 == "true"
								${NETRuntime::Install} $0 $R7 $R6 $R8 $R9
								Delete "$R6" ; Clean up downloaded file
								${If} $R8 != "true"
									${Runtime::ShowMessage} "dotnet" $0 $R7 "install_failed" $R9
									${If} $4 == "true"
										${WriteRuntimeData} RuntimeErrors NETRuntime$R0 "download_install_failed"
									${EndIf}
								${EndIf}
							${Else}
								${Runtime::ShowMessage} "dotnet" $0 $R7 "download_failed" ""
								${If} $4 == "true"
									${WriteRuntimeData} RuntimeErrors NETRuntime$R0 "download_failed"
								${EndIf}
							${EndIf}
						${EndIf}
						${Break}
					${Default}
						${DebugMsg} "Unknown action for .NET runtime: $3"
						${Break}
				${EndSwitch}
			${EndIf}
			Return
		
		_NETRUNTIME_COMPLETE:
		${DebugMsg} ".NET runtime dependency check completed."
		
		; Check if any critical runtime errors occurred
		${ReadRuntimeData} $R8 RuntimeErrors VCRuntime1
		${ReadRuntimeData} $R9 RuntimeErrors NETRuntime1
		${If} $R8 != ""
		${OrIf} $R9 != ""
			${DebugMsg} "Critical runtime dependencies failed - some features may not work"
			; Application can decide whether to continue or abort
		${EndIf}
	!endif
!macroend

;= Runtime cleanup and validation
${SegmentPostPrimary}
	!ifdef RUNTIMEDEPENDENCIES_ENABLED
		${DebugMsg} "Validating runtime dependencies post-execution..."
		
		; Verify that critical runtimes are still available after app execution
		; This helps detect if the app somehow corrupted or uninstalled runtimes
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 VCRuntime$R0 Version
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 VCRuntime$R0 Architecture
			${ReadLauncherConfig} $4 VCRuntime$R0 Required
			
			${If} $4 == "true"
				${If} $1 == "both"
					${VCRuntime::IsInstalled} $0 "x86" $R8 $R9
					${VCRuntime::IsInstalled} $0 "x64" $R7 $R6
					${If} $R8 != "true"
					${AndIf} $R7 != "true"
						${DebugMsg} "Warning: Critical VC++ runtime $0 no longer detected"
					${EndIf}
				${Else}
					${VCRuntime::IsInstalled} $0 $1 $R8 $R9
					${If} $R8 != "true"
						${DebugMsg} "Warning: Critical VC++ runtime $0 $1 no longer detected"
					${EndIf}
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
		
		; Same validation for .NET runtimes
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 NETRuntime$R0 Framework
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${ReadLauncherConfig} $1 NETRuntime$R0 Architecture
			${ReadLauncherConfig} $4 NETRuntime$R0 Required
			
			${If} $4 == "true"
				${If} $1 == "anycpu"
					${If} ${BitDepth} 64
						StrCpy $1 "x64"
					${Else}
						StrCpy $1 "x86"
					${EndIf}
				${EndIf}
				
				${NETRuntime::IsInstalled} $0 $1 $R8 $R9
				${If} $R8 != "true"
					${DebugMsg} "Warning: Critical .NET runtime $0 no longer detected"
				${EndIf}
			${EndIf}
			
			IntOp $R0 $R0 + 1
		${Loop}
	!endif
!macroend

;= Final cleanup
${SegmentUnload}
	!ifdef RUNTIMEDEPENDENCIES_ENABLED
		${DebugMsg} "Cleaning up runtime dependency data..."
		
		; Clean up any temporary runtime error tracking
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 VCRuntime$R0 Version
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${DeleteRuntimeData} RuntimeErrors VCRuntime$R0
			IntOp $R0 $R0 + 1
		${Loop}
		
		StrCpy $R0 1
		${Do}
			ClearErrors
			${ReadLauncherConfig} $0 NETRuntime$R0 Framework
			${IfThen} ${Errors} ${|} ${ExitDo} ${|}
			
			${DeleteRuntimeData} RuntimeErrors NETRuntime$R0
			IntOp $R0 $R0 + 1
		${Loop}
		
		${DebugMsg} "Runtime dependencies cleanup completed."
	!endif
!macroend

!endif
