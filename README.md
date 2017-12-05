# PortableApps Compiler - _Development Branch_
----------

This branch is meant for the cutting-edge of development. Don't expect this version to work flawlessly. There may be bugs hidden throughout this experimental version of PortableApps Compiler. With this branch you will find the coding practices of Chris Morgan, FukenGruven, Azure Zanculmarktum, and myself (daemon.devin). You will also see minor influence from contributors like LegendaryHawk, DoomStorm, and other fellow developers as well. So you can expect to see great things to come out of this experimental build.

With all that said, enjoy the fresh ideas which are currently being worked out.

## CHANGES
----------

##### Environment Variables
- All environment variables that start with `PAL` have been changed to `PAC` 
  - _I.E._ `%PAL:AppDir%` is now `%PAC:AppDir%` and so on..
- All environment variables that start with `PortableApps.com` have been changed to `PortableApps` 
  - _I.E._ `%PortableApps.comDocuments%` is now `%PortableAppsDocuments%` and so on..

##### Folder Structure
- I've changed the folder structure. To illustrate the new directory layout let's imagine we're looking at a portable version of 7-Zip which was compiled using this new design layout.

> Example Directory Tree:
> ```
> 7-ZipPortable (Root)
>       |   7-ZipPortable.exe (Portable Launcher)
>       |   7-ZipPortable.ini (User Config File)
>       |   
>       +---app
>       |    +---AppInfo    (Kept for Compatibility with PA.c Menu)
>       |    |       AppIcon.ico            (Needed with PA.c Menu)
>       |    |       AppIcon_128.png          ' '     ' '     ' '
>       |    |       AppIcon_16.png           ' '     ' '     ' '
>       |    |       AppIcon_32.png           ' '     ' '     ' '
>       |    |       AppInfo.ini              ' '     ' '     ' '
>       |    |       Installer.ini
>       |    |       EULA.txt
>       |    |       ExtendWrapper.nsh       (Formally Custom.nsh)
>       |    |       Wrapper.ini            (Formally Launcher.ini)
>       |    |       
>       |    \---DefaultSettings (Formally DefaultData)
>       |        |   DEFAULT 7-ZIP SETTINGS HERE
>       |        |
>       |        \---Config (Formally Default Settings)
>       |            7-Zip.reg
>       |               
>       +---bin
>       |    +---7-Zip (32-Bit Program Files)
>       |    |   |   7-zip.dll
>       |    |   |   7z.dll
>       |    |   |   7z.exe
>       |    |   |   7zFM.exe
>       |    |   |   '' '' ''
>       |    |   |   
>       |    |   \---Lang
>       |    |        af.txt
>       |    |        an.txt
>       |    |        ar.txt
>       |    |        ''  ''
>       |    |
>       |    +---7-Zip64 (64-Bit Program Files)
>       |    |   |    7-zip.dll
>       |    |   |    7z.dll
>       |    |   |    7z.exe
>       |    |   |    7zFM.exe
>       |    |   |    '' '' ''
>       |    |   |   
>       |    |   \---Lang
>       |    |        af.txt
>       |    |        an.txt
>       |    |        ar.txt
>       |    |        ''  ''
>       |    |
>       |    \---Settings (Fromally Data)
>       |        |    7-ZIP SETTINGS HERE
>       |        |   
>       |        \---Config (Fromally Settings)
>       |             7-Zip.reg
>       |             7-ZipPortableSettings.ini
>       |
>       \---etc
>            7-ZipPortable.ini
>            README
>            UNLICENSE (using Unlicense.org/ now)
> ```

##### PAF to PAC Conversion
- The compiler can now handle converting PAF PortableApps to the above folder layout. Everything is handled automatically so you do not need to manually set the files in the correct place. I also added support for converting FukenGruven's old PAFs as well.
- Do not expect the PA.c Installer to work out of the box for this new folder structure. Since I've renamed and moved around the applicable configuration files, PA.c Installer won't be able to locate the right files any more and most likely won't be able to pack your portable. However, I haven't tested this out yet.

## Features
----------

The following is a list of features that is currently available with PortableApps Compiler. Everything listed here has been tested and is in working order.

