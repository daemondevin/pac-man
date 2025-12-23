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
;	Architecture    -	x86, x64, or amd64
;	Mode            -	detect, install, or bundle
;	Action          -	skip, warn, install, or bundle
;	Installer       -	Name of the redistributable installer (for bundle mode)
;	MinVersion      -	Minimum acceptable version (optional)
;	Required        -	true/false - whether app requires this runtime
;
; NETRuntime Keys:
;	Framework       -	net20, net35, net40, net45, net46, net47, net48, net50, net60, net70, net80
;	Architecture    -	x86, x64, amd64, or anycpu
;	Mode            -	detect, install, or bundle  
;	Action          -	skip, warn, install, or bundle
;	Installer          -	Name of the .NET installer (for bundle mode)
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


!ifdef SEGMENTS_RUNTIME

;= VARIABLES
Var VCVersion
Var VCFramework
Var VCArchitecture
Var VCMode
Var VCAction
Var VCRequired
Var VCMinVersion
Var VCInstaller
Var VCGUID
Var NETVersion
Var NETFramework
Var NETArchitecture
Var NETMode
Var NETAction
Var NETRequired
Var NETMinVersion
Var NETInstaller
Var ExpectedVersion
Var InstalledVersion
Var DownloadResult
Var CompareResult
Var InstallResult
Var IsInstalled
Var SkipCheck

;= INCLUDES
!ifndef LOGICLIB
    !include LogicLib.nsh
!endif

;= MACROS
; Generate user-friendly error messages
!define Runtime::ShowMessage `!insertmacro _Runtime::ShowMessage`
!macro _Runtime::ShowMessage _TYPE _VERSION _ARCH _ACTION _ERROR
	${If} "${_TYPE}" == "vcruntime"
		StrCpy $R1 "Visual C++ ${_VERSION} ${_ARCH} Redistributable"
	${Else}
		StrCpy $R1 ".NET ${_VERSION} Runtime"
	${EndIf}
	${Switch} "${_ACTION}"
		${Case} "missing"
			MessageBox MB_OK|MB_ICONEXCLAMATION "Missing Runtime Dependency$\n$\nThe application requires $R1 which is not installed on this system.$\n$\nPlease install this runtime and try again."
			${Break}
		${Case} "version"
			MessageBox MB_OK|MB_ICONEXCLAMATION "Outdated Runtime Version$\n$\nThe application requires $R1 version ${_ERROR} or newer.$\n$\nPlease update this runtime and try again."
			${Break}
		${Case} "install_failed"
			MessageBox MB_OK|MB_ICONSTOP "Runtime Installation Failed$\n$\nFailed to install $R1.$\n$\nError: ${_ERROR}$\n$\nPlease install manually and try again."
			${Break}
		${Case} "download_failed"
			MessageBox MB_OK|MB_ICONSTOP "Runtime Download Failed$\n$\nFailed to download $R1.$\n$\nPlease check your internet connection or install manually."
			${Break}
		${Default}
			MessageBox MB_OK|MB_ICONINFORMATION "Runtime Information$\n$\n$R1: ${_ERROR}"
			${Break}
	${EndSwitch}
!macroend
; Install VC++ runtime
!define VCRuntime::Install `!insertmacro _VCRuntime::Install`
!macro _VCRuntime::Install _VERSION _ARCH _INSTALLER _RESULT _ERROR
	; Initialize outputs
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""

	; Check if installer exists
	${If} ${FileExists} "${_INSTALLER}"
		${DebugMsg} "Installing VC++ ${_VERSION} (${_ARCH}) runtime from: ${_INSTALLER}"

		; Define command line based on version (kept optional for flexibility)
		${If} ${_VERSION} == "2005"
			StrCpy $R7 "/q"
		${ElseIf} ${_VERSION} == "2008"
			StrCpy $R7 "/q"
		${ElseIf} ${_VERSION} == "2010"
			StrCpy $R7 "/q"
		${Else}
			StrCpy $R7 "/install /quiet /norestart"
		${EndIf}

		; Execute runtime installer silently
        Push $0
		nsExec::ExecToStack '"${_INSTALLER}" $R7'
		Pop $0 ; exit code

		; Interpret exit codes
		${Switch} $0
			${Case} 0
				StrCpy ${_RESULT} "true"
				${DebugMsg} "VC++ ${_VERSION} runtime installed successfully."
				${Break}

			${Case} 3010
				StrCpy ${_RESULT} "true"
				StrCpy ${_ERROR} "Installation successful, restart required."
				${DebugMsg} "VC++ runtime installed (restart required)."
				${Break}

			${Case} 1638
				StrCpy ${_RESULT} "true"
				StrCpy ${_ERROR} "A newer or same version is already installed."
				${DebugMsg} "VC++ runtime already installed."
				${Break}

			${Case} 1603
				StrCpy ${_ERROR} "Fatal installation error (1603)."
				${DebugMsg} "VC++ runtime fatal error 1603."
				${Break}

			${Case} 1618
				StrCpy ${_ERROR} "Another installation is in progress (1618)."
				${DebugMsg} "VC++ runtime installation blocked by concurrent process."
				${Break}

			${Default}
				StrCpy ${_ERROR} "Installation failed with exit code $0."
				${DebugMsg} "VC++ runtime installation failed with exit code $0."
				${Break}
		${EndSwitch}

	${Else}
		StrCpy ${_ERROR} "Installer file not found: ${_INSTALLER}"
		${DebugMsg} "VC++ runtime installer missing at ${_INSTALLER}."
	${EndIf}
!macroend
; Install .NET runtime
!define NETRuntime::Install `!insertmacro _NETRuntime::Install`
!macro _NETRuntime::Install _FRAMEWORK _ARCH _INSTALLER _RESULT _ERROR	
	StrCpy ${_RESULT} "false"
	StrCpy ${_ERROR} ""
	
	${If} ${FileExists} "${_INSTALLER}"
		${DebugMsg} "Installing .NET ${_FRAMEWORK} runtime from: ${_INSTALLER}"
		
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
        Push $0
        nsExec::ExecToStack '"${_INSTALLER}" $R8'
		Pop $0 ; exit code
		
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
		StrCpy ${_ERROR} "Source file not found: ${_INSTALLER}"
		${DebugMsg} ".NET runtime source not found: ${_INSTALLER}"
	${EndIf}
