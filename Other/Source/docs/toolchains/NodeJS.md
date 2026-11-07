# Node.js toolchain

Puts a portable Node.js (with npm) in front of the app's `PATH`, and keeps npm's global packages, cache and settings, and Corepack's package managers, in the package.

```INI
[Activate]
Toolchains=NodeJS
```

`Node` works as well as `NodeJS` in the list. The settings section is always `[NodeJS]`.

## Getting Node.js

1. Download the Windows **zip** (`node-v<version>-win-x64.zip`) from [nodejs.org](https://nodejs.org/en/download), not the installer.
2. Unpack it into `CommonFiles\NodeJS` next to your packages (for example `X:\PortableApps\CommonFiles\NodeJS`), so that `CommonFiles\NodeJS\node.exe` exists. The zip holds a folder named like `node-v22.11.0-win-x64`; its contents are what go in `NodeJS`.

npm, npx and Corepack come with it. A Node.js kept somewhere else works too: point `Path` at the folder with `node.exe`.

## Settings

In a `[NodeJS]` section, in the user's `<AppID>.ini` or the launcher INI.

| Key | Default | What it does |
| --- | --- | --- |
| `Enabled` | `true` | `false` turns the toolchain off. |
| `Path` | `%PAL:CommonFiles%\NodeJS` | The folder with `node.exe`. |
| `Redirect` | `true` | `true` keeps npm's prefix, cache and settings, Corepack and the REPL history in `Data\Toolchains\NodeJS`. `false` leaves them in `%APPDATA%\npm`, `%LOCALAPPDATA%\npm-cache`, `%USERPROFILE%\.npmrc` and so on. |
| `ClearCache` | `false` | `true` empties npm's cache when the app closes. |

## What it changes for the app

| | Value | When |
| --- | --- | --- |
| `PATH` | npm's prefix, then `<Path>`, in front | Always (the prefix with `Redirect=true`) |
| `npm_config_prefix` | `Data\Toolchains\NodeJS\npm` | `Redirect=true` |
| `npm_config_cache` | `Data\Toolchains\NodeJS\npm-cache` | `Redirect=true` |
| `npm_config_userconfig` | `Data\Toolchains\NodeJS\.npmrc` | `Redirect=true` |
| `COREPACK_HOME` | `Data\Toolchains\NodeJS\corepack` | `Redirect=true` |
| `NODE_REPL_HISTORY` | `Data\Toolchains\NodeJS\.node_repl_history` | `Redirect=true` |

npm reads `npm_config_*` variables like its own settings, so nothing is written to `%USERPROFILE%\.npmrc`. `npm config set` writes to the package's `.npmrc` instead.

The prefix comes before Node.js itself on `PATH`. A newer npm installed with `npm install -g npm` therefore takes over from the one that came with Node.js, for this package only.

## Where packages go

| Command | Installs into |
| --- | --- |
| `npm install -g <package>` | `Data\Toolchains\NodeJS\npm` (with `Redirect=true`), with its commands on `PATH` |
| `npm install <package>` | The project's own `node_modules`, as usual |
| `corepack enable`, then `pnpm` or `yarn` | `Data\Toolchains\NodeJS\corepack` |

`corepack enable` writes its `pnpm` and `yarn` shims next to `node.exe`, in the shared Node.js folder, so every package using that Node.js gets them.

## Data

| In `Data\Toolchains\NodeJS` | Contents |
| --- | --- |
| `npm` | Global packages and their commands |
| `npm-cache` | npm's download cache (safe to delete) |
| `.npmrc` | npm settings (`npm config set`), such as registries and tokens |
| `corepack` | Package managers Corepack downloaded |
| `.node_repl_history` | History of the `node` REPL |

A package can ship a starting `.npmrc` in `App\DefaultData\Toolchains\NodeJS`. It's copied to `Data` the first time.

> [!NOTE]
> An `.npmrc` with an auth token travels with the package. Keep that in mind before sharing a copy of `Data`.

## What's journaled and undone

With `Redirect=true`, these are journaled when they aren't there yet, in case a tool ignores the variables:

| Could be written | When the app closes |
| --- | --- |
| `%APPDATA%\npm`, `%APPDATA%\npm-cache` | Removed, if they weren't there before |
| `%LOCALAPPDATA%\npm-cache` (npm's default cache) | Removed, if it wasn't there before |
| `%LOCALAPPDATA%\node` (Corepack's default home) | Removed, if it wasn't there before |

## Example

```INI
[Activate]
Toolchains=NodeJS

[NodeJS]
Path=%PAL:CommonFiles%\NodeJS22
ClearCache=true
```
