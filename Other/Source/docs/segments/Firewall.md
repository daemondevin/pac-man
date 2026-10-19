# Firewall rules

The Firewall segment adds Windows Firewall rules for as long as the app runs and removes them when it closes, or on the next launch after a crash. It uses `netsh advfirewall`.

Every rule gets ` [pac-man:<AppID>]` appended to its name, and the launcher only ever deletes rules by that full name. Rules that the user, Windows or another program created are never touched, even if they have the same base name.

## Enabling it

```ini
[Activate]
Firewall=true
```

Recompile the launcher after adding the key.

The segment needs administrator rights. Without them it adds nothing and shows one warning. See [README.md](README.md#administrator-rights) for `RunAsAdmin`.

## Rules

```ini
[FirewallRule1]
Name=MyApp HTTP Server
Direction=In
Action=Allow
Protocol=TCP
LocalPort=8080
Program=%PAL:AppDir%\MyApp\server.exe
Profile=Private,Public
Description=Allow HTTP access to MyApp server
Required=true
```

| Key | Default | Description |
| --- | --- | --- |
| `Name` | (required) | Rule name. Shown in Windows as `<Name> [pac-man:<AppID>]`. |
| `Direction` | `In` | `In`, `Out` or `Both`. `Both` creates two rules with the same name. |
| `Action` | `Allow` | `Allow`, `Block` or `Bypass`. |
| `Protocol` | `Any` | `Any`, `TCP`, `UDP`, `ICMPv4`, `ICMPv6` or a protocol number. |
| `LocalPort` | | A port, a range or a list: `80`, `8000-8080`, `80,443`. TCP and UDP only. |
| `RemotePort` | | Same format as `LocalPort`. |
| `LocalAddress` | | An address, range, subnet or keyword. |
| `RemoteAddress` | | Same format as `LocalAddress`. |
| `Program` | | The executable the rule applies to. |
| `Service` | | Short name of a service the rule applies to. |
| `Profile` | `Any` | `Any`, or a comma-separated list of `Domain`, `Private`, `Public`. Spaces in the list are ignored. |
| `InterfaceType` | `Any` | `Any`, `Wireless`, `LAN` or `RAS`. |
| `Enabled` | `true` | `false` adds the rule switched off. |
| `EdgeTraversal` | `false` | `true` allows edge traversal. Inbound rules only. |
| `Security` | `NotRequired` | `NotRequired`, `Authenticate`, `AuthEnc`, `AuthDynEnc` or `AuthNoEncap`. |
| `Description` | | Rule description. |
| `Required` | `false` | `true` shows a warning when the rule can't be added. |

## Blocking every program in a folder

A section with `BlockAll=true` adds an outbound block rule for every `.exe` it finds, instead of one named rule. Useful for keeping an app and its helpers offline.

```ini
[FirewallRule2]
BlockAll=true
BlockAllDir=%PAL:AppDir%\MyApp
BlockAllRecur=true
```

| Key | Default | Description |
| --- | --- | --- |
| `BlockAll` | | `true` to scan a folder and block each program in it. |
| `BlockAllDir` | | The folder to scan. |
| `BlockAllRecur` | `true` | `false` scans only the folder itself, not its subfolders. |

## How it's undone

Before each rule is added, a `CMD` journal entry is written that deletes the rule by its full tagged name. netsh's "no rules match" exit code counts as success, so the undo is safe to run when the rule is already gone.

The entry is marked admin-only. A launch without administrator rights keeps it in the journal rather than running it and failing, and the next elevated launch removes the rule.

## Notes

- `IfExists` is accepted for compatibility and ignored. A rule that already carries this app's tag can only be left over from this app, so it is replaced and removed again on exit.
- The segment runs only for the first launch of an app.