!macroend

;= FUNCTIONS
; Check if specific VC++ runtime is installed
Function IsVCRuntimeInstalled
	!define VCRuntime::IsInstalled `!insertmacro _VCRuntime::IsInstalled`
	!macro _VCRuntime::IsInstalled _VERSION _ARCH _RESULT _INSTALLED_VERSION
		Push "${_VERSION}"
		Push "${_ARCH}"
		Call IsVCRuntimeInstalled
		Pop ${_RESULT}  			; Version string
		Pop ${_INSTALLED_VERSION}	; "true" or "false"
	!macroend

  Exch $1	; _ARCH
  Exch
  Exch $0	; _VERSION
  Push $2
  Push $3
  Push $4
  Push $5
  Push $R8	; Registry key
  Push $R9	; Expected minimum version
  
  StrCpy $R0 "false"
  StrCpy $R1 ""
  
  ; Determine registry key and expected version based on VC++ version
  ${Switch} "$0"
    ${Case} "2005"
      ${If} "$1" == "x86"
        StrCpy $R8 "{7299052b-02a4-4627-81f2-1818da5d550d}"
        StrCpy $R9 "8.0.56336"
      ${ElseIf} "$1" == "x64"
        StrCpy $R8 "{071c9b48-7c32-4621-a0ac-3f809523288f}"
        StrCpy $R9 "8.0.56336"
      ${Else}
        Goto _VCRUNTIME_CHECK_END
      ${EndIf}
      ${Break}
      
    ${Case} "2008"
      ${If} "$1" == "x86"
        StrCpy $R8 "{9A25302D-30C0-39D9-BD6F-21E6EC160475}"
        StrCpy $R9 "9.0.30729"
      ${ElseIf} "$1" == "x64"
        StrCpy $R8 "{8220EEFE-38CD-377E-8595-13398D740ACE}"
        StrCpy $R9 "9.0.30729"
      ${Else}
        Goto _VCRUNTIME_CHECK_END
      ${EndIf}
      ${Break}
      
    ${Case} "2010"
      ${If} "$1" == "x86"
        StrCpy $R8 "{196BB40D-1578-3D01-B289-BEFC77A11A1E}"
        StrCpy $R9 "10.0.40219"
      ${ElseIf} "$1" == "x64"
        StrCpy $R8 "{DA5E371C-6333-3D8A-93A4-6FD5B20BCC6E}"
        StrCpy $R9 "10.0.40219"
      ${Else}
        Goto _VCRUNTIME_CHECK_END
      ${EndIf}
      ${Break}
      
    ${Case} "2012"
      ${If} "$1" == "x86"
        StrCpy $R8 "{33d1fd90-4274-48a1-9bc1-97e33d9c2d6f}"
        StrCpy $R9 "11.0.61030"
      ${ElseIf} "$1" == "x64"
        StrCpy $R8 "{ca67548a-5ebe-413a-b50c-4b9ceb6d66c6}"
        StrCpy $R9 "11.0.61030"
      ${Else}
        Goto _VCRUNTIME_CHECK_END
      ${EndIf}
      ${Break}
      
    ${Case} "2013"
      ${If} "$1" == "x86"
        StrCpy $R8 "{f65db027-aff3-4070-886a-0d87064aabb1}"
        StrCpy $R9 "12.0.40664"
      ${ElseIf} "$1" == "x64"
        StrCpy $R8 "{050d4fc8-5d48-4b8f-8972-47c82c46020f}"
        StrCpy $R9 "12.0.40664"
      ${Else}
        Goto _VCRUNTIME_CHECK_END
      ${EndIf}
      ${Break}
      
    ${Case} "2015"
    ${Case} "2017"
    ${Case} "2019"
    ${Case} "2022"
      ; VC++ 2015-2022 all use the same redistributable (v14.x)
      ${If} "$1" == "x86"
        StrCpy $R8 "{e2803110-78b3-4664-a479-3611a381656a}"
        StrCpy $R9 "14.0.24215"
      ${ElseIf} "$1" == "x64"
        StrCpy $R8 "{d992c12e-cab2-426f-bde3-fb8c53950b0d}"
        StrCpy $R9 "14.0.24215"
      ${ElseIf} "$1" == "arm64"
        StrCpy $R8 "{5e791fcf-45a5-40b1-9b78-fb1cf5680841}"
        StrCpy $R9 "14.0.24215"
      ${Else}
        Goto _VCRUNTIME_CHECK_END
      ${EndIf}
      ${Break}
      
    ${Default}
      ; Unknown version
      DetailPrint "Unknown VC++ runtime version: $0"
      Goto _VCRUNTIME_CHECK_END
      ${Break}
  ${EndSwitch}
  
  ; Check registry for installation
  ; Try HKLM first (system-wide installation)
  ${If} "$1" == "x86"
    ${If} ${BitDepth} 64
      ; On 64-bit Windows, check the 32-bit registry view
      SetRegView 32
      ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "Version"
      ${If} $2 == ""
        ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "DisplayVersion"
      ${EndIf}
      SetRegView lastused
    ${Else}
      ; On 32-bit Windows, use default view
      ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "Version"
      ${If} $2 == ""
        ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "DisplayVersion"
      ${EndIf}
    ${EndIf}
  ${ElseIf} "$1" == "x64"
    ${If} ${BitDepth} 64
      ; On 64-bit Windows, check the 64-bit registry view
      SetRegView 64
      ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "Version"
      ${If} $2 == ""
        ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "DisplayVersion"
      ${EndIf}
      SetRegView lastused
    ${Else}
      ; x64 runtime cannot be installed on 32-bit Windows
      Goto _VCRUNTIME_CHECK_END
    ${EndIf}
  ${ElseIf} "$1" == "arm64"
    ; ARM64 runtime check
    SetRegView 64
    ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "Version"
    ${If} $2 == ""
      ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "DisplayVersion"
    ${EndIf}
    SetRegView lastused
  ${EndIf}
  
  ; If not found in HKLM, try HKCU (per-user installation)
  ${If} $2 == ""
    ${If} "$1" == "x86"
      ${If} ${BitDepth} 64
        SetRegView 32
      ${EndIf}
      ReadRegStr $2 HKCU "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "Version"
      ${If} $2 == ""
        ReadRegStr $2 HKCU "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "DisplayVersion"
      ${EndIf}
      ${If} ${BitDepth} 64
        SetRegView lastused
      ${EndIf}
    ${ElseIf} "$1" == "x64"
      ${If} ${BitDepth} 64
        SetRegView 64
        ReadRegStr $2 HKCU "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "Version"
        ${If} $2 == ""
          ReadRegStr $2 HKCU "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "DisplayVersion"
        ${EndIf}
        SetRegView lastused
      ${EndIf}
    ${ElseIf} "$1" == "arm64"
      SetRegView 64
      ReadRegStr $2 HKCU "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "Version"
      ${If} $2 == ""
        ReadRegStr $2 HKCU "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$R8" "DisplayVersion"
      ${EndIf}
      SetRegView lastused
    ${EndIf}
  ${EndIf}
  
  ; Alternative check: Look for the actual DLL files
  ${If} $2 == ""
    ${If} "$1" == "x86"
      ${If} ${FileExists} "$SYSDIR\vcruntime140.dll"
        StrCpy $2 "14.0.0.0" ; Found, but version unknown
      ${ElseIf} ${FileExists} "$SYSDIR\msvcr120.dll"
        StrCpy $2 "12.0.0.0"
      ${ElseIf} ${FileExists} "$SYSDIR\msvcr110.dll"
        StrCpy $2 "11.0.0.0"
      ${ElseIf} ${FileExists} "$SYSDIR\msvcr100.dll"
        StrCpy $2 "10.0.0.0"
      ${ElseIf} ${FileExists} "$SYSDIR\msvcr90.dll"
        StrCpy $2 "9.0.0.0"
      ${ElseIf} ${FileExists} "$SYSDIR\msvcr80.dll"
        StrCpy $2 "8.0.0.0"
      ${EndIf}
    ${ElseIf} "$1" == "x64"
      ${If} ${FileExists} "$WINDIR\System32\vcruntime140.dll"
        StrCpy $2 "14.0.0.0"
      ${ElseIf} ${FileExists} "$WINDIR\System32\msvcr120.dll"
        StrCpy $2 "12.0.0.0"
      ${ElseIf} ${FileExists} "$WINDIR\System32\msvcr110.dll"
        StrCpy $2 "11.0.0.0"
      ${ElseIf} ${FileExists} "$WINDIR\System32\msvcr100.dll"
        StrCpy $2 "10.0.0.0"
      ${ElseIf} ${FileExists} "$WINDIR\System32\msvcr90.dll"
        StrCpy $2 "9.0.0.0"
      ${ElseIf} ${FileExists} "$WINDIR\System32\msvcr80.dll"
        StrCpy $2 "8.0.0.0"
      ${EndIf}
    ${EndIf}
  ${EndIf}
  
  ; Check if version meets minimum requirement
  ${If} $2 != ""
    StrCpy $R1 $2
    
    ; Parse version numbers for comparison (major.minor.build.revision)
    ; Simple string comparison works for most cases
	Push $2
	Push $R9
    Call VersionCheck
	Pop $3
    
    ; $3: 0 = equal, 1 = $2 is newer, 2 = $R9 is newer
    ${If} $3 == 0
    ${OrIf} $3 == 1
      StrCpy $R0 "true"
    ${EndIf}
  ${EndIf}
  
  _VCRUNTIME_CHECK_END:
  Pop $R9
  Pop $R8
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $0
  Pop $1
  Exch $R1 ; Installed version
  Exch
  Exch $R0 ; Result
