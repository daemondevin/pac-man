
## Introduction

This is a fork of the official [PortableApps.com Launcher][1]. I forked this project because I wanted to incorporate some ideas I had that I believe would better this project in its entirety. So instead of going to [PortableApps.com][2] and sharing my ideas ([a superfluous attempt][3] was already made; to what seemed like no avail), I feel it would be much more advantageous on my part to just implement these ideas instead. 

I have no real expectations that any of these ideas will actually be pulled into the official version of __PAL__ (_PortableApps.com Launcher_) but if any of them do than kudos.. lol. If anyone is actually reading this and does find some of these concepts to be useful then maybe support my effort in supporting their cause. 

I should say that what I'm going to be adding to this variant of PAL is what works for me and my environment. All the concepts that you find here should work with any other environment unless explicitly expressed otherwise. So like I say in a recent motto I have recently just adopted, _"Port and let portable!"_ — You see what I did there? Lol. If you don't, no worries; I guess I should just _live and let live_.

## Feature Concepts

Here's a small list of a few ideas that I want to try and implement with this project. These are just things I plan on working on in my spare time and while the ideas listed below are not recognized by PortableApps.com please be aware that using some of the things you find in this variant of PAL can and most likely will be buggy. 

* __Support for NSIS3:__
Well, support for [NSISPortable][4] rather which is packaged with the latest release of NSIS. The current official release of PAL is using NSIS v2.46.5-Unicode which is actually packaged with the project. So I would like to completely remove the need for this dependency entirely.

* __Manifest Support:__
With the release of NSIS3, support for adding an application manifest is done automatically and defaults to supporting Windows 7 and later versions.  

* __.NET Handling:__
I'll just be adding a means for checking a system for the required version of the .NET Framework because John T. Haller [explains][5] in great detail how the .NET Framework has no real practical means for portability when it comes to Portable Apps. He ends his article with, 
>"_...applications based on .NET simply can't be considered portable due to the fact that the files they need can't be bundled portably and won't be on a large number of PCs you encounter in the wild._"

* __Support Registering Libraries:__
The official release of PAL has no native support for registering libraries (DLLs), so I will try to add support for registering files. Be aware though that a program developer has complete control over what happens when you call _RegSvr32_ which is what is used by `RegDLL` (the native command used by NSIS for registering files). With that being said, my ideas on this topic may be buggy.

* __Support Services:__
The support for services is by default disabled in the official builds of PAL. In the source code it states that they might be unstable and the plugin is large in size. I plan on not using a plugin to support services, instead I plan on dealing with this by using the command line with a few functions and macros to try and keep things simple.

* __Etc. Etc. And So On:__
Other things could follow depending on my availability, interest.. and of course the interest and support from others. So with that being said, this little project might not even see the light of day. Lol.

## Added Features
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
Added new keys to the `[Activate]` section. They are as follows (a short description of what each key means or does can be found further below):
> Note: You should only use the following keys if you need them, otherwise they should be omitted entirely.
```INI
[Activate]
Services=true
RegDLLs=true
JDK=true
Ghostscript=true
```

* __Services:__ Add support for Windows Services

