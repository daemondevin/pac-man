# Python toolchain

Puts a portable Python in front of the app's `PATH`, and keeps the packages you install with `pip install --user`, and pip's cache, in the package.

```INI
[Activate]
Toolchains=Python
```

## Getting Python

The toolchain needs a folder with `python.exe` in it, in `CommonFiles\Python` next to your packages (for example `X:\PortableApps\CommonFiles\Python`), or wherever `Path` says.

The simplest portable Python is a copy of a normal installation:

1. Install Python from [python.org](https://www.python.org/downloads/windows/) for the current user.
2. Copy its folder (`%LOCALAPPDATA%\Programs\Python\Python3XX`) to `CommonFiles\Python`.
3. Uninstall the installed copy if you don't need it.

A copied Python runs from anywhere. The small launchers in its `Scripts` folder (`pip.exe` and those that packages add) remember the path of the `python.exe` they were installed with, though, so they stop working when the drive letter changes. Use `python -m pip` instead of `pip`, and `python -m <tool>` for other tools that support it.

The **embeddable package** from python.org also works, with limits. It's built to be isolated: it ignores Python's environment variables and the user site, so `Redirect` has no effect on it. It also comes without pip. Use it when the app only needs to run Python, not install packages.

## Settings

In a `[Python]` section, in the user's `<AppID>.ini` or the launcher INI.

| Key | Default | What it does |
| --- | --- | --- |
| `Enabled` | `true` | `false` turns the toolchain off. |
| `Path` | `%PAL:CommonFiles%\Python` | The folder with `python.exe`. |
| `Redirect` | `true` | `true` keeps the user site and pip's cache in `Data\Toolchains\Python`. `false` leaves them in `%APPDATA%\Python` and `%LOCALAPPDATA%\pip`. |
| `ClearCache` | `false` | `true` empties pip's cache when the app closes. |

## What it changes for the app

| | Value | When |
| --- | --- | --- |
| `PATH` | The user `Scripts` folder, then `<Path>` and `<Path>\Scripts`, in front | Always (the user `Scripts` folder with `Redirect=true`) |
| `PYTHONUSERBASE` | `Data\Toolchains\Python` | `Redirect=true` |
| `PIP_CACHE_DIR` | `Data\Toolchains\Python\pip-cache` | `Redirect=true` |
| `PYTHONHOME` | Cleared | Always |

The user `Scripts` folder is where commands from `pip install --user` go: `Data\Toolchains\Python\Python3XX\Scripts`, or `Python3XX-32\Scripts` for a 32-bit Python. The launcher asks Python which (`python -m site --user-site`), so it's always the right one for the Python found.

`PYTHONHOME` is cleared because one left on the computer by another Python would point this one at the wrong standard library. `PYTHONPATH` is left as it is.

## Where packages go

| Command | Installs into |
| --- | --- |
| `python -m pip install --user <package>` | `Data\Toolchains\Python` (with `Redirect=true`): this package only |
| `python -m pip install <package>` | `<Path>\Lib\site-packages`: the shared Python, for every package that uses it |

Use `--user` for what one app needs, and a plain install for what every app using this Python should have. A virtual environment (`python -m venv`) works as usual and goes wherever you create it.

## Data

| In `Data\Toolchains\Python` | Contents |
| --- | --- |
| `Python3XX\site-packages` | Packages installed with `--user` |
| `Python3XX\Scripts` | Their commands |
| `pip-cache` | Downloaded packages and wheels (safe to delete) |

A package can ship starting files (a `pip.ini`, for example) in `App\DefaultData\Toolchains\Python`. They're copied to `Data` the first time.

## What's journaled and undone

With `Redirect=true`, these are journaled when they aren't there yet, in case a tool ignores the variables:

| Could be written | When the app closes |
| --- | --- |
| `%APPDATA%\Python` (the default user site) | Removed, if it wasn't there before |
| `%LOCALAPPDATA%\pip` (pip's default cache) | Removed, if it wasn't there before |

## Example

```INI
[Activate]
Toolchains=Python

[Python]
Path=%PAL:CommonFiles%\Python312
ClearCache=true
```