FunctionEnd

; Check if .NET Framework/Core is installed
Function IsNETRuntimeInstalled
	!define NETRuntime::IsInstalled `!insertmacro _NETRuntime::IsInstalled`
	!macro _NETRuntime::IsInstalled _FRAMEWORK _ARCH _RESULT _INSTALLED_VERSION
		Push "${_FRAMEWORK}"			; _FRAMEWORK
		Push "${_ARCH}"					; _ARCH
		Push "${_RESULT}"				; _RESULT placeholder
		Push "${_INSTALLED_VERSION}"	; _INSTALLED_VERSION placeholder
		Call IsNETRuntimeInstalled
		Pop ${_INSTALLED_VERSION}		; _INSTALLED_VERSION
		Pop ${_RESULT}					; _RESULT ("true" or "false")
	!macroend

	Exch $R9 ; _INSTALLED_VERSION
	Exch
	Exch $R8 ; _RESULT
	Exch
	Exch 2
	Exch $1  ; _ARCH
	Exch
	Exch 3
	Exch $0  ; _FRAMEWORK

	Push $2
	Push $3
	Push $4

	StrCpy $R8 "false"
	StrCpy $R9 ""

	${Switch} "$0"
		${Case} "net20"
			ReadRegStr $2 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Version"
			${IfNot} ${Errors}
				StrCpy $R8 "true"
				StrCpy $R9 "$2"
				; ${DebugMsg} ".NET Framework 2.0 found: version $2"
			${EndIf}
			${Break}

		${Case} "net35"
			ReadRegDWORD $2 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Install"
			${If} $2 == 1
				ReadRegStr $3 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Version"
				StrCpy $R8 "true"
				StrCpy $R9 "$3"
				; ${DebugMsg} ".NET Framework 3.5 found: version $3"
			${EndIf}
			${Break}

		${Case} "net40"
			ReadRegDWORD $2 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Install"
			${If} $2 == 1
				ReadRegStr $3 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Version"
				StrCpy $R8 "true"
				StrCpy $R9 "$3"
				; ${DebugMsg} ".NET Framework 4.0 found: version $3"
			${EndIf}
			${Break}

		${Case} "net45"
		${Case} "net46"
		${Case} "net47"
		${Case} "net48"
			ReadRegDWORD $2 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release"
			${If} $2 >= 378389
				ReadRegStr $3 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Version"
				StrCpy $R8 "true"
				StrCpy $R9 "$3"
				; ${DebugMsg} ".NET Framework 4.5+ found: version $3, release $2"
			${EndIf}
			${Break}

		${Case} "net50"
		${Case} "net60"
		${Case} "net70"
		${Case} "net80"
			${WordReplace} "$0" "net" "" "+" $2
			${If} "$1" == "x64"
			${OrIf} "$1" == "anycpu"
				ReadRegStr $3 HKLM "SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedhost" "Version"
			${Else}
				ReadRegStr $3 HKLM "SOFTWARE\dotnet\Setup\InstalledVersions\x86\sharedhost" "Version"
			${EndIf}
			${IfNot} ${Errors}
				Push $3
				Push "$2.0"
				Call VersionCheck
				Pop $4
				${If} $4 >= 0
					StrCpy $R8 "true"
					StrCpy $R9 "$3"
					; ${DebugMsg} ".NET $2+ found: version $3"
				${EndIf}
			${EndIf}
			${Break}

		${Default}
			; ${DebugMsg} "Unknown .NET framework: $0"
			${Break}
	${EndSwitch}

	Pop $4
	Pop $3
	Pop $2

	Exch $0  ; restore stack order
	Exch 3
	Exch $1
	Exch 2
	Exch $R8
	Exch
	Exch $R9
