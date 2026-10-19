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

The one deliberate exception to the first two is installing a shared runtime (Visual C++ or .NET) system-wide: it can't safely be removed again, because other programs may start using it. The Runtime segment only does that when the user agrees in a prompt that says it is permanent, and prefers a portable copy whenever one is available.

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
| `REGEMPTY` | root, subkey | Delete the key only if it has no subkeys and no values (parent keys created on the way to a new key) |
| `REGVALUE` | root, subkey, value name, previous value (`STR:`/`EXP:`/`DWORD:` or empty) | Restore the previous value, or delete it if it didn't exist |
| `FILE` | path, backup | Delete the file, move the backup back |
| `DIR` | path, backup, `recursive` | Remove the directory (never recursing into a junction or symlink), restore the backup |
| `LINK` | link path, backup | Remove the link itself, never its target; restore the backup |
| `CMD` | command line, accepted exit codes, `admin` | Run the command (e.g. `sc delete`, `netsh ... delete rule`, `schtasks /delete`). With `admin`, the entry is kept rather than run when the launcher is not elevated |
| `DRIVER` | copy of the package's INF | Find the driver store's `oemNN.inf` with the same content and remove the package (`pnputil /delete-driver /uninstall /force`) |
| `TASK` | task name, XML backup, `admin` | Delete the task if it exists, re-create the exported original if there was one |
| `FONT` | font file, flags | `RemoveFontResourceEx` and broadcast `WM_FONTCHANGE` |
| `STRIPLINES` | text file, marker | Remove every line that contains the marker |
| `SVCSTOP` | service name, timeout | Stop the service and wait until it reports `STOPPED` |
| `COMDLL` | COM server, scope, bitness, CLSID | Unregister it (in-process for user scope, `regsvr32 /u` or `/unregserver` for machine scope). Skipped when the CLSID is already gone |
| `TYPELIB` | type library, scope | `UnRegisterTypeLib(ForUser)` if it is still registered |

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
| `${Journal::RegKey} Segment Root Subkey $var` | Journal a key about to be created or replaced: exports an existing key (`existed`), or records the key and its missing parents (`new`) |
| `${Journal::RegKeyExists} Root Subkey $var` | 1 when the key exists (HKCU, HKLM or HKCR), else 0 |
| `${Journal::FindStagedInf} InfFile $var` | The `oemNN.inf` in the driver store with the same content as InfFile, or empty |
| `${Journal::PnPUtil} $var` | The pnputil.exe to use (the 64-bit one under WOW64) |
| `${Journal::BackupFile} Segment Path $var` | Copy a file into the journal store and return the backup path |
| `${Journal::Discard} Segment` | Drop the newest entry when the mutation it guarded definitely did not happen |
| `${Journal::PEBitness} Path $var` | 32 or 64 from a file's PE header |
| `${Journal::RegSvr32} Bitness $var` | The regsvr32.exe that matches a 32 or 64-bit server |
| `${Journal::ComUserCall} Path Proc $var` | Call DllRegisterServer/DllUnregisterServer in-process, redirected to HKCU |
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
| Runtime | `Runtime` | **Done**; nothing to journal (it only sets environment variables for the app). |
| RegDLL | `RegDLLs` | **Journaled**, user scope by default; runtime-tested for user and machine scope, crash recovery and protection of an existing registration |
| Fonts | `Fonts` | **Journaled**; runtime-tested (user scope, crash recovery) |
| Symlinks | `Symlinks` | **Journaled**; hard links runtime-tested including restore of the file that was there before. |
| Associations | `FileAssociations` | **Journaled**, user scope only; runtime-tested (file types, protocols, context menus, replace of an existing ProgID, crash recovery, foreign keys preserved) |
| Firewall | `Firewall` | **Journaled**, admin only; Needs more testing under Windows Firewall |
| Drivers | `Drivers` | **Journaled**, admin only; runtime-tested against a pnputil stand-in (add, already-staged package left alone, failed package, architecture filter, crash recovery). Needs more testing. |
| Services | `Services` | **Journaled**; runtime-tested for new services and crash recovery. |
| Tasks | `Tasks` | **Journaled**; runtime-tested but needs more testing against other versions of Windows |

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

**Executables per architecture**

`[Launch]` takes an executable for each Windows architecture, and a second one for launches with command line parameters:

