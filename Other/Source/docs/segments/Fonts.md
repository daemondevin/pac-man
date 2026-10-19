# Fonts

The Fonts segment makes an app's fonts available while it runs. Font files are never copied into the Windows Fonts folder, and every font is unloaded again when the app closes, or on the next launch after a crash.

## Enabling it

```ini
[Activate]
Fonts=true
```

Recompile the launcher after adding the key.

With no `[FontN]` sections, every font in `%PAL:DataDir%\Fonts` is loaded for the session. That's the simplest setup: users drop fonts into `Data\Fonts`, and they're available while the app runs.

## Fonts

```ini
[Font1]
File=%PAL:AppDir%\Fonts\*.ttf
Scope=Temporary

[Font2]
File=%PAL:AppDir%\Fonts\Brand.otf
Scope=User
Name=Brand Sans (OpenType)
IfExists=replace
Required=true
```

| Key | Default | Description |
| --- | --- | --- |
| `File` | (required) | A font file or a wildcard such as `*.ttf`. |
| `Scope` | `Temporary` | How widely the font is made available (below). |
| `Name` | file name + ` (TrueType)` or ` (OpenType)` | Registry value name for `User` and `System` scope. Ignored when `File` is a wildcard. |
| `IfExists` | `skip` | `skip` or `replace`, when the registry value for `User` or `System` scope already exists. `replace` backs up the old value and puts it back on exit. |
| `Required` | `false` | `true` shows a warning when a font can't be loaded. |

### Scopes

| `Scope` | What it does | Admin rights |
| --- | --- | --- |
| `Temporary` | Loads the font for the current session. Every program can use it until it's removed. | No |
| `User` | Also registers it for the current user (per-user fonts, Windows 10 version 1809 and later), for apps that look fonts up in the registry. | No |
| `System` | Also registers it machine-wide. Without administrator rights, the font is loaded with `Temporary` scope instead. | Yes |

Most apps only need `Temporary`. Use `User` when an app lists fonts from the registry rather than asking Windows which fonts are loaded.

## How it's undone

| Change | Journal entry | On exit |
| --- | --- | --- |
| A font loaded | `FONT` | Unloaded |
| A registry value written (`User` or `System` scope) | `REGVALUE` with the previous value | The previous value is put back, or the value is deleted |

Running programs are then told the font list changed, so they stop offering the removed fonts.

## Notes

- The segment runs only for the first launch of an app.
