; ModernWinVer.nsh - Modern Windows Version Detection
; Optimized for Windows 10, 11, and current Server versions
; Extends and modernizes the standard WinVer.nsh with LogicLib support

!ifndef MODERN_WINVER_NSH
!define MODERN_WINVER_NSH

!ifndef LOGICLIB
    !include LogicLib.nsh
!endif

; Windows Version Constants (Major.Minor.Build)
!define WINVER_11_BUILD   22000   ; Windows 11 minimum build

; Windows 10/11 Version Numbers (Builds)
!define WIN10_1507        10240   ; Windows 10 RTM (July 2015)
!define WIN10_1511        10586   ; November Update
!define WIN10_1607        14393   ; Anniversary Update / Server 2016
!define WIN10_1703        15063   ; Creators Update
!define WIN10_1709        16299   ; Fall Creators Update
!define WIN10_1803        17134   ; April 2018 Update
!define WIN10_1809        17763   ; October 2018 Update / Server 2019
!define WIN10_1903        18362   ; May 2019 Update
!define WIN10_1909        18363   ; November 2019 Update
!define WIN10_2004        19041   ; May 2020 Update
!define WIN10_20H2        19042   ; October 2020 Update
!define WIN10_21H1        19043   ; May 2021 Update
!define WIN10_21H2        19044   ; November 2021 Update
!define WIN10_22H2        19045   ; October 2022 Update (Final)

; Windows 11 Version Numbers (Builds)
!define WIN11_21H2        22000   ; Windows 11 RTM (October 2021)
!define WIN11_22H2        22621   ; September 2022 Update
!define WIN11_23H2        22631   ; October 2023 Update
!define WIN11_24H2        26100   ; September 2024 Update

; Windows Server Version Numbers
!define WINSERVER_2016    14393
!define WINSERVER_2019    17763
!define WINSERVER_2022    20348
!define WINSERVER_2025    26100   ; Expected build (may vary)

; Product Type Constants
!define VER_NT_WORKSTATION       1
!define VER_NT_DOMAIN_CONTROLLER 2
!define VER_NT_SERVER            3

; Architecture Constants
!define ARCH_X86    "x86"
!define ARCH_X64    "x64"
!define ARCH_ARM64  "ARM64"


;= LogicLib Integration - Version Checks
; AtLeastWin10
!macro _AtLeastWin10 _a _b _t _f
    !insertmacro _>= `${_b}` 10 `${_t}` `${_f}`
!macroend
!define AtLeastWin10 `"" AtLeastWin10 ""`

; AtMostWin10
!macro _AtMostWin10 _a _b _t _f
    !insertmacro _<= `${_b}` 10 `${_t}` `${_f}`
!macroend
!define AtMostWin10 `"" AtMostWin10 ""`

; IsWin10
!macro _IsWin10 _a _b _t _f
    !insertmacro _= `${_b}` 10 `${_t}` `${_f}`
!macroend
!define IsWin10 `"" IsWin10 ""`

; AtLeastWin11
!macro _AtLeastWin11 _a _b _t _f
    !insertmacro _>= `${_b}` 11 `${_t}` `${_f}`
!macroend
!define AtLeastWin11 `"" AtLeastWin11 ""`

; AtMostWin11
!macro _AtMostWin11 _a _b _t _f
    !insertmacro _<= `${_b}` 11 `${_t}` `${_f}`
!macroend
!define AtMostWin11 `"" AtMostWin11 ""`

; IsWin11
!macro _IsWin11 _a _b _t _f
    !insertmacro _= `${_b}` 11 `${_t}` `${_f}`
!macroend
!define IsWin11 `"" IsWin11 ""`

; IsWinServer
!macro _IsWinServer _a _b _t _f
    !insertmacro _= `${_b}` S `${_t}` `${_f}`
!macroend
!define IsWinServer `"" IsWinServer ""`