```INI
[Launch]
ProgramExecutable=App\app.exe
ProgramExecutable64=App64\app.exe
ProgramExecutableARM64=AppARM64\app.exe
ProgramExecutableWhenParameters=App\app-cli.exe
ProgramExecutableWhenParameters64=App64\app-cli.exe
ProgramExecutableWhenParametersARM64=AppARM64\app-cli.exe
```

- The launcher works out the architecture Windows itself runs on, so an ARM64 PC is told apart from an x64 one (a 32-bit launcher sees both as 64-bit).
- With parameters, `ProgramExecutableWhenParameters<arch>` is used; without them, or when that key is missing, `ProgramExecutable<arch>`.
- ARM64 falls back to x64 and then x86, and x64 to x86, when its keys are missing or the file they name doesn't exist. A package can add an ARM64 build without breaking copies that don't have one yet.
- `%PAL:ProgramDir%` is the folder of the executable picked for the launch (with the usual `:ForwardSlash` and `:DoubleBackslash` forms), for use in `WorkingDirectory` and anywhere else a path is needed.
- `Custom.nsh` can force a build by setting `$Arch` (`x86`, `x64` or `arm64`) in its `.onInit` hook.

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
Fonts=true
Symlinks=true
FileAssociations=true
Firewall=true
Drivers=true
Runtime=true
FileCleanup=true
DirectoryCleanup=true
Hosts=true
```

A key set to `false` is treated the same as an omitted key.

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

- **Services:** Temporary Windows services. Needs administrator rights; without them nothing is changed and one warning is shown.
  > To use this feature add the section `[Service1]` (numerical ordering) to the `Launcher.ini` file. Each entry supports the following keys:

| **Key**     | **Value** |
| :---------- | :-------- |
| Name        | The service name. |
| Path        | The service binary, optionally followed by arguments. Supports environment variables. Quote the binary when its path has spaces and arguments follow. |
| Type        | _own_ (default for new services), _share_, _interact_, _kernel_, _filesys_, _rec_ |
| Start       | _demand_ (default for new services), _boot_, _system_, _auto_, _delayed-auto_, _disabled_ |
| Depend      | Dependencies separated by `/` (new services only). |
| DisplayName | Optional display name (new services only). |
| IfExists    | _skip_ (default): an existing service with this name is left alone and the portable one is not installed.<br />_replace_: the existing service is stopped and temporarily pointed at the portable binary. Its account, dependencies, description and recovery settings are untouched, and its original binary path, start type and running state are restored afterwards. |
| Timeout     | Seconds to wait for the service to start or stop (default 30). |
| Required    | _true_ to show a warning when the service does not start. |

> New services are stopped and deleted on exit. Replaced services are stopped, pointed back at their original binary and restarted if they were running. Both are journaled, so the same happens on the next launch after a crash.
>
> ```INI
> [Service1]
> Name=SomeServiceName
> Path=%PAL:AppDir%\service32.exe
> Start=demand
>
> [Service2]
> Name=AnotherService
> Path="%PAL:DataDir%\My Service\service64.exe" -run
> Type=own
> Start=auto
> IfExists=replace
> ```

- **RegDLLs:** Temporary COM registration of DLLs, EXE servers and type libraries.

  > To use this feature add the section `[RegisterDLL1]` (numerical ordering) to the `Launcher.ini` file. Each entry supports these keys:
  >
  > - **Type:** _REGDLL_ (COM DLL/OCX), _REGDLLTLB_ (DLL plus its embedded type library), _REGTLB_ (type library), _REGUSERTLB_ (type library for the current user only), _REGEXE_ (out-of-process server via `/regserver`).
  > - **File:** Path to the file. Supports environment variables.
  > - **Scope:** _user_ (default for 32-bit DLLs) registers for the current user only, with no admin rights needed: the launcher calls `DllRegisterServer` in-process with HKCR and HKLM redirected to HKCU. _machine_ uses the matching `regsvr32.exe` and needs admin rights. 64-bit DLLs and EXE servers are always machine scope.
  > - **CLSID:** Optional, recommended. If the same class is already registered, its key is backed up and restored on exit instead of being lost.
  > - **ProgID:** Optional. Used to look up the CLSID when it isn't given; its key is protected the same way.
  >
  > Type libraries that are already registered are left alone.
  >
  > ```INI
  > [RegisterDLL1]
  > Type=REGDLL
  > File=%PAL:AppDir%\controller.dll
  > CLSID={00000000-0000-0000-0000-000000000000}
  >
  > [RegisterDLL2]
  > Type=REGEXE
  > File=%PAL:AppDir%\server.exe
  > ```

- **Tasks:** Session-bound Windows scheduled tasks.

  > `[TaskCleanup]` lists tasks the app itself creates while it runs. Each name is checked before the app starts: a task that doesn't exist yet is deleted when the app exits (or on the next launch after a crash), and a task that already existed is someone else's and is left alone.
  >
  > ```INI
  > [TaskCleanup]
  > 1=MyAppTask1
  > 2=Another Task w/ Spaces
  > ```
  >
  > `[ScheduledTask1]`, `[ScheduledTask2]` and so on are created by the launcher and removed again on exit:
  >
  > - **Name** (required; may include a folder, `\Vendor\Task`), **Command** (required, supports `%PAL:...%`), **Arguments**.
  > - **Schedule** (required): _ONCE_, _MINUTE_, _HOURLY_, _DAILY_, _WEEKLY_, _MONTHLY_, _ONIDLE_, _ONSTART_ or _ONLOGON_; with **Modifier**, **Days**, **Months**, **StartTime** (`HH:mm`), **StartDate** / **EndDate** (in the Windows locale's date format) and **IdleTime** as `schtasks` expects them.
  > - **RunAsUser**: _SYSTEM_, or omit for the current user (other accounts would need a password in `Launcher.ini`, which isn't supported). **RunLevel**: _LIMITED_ (default) or _HIGHEST_. Both _SYSTEM_ and _HIGHEST_ need administrator rights; without them the task is skipped with one warning.
  > - **Enabled** (default _true_), **RunNow** (_true_ runs it once right after creation), **Required** (_true_ to warn when it can't be created).
  > - **IfExists**: _skip_ (default) leaves an existing task with that name alone. _replace_ exports it with PowerShell's `Export-ScheduledTask`, replaces it, and re-creates the original on exit. A task that logs on with a stored password can't be re-created without that password, so it is never replaced.
  >
  > ```INI
  > [ScheduledTask1]
  > Name=MyAppMaintenance
  > Command=%PAL:AppDir%\MyApp\maintenance.exe
  > Arguments=--cleanup --temp
  > Schedule=DAILY
  > StartTime=02:00
  > ```

- **Java:** Add support for the Java Runtime Environment.

- **JDK:** Add support for the Java Development Kit.

- **XML:** Add XML support.

- **Ghostscript:** Add Ghostscript support.

- **Fonts:** Make fonts available while the app runs. Font files are never copied into the Windows Fonts folder.

  > With no `[FontN]` sections, every font in `Data\Fonts` is loaded for the session (the old `FontsFolder` behaviour). For more control add `[Font1]`, `[Font2]` and so on:
  >
  > - **File:** Font file or wildcard. Supports environment variables.
  > - **Scope:** _Temporary_ (default) loads the font for the session with `AddFontResource`. _User_ also registers it under `HKCU` (per-user fonts, Windows 10 1809 and later). _System_ registers it under `HKLM` and needs admin rights; without them the font is loaded temporarily instead.
  > - **Name:** Registry value name for User/System scope (defaults to the file name plus " (TrueType)" or " (OpenType)").
  > - **IfExists:** _skip_ (default) or _replace_ when that registry value already exists. _replace_ backs up the old value and restores it.
  > - **Required:** _true_ to warn when a font cannot be loaded.
  >
  > ```INI
  > [Font1]
  > File=%PAL:AppDir%\Fonts\*.ttf
  > Scope=User
  > ```

- **Symlinks:** Link places an app insists on using into the portable `Data` folder. The user can turn this off with `Symlinks=false` in their `<AppID>.ini`.

  > Add `[Symlink1]`, `[Symlink2]` and so on:
  >
  > - **Type:** _junction_ (default; directory, no admin rights), _soft_ (directory symlink, falls back to a junction when Windows refuses), _symbolic_ (file symlink; admin rights or Developer Mode), _hard_ (file hard link, same volume only).
  > - **Source:** File or folder inside `Data` that the link points to. Folders are created when missing.
  > - **Target:** Where the link goes. Supports environment variables.
  >
  > Whatever already exists at the target is renamed to `<Target>.BackupBy<AppID>` (nothing is copied or deleted) and renamed back on exit. Rollback removes the link only when it provably is the launcher's own (a junction/symlink, or a hard link to the source), so real data is never deleted.
  >
  > ```INI
  > [Symlink1]
  > Type=junction
  > Source=Settings
  > Target=%APPDATA%\Vendor\App
  > ```

- **FileAssociations:** File types, URL protocols and context menu entries for as long as the app runs. Everything is written to `HKCU\Software\Classes`; `UserChoice` is never touched, so Windows stays in charge of default apps. The user can turn this off with `FileAssociations=false` in their `<AppID>.ini`.

  > `[FileAssociation1]`, `[FileAssociation2]` and so on:
  >
  > - **Extension:** One extension or a comma separated list (the dot is optional).
  > - **ProgID:** Program identifier. Defaults to `<AppID>.<first extension>`.
  > - **Description**, **DefaultIcon** (`path,index`), **OpenCommand** (required, `%1` = file), **EditCommand** (optional).
  > - **IfExists:** _skip_ (default): an extension that already has a handler only gains the app in its "Open with" list, and an existing ProgID makes the section skip. _replace_: the extension's default is set and an existing ProgID is backed up and replaced.
  >
  > `[ProtocolHandler1]` and so on: **Protocol** (scheme, `myapp`, `myapp:` or `myapp://`), **Description**, **DefaultIcon**, **OpenCommand** (required, `%1` = full URL), **IfExists** (_skip_ leaves a scheme registered anywhere alone; _replace_ overrides it for the current user).
  >
  > `[ContextMenu1]` and so on:
  >
  > - **Target:** `.ext` (via `SystemFileAssociations`, so it works whichever app owns the extension), `*`, `Directory`, `Directory\Background`, `Drive`, `Folder`, `AllFilesystemObjects` or a ProgID.
  > - **MenuKey** (defaults to `<AppID>.<N>`), **MenuText** (required), **MenuCommand** (required; `%1` for files and folders, `%V` for `Directory\Background`), **MenuIcon**, **Position** (_Top_ or _Bottom_), **Extended** (_true_ = Shift+right-click only), **IfExists**.
  >
  > Windows strips one pair of outer quotes from INI values, so a command such as `"%PAL:AppDir%\App\app.exe" "%1"` arrives broken; the segment detects this and puts the quotes back.
  >
  > Every key that did not exist is removed on exit; parent keys created for it are removed only while empty, so anything another program adds meanwhile is kept. Replaced keys are exported first and imported back.
  >
  > ```INI
  > [FileAssociation1]
  > Extension=.myfile,.myother
  > ProgID=MyApp.Document
  > Description=My App Document
  > DefaultIcon=%PAL:AppDir%\MyApp\myapp.exe,0
  > OpenCommand="%PAL:AppDir%\MyApp\myapp.exe" "%1"
  >
  > [ProtocolHandler1]
  > Protocol=myapp
  > OpenCommand="%PAL:AppDir%\MyApp\myapp.exe" "%1"
  >
  > [ContextMenu1]
  > Target=Directory\Background
  > MenuText=Open My App here
  > MenuCommand="%PAL:AppDir%\MyApp\myapp.exe" "%V"
  > ```

