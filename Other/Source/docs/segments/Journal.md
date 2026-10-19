# The rollback journal

Every segment in these docs records how to undo a change before it makes the change. That record is the journal. When the app closes, the launcher works through it newest first until it is empty; if the launcher never got that far, the next launch does it before changing anything else.

The result is one guarantee for the whole framework: whatever a pac-man launcher changes on a PC is undone, whether the app closes normally, the launcher is killed, the PC loses power or the USB stick is pulled.

## What a launch looks like

1. **Recover.** The first launch of an app checks for a journal left behind by an earlier session. If there is one, it rolls it back first and tells the user why.
2. **Open a session.** A new, empty journal is opened for this launch.
3. **Record, then change.** Each segment writes an undo entry, then makes its change. An entry is only ever written for a change that is about to happen.
4. **Run the app.** The launcher waits for it to close.
5. **Roll back.** Each segment undoes its own entries, newest first. A final pass undoes anything still left, in the fixed segment order (see [README.md](README.md#order)).
6. **Close the session.** An empty journal is deleted. A journal that still has entries (for example, an undo that needs administrator rights the launcher no longer has) is marked incomplete and retried on the next launch.

Second launches of an app that is already running never recover or record anything: the journal belongs to the launcher that opened it.

## Where it is kept

| What | Where |
| --- | --- |
| The journal | `HKCU\Software\pac-man\Journal\<AppID>` |
| Backups it refers to (exported registry keys, files, task definitions, INF copies) | `%LOCALAPPDATA%\pac-man\Journal\<AppID>` |

Both are on the host PC, not in the portable app's folder, so recovery works even if the app comes back on a different drive letter or from a different folder.

The journal key holds the session values and one subkey per segment:

| Value | Meaning |
| --- | --- |
| `State` | `active` while a launch is running; `incomplete` when the last rollback left entries; `detached` when the launcher deliberately did not wait for the app (see below) |
| `PID` | Process id of the launcher that opened the session |
| `Launcher` | Full path of that launcher |
| `Version` | PortableApps Compiler version that wrote the journal |

Under each segment's subkey, `Count` is the number of live entries and `1.Op`, `1.A` to `1.D`, `2.Op` and so on are the entries themselves, numbered oldest first.

## Kinds of undo entry

There are 14. Every one is written so that running it twice is harmless, which is what lets an interrupted recovery simply start again.

| Entry | Undoes | How |
| --- | --- | --- |
| `REGKEY` | A registry key that was created or replaced | Deletes the key, then re-imports the backup taken before it was replaced |
| `REGEMPTY` | A parent key created on the way to a new key | Deletes it only if it has no subkeys and no values |
| `REGVALUE` | A registry value that was written | Puts the previous value back with its type, or deletes the value if there was none |
| `FILE` | A file that was created or replaced | Deletes the file, then moves the backup back |
| `DIR` | A folder that was created or replaced | Deletes it (recursively only when recorded that way, and never through a junction or link), then moves the backup back |
| `LINK` | A junction, symbolic link or hard link | Removes the link only when it is provably the one the launcher made, then puts back what was there |
| `CMD` | Anything a command can undo (firewall rules, for example) | Runs the recorded command; listed exit codes count as success. Entries marked admin-only wait for an elevated launch |
| `FONT` | A font loaded for the session | Unloads it and tells running programs the font list changed |
| `STRIPLINES` | Lines added to a text file (the hosts file) | Removes every line carrying the launcher's tag |
| `SVCSTOP` | A service that was started | Stops it and waits until it reports stopped |
| `COMDLL` | A COM server registration | Unregisters it, per user or machine-wide as it was registered |
| `TYPELIB` | A type library registration | Unregisters it if it is still registered |
| `TASK` | A scheduled task | Deletes it, then re-creates the task it replaced from the exported definition |
| `DRIVER` | A driver package in the driver store | Finds the package by its INF's content and removes it with pnputil |

## What the user sees

After an interrupted session, the next launch shows:

> *App* did not shut down cleanly last time. The changes it made to this computer will now be undone before it starts again.

If the launcher also shows the PortableApps.com "did not close properly" notice, the journal stays quiet and recovers behind it, so the user only sees one message.

If some entries cannot be undone yet, typically because they need administrator rights, the user is told they will be retried on the next launch. Nothing is dropped.

## When the launcher doesn't wait

With `WaitForProgram=false` under `[Launch]`, the launcher exits as soon as the app has started, so the app's system changes have to outlive it. The journal is left with `State=detached`, and the next launch rolls it back quietly, without the crash message, before it starts the app again.

Use this only for apps that can't be waited on. Until the next launch, the changes stay on the PC.

## Manual recovery

Launching the app again is always the first thing to try: recovery runs automatically.

If the app can't be launched any more (for example, it was deleted), the information needed to undo its changes is still on the PC:

- Exported registry keys in the backup folder are ordinary `.reg` files and can be imported with `reg import`.
- The Hosts segment keeps a full copy of the hosts file from before its first change.
- Scheduled tasks it replaced are kept as task XML, which `schtasks /create /xml` accepts.

When reporting a problem, include an export of `HKCU\Software\pac-man\Journal` and the contents of `%LOCALAPPDATA%\pac-man\Journal`.