; AtLeastWin10Build - Compare against specific build numbers
!macro _AtLeastWin10Build _a _b _t _f
    !insertmacro _>= `${_b}` B `${_t}` `${_f}`
!macroend
!define AtLeastWin10Build `"" AtLeastWin10Build ""`

; IsWin10LTSC
!macro _IsWin10LTSC _a _b _t _f
    !insertmacro _= `${_b}` LTSC `${_t}` `${_f}`
!macroend
!define IsWin10LTSC `"" IsWin10LTSC ""`

; IsWin64
!macro _IsWin64 _a _b _t _f
    !insertmacro _= `${_b}` 64 `${_t}` `${_f}`
!macroend
!define IsWin64 `"" IsWin64 ""`

; IsARM64
!macro _IsARM64 _a _b _t _f
    !insertmacro _= `${_b}` ARM `${_t}` `${_f}`
!macroend
!define IsARM64 `"" IsARM64 ""`

;= Helper Functions for LogicLib
!macro __ModernWinVer_DefineOSTest Test
    !ifdef __ModernWinVer_${Test}_Defined
        !undef __ModernWinVer_${Test}_Defined
    !endif
    !define __ModernWinVer_${Test}_Defined
    
    !ifndef __ModernWinVer_${Test}_Call
        !define __ModernWinVer_${Test}_Call
        
        !ifdef __UNINSTALL__
            !define __ModernWinVer_${Test}_Func Un.__ModernWinVer_${Test}
        !else
            !define __ModernWinVer_${Test}_Func __ModernWinVer_${Test}
        !endif
        
        Function ${__ModernWinVer_${Test}_Func}
            !insertmacro __ModernWinVer_${Test}_Impl
        FunctionEnd
    !endif
!macroend

; Comparison operator implementation
!macro _>= _a _b _t _f
    !verbose push
    !verbose 4
    !if `${_b}` == 10
        !insertmacro __ModernWinVer_DefineOSTest AtLeastWin10
        Call ${__ModernWinVer_AtLeastWin10_Func}
        Pop $0
        !insertmacro _= $0 true `${_t}` `${_f}`
    !else if `${_b}` == 11
        !insertmacro __ModernWinVer_DefineOSTest AtLeastWin11
        Call ${__ModernWinVer_AtLeastWin11_Func}
        Pop $0
        !insertmacro _= $0 true `${_t}` `${_f}`
    !else if `${_b}` == B
        !insertmacro __ModernWinVer_DefineOSTest AtLeastBuild
        Call ${__ModernWinVer_AtLeastBuild_Func}
        Pop $0
        !insertmacro _= $0 true `${_t}` `${_f}`
    !else
        !error "Unsupported version comparison: ${_b}"
    !endif
    !verbose pop
!macroend

!macro _<= _a _b _t _f
    !verbose push
    !verbose 4
    !if `${_b}` == 10
        !insertmacro __ModernWinVer_DefineOSTest AtMostWin10
        Call ${__ModernWinVer_AtMostWin10_Func}
        Pop $0
        !insertmacro _= $0 true `${_t}` `${_f}`
    !else if `${_b}` == 11
        !insertmacro __ModernWinVer_DefineOSTest AtMostWin11
        Call ${__ModernWinVer_AtMostWin11_Func}
        Pop $0
        !insertmacro _= $0 true `${_t}` `${_f}`
    !else
        !error "Unsupported version comparison: ${_b}"
    !endif
    !verbose pop
!macroend

