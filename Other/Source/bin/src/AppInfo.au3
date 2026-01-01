#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=assets\AppInfoGenerator.ico
#AutoIt3Wrapper_Outfile=..\AppInfoINIGenerator.exe
#AutoIt3Wrapper_UseX64=n
#AutoIt3Wrapper_Res_Comment=PortableApps Compiler AppInfo.ini Configuration Generator
#AutoIt3Wrapper_Res_Description=Generate a AppInfo.ini configuration file for a PortableApps.com compliant portable application
#AutoIt3Wrapper_Res_Fileversion=1.0.2.1
#AutoIt3Wrapper_Res_ProductName=AppInfoINIGenerator.exe
#AutoIt3Wrapper_Res_ProductVersion=1.0.2.1
#AutoIt3Wrapper_Res_CompanyName=How Dumb, LLC
#AutoIt3Wrapper_Res_LegalCopyright=Devin Gaul
#AutoIt3Wrapper_Res_Language=1033
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ButtonConstants.au3>
#include <ComboConstants.au3>
#include <EditConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <GUIConstantsEx.au3>
#include <GuiToolTip.au3>
#include <WindowsStylesConstants.au3>

; GUI Style
#include "_UskinLibrary.au3"
_Uskin_LoadDLL()
_USkin_Init(@ScriptDir & "\WinAjuda.msstyles")
;#include ".\WinAjuda.au3"
;_USkin_Init(_WinAjuda(True))

Local $sAssetsPath = @TempDir & "\AppInfoINIGenerator"
DirRemove($sAssetsPath, 0)
DirCreate($sAssetsPath)
Global $sCertificate = $sAssetsPath & "\Certificate.ico"
FileInstall("assets\Certificate.ico", $sCertificate, 1)
Global $sDependencies = $sAssetsPath & "\Dependencies.ico"
FileInstall("assets\Dependencies.ico", $sDependencies, 1)
Global $sHelp = $sAssetsPath & "\Help.ico"
FileInstall("assets\Help.ico", $sHelp, 1)
Global $sFileWrite = $sAssetsPath & "\FileWrite.ico"
FileInstall("assets\FileWrite.ico", $sFileWrite, 1)
Global $sLicense = $sAssetsPath & "\License.ico"
FileInstall("assets\License.ico", $sLicense, 1)
Global $sPortableApps = $sAssetsPath & "\PortableApps.ico"
FileInstall("assets\PortableApps.ico", $sPortableApps, 1)
Global $sPlugins = $sAssetsPath & "\Plugins.ico"
FileInstall("assets\Plugins.ico", $sPlugins, 1)
Global $sControl = $sAssetsPath & "\Control.ico"
FileInstall("assets\Control.ico", $sControl, 1)
Global $sVersion = $sAssetsPath & "\Version.ico"
FileInstall("assets\Version.ico", $sVersion, 1)
Global $sGenerator = $sAssetsPath & "\Generator.ico"
FileInstall("assets\Generator.ico", $sGenerator, 1)
Global $sPublisher = $sAssetsPath & "\Publisher.ico"
FileInstall("assets\Publisher.ico", $sPublisher, 1)
Global $g_bModified = False
; Global $g_hStatusBar

Local $AppInfo = GUICreate("AppInfo.ini Generator", 1040, 601, 192, 124)
GUISetIcon($sGenerator)
GUISetFont(10, 400, 0, "Segoe UI")
GUISetBkColor(0xE3E3E3)
;GUICtrlSetDefBkColor(0x000000)
;GUICtrlSetDefColor(0xC0C0C0)


Local $WindowIcon = GUICtrlCreateIcon($sGenerator, -1, 16, 7, 48, 48)
GUICtrlCreateLabel("AppInfo INI Configuration Generator", 76, 37, 232, 18)
GUICtrlSetFont(-1, 8, 400, 0, "Segoe UI")
GUICtrlCreateLabel("PortableApps Compiler", 76, 7, 222, 32)
GUICtrlSetFont(-1, 16, 400, 0, "Segoe UI")

Local $SaveBtn = GUICtrlCreateButton("Save", 950, 15, 75, 33, $BS_FLAT)
Local $ClearBtn = GUICtrlCreateButton("Clear", 870, 15, 75, 33, $BS_FLAT)
Local $ImportBtn = GUICtrlCreateButton("Import", 790, 15, 75, 33, $BS_FLAT)

Local $ExitBtn = GUICtrlCreateButton("Exit", 950, 560, 75, 33, $BS_FLAT)

Local $OpenLauncherGenerator = GUICtrlCreateButton("Launcher Generator", 318, 16, 147, 33, $BS_FLAT)
Local $OpenInstallerGenerator = GUICtrlCreateButton("Installer Generator", 472, 16, 147, 33, $BS_FLAT)

