
## Introduction
----------
This is a fork of the official [PortableApps.com Launcher][1]. I forked this project because I wanted to incorporate some ideas I had that I believe would better this project in its entirety. So instead of going to [PortableApps.com][2] and sharing my ideas ([a superfluous attempt][3] was already made; to what seemed like no avail), I feel it would be much more advantageous on my part to just implement these ideas instead. 

<del>I have no real expectations that any of these ideas will actually be pulled into the official version of __PAL__ (_PortableApps.com Launcher_) but if any of them do than kudos.. lol. If anyone is actually reading this and does find some of these concepts to be useful then maybe support my effort in supporting their cause.</del>

I've come to the conclusion that I no longer care to add any support to the official version of PAL. The current developers of the official builds are completely useless in the sense that they treat any progressive ideas as the Devil's work&mdash;I'm only kidding, although I do think to be a part of their exclusive community you need a members-only Letterman's Jacket. I'm tired of trying to help their cause. I kept on sharing my ideas with them over and over again only to be dismissed and ignored. It was as if they couldn't wait to deprecate my ideas. So instead of holding my breathe, I'll just take this project to new heights; that far exceeds the official predecessor (which, by the way, hasn't received any real worthwhile development in years).

I should say that what I'm going to be adding to this variant of PAL is what works for me and my environment. All the concepts that you find here should work with any other environment unless explicitly expressed otherwise. So like I say in a recent motto I have recently just adopted, _"Port and let portable!"_ — You see what I did there? Lol. If you don't, no worries; I guess I should just _live and let live_.

## Concepts
----------

Here's a small list of a few ideas that I want to try and implement with this project. These are just things I plan on working on in my spare time and while the ideas listed below are not recognized by PortableApps.com please be aware that using some of the things you find in this variant of PAL can and most likely will be buggy. 

* __Support for NSIS3:__ (DONE)

<del>Well, support for [NSISPortable][4] rather which is packaged with the latest release of NSIS. The current official release of PAL is using NSIS v2.46.5-Unicode which is actually packaged with the project. So I would like to completely remove the need for this dependency entirely.</del>

* __Manifest Support:__ (DONE)

<del>With the release of NSIS3, support for adding an application manifest is done automatically and defaults to supporting Windows 7 and later versions.</del>  

* __.NET Handling:__ (DONE)

<del>I'll just be adding a means for checking a system for the required version of the .NET Framework because John T. Haller [explains][5] in great detail how the .NET Framework has no real practical means for portability when it comes to Portable Apps. He ends his article with,</del> 
>"_...applications based on .NET simply can't be considered portable due to the fact that the files they need can't be bundled portably and won't be on a large number of PCs you encounter in the wild._"

* __Support Registering Libraries:__ (DONE)

<del>The official release of PAL has no native support for registering libraries (DLLs), so I will try to add support for registering files. Be aware though that a program developer has complete control over what happens when you call _RegSvr32_ which is what is used by `RegDLL` (the native command used by NSIS for registering files). With that being said, my ideas on this topic may be buggy.</del>

* __Support Services:__ (DONE)

<del>The support for services is by default disabled in the official builds of PAL. In the source code it states that they might be unstable and the plugin is large in size. I plan on not using a plugin to support services, instead I plan on dealing with this by using the command line with a few functions and macros to try and keep things simple.</del><br /><del>__TODO:__ Still need to rewrite the `Services.nsh` segment to handle services without using custom code or a plugin.</del>

* __Language Handling:__ (In Progress)

The official PAL's language handling is based on the setting of the PortableApps.com Platform language. Not every user of a PAF uses the PortableApps.com Platform so I'm rewritting the language handling to support and be based on the end-users operating system language. As it is written now, if you want language support you need to use the `custom.nsh` file.<br />__TODO:__ Fallback on the original method to use the `Launcher.ini` but still be based on the OS language.

* __Redevelop Generator Wizard:__ (Brainstorming)

I'm conceptualizing and outlining ideas for a nice GUI which will potentially allow the user to just select certain checkboxes for the `[Dependencies]` section which is discussed in greater detail further below. This way I can eliminate the need to use all those keys in the _AppInfo.ini_ file. I'd like to point out that my knowledgebase in this area of NSIS is primitive and/or novice at best so I'm certainly open to any helpful input and suggestions in this area.

* __Rename This Project:__ (Brainstorming)

I've decided to rename this project to set it a part from the official PA.c Launcher. This rebranding is to help make this project it's own entity. So instead of people looking at the official builds of PAL and thinking, _"Wow! How cool is that feature?! I wonder who had the idea to add that?"_ they can think that about my version and know exactly who added that _cool_ feature instead; __me__.

