# Git toolchain

Puts a portable Git in front of the app's `PATH`, and keeps Git's global configuration in the package.

```INI
[Activate]
Toolchains=Git
```

## Getting Git

The toolchain needs **PortableGit**, the portable build of Git for Windows:

1. Download `PortableGit-<version>-64-bit.7z.exe` from [git-scm.com/download/win](https://git-scm.com/download/win), under "Portable".
2. Run it and extract it to `CommonFiles\Git` next to your packages (for example `X:\PortableApps\CommonFiles\Git`), so that `CommonFiles\Git\cmd\git.exe` exists.

A Git kept somewhere else works too: point `Path` at the folder that holds `cmd\git.exe`.

A freshly extracted PortableGit finishes its setup with `post-install.bat` the first time it runs. The launcher runs that script for you if it's still there; the script deletes itself when it's done.

## Settings

In a `[Git]` section, in the user's `<AppID>.ini` or the launcher INI.

| Key | Default | What it does |
| --- | --- | --- |
| `Enabled` | `true` | `false` turns the toolchain off. |
| `Path` | `%PAL:CommonFiles%\Git` | The folder with `cmd\git.exe`. |
| `Redirect` | `true` | `true` keeps Git's global configuration in `Data\Toolchains\Git\.gitconfig`. `false` leaves it in `%USERPROFILE%\.gitconfig`. |
| `Home` | `false` | `true` also moves `HOME` to `Data\Toolchains\Git\home` (needs `Redirect=true`). See [HOME](#home). |

## What it changes for the app

| | Value | When |
| --- | --- | --- |
| `PATH` | `<Path>\cmd` in front | Always |
| `GIT_CONFIG_GLOBAL` | `Data\Toolchains\Git\.gitconfig` | `Redirect=true` |
| `HOME` | `Data\Toolchains\Git\home` | `Redirect=true` and `Home=true` |

Only `cmd` goes on `PATH`. That's the folder Git for Windows itself recommends, with `git.exe`, `git-gui.exe` and `gitk.exe`. Git's Unix tools (`usr\bin`) stay off the `PATH`, so they never hide Windows commands such as `find` or `sort`. An app that wants Git Bash can be pointed at `<Path>\bin\bash.exe` or `<Path>\git-bash.exe`.

`GIT_CONFIG_GLOBAL` needs Git 2.32 or later.

## Data

| In `Data\Toolchains\Git` | Contents |
| --- | --- |
| `.gitconfig` | `git config --global` settings: your name and email, aliases, credential helper and so on |
| `home` | With `Home=true`: Git's `HOME` (see below) |

The configuration starts out empty, so set your name and email once:

```
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

A package can ship a starting configuration as `App\DefaultData\Toolchains\Git\.gitconfig`. It's copied to `Data` the first time.

### HOME

Git finds `.ssh` (SSH keys and `known_hosts`), `.bash_history`, `.git-credentials` and other dotfiles in `HOME`, which is `%USERPROFILE%` by default. `Home=true` moves `HOME` into the package so SSH keys and history travel with it.

It's off by default because `HOME` isn't only Git's: other programs the app starts read it too, and SSH keys on a removable drive may not be what you want. Turn it on when the package is yours and the keys should go with it.

## What's journaled and undone

| Could be written | When the app closes |
| --- | --- |
| `%USERPROFILE%\.git-credentials` (passwords in plain text, written by `credential.helper=store`) | Removed, if it wasn't there before |

This is journaled only with `Redirect=true` and `Home=false`. With `Home=true` the file is in the package instead.

Git Credential Manager, the default helper in Git for Windows, keeps credentials in the Windows Credential Manager rather than in files. Those stay on the computer; remove them under Control Panel > Credential Manager, or use `credential.helper=store` with `Home=true` to keep them in the package.

## Example

```INI
[Activate]
Toolchains=Git

[Git]
Path=%PAL:Drive%\Tools\PortableGit
Home=true
```
