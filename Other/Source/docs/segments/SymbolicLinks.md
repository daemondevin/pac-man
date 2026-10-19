# Symbolic links and junctions

The Symlinks segment links places an app insists on using, such as `%APPDATA%\Vendor\App`, to folders or files in the portable `Data` folder. The app reads and writes where it always does, and the data ends up with the portable app.

A link is only ever removed when it's provably the one the launcher made, and whatever was at that location before the launch is put back.

## Enabling it

```ini
[Activate]
Symlinks=true
```

Recompile the launcher after adding the key. Users can turn the segment off with `Symlinks=false` in their `<AppID>.ini` user configuration file.

## Links

```ini
[Symlink1]
Type=junction
Source=Settings
Target=%APPDATA%\Vendor\App

[Symlink2]
Type=hard
Source=settings\license.dat
Target=%LOCALAPPDATA%\Vendor\license.dat
```

| Key | Description |
| --- | --- |
| `Type` | The kind of link (below). |
| `Source` | File or folder inside the `Data` folder that the link points to. Missing folders are created; files must already exist. |
| `Target` | Where the link is created. |

### Link types

| `Type` | Links | Admin rights | Notes |
| --- | --- | --- | --- |
| `junction` | Folders | No | The usual choice for folders. Works across volumes on the same PC. |
| `soft` | Folders | No | A directory symbolic link. When Windows refuses an unprivileged symbolic link, a junction is made instead. |
| `symbolic` | Files | Yes, or Developer Mode | A file symbolic link. |
| `hard` | Files | No | A file hard link. Source and target must be on the same volume. |

## What happens to what was there

If something already exists at `Target` (a real folder from an installed copy of the app, for example), it's renamed to `<Target>.BackupBy<AppID>` before the link is made. The rename stays on the same volume, so nothing is copied, however large it is.

When the app closes, the link is removed and the original is renamed back.

## How it's undone

| Change | Journal entry | On exit |
| --- | --- | --- |
| A link, plus the original it moved aside | `LINK` | The link is removed if it's provably the launcher's (a reparse point, or a hard link to `Source`), then the original is renamed back |
| A parent folder created for the link | `DIR` | Removed only if still empty |

Rollback never deletes through a link: removing a junction removes the junction, never the data in `Data`.

## Notes

- A hard link and its source are the same file. Changes made through either name show in both, which is the point.
- If something else replaces the link while the app runs, the launcher can no longer prove it's its own, so it leaves the new item alone. The original stays at `<Target>.BackupBy<AppID>`, the entry stays in the journal, and the user is told a change couldn't be undone. Moving the new item away lets the next launch finish the job.
- The segment runs only for the first launch of an app.
