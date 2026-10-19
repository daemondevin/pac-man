# Scheduled tasks

The Tasks segment handles two kinds of Windows scheduled task, and makes sure neither outlives the app, even after a crash:

- tasks the **app** creates while it runs, which the launcher deletes again afterwards;
- tasks the **launcher** creates for the app, which exist only while the app runs.

## Enabling it

```ini
[Activate]
Tasks=true
```

Recompile the launcher after adding the key.

## Tasks the app creates

List the names of tasks the app is known to create:

```ini
[TaskCleanup]
1=MyAppTask1
2=Another Task w/ Spaces
```

Each name is checked before the app starts:

- A task that doesn't exist yet is deleted again when the app closes, or on the next launch after a crash.
- A task that already exists belongs to someone else (an installed copy of the app, for example) and is left alone, even if the app changes it while it runs.

## Tasks the launcher creates

```ini
[ScheduledTask1]
Name=MyAppMaintenance
Command=%PAL:AppDir%\MyApp\maintenance.exe
Arguments=--cleanup --temp
Schedule=DAILY
StartTime=02:00
```

| Key | Default | Description |
| --- | --- | --- |
| `Name` | (required) | Task name, optionally in a folder: `\Vendor\Task`. |
| `Command` | (required) | Program to run. |
| `Arguments` | | Command line arguments. |
| `Schedule` | (required) | `ONCE`, `MINUTE`, `HOURLY`, `DAILY`, `WEEKLY`, `MONTHLY`, `ONIDLE`, `ONSTART` or `ONLOGON`. |
| `Modifier` | | Repeat interval, e.g. `15` with `MINUTE` for every 15 minutes. |
| `Days` | | Days for `WEEKLY` or `MONTHLY`, e.g. `MON,FRI` or `1,15`. |
| `Months` | | Months for `MONTHLY`, e.g. `JAN,JUL`. |
| `StartTime` | | `HH:mm`. |
| `StartDate` | | Start date, in the date format of the Windows locale. |
| `EndDate` | | End date, same format. |
| `IdleTime` | | Minutes of idle time for `ONIDLE`. |
| `RunAsUser` | current user | `SYSTEM`, or leave it out to run as the current user. |
| `RunLevel` | `LIMITED` | `LIMITED` or `HIGHEST`. |
| `Enabled` | `true` | `false` creates the task disabled. |
| `RunNow` | `false` | `true` runs the task once straight after creating it. |
| `IfExists` | `skip` | What to do when a task with this name already exists (below). |
| `Required` | `false` | `true` shows a warning when the task can't be created. |

The keys map onto `schtasks /create` options (`/SC`, `/MO`, `/D`, `/M`, `/ST`, `/SD`, `/ED`, `/I`, `/RU`, `/RL`), so `schtasks /?` describes the accepted values in detail.

### When the task already exists

| `IfExists` | Behaviour |
| --- | --- |
| `skip` | The existing task is left alone and nothing is created. |
| `replace` | The existing task is exported, replaced with the launcher's, and re-created from the export when the app closes. |

A task that stores a password can't be re-created without that password, so `replace` skips it rather than lose it.

## Accounts and privileges

- Tasks for the current user at `LIMITED` level need no administrator rights.
- `RunAsUser=SYSTEM` and `RunLevel=HIGHEST` need administrator rights. Without them, the task is skipped and one warning is shown.
- Other accounts would need a password in the launcher ini, which isn't supported.

## How it's undone

A `TASK` journal entry is written before every task is created or claimed:

| Task | On exit |
| --- | --- |
| Listed under `[TaskCleanup]` and not there before | Deleted if it exists |
| Created by the launcher | Deleted |
| Replaced by the launcher | Deleted, then the original is re-created from its exported definition |

Exporting a task uses PowerShell's `Export-ScheduledTask`; the export is kept in the journal's backup folder until the original is back.

## Notes

- The segment runs only for the first launch of an app.
