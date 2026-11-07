# Go toolchain

Puts a portable Go in front of the app's `PATH`, and keeps `GOPATH` (installed tools and the module cache), the build cache and `go env -w` settings in the package.

```INI
[Activate]
Toolchains=Go
```

## Getting Go

1. Download the Windows **zip** (`go<version>.windows-amd64.zip`) from [go.dev/dl](https://go.dev/dl/), not the installer.
2. Unpack it into `CommonFiles\Go` next to your packages (for example `X:\PortableApps\CommonFiles\Go`), so that `CommonFiles\Go\bin\go.exe` exists. The zip holds a folder named `go`; its contents are what go in `Go`.

A Go kept somewhere else works too: point `Path` at the folder with `bin\go.exe`.

## Settings

In a `[Go]` section, in the user's `<AppID>.ini` or the launcher INI.

| Key | Default | What it does |
| --- | --- | --- |
| `Enabled` | `true` | `false` turns the toolchain off. |
| `Path` | `%PAL:CommonFiles%\Go` | The folder with `bin\go.exe` (Go's root). |
| `Redirect` | `true` | `true` keeps `GOPATH`, the build cache and Go's settings in `Data\Toolchains\Go`. `false` leaves them in `%USERPROFILE%\go`, `%LOCALAPPDATA%\go-build` and `%APPDATA%\go`. |
| `ClearCache` | `false` | `true` empties the build cache when the app closes. |

## What it changes for the app

| | Value | When |
| --- | --- | --- |
| `PATH` | `Data\Toolchains\Go\go\bin`, then `<Path>\bin`, in front | Always (`GOPATH\bin` with `Redirect=true`) |
| `GOROOT` | `<Path>` | Always |
| `GOPATH` | `Data\Toolchains\Go\go` | `Redirect=true` |
| `GOCACHE` | `Data\Toolchains\Go\cache` | `Redirect=true` |
| `GOENV` | `Data\Toolchains\Go\env` | `Redirect=true` |
| `GOMODCACHE` | Cleared, so it follows `GOPATH` (`go\pkg\mod`) | `Redirect=true` |

`GOROOT` is set even though Go can find its own root, because a `GOROOT` left on the computer by another Go would point this one at the wrong standard library.

`GOPATH\bin` comes first on `PATH`, so tools installed with `go install` are found.

## Data

| In `Data\Toolchains\Go` | Contents |
| --- | --- |
| `go\bin` | Tools installed with `go install` |
| `go\pkg\mod` | The module cache: downloaded modules, and newer Go versions fetched for `GOTOOLCHAIN` |
| `cache` | The build cache (safe to delete; cleared with `ClearCache=true`) |
| `env` | Settings from `go env -w`, such as `GOPROXY` or `GOPRIVATE` |

Go makes the module cache read-only. To empty it, run `go clean -modcache` rather than deleting the folder.

A package can ship starting settings as `App\DefaultData\Toolchains\Go\env`. It's copied to `Data` the first time.

## What's journaled and undone

With `Redirect=true`, these are journaled when they aren't there yet, in case a tool ignores the variables:

| Could be written | When the app closes |
| --- | --- |
| `%USERPROFILE%\go` (the default `GOPATH`) | Removed, if it wasn't there before |
| `%LOCALAPPDATA%\go-build` (the default build cache) | Removed, if it wasn't there before |
| `%APPDATA%\go` (the default settings, and Go's telemetry data, which always goes here) | Removed, if it wasn't there before |

## Example

```INI
[Activate]
Toolchains=Go

[Go]
Path=%PAL:CommonFiles%\Go123
ClearCache=true
```
