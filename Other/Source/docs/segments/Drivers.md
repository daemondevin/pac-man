# Driver packages

The Drivers segment adds driver packages to the Windows driver store for as long as the app runs, and removes them when it closes or on the next launch after a crash. Devices that were using a removed driver fall back to the driver they had before.

It uses `pnputil /add-driver` and `/delete-driver`, which need Windows 10 version 1607 or later.

## Enabling it

```ini
[Activate]
Drivers=true
```

Recompile the launcher after adding the key.

The segment needs administrator rights. Without them it adds nothing and shows one warning. See [README.md](README.md#administrator-rights) for `RunAsAdmin`.

## Packages

```ini
[Driver1]
InfFile=%PAL:AppDir%\Drivers\x64\mydevice.inf
Architecture=x64
Install=true
Required=true
```

| Key | Default | Description |
| --- | --- | --- |
| `InfFile` | (required) | The driver package's INF file. The rest of the package (`.sys`, `.cat` and so on) must sit next to it, as pnputil expects. |
| `Architecture` | `any` | `x86`, `x64` or `any`. A section for the other bitness is skipped, so a package can be listed once per architecture. |
| `Install` | `true` | `true` also installs the driver on matching devices that are present (`pnputil /install`). `false` only adds it to the driver store. |
| `Required` | `false` | `true` shows a warning when the package can't be added. |

The package must be signed the way Windows requires. pnputil refuses an unsigned or wrongly signed package, and the launcher reports that as a failure.

A typical layout, with one section per architecture:

```ini
[Driver1]
InfFile=%PAL:AppDir%\Drivers\x86\mydevice.inf
Architecture=x86

[Driver2]
InfFile=%PAL:AppDir%\Drivers\x64\mydevice.inf
Architecture=x64
```

## Packages that are already there

A package whose INF content matches one already in the driver store before the launch belongs to someone else, such as an installed copy of the app. It is left alone and never removed.

## How it's undone

Before pnputil runs, the launcher journals a `DRIVER` entry holding a copy of the INF. To undo it, the launcher looks through `%WINDIR%\INF` for the `oemNN.inf` with the same content and removes that package with `pnputil /delete-driver /uninstall /force`.

The published `oemNN.inf` name is never read from pnputil's output, which is translated on non-English Windows. Matching by content works in every language.

Removing a driver needs administrator rights. If a later launch isn't elevated, the entry stays in the journal until one is.

## Notes

- A 32-bit launcher on 64-bit Windows uses the 64-bit pnputil, since there's no 32-bit one.
- The segment runs only for the first launch of an app.