Local $DependanciesGroup = GUICtrlCreateGroup("", 230, 278, 236, 279)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
;GUICtrlSetDefColor(0xC0C0C0)
Local $DependenciesLabel = GUICtrlCreateLabel("[Dependencies]", 274, 298, 160, 25)
GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
Local $Icon5 = GUICtrlCreateIcon($sDependencies, -1, 240, 295, 32, 32)
Local $Label3 = GUICtrlCreateLabel("Java Runtime Environment", 242, 332, 212, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $JavaCombo = GUICtrlCreateCombo("none", 242, 353, 215, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
GUICtrlSetData(-1, "find|require")
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Add support for the Java Runtime Environment")
Local $Label4 = GUICtrlCreateLabel("Java Development Kit", 242, 388, 212, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $JDKCombo = GUICtrlCreateCombo("none", 242, 409, 215, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
GUICtrlSetData(-1, "find|require")
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Add support for the Java Development Kit")
Local $Label5 = GUICtrlCreateLabel(".NET Developer Platform", 242, 444, 212, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $Combo4 = GUICtrlCreateCombo("none", 242, 465, 215, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
GUICtrlSetData(-1, "find|require")
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Add support for .NET developer platform")
Local $Label6 = GUICtrlCreateLabel("VC++ Runtime Environment", 242, 500, 212, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $Combo5 = GUICtrlCreateCombo("none", 242, 521, 215, 25, BitOR($CBS_DROPDOWN, $CBS_AUTOHSCROLL))
GUICtrlSetData(-1, "find|require")
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Can this program change directories? If not, warn the user?")
Local $DependenciesHelpButton = GUICtrlCreateButton("", 426, 300, 27, 25, BitOR($BS_FLAT,$BS_ICON))
GUICtrlSetImage(-1, $sHelp, -1, 0)
GUICtrlSetTip(-1, "[Dependencies] Help")
GUICtrlSetCursor(-1, 4)
GUICtrlCreateGroup("", -99, -99, 1, 1)

Local $DetailsGroup = GUICtrlCreateGroup("", 230, 54, 580, 223)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $NameLabel = GUICtrlCreateLabel("Name:", 242, 109, 180, 20)
Local $NameInput = GUICtrlCreateInput("", 242, 129, 180, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Should be the same as AppName in Launcher.ini")
GUICtrlSetCursor(-1, 5)
Local $AppIDLabel = GUICtrlCreateLabel("AppID", 242, 159, 180, 20)
Local $AppIDInput = GUICtrlCreateInput("", 242, 181, 179, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Globally unique id for the application. Generally just the name without spaces")
Local $PublisherLabel = GUICtrlCreateLabel("Publisher", 242, 210, 180, 20)
Local $PublisherInput = GUICtrlCreateInput("", 242, 232, 180, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The name of the spplication's creator. Either a company's or the software developer")
Local $HomepageLabel = GUICtrlCreateLabel("Homepage", 430, 109, 180, 20)
Local $HomepageInput = GUICtrlCreateInput("", 430, 129, 180, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The publisher's website")
Local $LanguageLabel = GUICtrlCreateLabel("Language", 618, 109, 180, 20)
Local $LanguageCombo = GUICtrlCreateCombo("Multilingual", 618, 129, 180, 25, BitOR($GUI_SS_DEFAULT_COMBO, $WS_BORDER))
GUICtrlSetData(-1, "Afrikaans|Albanian|Arabic|Armenian|Basque|Belarusian|Bosnian|Breton|Bulgarian|Catalan|Cibemba|Croatian|Czech|Danish|Dutch|Efik|English|Estonian|Farsi|Finnish|French|Galician|Georgian|German|Greek|Hebrew|Hungarian|Icelandic|Igbo|Indonesian|Irish|Italian|Japanese|Khmer|Korean|Kurdish|Latvian|Lithuanian|Luxembourgish|Macedonian|Malagasy|Malay|Mongolian|Norwegian|NorwegianNynorsk|Pashto|Polish|Portuguese|PortugueseBR|Romanian|Russian|Serbian|SerbianLatin|SimpChinese|Slovak|Slovenian|Spanish|SpanishInternational|Swahili|Swedish|Thai|TradChinese|Turkish|Ukranian|Uzbek|Valencian|Vietnamese|Welsh|Yoruba")
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The language the app is available in")
Local $CategoryLabel = GUICtrlCreateLabel("Category", 430, 159, 180, 20)
Local $CategoryCombo = GUICtrlCreateCombo("", 430, 181, 180, 25, BitOR($GUI_SS_DEFAULT_COMBO, $WS_BORDER))
GUICtrlSetData(-1, "Accessibility|Development|Education|Games|Graphics & Pictures|Internet|Music & Video|Office|Security|Utilities")
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The category that the application falls under")
Local $DescriptionLabel = GUICtrlCreateLabel("Description", 430, 210, 180, 20)
Local $TrademarksLabel = GUICtrlCreateLabel("Trademarks", 618, 159, 180, 20)
Local $InstallTypeLabel = GUICtrlCreateLabel("InstallType", 618, 210, 180, 20)
Local $DetailsLabel = GUICtrlCreateLabel("[Details]", 274, 74, 360, 25)
GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
Local $DetailsHelpButton = GUICtrlCreateButton("", 770, 76, 27, 25, BitOR($BS_FLAT,$BS_ICON))
GUICtrlSetImage(-1, $sHelp, -1, 0)
GUICtrlSetTip(-1, "[Details] Help")
GUICtrlSetCursor(-1, 4)
Local $DetailsIcon = GUICtrlCreateIcon($sFileWrite, -1, 240, 71, 32, 32)
Local $DescriptionInput = GUICtrlCreateInput("", 430, 232, 180, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetLimit(-1, 512)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Brief description of what the application is. Maximum of 512 characters")
Local $TrademarksInput = GUICtrlCreateInput("", 618, 181, 180, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Any trademark notifications that should appear")
Local $InstallTypeInput = GUICtrlCreateInput("", 618, 232, 180, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetLimit(-1, 512)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Specific install type. For example: Mozilla Firefox Developer Edition or JDK 25-LTS")
GUICtrlCreateGroup("", -99, -99, 1, 1)

Local $LicenseGroup = GUICtrlCreateGroup("", 10, 374, 212, 183)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $LicenseLabel = GUICtrlCreateLabel("[License]", 54, 394, 88, 25)
GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
Local $LicenseIcon = GUICtrlCreateIcon($sLicense, -1, 20, 391, 32, 32)
Local $LicenseHelpButton = GUICtrlCreateButton("", 182, 396, 27, 25, BitOR($BS_FLAT,$BS_ICON))
GUICtrlSetImage(-1, $sHelp, -1, 0)
GUICtrlSetTip(-1, "[License] Help")
GUICtrlSetCursor(-1, 4)
Local $ShareableCheckbox = GUICtrlCreateCheckbox("Shareable", 22, 455, 188, 20)
GUICtrlSetTip(-1, "Allow for manipulation of the Windows Registry")
Local $FreewareCheckbox = GUICtrlCreateCheckbox("Freeware", 22, 505, 188, 20)
GUICtrlSetTip(-1, "Enable support for copying registry keys to a special hive (HKCU\Software\PortableApps.com)")
Local $OpenSourceCheckbox = GUICtrlCreateCheckbox("Open Source", 22, 480, 188, 20)
GUICtrlSetTip(-1, "Allow for x64 bit registry access by turning on registry redirection ")
Local $EULACheckbox = GUICtrlCreateCheckbox("End User License Agreement", 22, 432, 196, 20)
GUICtrlSetTip(-1, "For applications which need to run as normal user but need the launcher to have elevated privileges")
Local $CommercialUseCheckbox = GUICtrlCreateCheckbox("Commercial Use", 22, 528, 188, 20)
GUICtrlSetTip(-1, "Enable support for enabling/disabling file system redirection")
GUICtrlCreateGroup("", -99, -99, 1, 1)

Local $FormatGroup = GUICtrlCreateGroup("", 10, 54, 212, 161)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $FormatLabel = GUICtrlCreateLabel("[Format]", 54, 74, 88, 25)
GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
Local $Icon7 = GUICtrlCreateIcon($sPortableApps, -1, 20, 71, 32, 32)
Local $FormatHelpButton = GUICtrlCreateButton("", 182, 76, 27, 25, BitOR($BS_FLAT,$BS_BITMAP))
GUICtrlSetImage(-1, $sHelp, -1, 0)
GUICtrlSetTip(-1, "[Format] Help")
GUICtrlSetCursor(-1, 4)
Local $TypeLabel = GUICtrlCreateLabel("Type", 22, 109, 188, 20)
GUICtrlSetTip(-1, "PortableApps.comFormat")
Local $PAFTypeInput = GUICtrlCreateInput("PortableApps.comFormat", 22, 129, 188, 25, BitOR($GUI_SS_DEFAULT_INPUT, $ES_READONLY, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "PortableApps.comFormat")
GUICtrlSetCursor(-1, 5)
Local $DisplayVersionLabel = GUICtrlCreateLabel("Version", 21, 159, 188, 20)
GUICtrlSetTip(-1, "The version the PortableApps.com Format  is in")
Local $PAFVersionInput = GUICtrlCreateInput("3.9", 22, 181, 188, 25, BitOR($GUI_SS_DEFAULT_INPUT, $ES_NUMBER, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The version of the PortableApps.com Format is in")
GUICtrlSetCursor(-1, 5)
GUICtrlCreateGroup("", -99, -99, 1, 1)

Local $SpecialPathsGroup = GUICtrlCreateGroup("", 818, 54, 212, 121)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $SpecialPathsLabel = GUICtrlCreateLabel("[SpecialPaths]", 862, 74, 128, 25)
GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
Local $Icon8 = GUICtrlCreateIcon($sPlugins, -1, 828, 71, 32, 32)
Local $SpecialPathsHelpButton = GUICtrlCreateButton("", 990, 76, 27, 25, BitOR($BS_FLAT,$BS_ICON))
GUICtrlSetImage(-1, $sHelp, -1, 0)
GUICtrlSetTip(-1, "[SpecialPaths] Help")
GUICtrlSetCursor(-1, 4)
Local $PluginsLabel = GUICtrlCreateLabel("Plugins", 830, 116, 188, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "PortableApps.comFormat")
Local $PluginsInput = GUICtrlCreateInput("none", 830, 136, 188, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Path to the application’s user-added plugins directory if it is within the App directory")
GUICtrlSetCursor(-1, 5)
GUICtrlCreateGroup("", -99, -99, 1, 1)

Local $ControlGroup = GUICtrlCreateGroup("", 474, 278, 334, 279)
Local $Icon14 = GUICtrlCreateIcon($sControl, -1, 484, 295, 32, 32)
Local $ControlLabel = GUICtrlCreateLabel("[Control]", 518, 298, 88, 25)
GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
Local $ControlEdit = GUICtrlCreateEdit("", 482, 340, 313, 205, -1, 0)
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetData(-1, StringFormat("[Control]\r\nIcons=2\r\nStart=AppNamePortable.exe\r\nStart1=AppNamePortable.exe\r\nName1=AppName Portable\r\nStart2=AppNamePortable2.exe\r\nName2=AppName Portable Other Part"))
Local $ControlHelpButton = GUICtrlCreateButton("", 764, 300, 27, 25, BitOR($BS_FLAT,$BS_ICON))
GUICtrlSetImage(-1, $sHelp, -1, 0)
GUICtrlSetTip(-1, "[Control] Help")
GUICtrlSetCursor(-1, 4)
GUICtrlCreateGroup("", -99, -99, 1, 1)
Local $VersionGroup = GUICtrlCreateGroup("", 10, 215, 212, 159)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $VersionLabe = GUICtrlCreateLabel("[Version]", 54, 235, 88, 25)
GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
Local $Icon6 = GUICtrlCreateIcon($sVersion, -1, 20, 232, 32, 32)
Local $VersionHelpButton = GUICtrlCreateButton("", 182, 237, 27, 25, BitOR($BS_FLAT,$BS_ICON))
GUICtrlSetImage(-1, $sHelp, -1, 0)
GUICtrlSetTip(-1, "[Version] Help")
GUICtrlSetCursor(-1, 4)
Local $PackageVersionLabel = GUICtrlCreateLabel("Package Version", 22, 270, 188, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "PortableApps.comFormat")
Local $PackageVersionInput = GUICtrlCreateInput("0.0.0.0", 22, 290, 188, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "This must be in 1.2.3.4 format with no other characters")
GUICtrlSetCursor(-1, 5)
Local $DissplayVersionLabel = GUICtrlCreateLabel("Display Version", 21, 320, 188, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "The version the PortableApps.com Format  is in")
Local $DisplayVersionInput = GUICtrlCreateInput("", 22, 342, 188, 25, BitOR($GUI_SS_DEFAULT_INPUT, $WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The user-friendly version. For example: 1.5 Beta or 1.5 RC Rev. 2")
GUICtrlSetCursor(-1, 5)
GUICtrlCreateGroup("", -99, -99, 1, 1)

Local $PublisherGroup = GUICtrlCreateGroup("", 818, 174, 214, 383)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $Label1 = GUICtrlCreateLabel("[Publisher]", 862, 194, 96, 25)
GUICtrlSetFont(-1, 14, 400, 0, "Segoe UI")
Local $Icon2 = GUICtrlCreateIcon($sPublisher, -1, 828, 191, 32, 32)
Local $PublisherHelpButton = GUICtrlCreateButton("", 990, 196, 27, 25, BitOR($BS_FLAT,$BS_ICON))
GUICtrlSetImage(-1, $sHelp, -1, 0)
GUICtrlSetTip(-1, "[License] Help")
GUICtrlSetCursor(-1, 4)
Local $CertSigningCBox = GUICtrlCreateCheckbox("Code Signing", 886, 401, 100, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Check this box to sign your launcher.")
Local $DeveloperLabel = GUICtrlCreateLabel("Developer:", 830, 229, 190, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $DeveloperInput = GUICtrlCreateInput("", 830, 249, 190, 25, BitOR($GUI_SS_DEFAULT_INPUT,$WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The name of the developer that created the portable application.")
GUICtrlSetCursor (-1, 5)
Local $ContributorsLabel = GUICtrlCreateLabel("Contributors:", 830, 285, 190, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $ContributorsInput = GUICtrlCreateInput("", 830, 305, 190, 25, BitOR($GUI_SS_DEFAULT_INPUT,$WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Specify anyone who has helped with the creation of the portable application.")
GUICtrlSetCursor (-1, 5)
Local $CreatorInput = GUICtrlCreateInput("", 830, 361, 190, 25, BitOR($GUI_SS_DEFAULT_INPUT,$WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "Specify the original developer of the PAF if you're updating someone else's work.")
GUICtrlSetCursor (-1, 5)
Local $CreatorLabel = GUICtrlCreateLabel("Creator:", 830, 341, 190, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $ExtensionInput = GUICtrlCreateInput("", 830, 457, 190, 25, BitOR($GUI_SS_DEFAULT_INPUT,$WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The certificate's file extension without the period (e.g. 'pfx' not '.pfx').")
GUICtrlSetCursor (-1, 5)
Local $ExtensionLabel = GUICtrlCreateLabel("Extension:", 830, 437, 190, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
Local $TimestampInput = GUICtrlCreateInput("", 830, 513, 190, 25, BitOR($GUI_SS_DEFAULT_INPUT,$WS_BORDER), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetBkColor(-1, 0xF4F7FC)
GUICtrlSetTip(-1, "The time-stamping service you would like to use. (Optional)")
GUICtrlSetCursor (-1, 5)
Local $TimestampLabel = GUICtrlCreateLabel("Timestamp URL:", 830, 493, 190, 20)
Local $Icon3 = GUICtrlCreateIcon($sCertificate, -1, 835, 397, 32, 32)
GUICtrlSetTip(-1, "The time-stamping service you would like to use. (Optional)")
GUICtrlCreateGroup("", -99, -99, 1, 1)

GUISetState(@SW_SHOW)

Func _ShowHelp($sSection, $iCtrlID)
	Local $sMsg = ""
	Switch $sSection
		Case "Dependencies"
			$sMsg = "- Check the boxes for what the application uses" & @CRLF & "   (Registry, Services, Fonts, etc.)." & @CRLF & _
					"- For JRE/JDK/.NET/VC++, choose 'find' to locate" & @CRLF & "   installed runtimes, 'require' to indicate the app needs them, or 'none'."
		Case "Details"
			$sMsg = "- Name: Should be the same as AppName in Launcher.ini" & @CRLF & _
					"- AppID: Globally unique id for the application." & @CRLF & "   Generally just the name without spaces." & @CRLF & _
					"- Publisher: The name of the spplication's creator." & @CRLF & "   Either a company's or the software developer." & @CRLF & _
					"- Homepage: The publisher's website." & @CRLF & _
					"- Language: The language the portableapp is available in." & @CRLF & _
					"- Category: The category the portableapp falls under." & @CRLF & _
					"- Description: Brief description of what the application is." & @CRLF & "   Maximum of 512 characters" & @CRLF & _
					"- Trademarks: Any trademark notifications that should appear." & @CRLF & _
					"- InstallType: Specific install type." & @CRLF & "   For example: Mozilla Firefox Developer Edition or JDK 25-LTS"
		Case "Publisher"
			$sMsg = "- Developer: The name of the developer that created the portable application." & @CRLF & _
					"- Contributor: Specify anyone who has helped with the creation of the portable application." & @CRLF & _
					"- Code Signing: Tick this checkbox if you have a certificate and want sign the launcher.." & @CRLF & _
					"- Creator: Specify the original developer of the PAF if you're updating someone else's work." & @CRLF & _
					"- Extension: The certificate's file extension without the period e.g. 'pfx' not '.pfx'." & @CRLF & _
					"- Timestamp URL: The URL to the time-stamping service you would like to use. Optional"
		Case "License"
			$sMsg = "Tick appropriate license flags: Shareable, Freeware," & @CRLF & "  Open Source, EULA required, and Commercial Use."
		Case "Format"
			$sMsg = "Type: Should always be 'PortableApps.comFormat'" & @CRLF & "Version: What version of the PortableApps.com Format is this portableapp in?"
		Case "SpecialPaths"
			$sMsg = "Paths inside the App directory such as 'Plugins'" & @CRLF & "  may be specified here. Use 'none' if not applicable."
		Case "Control"
			$sMsg = "This section contains the launcher control entries." & @CRLF & "  Example content is pre-filled."
		Case "Version"
			$sMsg = "- PackageVersion: This must be in 1.2.3.4 format with no other characters." & @CRLF & "- DisplayVersion: The user-friendly version." & @CRLF & "   For example: 1.5 Beta or 1.5 RC Rev. 2."
		Case Else
			$sMsg = "No help available for this section."
	EndSwitch

	Local $aPos = ControlGetPos("", "", $iCtrlID)
	If @error Then Return

	Local $aScreen = WinGetPos(ControlGetHandle("", "", $iCtrlID))
	If @error Then Return

	Local $iX = $aScreen[0] + ($aPos[2] / 2)
	Local $iY = $aScreen[1] + ($aPos[3] / 2)

	ToolTip($sMsg, $iX, $iY, "[" & $sSection & "] Help", 1, 1)
	Sleep(2000)
	ToolTip("")
	; MsgBox(64, $sSection & " Help", $sMsg)
EndFunc   ;==>_ShowHelp

; Return "1" or "0" for checkboxes
Func _CBVal($hCtrl)
	Return GUICtrlRead($hCtrl) ? "1" : "0"
EndFunc   ;==>_CBVal

; Read the raw contents of a section (including keys) from an INI/text file.
Func _ReadSectionRaw($sFile, $sSection)
	If Not FileExists($sFile) Then Return ""
	Local $h = FileOpen($sFile, 0)
	If $h = -1 Then Return ""
	Local $sHeader = "[" & $sSection & "]"
	Local $bInSection = False
	Local $sOut = ""
	While 1
		Local $line = FileReadLine($h)
		If @error Then ExitLoop
		If StringStripWS($line, 3) = "" And Not $bInSection Then ContinueLoop
		If StringLeft(StringStripWS($line, 3), 1) = ";" And Not $bInSection Then ContinueLoop
		If $bInSection Then
			; stop when we hit next section
			If StringLeft($line, 1) = "[" Then ExitLoop
			$sOut &= $line & @CRLF
		Else
			If StringStripWS($line, 3) = $sHeader Then
				$bInSection = True
			EndIf
		EndIf
	WEnd
	FileClose($h)
	; Trim trailing CRLF
	If StringRight($sOut, 2) = @CRLF Then $sOut = StringLeft($sOut, StringLen($sOut) - 2)
	Return $sOut
EndFunc   ;==>_ReadSectionRaw

; Save the AppInfo INI constructed from GUI inputs
Func _SaveAppInfo()
	; Ask user where to save
	Local $sDefault = @ScriptDir & "\AppInfo.ini"
	Local $sFile = FileSaveDialog("Save AppInfo.ini", @ScriptDir, "INI files (*.ini)|All files (*.*)", 2)
	If @error Then Return

	; Format
	Local $sType = GUICtrlRead($PAFTypeInput)
	Local $sPAFVersion = GUICtrlRead($PAFVersionInput)

	; Version
	Local $sPackageVersion = GUICtrlRead($PackageVersionInput)
	Local $sDisplayVersion = GUICtrlRead($DisplayVersionInput)

	; Details
	Local $sName = GUICtrlRead($NameInput)
	Local $sAppID = GUICtrlRead($AppIDInput)
	Local $sPub = GUICtrlRead($PublisherInput)
	Local $sHomepage = GUICtrlRead($HomepageInput)
	Local $sLanguage = GUICtrlRead($LanguageCombo)
	Local $sCategory = GUICtrlRead($CategoryCombo)
	Local $sDescription = GUICtrlRead($DescriptionInput)
	Local $sTrademarks = GUICtrlRead($TrademarksInput)
	Local $sInstallType = GUICtrlRead($InstallTypeInput)
	Local $sPlugins = GUICtrlRead($PluginsInput)
	Local $sControl = GUICtrlRead($ControlEdit)

	; Publisher
	Local $sDeveloper = GUICtrlRead($DeveloperInput)
	Local $sContributors = GUICtrlRead($ContributorsInput)
	Local $sCreator = GUICtrlRead($CreatorInput)
	Local $sExtension = GUICtrlRead($ExtensionInput)
	Local $sTimestamp = GUICtrlRead($TimestampInput)

	; Dependencies
	Local $sJava = GUICtrlRead($JavaCombo)
	Local $sJDK = GUICtrlRead($JDKCombo)
	Local $sDotNet = GUICtrlRead($Combo4)
	Local $sVC = GUICtrlRead($Combo5)

	; License
	Local $sShareable = _CBVal($ShareableCheckbox)
	Local $sFreeware = _CBVal($FreewareCheckbox)
	Local $sOpenSource = _CBVal($OpenSourceCheckbox)
	Local $sEULA = _CBVal($EULACheckbox)
	Local $sCommercial = _CBVal($CommercialUseCheckbox)

	; Build INI text
	Local $sOut = ""
	; Format section
	$sOut &= "[Format]" & @CRLF
	$sOut &= "Type=" & $sType & @CRLF
	$sOut &= "PortableAppsFormatVersion=" & $sPAFVersion & @CRLF & @CRLF

	; Version
	$sOut &= "[Version]" & @CRLF
	$sOut &= "PackageVersion=" & $sPackageVersion & @CRLF
	If $sDisplayVersion <> "" Then $sOut &= "DisplayVersion=" & $sDisplayVersion & @CRLF
	$sOut &= @CRLF

	; Details
	$sOut &= "[Details]" & @CRLF
	If $sName <> "" Then $sOut &= "Name=" & $sName & @CRLF
	If $sAppID <> "" Then $sOut &= "AppID=" & $sAppID & @CRLF
	If $sPub <> "" Then $sOut &= "Publisher=" & $sPub & @CRLF
	If $sHomepage <> "" Then $sOut &= "Homepage=" & $sHomepage & @CRLF
	If $sLanguage <> "" Then $sOut &= "Language=" & $sLanguage & @CRLF
	If $sCategory <> "" Then $sOut &= "Category=" & $sCategory & @CRLF
	If $sDescription <> "" Then $sOut &= "Description=" & $sDescription & @CRLF
	If $sTrademarks <> "" Then $sOut &= "Trademarks=" & $sTrademarks & @CRLF
	If $sInstallType <> "" Then $sOut &= "InstallType=" & $sInstallType & @CRLF
	$sOut &= @CRLF

	; Publisher
	$sOut &= "[Publisher]" & @CRLF
	If $sName <> "" Then $sOut &= "Developer=" & $sDeveloper & @CRLF
	If $sAppID <> "" Then $sOut &= "Contributor=" & $sContributors & @CRLF
	If $sPub <> "" Then $sOut &= "Creator=" & $sCreator & @CRLF
	If $sHomepage <> "" Then $sOut &= "Extension=" & $sExtension & @CRLF
	If $sHomepage <> "" Then $sOut &= "Timestamp=" & $sTimestamp & @CRLF
	$sOut &= @CRLF

	; License
	$sOut &= "[License]" & @CRLF
	$sOut &= "Shareable=" & $sShareable & @CRLF
	$sOut &= "Freeware=" & $sFreeware & @CRLF
	$sOut &= "OpenSource=" & $sOpenSource & @CRLF
	$sOut &= "EULARequired=" & $sEULA & @CRLF
	$sOut &= "CommercialUse=" & $sCommercial & @CRLF & @CRLF

	; SpecialPaths
	$sOut &= "[SpecialPaths]" & @CRLF
	If $sPlugins <> "" Then $sOut &= "Plugins=" & $sPlugins & @CRLF
	$sOut &= @CRLF

	; Dependencies
	$sOut &= "[Dependencies]" & @CRLF
	$sOut &= "JavaRuntime=" & $sJava & @CRLF
	$sOut &= "JavaJDK=" & $sJDK & @CRLF
	$sOut &= "DotNet=" & $sDotNet & @CRLF
	$sOut &= "VCRedist=" & $sVC & @CRLF

	; Control: attempt to preserve as-is (if user left it as block)
	$sOut &= $sControl & @CRLF

	; Write file
	Local $hFile = FileOpen($sFile, 2)
	If $hFile = -1 Then
		MsgBox(16, "Error", "Unable to open file for writing: " & $sFile)
		Return
	EndIf
	FileWrite($hFile, $sOut)
	FileClose($hFile)
	MsgBox(64, "Saved", "AppInfo.ini saved to:" & @CRLF & $sFile)
EndFunc   ;==>_SaveAppInfo

; Import existing AppInfo.ini and populate controls where possible
Func _ImportAppInfo()
	Local $sFile = FileOpenDialog("Select AppInfo.ini to Import", @ScriptDir, "INI files (*.ini)|All files (*.*)", 1)
	If @error Then Return
	; Populate known keys using IniRead where possible
	; Format
	Local $sType = IniRead($sFile, "Format", "Type", "")
	If $sType <> "" Then GUICtrlSetData($PAFTypeInput, $sType)
	Local $sPAFVer = IniRead($sFile, "Format", "PortableAppsFormatVersion", "")
	If $sPAFVer <> "" Then GUICtrlSetData($PAFVersionInput, $sPAFVer)

	; Version
	Local $sPkgVer = IniRead($sFile, "Version", "PackageVersion", "")
	If $sPkgVer <> "" Then GUICtrlSetData($PackageVersionInput, $sPkgVer)
	Local $sDispVer = IniRead($sFile, "Version", "DisplayVersion", "")
	If $sDispVer <> "" Then GUICtrlSetData($DisplayVersionInput, $sDispVer)

	; Details
	Local $sName = IniRead($sFile, "Details", "Name", "")
	If $sName <> "" Then GUICtrlSetData($NameInput, $sName)
	Local $sAppID = IniRead($sFile, "Details", "AppID", "")
	If $sAppID <> "" Then GUICtrlSetData($AppIDInput, $sAppID)
	Local $sPub = IniRead($sFile, "Details", "Publisher", "")
	If $sPub <> "" Then GUICtrlSetData($PublisherInput, $sPub)
	Local $sHomepage = IniRead($sFile, "Details", "Homepage", "")
	If $sHomepage <> "" Then GUICtrlSetData($HomepageInput, $sHomepage)
	Local $sLanguage = IniRead($sFile, "Details", "Language", "")
	If $sLanguage <> "" Then GUICtrlSetData($LanguageCombo, $sLanguage)
	Local $sCategory = IniRead($sFile, "Details", "Category", "")
	If $sCategory <> "" Then GUICtrlSetData($CategoryCombo, $sCategory)
	Local $sDesc = IniRead($sFile, "Details", "Description", "")
	If $sDesc <> "" Then GUICtrlSetData($DescriptionInput, $sDesc)
	Local $sTrademarks = IniRead($sFile, "Details", "Trademarks", "")
	If $sTrademarks <> "" Then GUICtrlSetData($TrademarksInput, $sTrademarks)
	Local $sInstallType = IniRead($sFile, "Details", "InstallType", "")
	If $sInstallType <> "" Then GUICtrlSetData($InstallTypeInput, $sInstallType)

	; License
	Local $sShare = IniRead($sFile, "License", "Shareable", "")
	If $sShare <> "" Then GUICtrlSetState($ShareableCheckbox, $sShare = "1")
	Local $sFree = IniRead($sFile, "License", "Freeware", "")
	If $sFree <> "" Then GUICtrlSetState($FreewareCheckbox, $sFree = "1")
	Local $sOS = IniRead($sFile, "License", "OpenSource", "")
	If $sOS <> "" Then GUICtrlSetState($OpenSourceCheckbox, $sOS = "1")
	Local $sE = IniRead($sFile, "License", "EULARequired", "")
	If $sE <> "" Then GUICtrlSetState($EULACheckbox, $sE = "1")
	Local $sC = IniRead($sFile, "License", "CommercialUse", "")
	If $sC <> "" Then GUICtrlSetState($CommercialUseCheckbox, $sC = "1")

    ; Update [Team] to [Publisher] if exists
    Local $bResult = _IniRenameSectionName($sFile, "Team", "Publisher")

    ; If it failed and we have a backup, restore it
    If Not $bResult Then
        MsgBox(3, "AppInfo INI Configuration Generator", "Failed to convert [Team] to [Publisher]! You'll need to do this manually.")
    EndIf

	; Publisher
	Local $sC = IniRead($sFile, "Publisher", "CertSigning", "")
	If $sC <> "" Then GUICtrlSetState($CertSigningCBox, $sC = "1")
	Local $sDev = IniRead($sFile, "Publisher", "Developer", "")
	If $sDev <> "" Then GUICtrlSetData($DeveloperInput, $sDev)
	Local $sContrib = IniRead($sFile, "Publisher", "Contributor", "")
	If $sContrib <> "" Then GUICtrlSetData($ContributorsInput, $sContrib)
	Local $sCre = IniRead($sFile, "Publisher", "Creator", "")
	If $sCre <> "" Then GUICtrlSetData($CreatorInput, $sCre)
	Local $sExt = IniRead($sFile, "Publisher", "Extension", "")
	If $sExt <> "" Then GUICtrlSetData($ExtensionInput, $sExt)
	Local $sTimestamp = IniRead($sFile, "Publisher", "Timestamp", "")
	If $sTimestamp <> "" Then GUICtrlSetData($TimestampInput, $sTimestamp)

	; SpecialPaths
	Local $sPlugins = IniRead($sFile, "SpecialPaths", "Plugins", "")
	If $sPlugins <> "" Then GUICtrlSetData($PluginsInput, $sPlugins)

	; Dependencies
	Local $sJava = IniRead($sFile, "Dependencies", "JavaRuntime", "")
	If $sJava <> "" Then GUICtrlSetData($JavaCombo, $sJava)
	Local $sJDK = IniRead($sFile, "Dependencies", "JavaJDK", "")
	If $sJDK <> "" Then GUICtrlSetData($JDKCombo, $sJDK)
	Local $sDotNet = IniRead($sFile, "Dependencies", "DotNet", "")
	If $sDotNet <> "" Then GUICtrlSetData($Combo4, $sDotNet)
	Local $sVC = IniRead($sFile, "Dependencies", "VCRedist", "")
	If $sVC <> "" Then GUICtrlSetData($Combo5, $sVC)

	; Control section: read raw block
	Local $sControlRaw = _ReadSectionRaw($sFile, "Control")
	If $sControlRaw <> "" Then
		GUICtrlSetData($ControlEdit, "[Control]" & @CRLF & $sControlRaw)
	EndIf

	MsgBox(64, "Import", "Import complete (where keys existed).")
EndFunc   ;==>_ImportAppInfo

; Clear UI to defaults
Func _ClearAll()
	GUICtrlSetData($PAFTypeInput, "PortableApps.comFormat")
	GUICtrlSetData($PAFVersionInput, "3.9")
	GUICtrlSetData($PackageVersionInput, "0.0.0.0")
	GUICtrlSetData($DisplayVersionInput, "")

	GUICtrlSetData($NameInput, "")
	GUICtrlSetData($AppIDInput, "")
	GUICtrlSetData($PublisherInput, "")
	GUICtrlSetData($HomepageInput, "")
	GUICtrlSetData($LanguageCombo, "Multilingual")
	GUICtrlSetData($CategoryCombo, "Accessibility")
	GUICtrlSetData($DescriptionInput, "")
	GUICtrlSetData($TrademarksInput, "")
	GUICtrlSetData($InstallTypeInput, "")
	GUICtrlSetData($PluginsInput, "none")
	GUICtrlSetData($DeveloperInput, "")
	GUICtrlSetData($ContributorsInput, "")
	GUICtrlSetData($CreatorInput, "")
	GUICtrlSetData($ExtensionInput, "")
	GUICtrlSetData($TimestampInput, "")
	GUICtrlSetData($ControlEdit, "[Control]" & @CRLF & "Icons=2" & @CRLF & "Start=AppNamePortable.exe" & @CRLF & "Start1=AppNamePortable.exe" & @CRLF & "Name1=AppName Portable" & @CRLF & "Start2=AppNamePortable2.exe" & @CRLF & "Name2=AppName Portable Other Part")

	; combos
	GUICtrlSetData($JavaCombo, "none")
	GUICtrlSetData($JDKCombo, "none")
	GUICtrlSetData($Combo4, "none")
	GUICtrlSetData($Combo5, "none")

	; uncheck checkboxes
	Local $aAllCBoxes = [$ShareableCheckbox, $FreewareCheckbox, $OpenSourceCheckbox, $EULACheckbox, $CommercialUseCheckbox, $CertSigningCBox]
	For $i = 0 To UBound($aAllCBoxes) - 1
		GUICtrlSetState($aAllCBoxes[$i], $GUI_UNCHECKED)
	Next
EndFunc   ;==>_ClearAll

#CS
Func _InitializeStatusBar()
    $g_hStatusBar = _GUICtrlStatusBar_Create($g_hMainGUI)
    Local $aParts[3] = [300, 400, -1]
    _GUICtrlStatusBar_SetParts($g_hStatusBar, $aParts)
    _GUICtrlStatusBar_SetText($g_hStatusBar, "Ready", 0)
    _GUICtrlStatusBar_SetText($g_hStatusBar, "No file loaded", 1)
EndFunc

Func _UpdateStatus($sText, $iPart = 0)
    _GUICtrlStatusBar_SetText($g_hStatusBar, $sText, $iPart)

EndFunc
#CE

Func _HandleControlEvent($nCtrlID)
	If $nCtrlID > 0 Then
		$g_bModified = True
		; _UpdateStatus("Modified", 1)
	EndIf
EndFunc   ;==>_HandleControlEvent

#Region INI Management Functions
; Renames a section in an INI file
; Parameters:
;   $sFilePath - Full path to the INI file
;   $sOldSection - Current section name (without brackets)
;   $sNewSection - New section name (without brackets)
; Returns:
;   True on success, False on failure
;   @error = 1: File doesn't exist
;   @error = 2: Old section not found
;   @error = 3: New section already exists
;   @error = 4: File read error
;   @error = 5: File write error
Func _IniRenameSectionName($sFilePath, $sOldSection, $sNewSection)
    ; Validate file exists
    If Not FileExists($sFilePath) Then
        Return SetError(1, 0, False)
    EndIf

    ; Strip any brackets if user included them
    $sOldSection = StringRegExpReplace($sOldSection, "^\[|\]$", "")
    $sNewSection = StringRegExpReplace($sNewSection, "^\[|\]$", "")

    ; Validate section names
    If StringStripWS($sOldSection, 3) = "" Or StringStripWS($sNewSection, 3) = "" Then
        Return SetError(2, 0, False)
    EndIf

    ; Read entire file
    Local $hFile = FileOpen($sFilePath, 0)
    If $hFile = -1 Then Return SetError(4, 0, False)

    Local $sContent = FileRead($hFile)
    FileClose($hFile)

    If @error Then Return SetError(4, 0, False)

    ; Check if old section exists
    If Not StringInStr($sContent, "[" & $sOldSection & "]") Then
        Return SetError(2, 0, False)
    EndIf

    ; Check if new section already exists
    If StringInStr($sContent, "[" & $sNewSection & "]") Then
        Return SetError(3, 0, False)
    EndIf

    ; Replace the section name (case-insensitive)
    Local $sPattern = "(?i)^\[" & StringRegExpReplace($sOldSection, "([\[\](){}.*+?\\^$|])", "\\$1") & "\]"
    $sContent = StringRegExpReplace($sContent, $sPattern, "[" & $sNewSection & "]")

    ; Write back to file
    $hFile = FileOpen($sFilePath, 2) ; Overwrite mode
    If $hFile = -1 Then Return SetError(5, 0, False)

    FileWrite($hFile, $sContent)
    Local $iWriteError = @error
    FileClose($hFile)

    If $iWriteError Then Return SetError(5, 0, False)

    Return True
EndFunc

; Renames a section with backup creation
; Parameters:
;   $sFilePath - Full path to the INI file
;   $sOldSection - Current section name
;   $sNewSection - New section name
;   $bCreateBackup - Create .bak file before modifying (default: True)
; Returns:
;   True on success, False on failure
Func _IniRenameSectionNameSafe($sFilePath, $sOldSection, $sNewSection, $bCreateBackup = True)
    If Not FileExists($sFilePath) Then
        Return SetError(1, 0, False)
    EndIf

    ; Create backup if requested
    If $bCreateBackup Then
        Local $sBackupPath = $sFilePath & ".bak"
        If Not FileCopy($sFilePath, $sBackupPath, 1) Then
            Return SetError(6, 0, False)
        EndIf
    EndIf

    ; Attempt the rename
    Local $bResult = _IniRenameSectionName($sFilePath, $sOldSection, $sNewSection)

    ; If it failed and we have a backup, restore it
    If Not $bResult And $bCreateBackup Then
        Local $sBackupPath = $sFilePath & ".bak"
        If FileExists($sBackupPath) Then
            FileCopy($sBackupPath, $sFilePath, 1)
        EndIf
    EndIf

    Return SetError(@error, @extended, $bResult)
EndFunc

; Gets all section names from an INI file
; Parameters:
;   $sFilePath - Full path to the INI file
; Returns:
;   Array of section names (without brackets) on success
;   Empty array on failure
Func _IniGetSectionNames($sFilePath)
    Local $aSections[0]

    If Not FileExists($sFilePath) Then Return $aSections

    Local $hFile = FileOpen($sFilePath, 0)
    If $hFile = -1 Then Return $aSections

    While 1
        Local $sLine = FileReadLine($hFile)
        If @error Then ExitLoop

        ; Match section headers [SectionName]
        Local $aMatch = StringRegExp($sLine, "^\s*\[([^\]]+)\]", 1)
        If Not @error And IsArray($aMatch) Then
            ReDim $aSections[UBound($aSections) + 1]
            $aSections[UBound($aSections) - 1] = $aMatch[0]
        EndIf
    WEnd

    FileClose($hFile)
    Return $aSections
EndFunc
#EndRegion

Func _CleanupAndExit()
	If $g_bModified Then
		Local $iResponse = MsgBox(3, "AppInfo INI Configuration Generator", "Save changes before exiting?")
		If $iResponse = 6 Then ; Yes
			; Save logic here
		ElseIf $iResponse = 2 Then ; Cancel
			Return
		EndIf
	EndIf

	Exit
EndFunc   ;==>_CleanupAndExit

While 1
	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case $GUI_EVENT_CLOSE, $ExitBtn
			_CleanupAndExit()
		Case $DependenciesHelpButton
			_ShowHelp("Dependencies", $DependenciesHelpButton)
		Case $DetailsHelpButton
			_ShowHelp("Details", $DetailsHelpButton)
		Case $LicenseHelpButton
			_ShowHelp("License", $LicenseHelpButton)
		Case $FormatHelpButton
			_ShowHelp("Format", $FormatHelpButton)
		Case $SpecialPathsHelpButton
			_ShowHelp("SpecialPaths", $SpecialPathsHelpButton)
		Case $ControlHelpButton
			_ShowHelp("Control", $ControlHelpButton)
		Case $VersionHelpButton
			_ShowHelp("Version", $VersionHelpButton)
		Case $PublisherHelpButton
			_ShowHelp("Publisher", $PublisherHelpButton)

		Case $OpenLauncherGenerator
			Run(".\LauncherINIGenerator.exe")

		Case $OpenInstallerGenerator
			Run(".\InstallerINIGenerator.exe")

		Case $SaveBtn
			_SaveAppInfo()

		Case $ClearBtn
			; Confirm then clear
			If MsgBox(4, "Clear", "Clear all fields and restore defaults?") = 6 Then _ClearAll()

		Case $ImportBtn
			_ImportAppInfo()
	EndSwitch
WEnd
