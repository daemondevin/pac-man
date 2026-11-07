# Rust toolchain

Puts a portable Rust in front of the app's `PATH`, and keeps Cargo's home (tools you install, the crate registry, settings) in the package.

```INI
[Activate]
Toolchains=Rust
```

## Getting Rust

The toolchain accepts two layouts in `CommonFiles\Rust` next to your packages (for example `X:\PortableApps\CommonFiles\Rust`), or wherever `Path` says. It checks for the standalone layout first.

### A standalone Rust

One fixed version, no rustup:

1. Download a standalone installer (`.msi`) from [Other ways to install Rust](https://forge.rust-lang.org/infra/other-installation-methods.html#standalone-installers).
2. Unpack it without installing: `msiexec /a rust-<version>-x86_64-pc-windows-gnu.msi /qb TARGETDIR=C:\Temp\rust`.
3. Copy the folder that holds `bin\rustc.exe` to `CommonFiles\Rust`, so that `CommonFiles\Rust\bin\rustc.exe` exists.

### A rustup install

Several toolchains, updates with `rustup update`, and targets and components on demand. Install rustup into the folder instead of the user profile, from a command prompt:

```
set CARGO_HOME=X:\PortableApps\CommonFiles\Rust\cargo
set RUSTUP_HOME=X:\PortableApps\CommonFiles\Rust\rustup
rustup-init.exe -y --no-modify-path --default-host x86_64-pc-windows-gnu
```

That gives `CommonFiles\Rust\cargo\bin\rustup.exe` and the toolchains in `CommonFiles\Rust\rustup`. Every package that uses this Rust shares those toolchains.

### MSVC or GNU

Rust needs a linker:

- **`x86_64-pc-windows-msvc`** (rustup's default) uses Microsoft's linker from Visual Studio or the C++ Build Tools. Those must be installed on each computer, so a package using this target isn't fully portable.
- **`x86_64-pc-windows-gnu`** brings its own linker. It's the one to use for a toolchain that has to work anywhere.

## Settings

In a `[Rust]` section, in the user's `<AppID>.ini` or the launcher INI.

| Key | Default | What it does |
| --- | --- | --- |
| `Enabled` | `true` | `false` turns the toolchain off. |
| `Path` | `%PAL:CommonFiles%\Rust` | The folder with `bin\rustc.exe` (standalone) or `cargo\bin\rustup.exe` (rustup). |
| `Redirect` | `true` | `true` keeps Cargo's home in `Data\Toolchains\Rust\.cargo`. `false` leaves it in `%USERPROFILE%\.cargo`, or in `<Path>\cargo` for a rustup install. |
| `ClearCache` | `true` | `true` deletes the downloaded crates (`registry\cache` and `registry\src`) when the app closes. |

`ClearCache` is on by default here, unlike the other toolchains, because the crate registry grows quickly and is the bulk of Cargo's home. Cargo downloads what a project needs again on the next build. Turn it off to build offline, or to save the downloads on a slow connection.

## What it changes for the app

| | Value | When |
| --- | --- | --- |
| `PATH` | `Data\Toolchains\Rust\.cargo\bin`, then `<Path>\bin` (standalone) or `<Path>\cargo\bin` (rustup), in front | Always (Cargo's `bin` with `Redirect=true`) |
| `CARGO_HOME` | `Data\Toolchains\Rust\.cargo` | `Redirect=true` |
| `CARGO_HOME` | `<Path>\cargo` | rustup, with `Redirect=false` |
| `RUSTUP_HOME` | `<Path>\rustup` | rustup |

Cargo's `bin` comes first on `PATH`, so tools installed with `cargo install` are found before the toolchain's own.

With a rustup install and `Redirect=true`, the toolchains stay shared in `<Path>\rustup`, and each package has its own Cargo home. When rustup installs a new toolchain it puts its proxies (`cargo.exe`, `rustc.exe`) in that package's Cargo `bin`, which is on `PATH`.

## Data

| In `Data\Toolchains\Rust\.cargo` | Contents |
| --- | --- |
| `bin` | Tools installed with `cargo install` |
| `registry`, `git` | Downloaded crates and git dependencies (`registry\cache` and `registry\src` are cleared with `ClearCache=true`; the index stays) |
| `config.toml` | Cargo settings |
| `credentials.toml` | Tokens from `cargo login` |

A package can ship a starting `config.toml` as `App\DefaultData\Toolchains\Rust\.cargo\config.toml`. It's copied to `Data` the first time.

## What's journaled and undone

With `Redirect=true`, these are journaled when they aren't there yet, in case a tool ignores the variables:

| Could be written | When the app closes |
| --- | --- |
| `%USERPROFILE%\.cargo` | Removed, if it wasn't there before |
| `%USERPROFILE%\.rustup` | Removed, if it wasn't there before |

## Example

```INI
[Activate]
Toolchains=Rust

[Rust]
Path=%PAL:CommonFiles%\RustGNU
ClearCache=false
```
