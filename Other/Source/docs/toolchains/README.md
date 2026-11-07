# Toolchains

Toolchains put portable development tools in front of a package's app: Git, Python, Node.js, Rust and Go. An editor, IDE, terminal or build tool launched by PAC-MAN then finds them on its `PATH`. What those tools write is kept in the package instead of the user profile.

Each toolchain has its own page:

| Toolchain | Page | Looks for |
| --- | --- | --- |
| Git | [Git.md](Git.md) | `cmd\git.exe` (PortableGit) |
| Python | [Python.md](Python.md) | `python.exe` |
| Node.js | [NodeJS.md](NodeJS.md) | `node.exe` |
| Rust | [Rust.md](Rust.md) | `bin\rustc.exe`, or `cargo\bin\rustup.exe` |
| Go | [Go.md](Go.md) | `bin\go.exe` |

## Turning them on

List the toolchains in the package's launcher INI, separated by commas. Only the ones listed are compiled into the launcher.

```INI
[Activate]
Toolchains=Git,Python,NodeJS,Rust,Go
```

`Node` works as well as `NodeJS`. Names are not case-sensitive.

## How they behave

These rules apply to every toolchain.

- **The programs aren't part of the package.** A toolchain looks for its programs in `CommonFiles` next to the package (for example `X:\PortableApps\CommonFiles\Rust`), so every package that uses them shares one copy. `Path` can point anywhere else.
- **Missing programs mean nothing changes.** When the programs aren't found, the toolchain sets no variables and adds nothing to `PATH`. The app starts with whatever the computer has.
- **The app's environment only.** Variables and `PATH` are set for the app and the processes it starts. Windows' own settings, the user's environment and the computer's `PATH` are never changed.
- **One `PATH` change.** Toolchains add their folders in the order listed in the table above (Git first), in front of the existing `PATH`, so they win over installed copies. Custom.nsh can add its own with `${Toolchain::AddPath}`. The combined list is applied once, with no length limit.
- **Data in the package.** With `Redirect=true` (the default), each toolchain keeps what its tools write in `Data\Toolchains\<Name>`.
- **Starting files.** A package can ship starting files in `App\DefaultData\Toolchains\<Name>` (a `.gitconfig`, an `.npmrc`). They're copied to `Data\Toolchains\<Name>` the first time.
- **Journaled leftovers.** With `Redirect=true`, the folders a tool would create in the user profile are journaled when they aren't there yet. If a tool ignores the variables, those folders are removed when the app closes, or on the next launch after a crash. Folders that were already there are never touched.

## Settings

Each toolchain reads its own section, such as `[Rust]`, in this order:

1. The user's `<AppID>.ini`, next to the launcher.
2. The launcher INI (`App\AppInfo\Launcher\<AppID>.ini`). This is the package's default.
3. The toolchain's built-in default.

An empty value counts as missing. Environment variables work in every value, including the launcher's own, such as `%PAL:CommonFiles%`, `%PAL:PortableAppsDir%` and `%PAL:DataDir%`.

Every toolchain takes these keys:

| Key | Default | What it does |
| --- | --- | --- |
| `Enabled` | `true` | `false` turns the toolchain off. |
| `Path` | `%PAL:CommonFiles%\<Name>` | Where the programs are. |
| `Redirect` | `true` | `true` keeps what the tools write in `Data\Toolchains\<Name>`. `false` leaves them with their usual folders in the user profile. |
| `ClearCache` | `false` (`true` for Rust) | `true` empties the download or build cache when the app closes. Python, Node.js, Rust and Go have this key. |

Git also has `Home`; see [Git.md](Git.md).

For example, a package that sets defaults in its launcher INI:

```INI
[Activate]
Toolchains=Git,Python

[Python]
Path=%PAL:PortableAppsDir%\PythonPortable\App\Python
```

and a user who overrides one of them in their `<AppID>.ini`:

```INI
[Git]
Home=true
```

## Writing a new toolchain

How toolchains are built, and how to add one, is in the framework README, under "Writing a toolchain".