* __Redevelop PA.c Installer:__ (Near Future)

I've been thinking I should probably go ahead and add my two-cents in the [PortableApps.com Installer](https://portableapps.com/apps/development/portableapps.com_installer). That project most certainly could use new life as well. However, if and when I do decide to start a new repository for the PA.c Installer, be aware that I'm going to probably change the output extension of the generated installer&mdash;which is currently something similar to `ApplicationPortable_1.0.2_English.paf.exe` to something else like `ApplicationPortable_1.0.2_English.mps.exe` (`.mps.exe` - _movable program scheme_; first thing that came to mind ..Lol.). I might just drop the `.paf.exe` and just stick with `.exe`. I don't know; I'll cross that bridge when I get there. 

* __Etc. Etc. And So On:__ (On Going Process)

Other things could follow depending on my availability, interest.. and of course the interest and support from others. So with that being said, this little project might not even see the light of day. Lol.

## Features
----------

#### __PortableApps.comLauncher.nsi__
 - <del>Added code to add a manifest file to the Launcher.exe for better user privileges support. Refer to line 80 for referance.</del>
 - Added support for using new NSISPortable which is the new NSIS3 with Unicode support. Removed NSIS in the App directory.
 - Adding an application manifest is now handled by default since NSIS3. The code has been commented out.
 - Added support for automatic code signing. Refer to the code block on line 709 for referance.
 - Added support to prevent a user from shutting down or at least allow enough time to cleanup before exiting then shutting down.
 - Added support for .NET checking from both 4.0 and below to 4.5 and above. See `DotNet.nsh` in the segments folder for referance. 

----------

#### __Launcher.ini__
__Environment Variables__
`%PROGRAMDATA%` has now been added and kept %ALLUSERSAPPDATA% for backwards compatibilty. Both can be used anywhere you can use an evironment variable.
`%PAL:CommonFiles%` may now be used within the _Launcher.ini_ configuration file. This environment variable will point to `..\PortableApps\CommonFiles` if applicable. Can be used anywhere you can use an environment variable.
> Example:
> ```INI
> [Environment]
> PATH=%PATH%;%PAL:CommonFiles%\AndroidSDK
> JAVA_HOME=%PAL:CommonFiles%\Java64
> ```

Added new keys to the `[Activate]` section. They are as follows (a short description of what each key means or does can be found further below):
> Note: You should only use the following keys if you need them, otherwise they should be omitted entirely.
```INI
[Activate]
Registry=true
RegRedirection=true
RegCopyKeys=true
Redirection=true
ForceRedirection=true
ExecAsUser=true
Services=true
RegDLLs=true
Tasks=true
Java=true
JDK=true
XML=true
Ghostscript=true
FontsFolder=true
FileCleanup=true
```

* __Registry:__ Add support for minipulating the Windows Registry.

* __RegRedirection:__ Enable support for enabling/disabling registry redirection.

* __RegCopyKeys:__ Enable support for copying registry keys to a special hive (`HKCU\Software\PortableApps.com`) before launching the application and restoring the keys after the application exits. See `RegistryCopyKeys.nsh` in the Segments directory.
> To use this feature add the section `[RegistryCopyKeys]` to the `Launcher.ini` file. Each entry should be the path to the registry key to be copied back and forth. Example usage:
> ```INI
> [RegistryCopyKeys]
> 1=HKCU\Software\MyProgram\ExtraCareNeededKey
> 2=HKLM\SOFTWARE\MyProgram\AnotherFragileKey
> ```

* __Redirection:__ Enable support for enabling/disabling file system redirection.

* __ForceRedirection:__ Checks using the variable `$Bit` to disable/enable file system redirection.

