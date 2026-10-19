# Segment documentation

These pages document the segments that run on the pac-man rollback journal. Each one changes something on the host PC for as long as the app runs, records how to undo that change before making it, and undoes it when the app closes, or on the next launch if the launcher was interrupted.

Start with [Journal.md](Journal.md): it explains the guarantees every segment below relies on.

| Page | Segment | `[Activate]` key | Changes | Admin rights |
| --- | --- | --- | --- | --- |
| [FileAssociations.md](FileAssociations.md) | Associations | `FileAssociations=true` | File types, URL protocols, context menus (HKCU only) | No |
| [Fonts.md](Fonts.md) | Fonts | `Fonts=true` | Session fonts, optionally registered per user or per machine | Only for `Scope=System` |
| [SymbolicLinks.md](SymbolicLinks.md) | Symlinks | `Symlinks=true` | Junctions, symbolic links and hard links into the Data folder | Only for file symbolic links |
| [COMRegistration.md](COMRegistration.md) | RegDLL | `RegDLLs=true` | COM servers and type libraries | Only for machine scope |
| [WindowsServices.md](WindowsServices.md) | Services | `Services=true` | Windows services | Yes |
| [HostsFile.md](HostsFile.md) | Hosts | `Hosts=true` | Lines in the hosts file | Yes |
| [Firewall.md](Firewall.md) | Firewall | `Firewall=true` | Windows Firewall rules | Yes |
| [ScheduledTasks.md](ScheduledTasks.md) | Tasks | `Tasks=true` | Scheduled tasks | Only for SYSTEM or highest privileges |
| [Drivers.md](Drivers.md) | Drivers | `Drivers=true` | Driver packages in the driver store | Yes |
| [RuntimeDependences.md](RuntimeDependences.md) | Runtime | `Runtime=true` | Nothing (checks only; an installer runs only with consent) | Only to install a runtime |

## Enabling a segment

Segments are compiled in, not switched on at run time. To use one:

1. Add its key under `[Activate]` in `App\AppInfo\Launcher\<AppID>.ini`.
2. Add the segment's numbered sections (`[Font1]`, `[FirewallRule1]` and so on) to the same file.
3. Recompile the launcher with PortableApps Compiler. The compiler reads `[Activate]` and only builds in the segments that are switched on.

Numbered sections are read in order, starting at 1, and reading stops at the first missing number. `[Font1]`, `[Font2]`, `[Font4]` loads two fonts, not three.

Values that take a path accept `%PAL:AppDir%`, `%PAL:DataDir%` and the other `%PAL:...%` variables, plus ordinary environment variables such as `%APPDATA%`.

## Administrator rights

Segments that need administrator rights fail closed: without them they change nothing and show one warning. To give the launcher rights, set `RunAsAdmin` under `[Launch]`:

| Value | Behaviour |
| --- | --- |
| `try` | Asks Windows for elevation; carries on without it if refused |
| `prompt` | Asks the user first whether to elevate; No starts without admin rights |
| `force` | Requires elevation; the app does not start without it |
| `compile-force` | Builds the launcher to always run elevated |

With `prompt`, users can skip the question permanently with `PromptAdmin=false` in their `<AppID>.ini` user configuration file.

An elevated launcher starts the app elevated too, unless `[Activate]` has `ExecAsUser=true`. That setting starts the app through Explorer as the normal user. It also means the app does not inherit environment variables the launcher set, so do not combine it with `[Environment]` settings or custom code that sets the environment for the app.

## Order

Segments are applied in this order before the app starts and undone in the reverse order after it closes, so nothing is removed while something applied after it still depends on it:

1. Runtime (checks, during start-up)
2. RegDLL
3. Fonts
4. Symlinks
5. Associations
6. Firewall
7. Hosts
8. Drivers
9. Services
10. Tasks

All of them run only for the first launch of an app. A second launch while the app is open hands its command line to the running app and changes nothing.
