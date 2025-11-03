; ModernWinVer.nsh - Modern Windows Version Detection
; Optimized for Windows 10, 11, and current Server versions
; Extends and modernizes the standard WinVer.nsh with LogicLib support

!ifndef MODERN_WINVER_NSH
!define MODERN_WINVER_NSH

!ifndef LOGICLIB
    !include LogicLib.nsh
!endif

; Windows Version Constants (Major.Minor.Build)
!define /ifndef WINVER_10         10.0    ; Windows 10 / Server 2016+
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
!define /ifndef VER_NT_WORKSTATION       1
!define /ifndef VER_NT_DOMAIN_CONTROLLER 2
!define /ifndef VER_NT_SERVER            3

; Architecture Constants
!define ARCH_X86    "x86"
!define ARCH_X64    "x64"
!define ARCH_ARM64  "ARM64"

;= Internal Helper Functions
!macro __WinVerCheck_AtLeastWin10
    Push $R0
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentMajorVersionNumber"
    IntCmp $R0 10 +3 +2 +3
        Push 0
        Goto +2
        Push 1
    Exch
    Pop $R0
!macroend

!macro __WinVerCheck_AtMostWin10
    Push $R0
    Push $R1
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentMajorVersionNumber"
    ReadRegStr $R1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    
    IntCmp $R0 10 0 +4
        IntCmp $R1 ${WINVER_11_BUILD} +2 +3 +2
    
    Push 1
    Goto +2
    Push 0
    
    Exch 2
    Pop $R1
    Pop $R0
!macroend

!macro __WinVerCheck_IsWin10
    Push $R0
    Push $R1
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentMajorVersionNumber"
    ReadRegStr $R1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    
    StrCmp $R0 "10" 0 +4
        IntCmp $R1 ${WINVER_11_BUILD} +3 +2 +3
    
    Push 0
    Goto +2
    Push 1
    
    Exch 2
    Pop $R1
    Pop $R0
!macroend

!macro __WinVerCheck_AtLeastWin11
    Push $R0
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    IntCmp $R0 ${WINVER_11_BUILD} +2 +3 +2
        Push 1
        Goto +2
        Push 0
    Exch
    Pop $R0
!macroend

!macro __WinVerCheck_AtMostWin11
    Push $R0
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    IntCmp $R0 ${WIN11_24H2} +2 +2 +3
        Push 1
        Goto +2
        Push 0
    Exch
    Pop $R0
!macroend

!macro __WinVerCheck_IsWin11
    Push $R0
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "CurrentBuild"
    IntCmp $R0 ${WINVER_11_BUILD} +2 +3 +2
        Push 1
        Goto +2
        Push 0
    Exch
    Pop $R0
!macroend

!macro __WinVerCheck_IsWinServer
    Push $R0
    ClearErrors
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "InstallationType"
    StrCmp $R0 "Server" +2
    StrCmp $R0 "Server Core" +2 +3
        Push 1
        Goto +2
        Push 0
    Exch
    Pop $R0
!macroend

!macro __WinVerCheck_IsWin10LTSC
    Push $R0
    Push $R1
    ReadRegStr $R0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "EditionID"
    
    StrCmp $R0 "EnterpriseS" is_ltsc_yes
    StrCmp $R0 "EnterpriseSN" is_ltsc_yes
    StrCmp $R0 "IoTEnterpriseS" is_ltsc_yes
    
    ReadRegStr $R1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName"
    StrLen $R0 $R1
    IntOp $R0 $R0 - 4
    StrCpy $R1 $R1 4 $R0
    
    StrCmp $R1 "LTSC" is_ltsc_yes
    StrCmp $R1 "LTSB" is_ltsc_yes
    
    Push 0
    Goto is_ltsc_done
    
    is_ltsc_yes:
        Push 1
    
    is_ltsc_done:
    Exch 2
    Pop $R1
    Pop $R0
!macroend

!macro __WinVerCheck_IsWin64
    ${If} ${RunningX64}
        Push 1
    ${Else}
        Push 0
    ${EndIf}
!macroend

!macro __WinVerCheck_IsARM64
    Push $R0
    ReadRegStr $R0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "PROCESSOR_ARCHITECTURE"
    StrCmp $R0 "ARM64" +3
        Push 0
        Goto +2
        Push 1
    Exch
    Pop $R0
!macroend

;= LogicLib Integration
; AtLeastWin10
!macro _AtLeastWin10 _a _b _t _f
    !insertmacro __WinVerCheck_AtLeastWin10
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define MWV_AtLeastWin10 `"" AtLeastWin10 ""`

; AtMostWin10
!macro _AtMostWin10 _a _b _t _f
    !insertmacro __WinVerCheck_AtMostWin10
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define MWV_AtMostWin10 `"" AtMostWin10 ""`

; IsWin10
!macro _IsWin10 _a _b _t _f
    !insertmacro __WinVerCheck_IsWin10
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define MWV_IsWin10 `"" IsWin10 ""`

; AtLeastWin11
!macro _AtLeastWin11 _a _b _t _f
    !insertmacro __WinVerCheck_AtLeastWin11
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define MWV_AtLeastWin11 `"" AtLeastWin11 ""`

; AtMostWin11
!macro _AtMostWin11 _a _b _t _f
    !insertmacro __WinVerCheck_AtMostWin11
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define MWV_AtMostWin11 `"" AtMostWin11 ""`

; IsWin11
!macro _IsWin11 _a _b _t _f
    !insertmacro __WinVerCheck_IsWin11
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define MWV_IsWin11 `"" IsWin11 ""`

; IsWinServer
!macro _IsWinServer _a _b _t _f
    !insertmacro __WinVerCheck_IsWinServer
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define MWV_IsWinServer `"" IsWinServer ""`

; IsWin10LTSC
!macro _IsWin10LTSC _a _b _t _f
    !insertmacro __WinVerCheck_IsWin10LTSC
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define MWV_IsWin10LTSC `"" IsWin10LTSC ""`

; IsWin64
!macro _IsWin64 _a _b _t _f
    !insertmacro __WinVerCheck_IsWin64
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define IsWin64 `"" IsWin64 ""`

; IsARM64
!macro _IsARM64 _a _b _t _f
    !insertmacro __WinVerCheck_IsARM64
    Pop $_LOGICLIB_TEMP
    !insertmacro _== $_LOGICLIB_TEMP 1 `${_t}` `${_f}`
!macroend
!define IsARM64 `"" IsARM64 ""`

;= Macro-based Functions (Alternative API)
!macro MWV_IsWindows11 _RESULT
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

!macro MWV_IsWindows10 _RESULT
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

!macro IsWindows10LTSC_Func _RESULT
    Push $0
    Push $1
    ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "EditionID"
    ${If} $0 == "EnterpriseS"
    ${OrIf} $0 == "EnterpriseSN"
    ${OrIf} $0 == "IoTEnterpriseS"
        StrCpy ${_RESULT} 1
        Goto done_ltsc_macro
    ${EndIf}
    ReadRegStr $1 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" "ProductName"
    StrLen $0 $1
    IntOp $0 $0 - 4
    StrCpy $1 $1 4 $0
    ${If} $1 == "LTSC"
    ${OrIf} $1 == "LTSB"
        StrCpy ${_RESULT} 1
    ${Else}
        StrCpy ${_RESULT} 0
    ${EndIf}
    done_ltsc_macro:
    Pop $1
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
!define IsWindows10LTSC "!insertmacro IsWindows10LTSC_Func"

!endif ; MODERN_WINVER_NSH