* __RegDLLs:__ Add support for handling library (DLLs) file registration.
> To use this feature add the section `[RegisterDLL1]` (numerical ordering) to the `Launcher.ini` file. Each entry supports two keys; _ProgID_ (The DLL's ProgID) and _File_ (The path to DLL. Supports environment variables). Example usage:
> ```INI
> [RegisterDLL1]
> ProgID=MyAppControlPanel
> File=${PAL:AppDir}\controller.cpl
>
> [RegisterDLL2]
> ProgID=DynamicLibrary
> File=${PAL:DataDir}\dynlib.dll
> ```
* __JDK:__ Add support for Java Development Kit.

* __Ghostscript:__ Add Ghostscript support.


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

> 
>|       __CertTimestamp__=*`Value`*     	|     __Timestamp Service__    	| __Algorithms__ 	|
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
ExecAsUser=true
UseStdUtils=true
InstallINF=true
DisableRedirection=true
ForceDisableRedirection=true
RegistryValueWrite=true
RegistryCopyKeys=true
RegDisableRedirection=true
FontsFolder=true
FileWriteReplace=true
FileCleanup=true
FileLocking=true
Firewall=true
Junctions=true
ACLRegSupport=true
ACLDirSupport=true
TaskCleanup=true
```
* __ElevatedPrivileges:__ For launchers which need to run with elevated privileges.

* __UsesJava:__ Specifies whether the portable application makes use of [Java Portable][JavaPortable].

* __UsesGhostscript:__ Specifies whether the portable application makes use of [Ghostscript Portable][GhostscriptPortable].

* __UsesDotNetVersion:__ Specify the minimum required version of the .NET framework the portable application needs. Values can be from `1.0` thru `4.7` (*e.g.* `UsesDotNetVersion=1.1` or `UsesDotNetVersion=4.6.2`).

* __ExecAsUser:__ For applications which need to run as normal user but need the launcher to have elevated privileges.

* __UseStdUtils:__ Include the StdUtils plug-in without `ExecAsUser`

* __InstallINF:__ Add support and macros for INF installation. Refer to the `Services.nsh` file in the Segments directory for reference.

* __DisableRedirection:__ Enable support for enabling/disabling file system redirection.

* __ForceDisableRedirection:__ Checks using the variable `$Bit` to disable/enable file system redirection.

* __RegistryValueWrite:__ Set this to true to set a sleep value for `[RegistryValueWrite]` otherwise the function is inaccurate.

* __RegistryCopyKeys:__ Enable support for adding the section `[RegistryCopyKeys]` in `Launcher.ini`. See `RegistryCopyKeys.nsh` in the Segments directory.

* __RegDisableRedirection:__ Enable support for enabling/disabling registry redirection (For use with `RegistryCopyKeys`)

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

* __FileWriteReplace:__ Enables the Replace functionality in `[FileWrite]`

* __FileCleanup:__ Enable support for adding the section `[FilesCleanup]` in `Launcher.ini`. See `FilesCleanup.nsh` in the Segments directory.

* __FileLocking:__ Enable this to prevent ejection/unplugging problems for USB devices. Windows Explorer tend to lock application's DLL(s). 
__Note:__ As of right now, this only enables support for using `${If} ${FileLocked}` and/or `${IfNot} ${FileLocked}` in the `custom.nsh` file. 
__ToDo:__ Handle without the use of `custom.nsh`. (Got a couple ideas already. Check back soon.)

* __Firewall:__ Enable Firewall support.

* __Junctions:__ Enable support for Junctions (_SymLinks_) functionality.

* __ACLRegSupport:__ Enable support for AccessControl on registry keys.

* __ACLDirSupport:__ Enable support for AccessControl on directories.

* __TaskCleanup:__ Enable the TaskCleanup segment for removing any Windows Tasks that was added during runtime.
> To use this feature add the section `[TaskCleanup]` to the `Launcher.ini` file. Each entry should be the Windows Task name to be removed. Example usage:
> ```INI
> [TaskCleanup]
> 1=MyAppTask1
> 2=Another Task w/ Spaces
> ```

## Contributors

This forked project has been started by [demon.devin][author] and hopefully maintained on a regular basis. However, if you would like to be a part of this then please do not hesitate on getting involved! I'm always open to new ideas and a willingness for the betterment of all things code. =)

I should convey that some of the code I've added here was written by FukenGruven. Without his codebase, most of this version of PAL would not be possible. So a round of applause is in order for FukenGruven! Thank you FG. =)


[1]: https://github.com/GordCaswell/portableapps.comlauncher "PortableApps.com Launcher"
[2]: http://portableapps.com/ "PortableApps.com/"
[3]: https://portableapps.com/node/56500 "A Superfluous Discussion"
[4]: https://portableapps.com/apps/development/nsis_portable "NSIS Portable"
[5]: http://johnhaller.com/useful-stuff/dot-net-portable-apps ".NET Availability and Viability With Portable Apps"
[MSAdvisory]: https://support.microsoft.com/en-us/kb/3033929 "MS Security Advisory: SHA2 support for Win7/Windows Server '08 R2: March 10, 2015"
[JavaPortable]: http://portableapps.com/apps/utilities/java_portable "Java Portable"
[GhostscriptPortable]: https://portableapps.com/apps/utilities/ghostscript_portable "Ghostscript Portable"
[author]: http://softables.tk/ "Softables.tk/"