* __ExecAsUser:__ For applications which need to run as normal user but need the launcher to have elevated privileges. [Read this](http://mdb-blog.blogspot.com/2013/01/nsis-lunch-program-as-user-from-uac.html) for more information on this concept.

* __Services:__ Add support for handling Windows Services.
> To use this feature add the section `[Service1]` (numerical ordering) to the `Launcher.ini` file. Each entry supports six keys which are as follows:

| __Key__ 	| __Value__ 	|
|:--------	|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	|
| Name 	| The local/portable service name. 	|
| Path 	| The path to the portable service executable. Supports environment variables. 	|
| Type 	| Specify whether you are dealing with a service, a kernel driver or a file system driver, etc.<br />Choose from: _own_, _share_, _interact_, _kernel_, _filesys_, _rec_ 	|
| Start 	| Specify when the service is supposed to start.<br />Choose from: _boot_, _system_, _auto_, _demand_, _disabled_, _delayed-auto_ 	|
| Depend 	| List any dependencies here separated by `/` (forward slash). 	|
| IfExists 	| If the service already exists, you can either skip it or replace it with the portable version of the service (the original service will be restored afterwards).<br />Choose from: _skip_, _replace_ 	|

> Example usage:
> ```INI
> [Service1]
> Name=SomeServiceName
> Path=%PAL:AppDir%\service32.sys
> Type=kernel
> Start=auto
> Depend=
> IfExists=replace
>
> [Service2]
> Name=AnotherService
> Path=%PAL:DataDir%\service64.exe
> Type=own
> Start=demand
> Depend=
> IfExists=skip
> ```

* __RegDLLs:__ Add support for handling library (DLLs) file registration.
> To use this feature add the section `[RegisterDLL1]` (numerical ordering) to the `Launcher.ini` file. Each entry supports two keys; _ProgID_ (The DLL's ProgID) and _File_ (The path to DLL. Supports environment variables). Example usage:
> ```INI
> [RegisterDLL1]
> ProgID=MyAppControlPanel
> File=%PAL:AppDir%\controller.cpl
>
> [RegisterDLL2]
> ProgID=DynamicLibrary
> File=%PAL:DataDir%\dynlib.dll
> ```

* __Tasks:__ Enable the TaskCleanup segment for removing any Windows Tasks that were added during runtime.
> To use this feature add the section `[TaskCleanup]` to the `Launcher.ini` file. Each entry should be the Windows Task name to be removed. Example usage:
> ```INI
> [TaskCleanup]
> 1=MyAppTask1
> 2=Another Task w/ Spaces
> ```

* __Java:__ Add support for the Java Runtime Environment.

* __JDK:__ Add support for the Java Development Kit.

* __XML:__ Add XML support.

* __Ghostscript:__ Add Ghostscript support.

* __FontsFolder:__ Allows the portable application to support fonts within the directory `..\Data\Fonts`. Any fonts added in this folder will be added and are available for usage during runtime. Be aware, the more fonts to process the longer it will take for the launcher to load and unload these fonts.
> Supported Fonts: 
> - .fon
> - .fnt
> - .ttf
> - .ttc
> - .fot
> - .otf
> - .mmm
> - .pfb
> - .pfm

* __FileCleanup:__ Enable support for adding the section `[FilesCleanup]` in `Launcher.ini`. See `FilesCleanup.nsh` in the Segments directory.
> To use this feature add the section `[FilesCleanup]` to the `Launcher.ini` file. Each entry should be the path to the file that needs deleting. Supports environment variables. Example usage:
> ```INI
> [FilesCleanup]
> 1=%PAL:DataDir%\uselessUpgradeFile.xml
> 2=%APPDATA%\MyProgram\purposelessCfg.ini
> ```

----------

#### __AppInfo.ini__
Added the section `[Team]` for use with code signing and application specifications. New keys are as follows (a short description of what each key means or does can be found further below):
> Note: You should only use the following keys if you need them, otherwise they should be omitted entirely.
```INI
[Team]
Developer=demon.devin
Contributors=DoomStorm
Creator=FukenGruven
CertSigning=true
CertExtension=p12
CertTimestamp=VeriSign
```
* __Developer:__ The name of the developer that created the portable application.

* __Contributors:__ Specify here anyone who has helped with the creation of the portable application.

* __Creator:__ Specify here the original developer of the PAF if you're updating someone else's work.

* __CertSigning:__ If set to true, the `Launcher.exe` will automatically be signed using dual signature hashing algorithm standards (_SHA256_ and _SHA1_). I decided to use dual signing because Windows 8 supports SHA256 Code Signing Certificates (SHA-2 hashing algorithm); whereas, Windows 7 may only support SHA-1 Code Signing Certificates (SHA-1 hashing algorithm). It should be noted that Windows 10 has stopped accepting SHA-1 certificates and certificate chains for Authenticode-signed binaries (unless a timestamp marked the binary as being signed before 1/1/2016). You can visit this [Microsoft Security Advisory article][MSAdvisory] on the availability of SHA-2 code signing support for Windows 7 and Windows Server 2008 R2 for more information about this topic.
>__*ATTENTION:*__ As it is written right now, the `PortableApps.comLauncherGenerator.exe` expects the certificate file to be the developer's name (same as the `[Team]Developer` key's value) and located in `..\Other\Source\Contrib\certificates`. 
> 
> _NOTE_: If your certificate requires you to use a password, refer to lines 741 and 742 and input your password on column 62.
> Be sure it is similar to something like this: `/p "PASSWORD"` where PASSWORD is your password.
* __CertExtension:__ If the key `CertSigning` is set to true then this should be set to the certificate's file extension without the period (e.g. "_pfx_" not "_.pfx_").
* __CertTimestamp:__ Here you can choose which time-stamping service you would like to use. Refer to the table below for a small list of available services and their available hashing algorithms. I would recommend using a service which uses both signature hashes. Be aware that this key is case-sensitive. If this key is omitted, the compiler will default to using _Comodo_.

|       __CertTimestamp__=*`Value`*     	|     __Timestamp Service__    	| __Algorithms__ 	|
|:------------------------	|:----------------------------	|:--------------------	|
| `Comodo`     	| Comodo Group, Inc.           	| _SHA-1_ & _SHA-2_    	|
| `Verisign`   	| Verisign, Inc.               	| _SHA-1_ & _SHA-2_    	|
| `GlobalSign` 	| GMO GlobalSign, Inc.         	| _SHA-1_ & _SHA-2_    	|
| `DigiCert`   	| DigiCert, Inc.               	| _SHA-1_ & _SHA-2_    	|
| `Starfield`  	| Starfield Technologies, LLC. 	| _SHA-1_ & _SHA-2_    	|
| `SwissSign`  	| SwissSign AG                 	| _SHA-2_              	|

I've added several new keys to the `[Dependencies]` section. These newly added keys act like on/off switches to allow support for certain plugins and/or macros/functions (a short description of what each key means or does can be found further below):
> Note: You should only use the following keys if you need them, otherwise they should be omitted entirely.
```INI
[Dependencies]
ElevatedPrivileges=true
UsesJava=true
UsesGhostscript=true
UsesDotNetVersion=4.5
UseStdUtils=true
InstallINF=true
RegistryValueWrite=true
FileWriteReplace=true
FileLocking=true
Firewall=true
Junctions=true
ACLRegSupport=true
ACLDirSupport=true
RMEmptyDir=true
LocalLow=true
PublicDoc=true
CompareVersions=true
ConfigFunctions=true
CloseWindow=true
JSONSupport=true
RestartSleep=500
WinMessages=true
LineWrite=true
```
* __ElevatedPrivileges:__ For launchers which need to run with elevated privileges.

* __UsesJava:__ Specifies whether the portable application makes use of [Java Portable][JavaPortable].

* __UsesGhostscript:__ Specifies whether the portable application makes use of [Ghostscript Portable][GhostscriptPortable].

* __UsesDotNetVersion:__ Specify the minimum required version of the .NET framework the portable application needs. Values can be from `1.0` thru `4.7` (*e.g.* `UsesDotNetVersion=1.1` or `UsesDotNetVersion=4.6.2`).

* __UseStdUtils:__ Include the _StdUtils_ plug-in without `ExecAsUser`

* __InstallINF:__ Add support and macros for INF installation. Refer to the `Services.nsh` file in the Segments directory for reference.

* __RegistryValueWrite:__ If you're using `[RegistryValueWrite]` than set this to true otherwise the function is inaccurate.

* __FileWriteReplace:__ Enables the Replace functionality in `[FileWrite]`

* __FileLocking:__ Enable this to prevent ejection/unplugging problems for USB devices. Windows Explorer tend to lock application's DLL(s). 
__Note:__ As of right now, this only enables support for using `${If} ${FileLocked}` and/or `${IfNot} ${FileLocked}` in the `custom.nsh` file. 
__ToDo:__ Handle without the use of `custom.nsh`. (Got a couple ideas already. Check back soon.)

* __Firewall:__ Enable Firewall support.

* __Junctions:__ Enable support for Junctions (_SymLinks_) functionality.

* __ACLRegSupport:__ Enable support for AccessControl on registry keys.

* __ACLDirSupport:__ Enable support for AccessControl on directories.

* __RMEmptyDir:__ Enable the function `RMEmptyDir`. See the `Core.nsh` segment on line 1192 for reference.

* __LocalLow:__ Enable the function `GetLocalAppDataLow`. See the `Core.nsh` segment on line 1351 for reference.

* __PublicDoc:__ Enable the function `GetPublicDoc`. See the `Core.nsh` segment on line 1427 for reference.

* __CompareVersions:__ Enable the function `Compare`. See the `Core.nsh` segment on line 141 for reference.

* __ConfigFunctions:__ Enable `ConfigWrite(s)` and `ConfigRead(s)` functions. See the `Core.nsh` segment on line 236 for reference.

* __CloseWindow:__ Enable `Close` function. See the `Core.nsh` segment on line 1288 for reference.

* __JSONSupport:__ Include the _nsJSON_ plugin allowing `nsJSON::Get`, `nsJSON::Set`, and `nsJSON::Serialize` for use within `custom.nsh`.

* __RestartSleep:__ Set this to a numerical value (in milliseconds) to set a sleep value for applications that need to restart (i.e. Notepad++ after installing new plugins).

* __WinMessages:__ Include the `WinMessages.nsh` file.

* __LineWrite:__ Include the `LineWrite.nsh` file.

## Documentation
----------

I've begin a small website dedicated to documenting anything I've deemed invaluable in my findings while I've devoted my time to PAFing. You should know that the content you find there is (or will be over time) a collection of help files and guides mostly focused on the making of PAFs. In some circles it's considered the most complete guide to making PAFs with PAL. So I encourage any novice PAFers to give it a visit; you can read up on a wide range of related topics from Registry best-practices to making your own self-signed certificates to sign your PAFs with. 

I've started this because the documentation which is supplied with PAL by PortableApps.com doesn't have, in my humble opinion, any solid information on the power and complexities it's framework has. So I've taken it upon myself to start working on jotting down this unofficial, but my official, guide to making a PAF with PAL. As time has gone by the website has taken on new meaning which now helps developers to better understand the inner workings of the PAL I'm working on here. Not only that but it also goes into great detail in explaining how certain applications and their components are used on a system; which will help you better understand what you're using in this project and why.

Because I am only just one man who has to live outside of my computer, the documentation project (like this project) will take sometime to finish (if ever) so please forgive me on it's incompleteness. This will also serve as a reference/cheat-sheet for those (I know I'll need it, which is partly why I've started it) who need a quick reminder on certain functions and macros for use within the `custom.nsh` file. As an added bonus, all (not yet but most) of the source code I've used here is outlined and better explained/documented there as well. For instance, visit this [page][DocsRegDLL] for a short guide on registering DLLs and all the macros I used to create the `RegisterDLL.nsh` segment. You can visit this [page][DocsServices] for an exhaustive tutorial on dealing with Windows Services; plus it explains what each macro is and does within the `Services.nsh` segment and how to use them in action.

#### __Visit the Docs:__ [The PAF Docs][DocsHome]

## Contributors
----------

This forked project has been started by [demon.devin][author] and hopefully maintained on a regular basis. However, if you would like to be a part of this then please do not hesitate on getting involved! I'm always open to new ideas and a willingness for the betterment of all things code. =)

A special thanks is expressed for [DoomStorm][TekSpert] for all the suggestions and heavily testing for bugs.

Thank you to the following people; Dave Green, HandyPAF, all those on the [Discord Workbench][DiscordWorkbench] and anyone else who makes use of this version to *port and let portable!* 

I should convey that some of the code I've added here was written by FukenGruven. Without his code-base, most of this version of PA.c Launcher would not be possible. So a round of applause is in order for FukenGruven! Thank you FukenGruven. 

----------

=)

