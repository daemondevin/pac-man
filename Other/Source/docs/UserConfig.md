# User Configuration File

Every portable app built with pac-man supports a user-editable configuration file located
in the *root of the package directory*, right beside the launcher executable. By convention
it is named after the app itself:

```
AppNamePortable\
├── App\
├── Data\
├── AppNamePortable.exe     ← Launcher
└── AppNamePortable.ini     ← This file
```

The file uses standard Windows INI format. All user configuration settings live in a single section
named after the application:

```ini
[AppNamePortable]
Key=Value
```

These keys are available in **every** portable app made with pac-man by default. They require
no extra setup from the developer as the launcher reads them automatically at runtime via the
built-in segment system.

> [!NOTE]
> **Developers:**  
> The keys documented here are those built into pac-man's framework. If you're creating a
> portable app using pac-man and you plan on adding configuration settings via `custom.nsh`,
> any keys you introduce should be documented so the user can be aware of said functionality
> because those settings are specific to your portable app and cannot be covered here for
> obvious reasons.

---

## Keys

### `DisableSplashScreen`

**Segment:** `SplashScreen.nsh`  
**Type:** Boolean (`true` / `false`)  
**Default:** *disabled*

This feature is currently disabled at the moment. It might be reenabled in the near future.

```ini
[AppNamePortable]
DisableSplashScreen=false
```

---

### `AdditionalParameters`

**Segment:** `ExecString.nsh`  
**Type:** String  
**Default:** *(empty — no extra parameters)*

Appends additional command-line arguments to the launcher's exec string at runtime. This is
applied on top of any `CommandLineArguments` the developer has set in `Launcher.ini`, and
environment variable expansion is performed on the value before it is passed to the process.

```ini
[AppNamePortable]
AdditionalParameters=--verbose --no-sandbox
```

Useful for power users who want to pass flags to the underlying application without modifying
the launcher itself. Leave blank or omit the key entirely to pass no extra arguments.

---

### `RunLocally`

**Segment:** `RunLocally.nsh`  
**Type:** Boolean (`true` / `false`)  
**Default:** `false`

When set to `true`, the launcher copies the app's `App\` and `Data\` directories to a
temporary folder (`%TEMP%\AppNamePortableLive\`) before executing, then removes the copy
on exit. This is useful when running from a slow medium (USB drives, network shares) where
the disk I/O would otherwise cause poor performance or timeouts.

```ini
[AppNamePortable]
RunLocally=true
```

> **Note:** Enabling this increases startup time proportional to the size of the app. On
> large apps or fast drives it may actually be slower than running directly.

---

### `FileAssociations`

**Segment:** `Associations.nsh`  
**Type:** Boolean (`true` / `false`)  
**Default:** `true`

Controls whether the launcher registers the file type associations defined in
`[FileAssociation1]`, `[FileAssociation2]`, etc. in `Launcher.ini`. When set to `false`,
no file type associations are created or restored for the duration of the session.

```ini
[AppNamePortable]
FileAssociations=false
```

Only has an effect if the developer has configured `[FileAssociation*]` sections in
`Launcher.ini`. Setting this to `false` lets the user opt out of file association
takeover without editing the launcher.

---

### `ProtocolHandlers`

**Segment:** `Associations.nsh`  
**Type:** Boolean (`true` / `false`)  
**Default:** `true`

Controls whether the launcher registers the URI/protocol handlers defined in
`[ProtocolHandler1]`, `[ProtocolHandler2]`, etc. in `Launcher.ini`. Set to `false` to
prevent the portable app from registering itself as a handler for any protocol during
the session.

```ini
[AppNamePortable]
ProtocolHandlers=false
```

Only has an effect if the developer has configured `[ProtocolHandler*]` sections in
`Launcher.ini`.

---

### `ShellIntegration`

**Segment:** `Associations.nsh`  
**Type:** Boolean (`true` / `false`)  
**Default:** `true`

Controls whether the launcher installs the context menu entries defined in
`[ContextMenu1]`, `[ContextMenu2]`, etc. in `Launcher.ini`. Set to `false` to prevent
the app from adding anything to the Windows right-click context menu.

```ini
[AppNamePortable]
ShellIntegration=false
```

Only has an effect if the developer has configured `[ContextMenu*]` sections in
`Launcher.ini`.

---

### `Symlinks`

**Segment:** `Symlinks.nsh`  
**Type:** Boolean (`true` / `false`)  
**Default:** `true`

Controls whether the launcher handles soft links, hard links, symbolic links, 
and/or junctions defined in `[Symlink1]`, `[Symlink2]`, etc. in `Launcher.ini`. 
Set to `false` to prevent the app from adding symbolic links.

```ini
[AppNamePortable]
Symlinks=false
```

Only has an effect if the developer has configured `[Symlink*]` sections in
`Launcher.ini`.

---

### `JavaPath`

**Segment:** `Java.nsh`  
**Type:** String
**Default:** *(empty — path to Java no set)*

If the portable app makes use of Java and the user doesn't have [**JavaPortable**](https://portableapps.com/apps/utilities/java_portable)
in `%PAC:CommonFiles%`, then the user may specify a path to Java here. Must
point to the directory with Java's `bin` folder inside so the launcher can
locate both `java.exe` and `javaw.exe`.

```ini
[AppNamePortable]
JavaPath=X:\utils\java
```

Only has an effect if the developer has configured `[Activate]:Java` with a
value of either `find` or `require` in the `Launcher.ini`.

---

### `PromptAdmin`

**Segment:** `RunAsAdmin.nsh`  
**Type:** Boolean (`true` / `false`)  
**Default:** `true` *(prompt is shown)*

Only relevant when the developer has set `[Launch]:RunAsAdmin=prompt` in `Launcher.ini`.
In that mode, the launcher asks the user at startup whether they want to run with
administrator privileges (since the app can benefit from elevation but does not require it).

Setting this key to `false` **permanently suppresses** that prompt — the app will always
launch without requesting elevation. Setting it to `true` or omitting the key entirely
preserves the default behaviour of showing the prompt each time.

```ini
[AppNamePortable]
PromptAdmin=false
```

This key has no effect when `RunAsAdmin` is set to `force` or `try`. It is only
consulted in `prompt` mode.

---

## Full Example

```ini
[AppNamePortable]

; Append extra flags every time the app launches
AdditionalParameters=--disable-gpu --log-level=1

; Run from a local temp copy for better performance on slow USB drives
RunLocally=false

; Suppress all shell integration for this session
FileAssociations=true
ProtocolHandlers=true
ShellIntegration=false

Deny the launcher from creating symbolic links for this session
Symlinks=false

; Set path to Java
JavaPath=X:\utils\java

; Don't ask about administrator privileges on startup
PromptAdmin=false
```

---

## Notes

> [!NOTE]  
> All keys are **optional**. Omitting a key is identical to leaving it at its documented
  default value.

> [!WARNING]  
> The section name `[AppNamePortable]` must match the app's actual name as compiled into
  the launcher. If the file has the wrong section name, all keys in it will be silently
  ignored.

> [!IMPORTANT]  
> This file is intended for end users. Developers should not rely on it for launcher
  behaviour that should always be on — use `Launcher.ini` for that.
