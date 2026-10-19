# File associations, protocols and context menus

The Associations segment registers file types, URL protocols and context menu entries for as long as the app runs. Everything is written under `HKCU\Software\Classes`, so it needs no administrator rights and affects only the current user.

The segment never touches the user's choice of default app (the `UserChoice` keys Windows keeps). By default, a file type that already has a handler only gains an **Open with** entry for the app.

## Enabling it

```ini
[Activate]
FileAssociations=true
```

Recompile the launcher after adding the key. Users can turn the whole segment off with `FileAssociations=false` in their `<AppID>.ini` user configuration file; this one key covers file types, protocols and context menus.

## File types

```ini
[FileAssociation1]
Extension=.myfile,.myother
ProgID=MyApp.Document
Description=My App Document
DefaultIcon=%PAL:AppDir%\MyApp\myapp.exe,0
OpenCommand="%PAL:AppDir%\MyApp\myapp.exe" "%1"
EditCommand="%PAL:AppDir%\MyApp\myapp.exe" /edit "%1"
IfExists=skip
```

| Key | Required | Description |
| --- | --- | --- |
| `Extension` | Yes | One extension or a comma-separated list. The leading dot is optional. |
| `ProgID` | No | Program identifier shared by every extension in the section. Defaults to `<AppID>.<first extension>`. |
| `Description` | No | The type name Explorer shows. |
| `DefaultIcon` | No | Icon as `path,index`. |
| `OpenCommand` | Yes | Command for the open verb. `%1` is the file. |
| `EditCommand` | No | Command for the edit verb. |
| `IfExists` | No | `skip` (default) or `replace` (`backup` is accepted as another name for it). See below. |

What `IfExists` does:

| Situation | `skip` | `replace` |
| --- | --- | --- |
| The extension has no handler | The app becomes its handler for the session | Same |
| The extension already has a handler | The ProgID is only added to the extension's `OpenWithProgids` list, so the app shows under **Open with** | The extension's default is set to this ProgID; the previous one comes back on exit |
| The ProgID already exists for this user | The whole section is skipped | The ProgID is backed up, replaced, and restored on exit |

Windows 10 and 11 still let the user's own default-app choice win over `replace`. `replace` makes the app the default only where the user hasn't picked one.

## URL protocols

```ini
[ProtocolHandler1]
Protocol=myapp
Description=My App Link
DefaultIcon=%PAL:AppDir%\MyApp\myapp.exe,0
OpenCommand="%PAL:AppDir%\MyApp\myapp.exe" "%1"
IfExists=skip
```

| Key | Required | Description |
| --- | --- | --- |
| `Protocol` | Yes | The URL scheme, without `://`. |
| `Description` | No | Name shown for the protocol. |
| `DefaultIcon` | No | Icon as `path,index`. |
| `OpenCommand` | Yes | Command that handles the URL. `%1` is the full URL. |
| `IfExists` | No | `skip` (default) leaves a scheme already registered anywhere (current user or machine) alone. `replace` overrides it for the current user and puts the original back on exit. |

## Context menu entries

```ini
[ContextMenu1]
Target=.txt
MenuKey=MyAppOpen
MenuText=Open with My App
MenuCommand="%PAL:AppDir%\MyApp\myapp.exe" "%1"
MenuIcon=%PAL:AppDir%\MyApp\myapp.exe,0
Position=Top
Extended=false
IfExists=skip
```

| Key | Required | Description |
| --- | --- | --- |
| `Target` | Yes | Where the entry appears (table below). `Extension` is accepted as an older name for this key. |
| `MenuKey` | No | Registry name of the verb. Defaults to `<AppID>.<N>`. Use a name of your own so the entry never collides with an installed copy of the same app. |
| `MenuText` | Yes | Text shown in the menu. |
| `MenuCommand` | Yes | Command to run. `%1` is the file or folder; use `%V` for `Directory\Background`. |
| `MenuIcon` | No | Icon as `path,index`. |
| `Position` | No | `Top` or `Bottom`. Omit for Windows' default position. |
| `Extended` | No | `true` shows the entry only when Shift is held. |
| `IfExists` | No | `skip` (default) leaves an entry that already exists with the same `MenuKey` on that target, for this user or machine-wide, alone; `replace` overrides it for this user until exit. |

| `Target` | The entry appears on |
| --- | --- |
| `.ext` | Files with that extension, whatever program handles them (written under `SystemFileAssociations`) |
| `*` | Every file |
| `Directory` | Folders |
| `Directory\Background` | The empty space inside an open folder |
| `Drive` | Drives |
| `Folder` | Folders and other shell folders (libraries, for example) |
| `AllFilesystemObjects` | Files and folders |
| A ProgID | Files of that program type |

## Pointing commands at the launcher

A command that runs the app's executable directly starts a copy that doesn't get the launcher's settings, such as portable data paths. When the app is already open, that can mean a second, non-portable instance.

Point commands at the launcher instead. pac-man doesn't set a variable for the launcher's path, so set one in `Custom.nsh`:

```nsis
!macro Variables
	System::Call `kernel32::SetEnvironmentVariable(t "PAL:LauncherPath", t "$EXEPATH")`
!macroend
```

```ini
OpenCommand="%PAL:LauncherPath%" "%1"
```

For a second launch to reach the running app, `SinglePortableAppInstance` under `[Launch]` must be `false` (with `true`, a second launch quits silently). The second launch then passes the file to the app, which opens it in its running window if it supports that.

## How it's undone

| Change | Journal entry | On exit |
| --- | --- | --- |
| A key that didn't exist | `REGKEY` | Deleted |
| A parent key created on the way to it | `REGEMPTY` | Deleted if still empty |
| A key that was replaced (`IfExists=replace`) | `REGKEY` with an exported backup | Deleted, then the backup is re-imported |
| A value written into a key that already existed | `REGVALUE` with the previous value | The previous value is put back, or the value is deleted |

Explorer is told the associations changed after the segment applies and after it rolls back, so menus and icons update without signing out.

## Notes

- Give each `[FileAssociationN]` section its own `ProgID`. A second section naming a ProgID the first one just created finds it already there, and with `IfExists=skip` the whole section is skipped. To give several extensions one ProgID, list them in one section's `Extension` key.
- The segment runs only for the first launch of an app.