!macro _= _a _b _t _f
    !verbose push
    !verbose 4
    !if `${_b}` == 10
        !insertmacro __ModernWinVer_DefineOSTest IsWin10
        Call ${__ModernWinVer_IsWin10_Func}
        Pop $0
        !insertmacro _== $0 true `${_t}` `${_f}`
    !else if `${_b}` == 11
        !insertmacro __ModernWinVer_DefineOSTest IsWin11
        Call ${__ModernWinVer_IsWin11_Func}
        Pop $0
        !insertmacro _== $0 true `${_t}` `${_f}`
    !else if `${_b}` == S
        !insertmacro __ModernWinVer_DefineOSTest IsServer
        Call ${__ModernWinVer_IsServer_Func}
        Pop $0
        !insertmacro _== $0 true `${_t}` `${_f}`
    !else if `${_b}` == LTSC
        !insertmacro __ModernWinVer_DefineOSTest IsLTSC
        Call ${__ModernWinVer_IsLTSC_Func}
        Pop $0
        !insertmacro _== $0 true `${_t}` `${_f}`
    !else if `${_b}` == 64
        !insertmacro __ModernWinVer_DefineOSTest Is64
        Call ${__ModernWinVer_Is64_Func}
        Pop $0
        !insertmacro _== $0 true `${_t}` `${_f}`
    !else if `${_b}` == ARM
        !insertmacro __ModernWinVer_DefineOSTest IsARM
        Call ${__ModernWinVer_IsARM_Func}
        Pop $0
        !insertmacro _== $0 true `${_t}` `${_f}`
    !else
        StrCmp `${_a}` `${_b}` `${_t}` `${_f}`
    !endif
    !verbose pop
!macroend

;= Macros for OS Tests
!macro __ModernWinVer_AtLeastWin10_Impl
    Push $1
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentMajorVersionNumber"
    IntCmp $1 10 0 not_atleast10
        Push "true"
        Goto done_atleast10
    not_atleast10:
        Push "false"
    done_atleast10:
    Exch
    Pop $1
!macroend

!macro __ModernWinVer_AtMostWin10_Impl
    Push $1
    Push $2
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentMajorVersionNumber"
    ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    
    ${If} $1 < 10
        Push "true"
    ${ElseIf} $1 == 10
        IntCmp $2 ${WINVER_11_BUILD} not_atmost10 not_atmost10 0
            Push "true"
            Goto done_atmost10
    ${EndIf}
    
    not_atmost10:
        Push "false"
    done_atmost10:
    Exch 2
    Pop $2
    Pop $1
!macroend

!macro __ModernWinVer_IsWin10_Impl
    Push $1
    Push $2
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentMajorVersionNumber"
    ReadRegStr $2 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    
    ${If} $1 == 10
        IntCmp $2 ${WINVER_11_BUILD} not_win10 not_win10 0
            Push "true"
            Goto done_win10
    ${EndIf}
    
    not_win10:
        Push "false"
    done_win10:
    Exch 2
    Pop $2
    Pop $1
!macroend

!macro __ModernWinVer_AtLeastWin11_Impl
    Push $1
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    IntCmp $1 ${WINVER_11_BUILD} 0 not_atleast11
        Push "true"
        Goto done_atleast11
    not_atleast11:
        Push "false"
    done_atleast11:
    Exch
    Pop $1
!macroend

!macro __ModernWinVer_AtMostWin11_Impl
    Push $1
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    IntCmp $1 ${WIN11_24H2} 0 0 not_atmost11
        Push "true"
        Goto done_atmost11
    not_atmost11:
        Push "false"
    done_atmost11:
    Exch
    Pop $1
!macroend

!macro __ModernWinVer_IsWin11_Impl
    Push $1
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    IntCmp $1 ${WINVER_11_BUILD} 0 not_win11
        Push "true"
        Goto done_win11
    not_win11:
        Push "false"
    done_win11:
    Exch
    Pop $1
!macroend

!macro __ModernWinVer_IsServer_Impl
    Push $1
    ClearErrors
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "InstallationType"
    ${If} $1 == "Server"
    ${OrIf} $1 == "Server Core"
        Push "true"
    ${Else}
        Push "false"
    ${EndIf}
    Exch
    Pop $1
!macroend

