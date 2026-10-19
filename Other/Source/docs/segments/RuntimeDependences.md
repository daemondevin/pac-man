# Runtime dependencies

The Runtime segment checks for the Visual C++ and .NET runtimes an app needs before the launcher changes anything. A missing runtime can be supplied the portable way, from a copy shipped with the app, for that app's process only.

Nothing this segment does needs undoing, so it doesn't use the journal. The one exception is installing a runtime system-wide, which only ever happens after the user agrees to a prompt saying it's permanent (see [below](#why-installs-are-never-undone)).

## Enabling it

```ini
[Activate]
Runtime=true
```

Recompile the launcher after adding the key.

## What happens for each runtime

1. **Installed?** If the runtime is installed system-wide, and new enough, nothing else happens.
2. **Portable copy?** If the section has `Local=` and that folder holds the runtime, the app uses it (see below). Nothing is installed.
3. **Installer?** If the section has `Installer=`, the user is asked whether to install the runtime, and told it will stay installed after the app closes. If they agree, the installer runs and the runtime is checked again.
4. **Still missing.** With `Required=true` the app doesn't start, and the user is told why. Otherwise they get a warning and the app starts anyway.

The checks run once, in the first launch of an app, before any segment changes anything. A second launch while the app is open doesn't repeat them.

## Visual C++

```ini
[VCRuntime1]
Version=2015-2022
Architecture=x64
MinVersion=14.28.29913
Local=%PAL:AppDir%\Runtimes\vc14_x64
Installer=vc_redist.x64.exe
Required=true
```

| Key | Default | Description |
| --- | --- | --- |
| `Version` | (required) | `2015-2022` (also written `2015`, `2017`, `2019`, `2022` or `14`), `2013`, `2012`, `2010`, `2008` or `2005`. |
| `Architecture` | `x86` | `x86`, `x64` or `arm64`. `arm64` is only valid for 2015-2022. |
| `MinVersion` | | Lowest acceptable 14.x version. 2015-2022 only. |

A portable Visual C++ copy is a folder of the runtime's DLLs. It's put at the front of `PATH` for the app's process.

## .NET

```ini
[NETRuntime1]
Framework=net8.0
Kind=desktop
Architecture=x64
MinVersion=8.0.5
Local=%PAL:AppDir%\dotnet
Required=true
```

| Key | Default | Description |
| --- | --- | --- |
| `Framework` | (required) | .NET Framework: `net20`, `net35`, `net40`, `net45`, `net451`, `net452`, `net46`, `net461`, `net462`, `net47`, `net471`, `net472`, `net48` or `net481` (dots are allowed: `net4.8`). .NET 5 and later: `net5.0`, `net6.0`, `net8.0` and so on (`net8` works too). |
| `Kind` | `core` | .NET 5 and later only: `core` (Microsoft.NETCore.App), `desktop` (Microsoft.WindowsDesktop.App) or `aspnet` (Microsoft.AspNetCore.App). |
| `Architecture` | `x86` | `x86` or `x64`. Ignored for .NET Framework. |
| `MinVersion` | | .NET 5 and later only, e.g. `8.0.5`. |

A portable .NET copy is a `dotnet` folder with a `shared\...` tree, as produced by an xcopy deployment. It's made visible to the app through `DOTNET_ROOT` (and the architecture-specific `DOTNET_ROOT_X86` / `DOTNET_ROOT_X64` variables), for the app's process only. .NET Framework can't be used portably, so `Local` doesn't apply to it.

## Keys for both

| Key | Default | Description |
| --- | --- | --- |
| `Local` | | Folder with a portable copy of the runtime. Only used when the runtime isn't installed. |
| `Installer` | | Redistributable to offer when the runtime is missing and `Local` can't provide it. A bare file name is looked for in `App\Prerequisites`. |
| `InstallerArgs` | see below | Switches for the installer. |
| `Required` | `false` | `true`: the app doesn't start while the runtime is missing. `false`: a warning, then the app starts. |

Default installer switches:

| Runtime | Switches |
| --- | --- |
| Visual C++ 2005, 2008 | `/q` |
| Visual C++ 2010, .NET Framework | `/passive /norestart` |
| Everything else | `/install /passive /norestart` |

## Why installs are never undone

A shared runtime can't safely be removed again: other programs may have started using it while the app ran. So the launcher never installs one silently, and never removes one. The prompt tells the user the runtime will stay, and declining is always possible.

## Older configurations

The keys from the previous version still work:

| Old key | Now means |
| --- | --- |
| `Action=skip` | The section is ignored. |
| `Action=install` or `Action=bundle` | Same as giving `Installer=`. |
| `Mode` | Ignored. |
