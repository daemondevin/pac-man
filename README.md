# PortableApps Compiler & Management

`PortableApps Compiler & Management` (_PortableApps Compiler_ or _Pac-Man_ for short) is an enhanced, compatibility-aware launcher framework inspired by the PortableApps.com Launcher (PAL). It is designed to support complex, modern and legacy Windows applications that PAL intentionally does not target. Pac-Man's framework is built on top of PAL and still produces packages that follow the [PortableApps.com Format](https://portableapps.com/manuals/PortableApps.comLauncher/ref/paf/index.html#portableapps-com-format-specification).

Pac-Man does **not** replace PAL. It augments PAL by adding:

- Structured lifecycle segments
- Crash-recovery guarantees
- Explicit rollback journaling
- Windows 10/11 compliant integration patterns

Pac-Man is designed to behave like a **transactional runtime environment**, not an installer. It exists to solve a different class of problems than PAL.

## Project Status: Pre-Production / Under Heavy Construction

Pac-Man is not ready for production deployment. The journal and the crash-recovery dispatcher are in place, but most of the system-integration segments have not been moved onto the journal yet (see [Implementation status](#implementation-status)). Until they are:

- Behavior may change between revisions
- Configuration formats are not yet frozen
- Backward compatibility is not guaranteed
- Segments that are not yet journaled can leave the host system modified if the launcher crashes

Production use is explicitly discouraged until every segment below is marked **Journaled** and the recovery paths have been exercised under forced-failure testing. For the full plan visit the [roadmap](https://github.com/daemondevin/pac-man/blob/master-rewrite/Other/Source/docs/ROADMAP.md).

### Definition of "Production-Ready"

Pac-Man is considered production-ready when:

- **A crash cannot leave the host system modified**
- **Every segment can fail safely**
- **Recovery is automatic, deterministic and tested**
- **Behavior is documented and enforced**
- **No hidden system state is introduced**

## Design Principles

1. No permanent system mutation
2. Every mutation must be reversible
3. Recovery must not depend on successful startup
4. User scope first, system scope only when required
5. Deterministic execution order
6. Fail closed, not open

### Functional Comparison

| Feature | PAL | Pac-Man |
| :------ | :-- | :------ |
| Crash Recovery | Limited | Journal-based |
| File Associations | Not supported | User-scoped |
| URL Protocols | Not supported | Supported |
| Windows Services | Not supported | Temporary |
| Firewall Rules | Not supported | Reversible |
| Scheduled Tasks | Not supported | Session-bound |
| COM Registration | Minimal | Fully tracked |
| Fonts | Limited | Fully reversible |
| Hosts File | Not supported | Transactional |
| Windows 11 Compliance | Partial | Explicit |

The Pac-Man column describes the target behavior. The [implementation status](#implementation-status) table shows how far each row has got.

## Crash Recovery Model

Crash recovery in Pac-Man is:

- **Deterministic**, not heuristic
- **Journal-driven**, not best-effort
- **Idempotent**, safe to re-run

If Pac-Man detects that a previous session ended unexpectedly, it **recovers first**, before any new changes are made. The check runs right after the instance mutex checks, so only the primary instance can recover: if another launcher for the same app is alive, its journal is not stale and is left alone.

A segment cleans up after itself with the same rollback call that crash recovery uses, so the normal shutdown path and the recovery path are one and the same code. The `Unload` step also rolls back anything a segment left behind, as a safety net.

When `[Launch]:WaitForProgram=false` the launcher exits while the app is still running, so its changes have to outlive the launcher. In that case the session is marked `detached` and the next launch rolls it back quietly.

## Journaling System

The journal records **only what is necessary to undo a change**. It is not a log; it is a rollback ledger.

### Storage

| Location | Contents |
| :------- | :------- |
| `HKCU\Software\pac-man\Journal\<AppID>` | Session values: `State` (`active`, `incomplete` or `detached`), `PID`, `Launcher`, `Version` |
| `HKCU\Software\pac-man\Journal\<AppID>\<Segment>` | One subkey per segment. `Count` plus `n.Op`, `n.A`, `n.B`, `n.C`, `n.D` for each entry |
| `%LOCALAPPDATA%\pac-man\Journal\<AppID>\` | Backup files referenced by journal entries. Kept on the host so a change of drive letter can't orphan them |

No keys are shared between segments, and an empty journal is deleted completely.

### Rules

- Journal **before** mutation
- Never infer state
- Never delete data you did not create
- Cleanup must clear the journal

### Undo operations

Every operation is idempotent. An entry is removed only after its undo succeeds; on the first failure the segment's rollback stops (so ordering is preserved), the session is marked `incomplete` and the remaining entries are retried on the next launch.

| Op | Arguments | Undo |
| :- | :-------- | :--- |
| `REGKEY` | root, subkey, `.reg` backup, view (`32`/`64`) | Delete the key, re-import the backup if one was taken |
| `REGVALUE` | root, subkey, value name, previous value (`STR:`/`EXP:`/`DWORD:` or empty) | Restore the previous value, or delete it if it didn't exist |
| `FILE` | path, backup | Delete the file, move the backup back |
| `DIR` | path, backup, `recursive` | Remove the directory (never recursing into a junction or symlink), restore the backup |
| `LINK` | link path, backup | Remove the link itself, never its target; restore the backup |
| `CMD` | command line, accepted exit codes | Run the command (e.g. `sc delete`, `netsh ... delete rule`, `schtasks /delete`) |
| `FONT` | font file, flags | `RemoveFontResourceEx` and broadcast `WM_FONTCHANGE` |
| `STRIPLINES` | text file, marker | Remove every line that contains the marker |

Undo operations that touch `HKLM` need administrator rights. Without them the entry is kept and retried later instead of being dropped.

## Segment Architecture

A compliant segment must:

- Be self-contained
- Never assume admin rights
- Never assume it completes
- Never assume a successful cleanup
- Never leak filesystem state
- Have every mutation reversible without context
- Declare changes before mutation (`${Journal::Record}`)
- Be callable from the normal lifecycle, from crash recovery and from a secondary instance (where it must be a safe no-op; the dispatcher only runs PAC-MAN segments in the primary instance)

### Writing a segment

```nsis
!ifdef SEGMENTS_EXAMPLE
${SegmentFile}

${SegmentPrePrimary}
	; Record exactly how to undo the change, then make the change.
	${Journal::Record} Example CMD `"$SYSDIR\sc.exe" delete MyService` "0,1060" "" ""
	nsExec::ExecToStack `"$SYSDIR\sc.exe" create MyService binpath= "$AppDirectory\svc.exe"`
	Pop $0
	Pop $1
!macroend

${SegmentPostPrimary}
	; The same call crash recovery uses.
	${Journal::Rollback} Example
!macroend

!endif
```

Then add the segment to `JOURNAL_RECOVERY_ORDER` in `Journal.nsh` and to the apply/cleanup lists in `PortableAppsCompiler.nsi`, and give it a `SEGMENTS_*` flag in `FeatureFlags.nsh` and `LauncherCompiler.nsi`.

The journal API lives in `Other/Source/Journal.nsh`:

| Macro | Purpose |
| :---- | :------ |
| `${Journal::Record} Segment Op A B C D` | Append an undo entry. Call it **before** the mutation |
| `${Journal::Rollback} Segment` | Undo the segment's entries, newest first |
| `${Journal::HasEntries} Segment $var` | Live entry count for a segment |
| `${Journal::BackupFile} Segment Path $var` | Copy a file into the journal store and return the backup path |
| `${Journal::Begin}` / `${Journal::End}` | Open and close the session (the lifecycle does this for you) |
| `${Journal::Recover}` | The crash-recovery dispatcher (the lifecycle calls it first) |

## Execution Order

### Apply Order

1. Runtime
2. RegDLL (and DirectX)
3. Fonts
4. Symlinks
5. Associations
6. Firewall
7. Hosts
8. Services (Drivers run just before Services)
9. Tasks

### Cleanup / Recovery Order

Exact reverse order. This ensures no consumer exists without its provider. Segments are only compiled in and dispatched when their feature flag is on.

## Implementation status

| Segment | Flag (`[Activate]` key) | Status |
| :------ | :---------------------- | :----- |
| Journal + recovery dispatcher | always on | **Done**, runtime-tested (normal run, forced crash, recovery, foreign edits preserved) |
| Hosts | `Hosts` | **Journaled**, runtime-tested |
| Runtime | `Runtime` | Not journaled; does not compile yet |
| RegDLL | `RegDLLs` | Not journaled; compiles |
| Fonts | `Fonts` | Not journaled; does not compile yet |
| Symlinks | `Symlinks` | Not journaled; does not compile yet |
| Associations | `FileAssociations` | Not journaled; does not compile yet |
| Firewall | `Firewall` | Not journaled; does not compile yet |
| Drivers | `Drivers` | Not journaled; does not compile yet |
| Services | `Services` | Not journaled; compiles |
| Tasks | `Tasks` | Not journaled; does not compile yet |

PAL-inherited segments (registry keys, file and directory moves, file writes and so on) keep their PAL behavior and are not part of the journal.

## Windows 10 / 11 Compliance

Pac-Man explicitly avoids:

- `UserChoice` hash tampering
- Silent default-app hijacking
- Undocumented Explorer hooks
- Global COM pollution

All shell integration follows **documented registry contracts** and respects OS safeguards.

## Security & Privilege Model

- Default execution is **non-admin**
- Admin-only segments must explicitly check elevation and fail closed without it
- No silent privilege escalation
- No persistent background components
- No certificates or other trust anchors are installed on the host

## Intended Use Cases

Pac-Man is suitable for portable developer tools, security tooling, controlled enterprise environments and forensic or sandbox workflows. It is **not** intended for silent system takeover, persistent background services or circumventing OS security policies.

## Configuration Reference

Everything that is available with the [PortableApps.com Launcher](https://portableapps.com/apps/development/portableapps.com_launcher) is also available with Pac-Man. The sections below cover what Pac-Man adds.

#### **Launcher.ini**

**Environment Variables**

- `%PROGRAMDATA%` has now been added and kept `%ALLUSERSAPPDATA%` for backwards compatibility. Both can be used anywhere you can use an evironment variable.
- `%PAL:CommonFiles%` may now be used within the _Launcher.ini_ configuration file. This environment variable will point to `..\PortableApps\CommonFiles` if applicable. Can be used anywhere you can use an environment variable.
  > Example:
  >
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
DirectoryCleanup=true
Hosts=true
```

The PAC-MAN integration segments use these keys as well: `Runtime`, `Fonts`, `Symlinks`, `FileAssociations`, `Firewall`, `Drivers`. A key set to `false` is treated the same as an omitted key.

- **Registry:** Add support for manipulating the Windows Registry.

- **RegRedirection:** Enable support for enabling/disabling registry redirection.

- **RegCopyKeys:** Enable support for copying registry keys to a special hive (`HKCU\Software\PortableApps.com`) before launching the application and restoring the keys after the application exits. See `RegistryCopyKeys.nsh` in the Segments directory.

  > To use this feature add the section `[RegistryCopyKeys]` to the `Launcher.ini` file. Each entry should be the path to the registry key to be copied back and forth. Example usage:
  >
  > ```INI
  > [RegistryCopyKeys]
  > 1=HKCU\Software\MyProgram\ExtraCareNeededKey
  > 2=HKLM\SOFTWARE\MyProgram\AnotherFragileKey
  > ```

- **Redirection:** Enable support for enabling/disabling file system redirection.

- **ForceRedirection:** Checks using the variable `$Bit` to disable/enable file system redirection.

- **ExecAsUser:** For applications which need to run as normal user but need the launcher to have elevated privileges. [Read this](http://mdb-blog.blogspot.com/2013/01/nsis-lunch-program-as-user-from-uac.html) for more information on this concept.

- **Services:** Add support for handling Windows Services.
  > To use this feature add the section `[Service1]` (numerical ordering) to the `Launcher.ini` file. Each entry supports six keys which are as follows:

| **Key**  | **Value**                                                                                                                                                                                            |
| :------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Name     | The local/portable service name.                                                                                                                                                                     |
| Path     | The path to the portable service executable. Supports environment variables.                                                                                                                         |
| Type     | Specify whether you are dealing with a service, a kernel driver or a file system driver, etc.<br />Choose from: _own_, _share_, _interact_, _kernel_, _filesys_, _rec_                               |
| Start    | Specify when the service is supposed to start.<br />Choose from: _boot_, _system_, _auto_, _demand_, _disabled_, _delayed-auto_                                                                      |
| Depend   | List any dependencies here separated by `/` (forward slash).                                                                                                                                         |
| IfExists | If the service already exists, you can either skip it or replace it with the portable version of the service (the original service will be restored afterwards).<br />Choose from: _skip_, _replace_ |

> Example usage:
>
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

- **RegDLLs:** Add support for handling library (DLLs) file registration.

  > To use this feature add the section `[RegisterDLL1]` (numerical ordering) to the `Launcher.ini` file. Each entry supports two keys; _ProgID_ (The DLL's ProgID) and _File_ (The path to DLL. Supports environment variables). Example usage:
  >
  > ```INI
  > [RegisterDLL1]
  > ProgID=MyAppControlPanel
  > File=%PAL:AppDir%\controller.cpl
  >
  > [RegisterDLL2]
  > ProgID=DynamicLibrary
  > File=%PAL:DataDir%\dynlib.dll
  > ```

- **Tasks:** Enable the TaskCleanup segment for removing any Windows Tasks that were added during runtime.

  > To use this feature add the section `[TaskCleanup]` to the `Launcher.ini` file. Each entry should be the Windows Task name to be removed. Example usage:
  >
  > ```INI
  > [TaskCleanup]
  > 1=MyAppTask1
  > 2=Another Task w/ Spaces
  > ```

- **Java:** Add support for the Java Runtime Environment.

- **JDK:** Add support for the Java Development Kit.

- **XML:** Add XML support.

- **Ghostscript:** Add Ghostscript support.

- **FontsFolder:** Allows the portable application to support fonts within the directory `..\Data\Fonts`. Any fonts added in this folder will be added and are available for usage during runtime. Be aware, the more fonts to process the longer it will take for the launcher to load and unload these fonts.

  > Supported Fonts:
  >
  > - .fon
  > - .fnt
  > - .ttf
  > - .ttc
  > - .fot
  > - .otf
  > - .mmm
  > - .pfb
  > - .pfm

- **FileCleanup:** Enable support for adding the section `[FilesCleanup]` in `Launcher.ini`. See `FilesCleanup.nsh` in the Segments directory.

  > To use this feature add the section `[FilesCleanup]` to the `Launcher.ini` file. Each entry should be the path to the file that needs deleting. Supports environment variables. Example usage:
  >
  > ```INI
  > [FilesCleanup]
  > 1=%PAL:DataDir%\uselessUpgradeFile.xml
  > 2=%APPDATA%\MyProgram\purposelessCfg.ini
  > ```

- **DirectoryCleanup:** Enable support for the sections `[DirectoriesCleanupIfEmpty]` and `[DirectoriesCleanupForce]` in `Launcher.ini`. See `DirectoriesCleanup.nsh` in the Segments directory.

- **Hosts:** Temporarily add entries to the Windows hosts file for as long as the app runs. Requires administrator rights (use `[Launch]:RunAsAdmin=try` or `prompt`); without them nothing is changed and a warning is shown.

  > Each line the launcher adds is tagged with `# [pac-man:<AppID>]`. On exit, or on the next launch after a crash, only the tagged lines are removed, so edits other programs make to the hosts file while the app runs are kept. A full copy of the hosts file is taken before the first change and kept in the journal store until the rollback succeeds. Entries that already exist are not added twice.
  >
  > ```INI
  > [Hosts]
  > 1=127.0.0.1 example.local
  > 2=::1 example.local
  > ```

---

#### **AppInfo.ini**

Added the section `[Team]` for use with code signing and application specifications. New keys are as follows (a short description of what each key means or does can be found further below):

> Note: You should only use the following keys if you need them, otherwise they should be omitted entirely.

```INI
[Team]
Developer=daemon.devin
Contributors=DoomStorm
Creator=FukenGruven
CertSigning=true
CertAlgorithm=SHA512
CertExtension=p12
CertTimestamp=VeriSign
```

- **Developer:** The name of the developer that created the portable application.

- **Contributors:** Specify here anyone who has helped with the creation of the portable application.

- **Creator:** Specify here the original developer of the PAF if you're updating someone else's work.

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

- **ElevatedPrivileges:** For launchers which need to run with elevated privileges.

- **UsesJava:** Specifies whether the portable application makes use of [Java Portable][javaportable].

- **UsesGhostscript:** Specifies whether the portable application makes use of [Ghostscript Portable][ghostscriptportable].

- **UsesDotNetVersion:** Specify the minimum required version of the .NET framework the portable application needs. Values can be from `1.0` thru `4.7` (_e.g._ `UsesDotNetVersion=1.1` or `UsesDotNetVersion=4.6.2`).

- **UseStdUtils:** Include the _StdUtils_ plug-in without `ExecAsUser`

- **InstallINF:** Add support and macros for INF installation. Refer to the `Services.nsh` file in the Segments directory for reference.

- **RegistryValueWrite:** If you're using `[RegistryValueWrite]` than set this to true otherwise the function is inaccurate.

- **FileWriteReplace:** Enables the Replace functionality in `[FileWrite]`

- **FileLocking:** Enable this to prevent ejection/unplugging problems for USB devices. Windows Explorer tend to lock application's DLL(s).
  **Note:** As of right now, this only enables support for using `${If} ${FileLocked}` and/or `${IfNot} ${FileLocked}` in the `custom.nsh` file.
  **ToDo:** Handle without the use of `custom.nsh`. (Got a couple ideas already. Check back soon.)

- **Firewall:** Enable Firewall support.

- **Junctions:** Enable support for Junctions (_SymLinks_) functionality.

- **ACLRegSupport:** Enable support for AccessControl on registry keys.

- **ACLDirSupport:** Enable support for AccessControl on directories.

- **RMEmptyDir:** Enable the function `RMEmptyDir`. See the `Core.nsh` segment on line 1192 for reference.

- **LocalLow:** Enable the function `GetLocalAppDataLow`. See the `Core.nsh` segment on line 1351 for reference.

- **PublicDoc:** Enable the function `GetPublicDoc`. See the `Core.nsh` segment on line 1427 for reference.

- **CompareVersions:** Enable the function `Compare`. See the `Core.nsh` segment on line 141 for reference.

- **ConfigFunctions:** Enable `Write(S)` and `Read(S)` functions (4 total). See the `Core.nsh` segment on line 236 for reference.

- **CloseWindow:** Enable `Close` function. See the `Core.nsh` segment on line 1288 for reference.

- **JSONSupport:** Include the _nsJSON_ plugin allowing `nsJSON::Get`, `nsJSON::Set`, and `nsJSON::Serialize` for use within `custom.nsh`.

- **RestartSleep:** Set this to a numerical value (in milliseconds) to set a sleep value for applications that need to restart (i.e. Notepad++ after installing new plugins).

- **WinMessages:** Include the `WinMessages.nsh` file.

- **LineWrite:** Include the `LineWrite.nsh` file.

- **TrimString:** Enable the function `Trim`. See the `Core.nsh` segment on line 1093 for reference.

- **CloseProcess:** Enable the function `CloseX`. See the `Core.nsh` segment on line 1125 for reference.

- **Include64:** Include the `64.nsh` file.

- **IncludeWordRep:** Include both `WordRepS` and `WordRep` functions. See the `Core.nsh` segment on line 608 for reference.

- **GetBetween:** Include the `GetBetween.nsh` file.


## Code-Signing

If `[Team]CertSigning` is set in `AppInfo.ini`, the compiled launcher is signed with `signtool` as the last step of the build.

- **CertSigning:** Sign the launcher.
- **CertExtension:** The certificate's file extension without the period (defaults to `pfx`). The certificate must be named after `[Team]Developer` and live in `Other\Source\contrib\certificates`.
- **CertTimestamp:** A timestamp server URL. Service names (e.g. `Sectigo`) fall back to Sectigo's server.

The certificate password is **never** stored in the source. Set it in the environment before compiling; it is read at compile time only and never ends up in the launcher:

```
set PACMAN_CERT_PASS=your-password
```

Leave it unset for certificates without a password.

## Documentation

Check out the Wiki section for various related articles related to creating PortableApps. The Wiki serves who need a quick reminder on certain functions and macros for use within the `custom.nsh` file. As an added bonus, all (not yet but most) of the source code I've used here is outlined and better explained/documented there as well. For instance, a short guide on registering DLLs and all the macros I used to create the `RegisterDLL.nsh` segment can be found in the Wiki. You can also find an exhaustive tutorial on dealing with Windows Services; plus it explains what each macro is and does within the `Services.nsh` segment and how to use them in action.

#### **Visit the Wiki:** [Pac-Man Wiki][wikihome]

## Contributors

This project has been started by **daemon.devin** and hopefully maintained on a regular basis. However, if you would like to be a part of this then please do not hesitate on getting involved! I'm always open to new ideas and a willingness for the betterment of all things code. =)

A special thanks to FukenGruven. His codebase was the skeleton which was used to start this project.

---

=)

[2]: http://portableapps.com/ "PortableApps.com/"
[3]: https://portableapps.com/node/56500 "A Superfluous Discussion"
[4]: https://portableapps.com/apps/development/nsis_portable "NSIS Portable"
[5]: http://johnhaller.com/useful-stuff/dot-net-portable-apps ".NET Availability and Viability With Portable Apps"
[msadvisory]: https://support.microsoft.com/en-us/kb/3033929 "MS Security Advisory: SHA2 support for Win7/Windows Server '08 R2: March 10, 2015"
[javaportable]: http://portableapps.com/apps/utilities/java_portable "Java Portable"
[ghostscriptportable]: https://portableapps.com/apps/utilities/ghostscript_portable "Ghostscript Portable"
[wikihome]: https://github.com/daemondevin/pac-man/wiki "Pac-Man Wiki"
[tekspert]: http://tekspert.se/ "Webmaster of TekSpert.se/"
[discordworkbench]: https://discord.gg/ExKbgXg "A PAFing Community (Discord Chat Platform)"