!macro __ModernWinVer_IsLTSC_Impl
    Push $1
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "EditionID"
    ${If} $1 == "EnterpriseS"
    ${OrIf} $1 == "EnterpriseSN"
    ${OrIf} $1 == "IoTEnterpriseS"
        Push "true"
    ${Else}
        ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName"
        StrCpy $1 $1 "" -4
        ${If} $1 == "LTSC"
        ${OrIf} $1 == "LTSB"
            Push "true"
        ${Else}
            Push "false"
        ${EndIf}
    ${EndIf}
    Exch
    Pop $1
!macroend

!macro __ModernWinVer_Is64_Impl
    ${If} ${RunningX64}
        Push "true"
    ${Else}
        Push "false"
    ${EndIf}
!macroend

!macro __ModernWinVer_IsARM_Impl
    Push $1
    ReadRegStr $1 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
    ${If} $1 == "ARM64"
        Push "true"
    ${Else}
        Push "false"
    ${EndIf}
    Exch
    Pop $1
!macroend

!macro __ModernWinVer_AtLeastBuild_Impl
    Push $1
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    ; This is a placeholder - actual build comparison would need the build number passed
    Push "false"
    Exch
    Pop $1
!macroend

;= Macro-based Functions (Alternative API)
!macro IsWindows11 _RESULT
    Push $0
    Push $1
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    IntCmp $0 ${WINVER_11_BUILD} 0 not_win11_macro is_win11_macro
    is_win11_macro:
        StrCpy ${_RESULT} 1
        Goto done_win11_macro
    not_win11_macro:
        StrCpy ${_RESULT} 0
    done_win11_macro:
    Pop $1
    Pop $0
!macroend

!macro IsWindows10 _RESULT
    Push $0
    Push $1
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentMajorVersionNumber"
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    ${If} $0 == "10"
        IntCmp $1 ${WINVER_11_BUILD} not_win10_macro not_win10_macro is_win10_macro
        is_win10_macro:
            StrCpy ${_RESULT} 1
            Goto done_win10_macro
    ${EndIf}
    not_win10_macro:
        StrCpy ${_RESULT} 0
    done_win10_macro:
    Pop $1
    Pop $0
!macroend

!macro IsWindowsServer _RESULT
    Push $0
    ClearErrors
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "InstallationType"
    ${If} $0 == "Server"
    ${OrIf} $0 == "Server Core"
        StrCpy ${_RESULT} 1
    ${Else}
        StrCpy ${_RESULT} 0
    ${EndIf}
    Pop $0
!macroend

!macro GetWindowsBuild _RESULT
    ReadRegStr ${_RESULT} HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
!macroend

!macro GetWindowsVersion _RESULT
    Push $0
    Push $1
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    IntCmp $0 ${WIN11_24H2} 0 +3 0
        StrCpy ${_RESULT} "Windows 11 24H2"
        Goto done_getver
    IntCmp $0 ${WIN11_23H2} 0 +3 0
        StrCpy ${_RESULT} "Windows 11 23H2"
        Goto done_getver
    IntCmp $0 ${WIN11_22H2} 0 +3 0
        StrCpy ${_RESULT} "Windows 11 22H2"
        Goto done_getver
    IntCmp $0 ${WIN11_21H2} 0 +3 0
        StrCpy ${_RESULT} "Windows 11 21H2"
        Goto done_getver
    ${IsWindowsServer} $1
    ${If} $1 == 1
        IntCmp $0 ${WINSERVER_2025} 0 +3 0
            StrCpy ${_RESULT} "Windows Server 2025"
            Goto done_getver
        IntCmp $0 ${WINSERVER_2022} 0 +3 0
            StrCpy ${_RESULT} "Windows Server 2022"
            Goto done_getver
        IntCmp $0 ${WINSERVER_2019} 0 +3 0
            StrCpy ${_RESULT} "Windows Server 2019"
            Goto done_getver
        IntCmp $0 ${WINSERVER_2016} 0 +3 0
            StrCpy ${_RESULT} "Windows Server 2016"
            Goto done_getver
        StrCpy ${_RESULT} "Windows Server (Unknown)"
        Goto done_getver
    ${EndIf}
    IntCmp $0 ${WIN10_22H2} 0 +3 0
        StrCpy ${_RESULT} "Windows 10 22H2"
        Goto done_getver
    IntCmp $0 ${WIN10_21H2} 0 +3 0
        StrCpy ${_RESULT} "Windows 10 21H2"
        Goto done_getver
    IntCmp $0 ${WIN10_21H1} 0 +3 0
        StrCpy ${_RESULT} "Windows 10 21H1"
        Goto done_getver
    IntCmp $0 ${WIN10_20H2} 0 +3 0
        StrCpy ${_RESULT} "Windows 10 20H2"
        Goto done_getver
    IntCmp $0 ${WIN10_2004} 0 +3 0
        StrCpy ${_RESULT} "Windows 10 2004"
        Goto done_getver
    IntCmp $0 ${WIN10_1507} 0 not_supported_getver 0
        StrCpy ${_RESULT} "Windows 10"
        Goto done_getver
    not_supported_getver:
        StrCpy ${_RESULT} "Unsupported Windows Version"
    done_getver:
    Pop $1
    Pop $0