[1]: https://github.com/GordCaswell/portableapps.comlauncher "PortableApps.com Launcher"
[2]: http://portableapps.com/ "PortableApps.com/"
[3]: https://portableapps.com/node/56500 "A Superfluous Discussion"
[4]: https://portableapps.com/apps/development/nsis_portable "NSIS Portable"
[5]: http://johnhaller.com/useful-stuff/dot-net-portable-apps ".NET Availability and Viability With Portable Apps"
[MSAdvisory]: https://support.microsoft.com/en-us/kb/3033929 "MS Security Advisory: SHA2 support for Win7/Windows Server '08 R2: March 10, 2015"
[JavaPortable]: http://portableapps.com/apps/utilities/java_portable "Java Portable"
[GhostscriptPortable]: https://portableapps.com/apps/utilities/ghostscript_portable "Ghostscript Portable"
[DocsRegDLL]: http://softables.tk/docs/advanced/regdll-and-regsrv32 "RegDLL & RegSrv32.exe—DLL Handling"
[DocsServices]: http://softables.tk/docs/advanced/services "A Look into Windows Services"
[DocsHome]: http://softables.tk/docs "The PAF Docs on Softables.tk/"
[author]: http://softables.tk/ "Softables.tk/"
[TekSpert]: http://tekspert.se/ "Webmaster of TekSpert.se/"
[DiscordWorkbench]: https://discord.gg/ExKbgXg "A PAFing Community (Discord Chat Platform)"
