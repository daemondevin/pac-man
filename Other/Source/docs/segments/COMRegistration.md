# COM registration

The RegDLL segment registers COM servers (`.dll`, `.ocx`, `.exe`) and type libraries an app needs while it runs, and unregisters them when it closes, or on the next launch after a crash.

32-bit DLLs are registered for the current user by default, so most apps need no administrator rights at all.

## Enabling it

```ini
[Activate]
RegDLLs=true
```

Recompile the launcher after adding the key.

## Registrations

```ini
[RegisterDLL1]
Type=REGDLL
File=%PAL:AppDir%\MyProg\MyProg.dll
CLSID={00000000-0000-0000-0000-000000000000}

[RegisterDLL2]
Type=REGTLB
File=%PAL:AppDir%\MyProg\MyProg.tlb
```

| Key | Default | Description |
| --- | --- | --- |
| `Type` | (required) | What to register (below). |
| `File` | (required) | Path to the file. |
| `Scope` | `user` for 32-bit DLLs | `user` or `machine` (below). |
| `CLSID` | | The class the server registers. Optional, but recommended. |
| `ProgID` | | Used to find the CLSID when `CLSID` isn't given. |

### Types

| `Type` | Registers |
| --- | --- |
| `REGDLL` | A COM DLL or OCX, through `DllRegisterServer` |
| `REGDLLTLB` | A DLL and the type library inside it |
| `REGTLB` | A type library: a `.tlb` file, or one embedded in a DLL or EXE |
| `REGUSERTLB` | A type library for the current user only (`REGTLB for user` is accepted too) |
| `REGEXE` | An out-of-process COM server, through `/regserver` |

### Scopes

| `Scope` | How | Admin rights |
| --- | --- | --- |
| `user` | The launcher calls `DllRegisterServer` itself, with HKCR and HKLM redirected to the current user's registry, so the registration lands in HKCU. | No |
| `machine` | `regsvr32` registers it system-wide, using the 32-bit or 64-bit `regsvr32` to match the DLL. | Yes |

64-bit DLLs and `REGEXE` servers are always registered with machine scope, because a 32-bit launcher can't load them to redirect their registration.

## Protecting existing registrations

If an installed program has already registered the same class, registering the portable copy would normally overwrite it. Giving `CLSID` (or `ProgID`) prevents that:

- The existing CLSID and ProgID keys are backed up before registering, and put back after unregistering.
- On rollback, the launcher can tell when the class is no longer registered and there's nothing left to undo.

Type libraries that are already registered, by anything, are left alone and not registered again, so an installed copy is never overwritten.

## How it's undone

| Registration | Journal entry | On exit |
| --- | --- | --- |
| COM server | `COMDLL` | `DllUnregisterServer` in-process (user scope), `regsvr32 /u` (machine scope) or `/unregserver` (EXE servers); then any backed-up CLSID and ProgID keys are re-imported |
| Type library | `TYPELIB` | Unregistered (per user or per machine, as it was registered) if it's still registered |

Machine-scope registrations need administrator rights to undo. If a later launch isn't elevated, the entries stay in the journal until one is.

## Notes

- The segment runs only for the first launch of an app.