- **Firewall:** Windows Firewall rules that exist only while the app runs. Requires administrator rights (use `[Launch]:RunAsAdmin=try` or `prompt`); without them nothing is changed and one warning is shown.

  > Every rule gets ` [pac-man:<AppID>]` appended to its name and is only ever deleted by that full name, so rules the launcher didn't create are never touched. Add `[FirewallRule1]`, `[FirewallRule2]` and so on:
  >
  > - **Name** (required), **Direction** (_In_ (default), _Out_ or _Both_), **Action** (_Allow_ (default), _Block_, _Bypass_), **Protocol** (_Any_ (default), _TCP_, _UDP_, _ICMPv4_, _ICMPv6_ or a number).
  > - **LocalPort** / **RemotePort** (TCP and UDP only), **LocalAddress** / **RemoteAddress**, **Program** (supports `%PAL:...%`), **Service**.
  > - **Profile** (_Any_ or a comma list of _Domain_, _Private_, _Public_), **InterfaceType** (_Any_, _Wireless_, _LAN_, _RAS_), **Enabled** (default _true_), **EdgeTraversal** (inbound only), **Security**, **Description**, **Required** (_true_ to warn when a rule can't be created).
  > - **BlockAll**=_true_ with **BlockAllDir** (and **BlockAllRecur**, default _true_) adds an outbound block rule for every `.exe` in that folder.
  >
  > An invalid section is reported and skipped; it never stops the app. `IfExists` is accepted and ignored: a rule that already carries this app's tag can only be a leftover of this app, so it is replaced.
  >
  > ```INI
  > [FirewallRule1]
  > Name=MyApp HTTP Server
  > Direction=In
  > Protocol=TCP
  > LocalPort=8080
  > Program=%PAL:AppDir%\MyApp\server.exe
  > Profile=Private,Public
  >
  > [FirewallRule2]
  > BlockAll=true
  > BlockAllDir=%PAL:AppDir%\MyApp\Updater
  > ```

- **Drivers:** Driver packages that are in the Windows driver store only while the app runs. Uses `pnputil /add-driver` and `/delete-driver` (Windows 10 1607 and later) and requires administrator rights; without them nothing is changed and one warning is shown.

  > Add `[Driver1]`, `[Driver2]` and so on:
  >
  > - **InfFile:** The package's INF (supports `%PAL:...%`). It has to be signed the way Windows requires, or pnputil refuses it.
  > - **Architecture:** _x86_, _x64_ or _any_ (default). The section is skipped on Windows of the other bitness, so a package can be listed once per architecture.
  > - **Install:** _true_ (default) also installs the driver on matching devices that are present; _false_ only adds it to the driver store.
  > - **Required:** _true_ to warn when the package can't be added.
  >
  > A package that is already in the driver store before launch belongs to someone else and is never removed. The journal keeps a copy of the INF and finds the package again by content (the driver store keeps a byte-identical copy as `oemNN.inf`), so cleanup works even when the portable drive is gone and never depends on pnputil's localized output.
  >
  > ```INI
  > [Driver1]
  > InfFile=%PAL:AppDir%\Drivers\x64\mydevice.inf
  > Architecture=x64
  >
  > [Driver2]
  > InfFile=%PAL:AppDir%\Drivers\x86\mydevice.inf
  > Architecture=x86
  > ```

- **Runtime:** Checks for the Visual C++ and .NET runtimes the app needs before anything else happens, and provides a missing one the portable way when it can.

  > `[VCRuntime1]`, `[VCRuntime2]` and so on:
  >
  > - **Version:** _2015-2022_ (also _2015_, _2017_, _2019_, _2022_), _2013_, _2012_, _2010_, _2008_ or _2005_.
  > - **Architecture:** _x86_ (default), _x64_ or _arm64_ (2015-2022 only). **MinVersion:** minimum 14.x version (2015-2022 only).
  >
  > `[NETRuntime1]`, `[NETRuntime2]` and so on:
  >
  > - **Framework:** .NET Framework (_net20_, _net35_, _net40_ ... _net48_, _net481_; dots allowed) or .NET 5 and later (_net6.0_, _net8.0_, also _net8_).
  > - **Kind** (.NET 5+): _core_ (default), _desktop_ or _aspnet_. **Architecture** (.NET 5+): _x86_ (default) or _x64_. **MinVersion** (.NET 5+): e.g. _8.0.5_.
  >
  > Both kinds also take:
  >
  > - **Local:** a portable copy, used only when the runtime isn't installed. Visual C++: a folder of runtime DLLs, put in front of `PATH`. .NET 5+: a `dotnet` folder, set as `DOTNET_ROOT`. Only the app's environment changes.
  > - **Installer:** a redistributable to offer when nothing else works (a bare file name is looked up in `App\Prerequisites`), with **InstallerArgs** to override the default silent switches. The user is asked first, and told that it stays installed.
  > - **Required:** _true_ stops the launch with a message when the runtime is still missing; otherwise a warning is shown and the app starts anyway.
  >
  > Detection never parses localized output: it reads the documented registry values (Visual C++ 2015-2022, .NET Framework `Release`), the runtime DLLs in the system folder for the requested architecture, the WinSxS assemblies (2005/2008) and the `dotnet\shared` folders (.NET 5+).
  >
  > ```INI
  > [VCRuntime1]
  > Version=2015-2022
  > Architecture=x64
  > Local=%PAL:AppDir%\Runtimes\vc14_x64
  > Required=true
  >
  > [NETRuntime1]
  > Framework=net8.0
  > Kind=desktop
  > Architecture=x64
  > Local=%PAL:AppDir%\dotnet
  > Installer=windowsdesktop-runtime-8.0-win-x64.exe
  > Required=true
  > ```

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