FunctionEnd

; Compare version strings
Function VersionCheck
	!define Runtime::VersionCheck `!insertmacro _Runtime::VersionCheck`
	!macro _Runtime::VersionCheck _VER1 _VER2 _RESULT
		Push ${_VER1}
		Push ${_VER2}
		Call VersionCheck
		Pop ${_RESULT} ; -1 = first < second, 0 = equal, 1 = first > second
	!macroend

	Exch $1 ; _VER2
	Exch
	Exch $0 ; _VER1
	Push $2
	Push $3
	Push $4
	Push $5
	Push $6

	StrCpy $2 0 ; index
	StrCpy $R0 0 ; result = equal by default

	${WordReplace} "$0" "." "$\n" "+" $3
	${WordReplace} "$1" "." "$\n" "+" $4

	${Do}
	${WordFind} "$3" "$\n" "+$2" $5
	${If} ${Errors}
		StrCpy $5 "0"
		ClearErrors
	${EndIf}

	${WordFind} "$4" "$\n" "+$2" $6
	${If} ${Errors}
		StrCpy $6 "0"
		ClearErrors
	${EndIf}

	; Convert to integers before comparing
	IntCmp $5 $6 0 _VERSION_LESS _VERSION_GREATER
	IntOp $2 $2 + 1

	; Stop if both next components are missing (both 0)
	${If} $5 == 0
	${AndIf} $6 == 0
		${ExitDo}
	${EndIf}

	${Loop}
	Goto _VERSION_END

	_VERSION_LESS:
	StrCpy $R0 -1
	Goto _VERSION_END

	_VERSION_GREATER:
	StrCpy $R0 1

	_VERSION_END:
	Pop $6
	Pop $5
	Pop $4
	Pop $3
	Pop $2
	Pop $1
	Pop $0
FunctionEnd

; Install .NET runtime
Function InstallNETRuntime


    Exch $R9 ; _ERROR
    Exch
    Exch $R8 ; _RESULT
    Exch
    Exch $R7 ; _INSTALLER
    Exch
    Exch $R6 ; _ARCH
    Exch
    Exch $R5 ; _FRAMEWORK
    Push $0
    Push $1

    ; Initialize outputs
    StrCpy $R8 "false"
    StrCpy $R9 ""

    ${If} ${FileExists} "$R7"
        ; ${DebugMsg} "Installing .NET $R5 ($R6) runtime from: $R7"

        ; Select appropriate silent install parameters
        ${Switch} "$R5"
            ${Case} "net20"
            ${Case} "net35"
            ${Case} "net40"
            ${Case} "net45"
            ${Case} "net46"
            ${Case} "net47"
            ${Case} "net48"
                StrCpy $0 "/q /norestart"
                ${Break}

            ${Case} "net50"
            ${Case} "net60"
            ${Case} "net70"
            ${Case} "net80"
                StrCpy $0 "/install /quiet /norestart"
                ${Break}

            ${Default}
                StrCpy $0 "/q /norestart"
                ${Break}
        ${EndSwitch}

        ; Run installer silently
        ExecWait '"$R7" $0' $1

        ; Interpret exit codes
        ${Switch} $1
            ${Case} 0
                StrCpy $R8 "true"
                ; ${DebugMsg} ".NET runtime installed successfully"
                ${Break}

            ${Case} 3010
                StrCpy $R8 "true"
                StrCpy $R9 "Installation successful, restart required"
                ; ${DebugMsg} ".NET runtime installed (restart required)"
                ${Break}

            ${Case} 1638
                StrCpy $R8 "true"
                StrCpy $R9 "A newer or same version already installed"
                ; ${DebugMsg} ".NET runtime already present or newer version installed"
                ${Break}

            ${Case} 1603
                StrCpy $R9 "Fatal installer error (1603)"
                ; ${DebugMsg} ".NET runtime installation fatal error 1603"
                ${Break}

            ${Case} 1618
                StrCpy $R9 "Another installation is already in progress (1618)"
                ; ${DebugMsg} ".NET runtime installer blocked by another installation"
                ${Break}

            ${Case} 5100
                StrCpy $R9 "Unsupported operating system for this .NET version (5100)"
                ; ${DebugMsg} ".NET runtime not supported on this OS version"
                ${Break}

            ${Default}
                StrCpy $R9 "Installation failed with exit code $1"
                ; ${DebugMsg} ".NET runtime installation failed (exit code $1)"
                ${Break}
        ${EndSwitch}
    ${Else}
        StrCpy $R9 "Source file not found: $R7"
        ; ${DebugMsg} ".NET runtime installer missing: $R7"
    ${EndIf}

    ; Return values
    Push $R8 ; result
    Push $R9 ; error

    Pop $1
    Pop $0
    Pop $R5
    Pop $R6
    Pop $R7
    Pop $R8
    Pop $R9
FunctionEnd