!macroend

!macro GetWindowsArchitecture _RESULT
    Push $0
    ${If} ${RunningX64}
        ReadRegStr $0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
        ${If} $0 == "ARM64"
            StrCpy ${_RESULT} ${ARCH_ARM64}
        ${Else}
            StrCpy ${_RESULT} ${ARCH_X64}
        ${EndIf}
    ${Else}
        StrCpy ${_RESULT} ${ARCH_X86}
    ${EndIf}
    Pop $0
!macroend

!macro RequireWindows10OrLater
    Push $0
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentMajorVersionNumber"
    ${If} $0 < 10
        MessageBox MB_OK|MB_ICONSTOP "This application requires Windows 10 or later."
        Quit
    ${EndIf}
    Pop $0
!macroend

!macro RequireWindows11OrLater
    Push $0
    ${IsWindows11} $0
    ${If} $0 == 0
        MessageBox MB_OK|MB_ICONSTOP "This application requires Windows 11 or later."
        Quit
    ${EndIf}
    Pop $0
!macroend

!macro GetWindowsDisplayVersion _RESULT
    ReadRegStr ${_RESULT} HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "DisplayVersion"
    ${If} ${_RESULT} == ""
        ReadRegStr ${_RESULT} HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ReleaseId"
    ${EndIf}
!macroend

!macro IsWindows10LTSC _RESULT
    Push $0
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "EditionID"
    ${If} $0 == "EnterpriseS"
    ${OrIf} $0 == "EnterpriseSN"
    ${OrIf} $0 == "IoTEnterpriseS"
        StrCpy ${_RESULT} 1
        Goto done_ltsc_macro
    ${EndIf}
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName"
    StrCpy $0 $0 "" -4
    ${If} $0 == "LTSC"
    ${OrIf} $0 == "LTSB"
        StrCpy ${_RESULT} 1
    ${Else}
        StrCpy ${_RESULT} 0
    ${EndIf}
    done_ltsc_macro:
    Pop $0
!macroend

!define IsWindows11 "!insertmacro IsWindows11"
!define IsWindows10 "!insertmacro IsWindows10"
!define IsWindowsServer "!insertmacro IsWindowsServer"
!define GetWindowsBuild "!insertmacro GetWindowsBuild"
!define GetWindowsVersion "!insertmacro GetWindowsVersion"
!define GetWindowsArchitecture "!insertmacro GetWindowsArchitecture"
!define RequireWindows10OrLater "!insertmacro RequireWindows10OrLater"
!define RequireWindows11OrLater "!insertmacro RequireWindows11OrLater"
!define GetWindowsDisplayVersion "!insertmacro GetWindowsDisplayVersion"
!define IsWindows10LTSC "!insertmacro IsWindows10LTSC"

!endif ; MODERN_WINVER_NSH
