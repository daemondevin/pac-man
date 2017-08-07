
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
#### __PortableApps.comLauncher.nsi__
 - <del>Added code to add a manifest file to the Launcher.exe for better user privileges support. Refer to line 80 for referance.</del>
 - Added support for using new NSISPortable which is the new NSIS3 with Unicode support. Removed NSIS in the App directory.
 - Adding an application manifest is now handled by default since NSIS3. The code has been commented out.
 - Added support for automatic code signing. Refer to the code block on line 709 for referance.
 - Added support to prevent a user from shutting down or at least allow enough time to cleanup before exiting then shutting down.
 - Added support for .NET checking from both 4.0 and below to 4.5 and above. See `DotNet.nsh` in the segments folder for referance. 

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

* __Services__
Add support for Windows Services

* __RegDLLs__
Add support for handling library (DLLs) file registration.
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
* __JDK__
Add support for Java Development Kit.

* __Ghostscript__
Add Ghostscript support.

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
* __Developer__
The name of the developer that created the portable application.

* __Contributors__
Specify here anyone who has helped with the creation of the portable application.

* __Creator__
Specify here the original developer of the PAF if you're updating someone elses work.

* __CertSigning__
If set to true, the `Launcher.exe` will be signed automatically using both _sha1_ and _sha256_. __Note:__ As it is written right now, the `LauncherGenerator.exe` expects the certificate to be the developer's name (same as the above key's value) and located in `..\Other\Source\Contrib\certificates`. 
> Note: If your certificate requires you to use a password, refer to lines 741 and 742 and input your password on column 62.
> Be sure it is similiar to something like this: `/p "PASSWORD"` where PASSWORD is your password.
* __CertExtension__
If the key `CertSigning` is set to true then this should be set to the certificate's file extension without the period (e.g. "_pfx_" not "_.pfx_").
* __CertTimestamp__
Here you can choose which timestamping service you would like to use. There are only 3 services to choose from as of right now; _Comodo_, _VeriSign_, and _GlobalSign_. Be aware that this key is case-sensitive. If this key is omitted, the compiler will default to using _Comodo_.

Alongside the already provided keys in the `[Dependencies]` section, I've added the support for the following (a short description of what each key means or does can be found further below):
> Note: You should only use the following keys if you need them, otherwise they should be omitted entirely.
```INI
[Dependencies]
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
* __ExecAsUser__
For applications which need to run as normal user but need the launcher to have elevated privileges.

* __UseStdUtils__
Include the StdUtils plug-in without `ExecAsUser`

* __InstallINF__
Add support and macros for INF installation. Refer to the `Services.nsh` file in the Segments directory for reference.

* __DisableRedirection__
Enable support for enabling/disabling file system redirection.

* __ForceDisableRedirection__
Checks using the variable `$Bit` to disable/enable file system redirection.

* __RegistryValueWrite__
Set this to true to set a sleep value for `[RegistryValueWrite]` otherwise the function is inaccurate.

* __RegistryCopyKeys__
Enable support for adding the section `[RegistryCopyKeys]` in `Launcher.ini`. See `RegistryCopyKeys.nsh` in the Segments directory.

* __RegDisableRedirection__
Enable support for enabling/disabling registry redirection (For use with `RegistryCopyKeys`)

* __FontsFolder__
Allows the portable application to support fonts within the directory `..\Data\Fonts`. Any fonts added in this folder will be added and are available for usage during runtime. Be aware, the more fonts to process the longer it will take for the launcher to load and unload these fonts.
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

* __FileWriteReplace__
Enables the Replace functionality in `[FileWrite]`

* __FileCleanup__
Enable support for adding the section `[FilesCleanup]` in `Launcher.ini`. See `FilesCleanup.nsh` in the Segments directory.

* __FileLocking__
Enable this to prevent ejection/unplugging problems for USB devices. Windows Explorer tend to lock application's DLL(s). 
__Note:__ As of right now, this only enables support for using `${If} ${FileLocked}` and/or `${IfNot} ${FileLocked}` in the `custom.nsh` file. 
__ToDo:__ Handle without the use of `custom.nsh`. (Got a couple ideas already. Check back soon.)

* __Firewall__
Enable Firewall support.

* __Junctions__
Enable support for Junctions (_SymLinks_) functionality.

* __ACLRegSupport__
Enable support for AccessControl on registry keys.

* __ACLDirSupport__
Enable support for AccessControl on directories.

* __TaskCleanup__
Enable the TaskCleanup segment for removing any Windows Tasks that was added during runtime.
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
[author]: http://softables.tk/ "Softables.tk/"