; Download runtime from Microsoft
Function DownloadRuntime
	!define Runtime::Download `!insertmacro _Runtime::Download`
	!macro _Runtime::Download _TYPE _VERSION _ARCH _DESTINATION _RESULT
		Push "${_TYPE}"			; _TYPE
		Push "${_VERSION}"		; _VERSION
		Push "${_ARCH}"			; _ARCH
		Push "${_DESTINATION}"	; _DESTINATION
		Push "${_RESULT}"		; _RESULT (placeholder)
		Call DownloadRuntime
		Pop ${_RESULT}			; _RESULT = "true" or "false"
	!macroend
  Exch $R9 ; _RESULT
  Exch
  Exch $R8 ; _DESTINATION
  Exch
  Exch 2
  Exch $1  ; _ARCH
  Exch
  Exch 3
  Exch $0  ; _VERSION
  Exch 4
  Exch $2  ; _TYPE
  Push $3
  Push $4
  Push $5
  
  StrCpy $R9 "false"
  StrCpy $3 ""
  
  ; Determine download URL
  ${If} "$2" == "vcruntime"
    ${Switch} "$0"
      ${Case} "2015"
      ${Case} "2017"
      ${Case} "2019"
      ${Case} "2022"
        ${If} "$1" == "x86"
          StrCpy $3 "https://aka.ms/vs/17/release/vc_redist.x86.exe"
        ${ElseIf} "$1" == "x64"
          StrCpy $3 "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        ${ElseIf} "$1" == "arm64"
          StrCpy $3 "https://aka.ms/vs/17/release/vc_redist.arm64.exe"
        ${Else}
          ; ${DebugMsg} "Unsupported architecture for VC++ runtime: $1"
          Goto DownloadEnd
        ${EndIf}
        ${Break}
      ${Case} "2013"
        ${If} "$1" == "x86"
          StrCpy $3 "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe"
        ${ElseIf} "$1" == "x64"
          StrCpy $3 "https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe"
        ${EndIf}
        ${Break}
      ${Case} "2012"
        ${If} "$1" == "x86"
          StrCpy $3 "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe"
        ${ElseIf} "$1" == "x64"
          StrCpy $3 "https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe"
        ${EndIf}
        ${Break}
      ${Case} "2010"
        ${If} "$1" == "x86"
          StrCpy $3 "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe"
        ${ElseIf} "$1" == "x64"
          StrCpy $3 "https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe"
        ${EndIf}
        ${Break}
      ${Default}
        ; ${DebugMsg} "No download URL for VC++ runtime version: $0"
        Goto DownloadEnd
        ${Break}
    ${EndSwitch}
    
  ${ElseIf} "$2" == "dotnet"
    ${Switch} "$0"
      ${Case} "net48"
        StrCpy $3 "https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP48-x86-x64-AllOS-ENU.exe"
        ${Break}
      ${Case} "net462"
        StrCpy $3 "https://download.microsoft.com/download/F/9/4/F942F07D-F26F-4F30-B4E3-EBD54FABA377/NDP462-KB3151800-x86-x64-AllOS-ENU.exe"
        ${Break}
      ${Case} "net60"
        ${If} "$1" == "x64"
          StrCpy $3 "https://download.visualstudio.microsoft.com/download/pr/5d2a1ebf-2c3f-42d4-9770-7cf8faeb7f1d/2b1e6e5a87cf2df3c4c65d247b7a177a/dotnet-runtime-6.0.36-win-x64.exe"
        ${ElseIf} "$1" == "x86"
          StrCpy $3 "https://download.visualstudio.microsoft.com/download/pr/5d2a1ebf-2c3f-42d4-9770-7cf8faeb7f1d/2b1e6e5a87cf2df3c4c65d247b7a177a/dotnet-runtime-6.0.36-win-x86.exe"
        ${ElseIf} "$1" == "arm64"
          StrCpy $3 "https://download.visualstudio.microsoft.com/download/pr/5d2a1ebf-2c3f-42d4-9770-7cf8faeb7f1d/2b1e6e5a87cf2df3c4c65d247b7a177a/dotnet-runtime-6.0.36-win-arm64.exe"
        ${EndIf}
        ${Break}
      ${Case} "net80"
        ${If} "$1" == "x64"
          StrCpy $3 "https://download.visualstudio.microsoft.com/download/pr/85c04f7e-ec7a-42a3-a23b-9fa1a445b6f9/b741713ef3a8722c7fd6efbaa4e71b96/dotnet-runtime-8.0.11-win-x64.exe"
        ${ElseIf} "$1" == "x86"
          StrCpy $3 "https://download.visualstudio.microsoft.com/download/pr/85c04f7e-ec7a-42a3-a23b-9fa1a445b6f9/b741713ef3a8722c7fd6efbaa4e71b96/dotnet-runtime-8.0.11-win-x86.exe"
        ${ElseIf} "$1" == "arm64"
          StrCpy $3 "https://download.visualstudio.microsoft.com/download/pr/85c04f7e-ec7a-42a3-a23b-9fa1a445b6f9/b741713ef3a8722c7fd6efbaa4e71b96/dotnet-runtime-8.0.11-win-arm64.exe"
        ${EndIf}
        ${Break}
      ${Default}
        ; ${DebugMsg} "No download URL for .NET runtime: $0"
        Goto DownloadEnd
        ${Break}
    ${EndSwitch}
    
  ${Else}
    ; ${DebugMsg} "Unknown runtime type: $2"
    Goto DownloadEnd
  ${EndIf}
  
  ${If} "$3" == ""
    ; ${DebugMsg} "Could not determine download URL"
    Goto DownloadEnd
  ${EndIf}
  
  ; ${DebugMsg} "Downloading $2 $0 ($1) from: $3"
  
  ; Download using inetc plugin
  inetc::get /popup "" /caption "Downloading $2 $0..." "$3" "$R8" /end
  Pop $5
  
  ${If} $5 == "OK"
    StrCpy $R9 "true"
    ; ${DebugMsg} "Downloaded successfully to: $R8"
  ${Else}
    ; ${DebugMsg} "Download failed: $5"
  ${EndIf}
  
  DownloadEnd:
  Pop $5
  Pop $4
  Pop $3
  Exch $2
  Exch 4
  Exch $0
  Exch 3
  Exch $1
  Exch 2
  Exch $R8
  Exch
  Exch $R9
FunctionEnd

