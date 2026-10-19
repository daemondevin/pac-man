# Windows services

The Services segment installs and starts Windows services the app needs while it runs. It can also borrow an existing service, temporarily pointing it at the portable binary. Either way, the PC's services are back the way they were when the app closes, or on the next launch after a crash.

## Enabling it

```ini
[Activate]
Services=true
```

Recompile the launcher after adding the key.

Services need administrator rights. Without them the segment changes nothing and shows one warning. See [README.md](README.md#administrator-rights) for `RunAsAdmin`.

## Services

```ini
[Service1]
Name=MyAppService
Path=%PAL:AppDir%\MyApp\service.exe
Type=own
Start=demand
Depend=Tcpip/Dnscache
DisplayName=My App Service
IfExists=skip
Timeout=30
Required=true
```

| Key | Default | Description |
| --- | --- | --- |
| `Name` | (required) | The service name. |
| `Path` | (required) | The service binary, optionally followed by arguments. Quote the binary when its path has spaces and arguments follow it. |
| `Type` | `own` | `own`, `share`, `interact`, `kernel`, `filesys` or `rec`. |
| `Start` | `demand` | `demand`, `boot`, `system`, `auto`, `delayed-auto` or `disabled`. |
| `Depend` | | Services this one depends on, separated by `/`. New services only. |
| `DisplayName` | | Name shown in the Services console. New services only. |
| `IfExists` | `skip` | What to do when a service with this name already exists (below). |
| `Timeout` | `30` | Seconds to wait for the service to start or stop. |
| `Required` | `false` | `true` shows a warning when the service doesn't start. |

## When the service already exists

| `IfExists` | Behaviour |
| --- | --- |
| `skip` | The existing service is left alone. The portable one isn't installed and nothing changes. |
| `replace` | The existing service is stopped and temporarily pointed at the portable binary, then started. |

With `replace`, only the binary path, start type and service type change. The service's account, dependencies, description and recovery settings are left untouched. On exit, the original binary path, start type and type are put back, and the service is started again if it was running before.

Use `replace` when the app ships its own build of a service the PC may already have (a database server, for example) and must use its own.

## How it's undone

The undo steps are journaled before each change, so they run newest first:

| Service | On exit |
| --- | --- |
| Installed by the launcher | Stopped (`SVCSTOP`), then deleted with `sc delete` |
| Borrowed with `IfExists=replace` | Stopped, then `sc config` puts the original binary path, start type and type back, then it's started again if it was running |

"Service doesn't exist" and "service already marked for deletion" count as success when deleting, so the undo is safe to run twice.

## Notes

- A service the launcher installs is stopped and removed even if other programs started using it while the app ran. Don't use this segment for a service other software should keep.
- The segment runs only for the first launch of an app.