- Everything that is available with [PortableApps.com Launcher](https://portableapps.com/apps/development/portableapps.com_launcher) is also available with PortableApps Compiler.
- Minipulating Windows Services.
- Dealing with Windows Tasks.
- Registering DLL files.
- Registry redirection support.
- File-system redirection support.
- Automatic code-signing.
- Font support for apps that make use of fonts.
- More feature soon to come!

----------

#### __Launcher.ini__

__Environment Variables__

- `%PROGRAMDATA%` has now been added and kept `%ALLUSERSAPPDATA%` for backwards compatibility. Both can be used anywhere you can use an evironment variable.
- `%PAC:CommonFiles%` may now be used within the _Launcher.ini_ configuration file. This environment variable will point to `..\PortableApps\CommonFiles` if applicable. Can be used anywhere you can use an environment variable.
> Example:
> ```INI
> [Environment]
> PATH=%PATH%;%PAC:CommonFiles%\AndroidSDK
> JAVA_HOME=%PAC:CommonFiles%\Java64
> ```

Added new keys to the `[Activate]` section. They are as follows (a short description of what each key means or does can be found further below):
> Note: You should only use the following keys if you need them, otherwise they should be omitted entirely.
```INI
[Activate]
DualMode=7-ZIP
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
DirectoryCleanup=true
```

* __DualMode:__ For a x86_64 hybrid wrapper. If you want to run 32-bit/64-bit side-by-side in _"Dual Mode"_. Just specify a short name (usually the AppID in all caps) in which you may use inside the Wrapper.ini as an environment variable. (e.g. `%7-ZIP%`)

* __Registry:__ Add support for manipulating the Windows Registry.

* __RegRedirection:__ Enable support for enabling/disabling registry redirection.

* __RegCopyKeys:__ Enable support for copying registry keys to a special hive (`HKCU\Software\PortableApps.com`) before launching the application and restoring the keys after the application exits. See `RegistryCopyKeys.nsh` in the Segments directory.
> To use this feature add the section `[RegistryCopyKeys]` to the `Wrapper.ini` file. Each entry should be the path to the registry key to be copied back and forth. Example usage:
> ```INI
> [RegistryCopyKeys]
> 1=HKCU\Software\MyProgram\ExtraCareNeededKey
> 2=HKLM\SOFTWARE\MyProgram\AnotherFragileKey
> ```

* __Redirection:__ Enable support for enabling/disabling file system redirection.

* __ForceRedirection:__ Checks using the variable `$Bit` to disable/enable file system redirection.

* __ExecAsUser:__ For applications which need to run as normal user but need the wrapper to have elevated privileges. [Read this](http://mdb-blog.blogspot.com/2013/01/nsis-lunch-program-as-user-from-uac.html) for more information on this concept.

* __Services:__ Add support for handling Windows Services.
> To use this feature add the section `[Service1]` (numerical ordering) to the `Wrapper.ini` file. Each entry supports six keys which are as follows:

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
> Path=%PAC:AppDir%\service32.sys
> Type=kernel
> Start=auto
> Depend=
> IfExists=replace
>
> [Service2]
> Name=AnotherService
> Path=%PAC:DataDir%\service64.exe
> Type=own
> Start=demand
> Depend=
> IfExists=skip
> ```

* __RegDLLs:__ Add support for handling library (DLLs) file registration.
> To use this feature add the section `[RegisterDLL1]` (numerical ordering) to the `Wrapper.ini` file. Each entry supports two keys; _ProgID_ (The DLL's ProgID) and _File_ (The path to DLL. Supports environment variables). Example usage:
> ```INI
> [RegisterDLL1]
> ProgID=MyAppControlPanel
> File=%PAC:AppDir%\controller.cpl
>
> [RegisterDLL2]
> ProgID=DynamicLibrary
> File=%PAC:DataDir%\dynlib.dll
> ```

* __Tasks:__ Enable the TaskCleanup segment for removing any Windows Tasks that were added during runtime.
> To use this feature add the section `[TaskCleanup]` to the `Wrapper.ini` file. Each entry should be the Windows Task name to be removed. Example usage:
> ```INI
> [TaskCleanup]
> 1=MyAppTask1
> 2=Another Task w/ Spaces
> ```

* __Java:__ Add support for the Java Runtime Environment.

* __JDK:__ Add support for the Java Development Kit.

* __XML:__ Add XML support.

* __Ghostscript:__ Add Ghostscript support.

* __FontsFolder:__ Allows the portable application to support fonts within the directory `..\Data\Fonts`. Any fonts added in this folder will be added and are available for usage during runtime. Be aware, the more fonts to process the longer it will take for the wrapper to load and unload these fonts.
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

* __FileCleanup:__ Enable support for adding the section `[FilesCleanup]` in `Wrapper.ini`. See `FilesCleanup.nsh` in the Segments directory.
> To use this feature add the section `[FilesCleanup]` to the `Wrapper.ini` file. Each entry should be the path to the file that needs deleting. Supports environment variables. Example usage:
> ```INI
> [FilesCleanup]
> 1=%PAC:DataDir%\uselessUpgradeFile.xml
> 2=%APPDATA%\MyProgram\purposelessCfg.ini
> ```

* __DirectoryCleanup:__ Enable support for the sections `[DirectoriesCleanupIfEmpty]` and `[DirectoriesCleanupForce]` in `Wrapper.ini`. See `DirectoriesCleanup.nsh` in the Segments directory.

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

* __CertSigning:__ If set to true, the `Wrapper.exe` will automatically be signed using dual signature hashing algorithm standards (_SHA256_ and _SHA1_). I decided to use dual signing because Windows 8 supports SHA256 Code Signing Certificates (SHA-2 hashing algorithm); whereas, Windows 7 may only support SHA-1 Code Signing Certificates (SHA-1 hashing algorithm). It should be noted that Windows 10 has stopped accepting SHA-1 certificates and certificate chains for Authenticode-signed binaries (unless a timestamp marked the binary as being signed before 1/1/2016). You can visit this [Microsoft Security Advisory article][MSAdvisory] on the availability of SHA-2 code signing support for Windows 7 and Windows Server 2008 R2 for more information about this topic.
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
TrimString=true
CloseProcess=true
Include64=true
IncludeWordRep=true
GetBetween=true
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

* __ConfigFunctions:__ Enable `Write(S)` and `Read(S)` functions (4 total). See the `Core.nsh` segment on line 236 for reference.

* __CloseWindow:__ Enable `Close` function. See the `Core.nsh` segment on line 1288 for reference.

* __JSONSupport:__ Include the _nsJSON_ plugin allowing `nsJSON::Get`, `nsJSON::Set`, and `nsJSON::Serialize` for use within `custom.nsh`.

* __RestartSleep:__ Set this to a numerical value (in milliseconds) to set a sleep value for applications that need to restart (i.e. Notepad++ after installing new plugins).

* __WinMessages:__ Include the `WinMessages.nsh` file.

* __LineWrite:__ Include the `LineWrite.nsh` file.

* __TrimString:__ Enable the function `Trim`. See the `Core.nsh` segment on line 1093 for reference.

* __CloseProcess:__ Enable the function `CloseX`. See the `Core.nsh` segment on line 1125 for reference.

* __Include64:__ Include the `64.nsh` file.

* __IncludeWordRep:__ Include both `WordRepS` and `WordRep` functions. See the `Core.nsh` segment on line 608 for reference.

* __GetBetween:__ Include the `GetBetween.nsh` file.

#### __Visit the Docs:__ [The PAF Docs][DocsHome]

## Contributors
----------

This project has been started by [demon.devin][author] and hopefully maintained on a regular basis. However, if you would like to be a part of this then please do not hesitate on getting involved! I'm always open to new ideas and a willingness for the betterment of all things code. =)

Thanks to [DoomStorm][TekSpert] for all the suggestions and heavily testing for bugs.

Thank you to the following people; Dave Green (RIP), HandyPAF, all those on the [Discord Workbench][DiscordWorkbench] and anyone else who makes use of this version to *port and let portable!* 

A special thanks to FukenGruven. His codebase was the skeleton which was used to start this project.

----------

=)

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