${SegmentFile}
${SegmentPre}

	${DebugMsg} "Checking Visual C++ runtime dependencies..."
	StrCpy $R0 1
	${Do}
		ClearErrors
		${ReadLauncherConfig} $VCVersion VCRuntime$R0 Version
		${IfThen} ${Errors} ${|} ${ExitDo} ${|}
		
		${ReadLauncherConfig} $VCArchitecture VCRuntime$R0 Architecture
		${ReadLauncherConfig} $VCMode VCRuntime$R0 Mode
		${ReadLauncherConfig} $VCAction VCRuntime$R0 Action
		${ReadLauncherConfig} $VCRequired VCRuntime$R0 Required
		${ReadLauncherConfig} $VCMinVersion VCRuntime$R0 MinVersion
		${ReadLauncherConfig} $VCInstaller VCRuntime$R0 Installer
		
        ; Reset state variables
        StrCpy $VCGUID ""
        StrCpy $ExpectedVersion ""
        StrCpy $InstalledVersion ""
        StrCpy $IsInstalled ""
        StrCpy $SkipCheck ""
        
		${DebugMsg} "Processing VC++ runtime: $VCVersion $VCArchitecture"

		; Determine registry key and expected version based on VC++ version
        ${Switch} "$VCVersion"

            ${Case} "2005"
                ${If} "$VCArchitecture" == "x86"
                    StrCpy $VCGUID "{7299052b-02a4-4627-81f2-1818da5d550d}"
                ${ElseIf} "$VCArchitecture" == "x64"
                    StrCpy $VCGUID "{071c9b48-7c32-4621-a0ac-3f809523288f}"
                ${EndIf}
                StrCpy $ExpectedVersion "8.0.56336"
                ${Break}

            ${Case} "2008"
                ${If} "$VCArchitecture" == "x86"
                    StrCpy $VCGUID "{9A25302D-30C0-39D9-BD6F-21E6EC160475}"
                ${ElseIf} "$VCArchitecture" == "x64"
                    StrCpy $VCGUID "{8220EEFE-38CD-377E-8595-13398D740ACE}"
                ${EndIf}
                StrCpy $ExpectedVersion "9.0.30729"
                ${Break}

            ${Case} "2010"
                ${If} "$VCArchitecture" == "x86"
                    StrCpy $VCGUID "{196BB40D-1578-3D01-B289-BEFC77A11A1E}"
                ${ElseIf} "$VCArchitecture" == "x64"
                    StrCpy $VCGUID "{DA5E371C-6333-3D8A-93A4-6FD5B20BCC6E}"
                ${EndIf}
                StrCpy $ExpectedVersion "10.0.40219"
                ${Break}

            ${Case} "2012"
                ${If} "$VCArchitecture" == "x86"
                    StrCpy $VCGUID "{33d1fd90-4274-48a1-9bc1-97e33d9c2d6f}"
                ${ElseIf} "$VCArchitecture" == "x64"
                    StrCpy $VCGUID "{ca67548a-5ebe-413a-b50c-4b9ceb6d66c6}"
                ${EndIf}
                StrCpy $ExpectedVersion "11.0.61030"
                ${Break}

            ${Case} "2013"
                ${If} "$VCArchitecture" == "x86"
                    StrCpy $VCGUID "{f65db027-aff3-4070-886a-0d87064aabb1}"
                ${ElseIf} "$VCArchitecture" == "x64"
                    StrCpy $VCGUID "{050d4fc8-5d48-4b8f-8972-47c82c46020f}"
                ${EndIf}
                StrCpy $ExpectedVersion "12.0.40664"
                ${Break}

            ${Case} "2015"
            ${Case} "2017"
            ${Case} "2019"
            ${Case} "2022"
                ${If} "$VCArchitecture" == "x86"
                    StrCpy $VCGUID "{e2803110-78b3-4664-a479-3611a381656a}"
                ${ElseIf} "$VCArchitecture" == "x64"
                    StrCpy $VCGUID "{d992c12e-cab2-426f-bde3-fb8c53950b0d}"
                ${ElseIf} "$VCArchitecture" == "arm64"
                    StrCpy $VCGUID "{5e791fcf-45a5-40b1-9b78-fb1cf5680841}"
                ${EndIf}
                StrCpy $ExpectedVersion "14.0.24215"
                ${Break}

            ${Default}
                ${DebugMsg} "Unknown VC++ version: $VCVersion"
                StrCpy $SkipCheck "1"
                ${Break}

        ${EndSwitch}

        ${If} $VCGUID == ""
            ${DebugMsg} "Unsupported architecture or missing GUID. Runtime skipped."
            StrCpy $SkipCheck "1"
        ${EndIf}

        ${If} $SkipCheck == "1"
            Goto _VCRUNTIME_CHECK_END
        ${EndIf}

        ${DebugMsg} "Checking registry (HKLM ? HKCU)"

        StrCpy $InstalledVersion ""

        ; Select correct registry view
        ${If} ${BitDepth} 64
            ${If} "$VCArchitecture" == "x86"
                SetRegView 32
            ${Else}
                SetRegView 64
            ${EndIf}
        ${EndIf}

        ReadRegStr $InstalledVersion HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$VCGUID" "DisplayVersion"

        ; Restore registry view
        SetRegView lastused

        ; Try HKCU if HKLM failed
        ${If} $InstalledVersion == ""
            ${If} ${BitDepth} 64
                ${If} "$VCArchitecture" == "x86"
                    SetRegView 32
                ${Else}
                    SetRegView 64
                ${EndIf}
            ${EndIf}

            ReadRegStr $InstalledVersion HKCU "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$VCGUID" "DisplayVersion"
            SetRegView lastused
        ${EndIf}

        ; Evaluate installed version
        ${If} $InstalledVersion != ""
            ${DebugMsg} "Found installed version: $InstalledVersion"

            Push $InstalledVersion
            Push $ExpectedVersion
            Call VersionCheck
            Pop $CompareResult

            ; CompareResult: 0 = equal, 1 = installed newer, 2 = expected newer
            ${If} $CompareResult != 2
                StrCpy $IsInstalled "true"
            ${EndIf}
        ${Else}
            ${DebugMsg} "VC++ runtime is NOT installed"
        ${EndIf}

        _VCRUNTIME_CHECK_END:

        ${If} $IsInstalled == "true"
            ${DebugMsg} "VC++ $VCVersion $VCArchitecture satisfied (installed: $InstalledVersion)"

            ; Check minimum version
            ${If} $VCMinVersion != ""
                
                Push $InstalledVersion
                Push $VCMinVersion
                Call VersionCheck
                Pop $CompareResult
                
                ${If} $CompareResult < 0
                    ${DebugMsg} "Installed version too old: $InstalledVersion < $VCMinVersion"

                    ${If} $VCAction == "warn"
                        ${Runtime::ShowMessage} "vcruntime" $VCVersion $VCArchitecture "version" $VCMinVersion
                    ${ElseIf} $VCAction == "install" 
                    ${OrIf} $VCAction == "bundle"
                        ; Upgrade
                        ${If} $VCInstaller != ""
                            ${VCRuntime::Install} $VCVersion $VCArchitecture "$Prerequisites\$VCInstaller" $InstallResult $CompareResult
                            ${If} $InstallResult != "true"
                                ${Runtime::ShowMessage} "vcruntime" $VCVersion $VCArchitecture "install_failed" $CompareResult
                                ${If} $VCRequired == "true"
                                    ${WriteRuntimeData} VCRuntime$R0 "Installed" "false"
                                ${EndIf}
                            ${EndIf}
                        ${EndIf}
                    ${EndIf}
                ${EndIf}
            ${EndIf}
        ${EndIf}

        ; Runtime not installed
        ${DebugMsg} "VC++ $VCVersion $VCArchitecture missing (Action: $VCAction)"

        ${Switch} $VCAction

            ${Case} "skip"
                ${DebugMsg} "Skip requested; ignoring missing runtime"
                ${Break}

            ${Case} "warn"
                ${Runtime::ShowMessage} "vcruntime" $VCVersion $VCArchitecture "missing" ""
                ${Break}

            ${Case} "install"
            ${Case} "bundle"
                ${If} $VCInstaller != ""
                    ${VCRuntime::Install} $VCVersion $VCArchitecture "$Prerequisites\$VCInstaller" $InstallResult $CompareResult

                    ${If} $InstallResult != "true"
                        ${Runtime::ShowMessage} "vcruntime" $VCVersion $VCArchitecture "install_failed" $CompareResult
                        ${If} $VCRequired == "true"
                            ${WriteRuntimeData} VCRuntime$R0 "Installed" "false"
                        ${EndIf}
                    ${EndIf}
                    ${Break}
                ${EndIf}

                ; No bundled installer so download it
                ${Runtime::Download} "vcruntime" "$VCVersion" "$VCArchitecture" "$TEMP\vcredist_$VCVersion_$VCArchitecture.exe" $DownloadResult
                ${If} $DownloadResult == "true"
                    ${VCRuntime::Install} $VCVersion $VCArchitecture "$TEMP\vcredist_$VCVersion_$VCArchitecture.exe" $InstallResult $CompareResult
                    Delete "$DownloadPath"

                    ${If} $InstallResult != "true"
                        ${Runtime::ShowMessage} "vcruntime" $VCVersion $VCArchitecture "install_failed" $CompareResult
                        ${If} $VCRequired == "true"
                            ${WriteRuntimeData} VCRuntime$R0 "Installed" "false"
                        ${EndIf}
                    ${EndIf}
                ${Else}
                    ${Runtime::ShowMessage} "vcruntime" $VCVersion $VCArchitecture "download_failed" ""
                    ${If} $VCRequired == "true"
                        ${WriteRuntimeData} VCRuntime$R0 "Installed" "false"
                    ${EndIf}
                ${EndIf}
                ${Break}

            ${Default}
                ${DebugMsg} "Unknown runtime action: $VCAction"
                ${Break}

        ${EndSwitch}
        
        ${ReadRuntimeData} $InstallResult VCRuntime$R0 "Installed"
        ${If} $InstallResult == "false"
            ${DebugMsg} "Critical runtime dependencies failed"
        ${EndIf}
		
		IntOp $R0 $R0 + 1
	${Loop}
	${DebugMsg} "VC++ runtime dependency check completed."
    
    ${DebugMsg} "Checking .NET runtime dependencies..."
    StrCpy $R0 1
    ${Do}
        ClearErrors
        ${ReadLauncherConfig} $NETFramework NETRuntime$R0 Framework
        ${IfThen} ${Errors} ${|} ${ExitDo} ${|}
        
        ${ReadLauncherConfig} $NETArchitecture NETRuntime$R0 Architecture
        ${ReadLauncherConfig} $NETMode NETRuntime$R0 Mode
        ${ReadLauncherConfig} $NETAction NETRuntime$R0 Action
        ${ReadLauncherConfig} $NETRequired NETRuntime$R0 Required
        ${ReadLauncherConfig} $NETMinVersion NETRuntime$R0 MinVersion
        ${ReadLauncherConfig} $NETInstaller NETRuntime$R0 Installer
        
        ${DebugMsg} "Processing .NET runtime: $0 $NETArchitecture"
        
        ; Architecture dispatch
        ${If} $NETArchitecture == "both"
            StrCpy $NETArchitecture "x86"
            Goto _PROCESS_NET
        _PROCESS_X64_AFTER_X86:
            StrCpy $NETArchitecture "x64"
            Goto _PROCESS_NET_FINAL
        ${ElseIf} $NETArchitecture == "anycpu"
            ${If} ${BitDepth} 64
                StrCpy $NETArchitecture "x64"
            ${Else}
                StrCpy $NETArchitecture "x86"
            ${EndIf}
            Goto _PROCESS_NET_FINAL
        ${Else}
            Goto _PROCESS_NET_FINAL
        ${EndIf}

        ; Runtime handler (first pass)
        _PROCESS_NET:
        
        StrCpy $R8 "false"
        StrCpy $R9 ""

        ${Switch} "$NETFramework"
            ${Case} "net20"
                ReadRegStr $InstalledVersion HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v2.0.50727" "Version"
                ${IfNot} ${Errors}
                    StrCpy $R8 "true"
                    ${DebugMsg} ".NET Framework 2.0 found: version $InstalledVersion"
                ${EndIf}
                ${Break}

            ${Case} "net35"
                ReadRegDWORD $2 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Install"
                ${If} $2 == 1
                    ReadRegStr $InstalledVersion HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v3.5" "Version"
                    StrCpy $R8 "true"
                    ${DebugMsg} ".NET Framework 3.5 found: version $InstalledVersion"
                ${EndIf}
                ${Break}

            ${Case} "net40"
                ReadRegDWORD $2 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Install"
                ${If} $2 == 1
                    ReadRegStr $InstalledVersion HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Version"
                    StrCpy $R8 "true"
                    ${DebugMsg} ".NET Framework 4.0 found: version $InstalledVersion"
                ${EndIf}
                ${Break}

            ${Case} "net45"
            ${Case} "net46"
            ${Case} "net47"
            ${Case} "net48"
                ReadRegDWORD $2 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release"
                ${If} $2 >= 378389
                    ReadRegStr $InstalledVersion HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Version"
                    StrCpy $R8 "true"
                    ${DebugMsg} ".NET Framework 4.5+ found: version $InstalledVersion, release $2"
                ${EndIf}
                ${Break}

            ${Case} "net50"
            ${Case} "net60"
            ${Case} "net70"
            ${Case} "net80"
                ${WordReplace} "$NETFramework" "net" "" "+" $2
                ${If} "$NETArchitecture" == "x64"
                ${OrIf} "$NETArchitecture" == "anycpu"
                    ReadRegStr $InstalledVersion HKLM "SOFTWARE\WOW6432Node\dotnet\Setup\InstalledVersions\x64\sharedhost" "Version"
                ${Else}
                    ReadRegStr $InstalledVersion HKLM "SOFTWARE\dotnet\Setup\InstalledVersions\x86\sharedhost" "Version"
                ${EndIf}
                ${IfNot} ${Errors}
                    Push $InstalledVersion
                    Push "$2.0"
                    Call VersionCheck
                    Pop $CompareResult
                    ${If} $CompareResult >= 0
                        StrCpy $R8 "true"
                        ${DebugMsg} ".NET $2+ found: version $InstalledVersion"
                    ${EndIf}
                ${EndIf}
                ${Break}

            ${Default}
                ${DebugMsg} "Unknown .NET framework: $NETFramework"
                ${Break}
        ${EndSwitch}

        ${If} $R8 == "true"
            ${DebugMsg} ".NET $NETFramework installed ($NETArchitecture): $InstalledVersion"

            ${If} $NETMinVersion != ""
                ${Runtime::VersionCheck} $InstalledVersion $NETMinVersion $CompareResult
                ${If} $CompareResult < 0
                    ${DebugMsg} "Installed version too old"

                    ${If} $NETAction == "warn"
                        ${Runtime::ShowMessage} "dotnet" $NETFramework $NETArchitecture "version" $NETMinVersion

                    ${ElseIf} $NETAction == "install"
                    ${OrIf} $NETAction == "bundle"

                        ${If} $NETInstaller != ""
                            ${NETRuntime::Install} $NETFramework $NETArchitecture "$Prerequisites\$NETInstaller" $InstallResult $CompareResult

                            ${If} $InstallResult != "true"
                                ${Runtime::ShowMessage} "dotnet" $NETFramework $NETArchitecture "install_failed" $CompareResult
                                ${If} $NETRequired == "true"
                                    ${WriteRuntimeData} NETRuntime$R0 "Installed" "false"
                                ${EndIf}
                            ${EndIf}
                        ${EndIf}

                    ${EndIf}
                ${EndIf}
            ${EndIf}

        ${Else}

            ${DebugMsg} ".NET $NETFramework not installed ($NETArchitecture)"

            ${Switch} $NETAction

                ${Case} "skip"
                    ${Break}

                ${Case} "warn"
                    ${If} $NETRequired == "true"
                        ${Runtime::ShowMessage} "dotnet" $NETFramework $NETArchitecture "missing" ""
                    ${EndIf}
                    ${Break}

                ${Case} "install"
                    ${If} $NETInstaller != ""
                        ${NETRuntime::Install} $NETFramework $NETArchitecture "$Prerequisites\$NETInstaller" $InstallResult $CompareResult

                        ${If} $InstallResult != "true"
                            ${Runtime::ShowMessage} "dotnet" $NETFramework $NETArchitecture "install_failed" $CompareResult
                            ${If} $NETRequired == "true"
                                ${WriteRuntimeData} NETRuntime$R0 "Installed" "false"
                            ${EndIf}
                        ${EndIf}

                    ${Else}
                        ${If} $NETRequired == "true"
                            ${Runtime::ShowMessage} "dotnet" $NETFramework $NETArchitecture "missing" ""
                        ${EndIf}
                    ${EndIf}
                    ${Break}

                ${Case} "bundle"
                    ${If} $NETInstaller != ""
                        ${NETRuntime::Install} $NETFramework $NETArchitecture "$Prerequisites\$NETInstaller" $InstallResult $CompareResult

                    ${Else}
                        ${Runtime::Download} "dotnet" $NETFramework $NETArchitecture "$TEMP\dotnet_${RuntimeFramework}_$NETArchitecture.exe" $DownloadResult

                        ${If} $DownloadResult == "true"
                            ${NETRuntime::Install} $NETFramework $NETArchitecture "$TEMP\dotnet_${RuntimeFramework}_$NETArchitecture.exe" $InstallResult $CompareResult
                            Delete "$TEMP\dotnet_${RuntimeFramework}_$NETArchitecture.exe"

                        ${Else}
                            ${Runtime::ShowMessage} "dotnet" $NETFramework $NETArchitecture "download_failed" ""
                            ${If} $NETRequired == "true"
                                ${WriteRuntimeData} NETRuntime$R0 "Installed" "false"
                            ${EndIf}
                        ${EndIf}
                    ${EndIf}
                    ${Break}

                ${Default}
                    ${DebugMsg} "Unknown action: $NETAction"
                    ${Break}

            ${EndSwitch}

        ${EndIf}

        ; Second pass for "both"
        ${If} $NETArchitecture == "both"
            Goto _PROCESS_X64_AFTER_X86
        ${EndIf}

        _PROCESS_NET_FINAL:
        ; fall-through back into ${Do} loop safely

        ; Post-loop error check
        ${DebugMsg} ".NET runtime dependency check completed."

        ${ReadRuntimeData} $InstallResult NETRuntime$R0 "Installed"

        ${If} $InstallResult == "false"
            ${DebugMsg} "Critical runtime dependencies failed"
        ${EndIf}
        IntOp $R0 $R0 + 1
    ${Loop}
!macroend
!endif
			
