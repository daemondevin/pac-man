# Runtime Dependencies in Portable Apps

Portable Apps are designed to run without requiring a traditional installation. However, many 
Windows applications still depend on **shared runtime libraries** that are not bundled with Windows itself.

The two most common runtime dependencies are:

- **Microsoft Visual C++ Redistributables (VC Runtime)**
- **Microsoft .NET Runtime / .NET Framework**

Understanding these dependencies is important when creating or packaging portable software.

---

# What Is a Runtime?

A **runtime** is a collection of libraries, APIs, and supporting files required by an application while 
it is executing.

Instead of including these libraries inside every executable, software developers often link against 
shared runtime libraries supplied by Microsoft.

Think of a runtime as the operating environment an application expects to exist.

Without the required runtime:

- the application may fail to start
- Windows may display a missing DLL error
- the program may immediately crash
- certain features may not function correctly

---

# Visual C++ Runtime (VC Runtime)

## What Is It?

Applications written in C or C++ using Microsoft Visual Studio frequently depend on the **Microsoft 
Visual C++ Runtime**.

These libraries provide functionality such as:

- memory allocation
- exception handling
- C/C++ standard library
- file handling
- threading
- localization
- floating-point support

Instead of embedding these libraries into every executable, developers often distribute them separately 
as the **Visual C++ Redistributable**.

---

## Common Runtime DLLs

Examples include:

```
msvcp140.dll
vcruntime140.dll
vcruntime140_1.dll
msvcr120.dll
msvcp120.dll
ucrtbase.dll
```

Each version of Visual Studio may require different runtime files.

---

## Static vs Dynamic Linking

Applications can be built in two ways.

### Static Linking

The runtime is compiled directly into the executable.

Advantages:

- No external VC runtime required
- Better portability

Disadvantages:

- Larger executable
- Every application carries its own copy

---

### Dynamic Linking

The executable loads shared runtime DLLs.

Advantages:

- Smaller executable
- Shared updates
- Reduced memory usage

Disadvantages:

- Runtime must be available
- Missing DLLs prevent startup

Most Windows software uses dynamic linking.

---

# Universal CRT (UCRT)

Modern versions of Windows include the **Universal C Runtime (UCRT)** as a system component.

Older Windows versions may require it separately.

Many modern Visual C++ applications depend on both:

- UCRT
- VC Runtime

---

# .NET Runtime

## What Is It?

Applications written using **C#**, **VB.NET**, or other .NET languages require the **.NET Runtime**.

Unlike native C++ applications, .NET applications execute inside Microsoft's managed runtime called the 
**Common Language Runtime (CLR)**.

The CLR provides:

- garbage collection
- memory management
- JIT compilation
- security
- reflection
- exception handling
- threading

---

# .NET Framework vs Modern .NET

Microsoft currently has two major .NET families.

## .NET Framework

Older Windows technology.

Versions include:

- 2.0
- 3.5
- 4.0
- 4.5
- 4.8

Most versions are Windows-only.

Many enterprise applications still use .NET Framework 4.x.

---

## Modern .NET

Previously known as:

- .NET Core

Now simply:

- .NET 5
- .NET 6
- .NET 7
- .NET 8
- .NET 9

Modern .NET is:

- cross-platform
- actively developed
- significantly faster
- side-by-side installable

---

# Framework-Dependent vs Self-Contained

Modern .NET applications are commonly published in two forms.

## Framework-Dependent

Requires the appropriate .NET Runtime already installed.

Advantages:

- smaller download
- shared runtime updates

Disadvantages:

- runtime dependency

---

## Self-Contained

Includes the entire runtime.

Advantages:

- no external dependency
- easier portability

Disadvantages:

- much larger application size

Many portable apps prefer self-contained publishing.

---

# How Portable Apps Handle Runtime Dependencies

Portable software generally uses one of several approaches.

---

## Option 1 — Require the Runtime

The launcher checks whether the runtime exists.

If missing:

- display an error
- explain what is required
- optionally offer a download

Advantages:

- smallest package

Disadvantages:

- depends on host system

---

## Option 2 — Bundle the Runtime

The portable package includes:

```
App
├── MyProgram.exe
└── Runtime
    ├── vcruntime140.dll
    ├── msvcp140.dll
    └── ...
```

The launcher adjusts the DLL search path so Windows loads the bundled libraries instead of relying on 
system-wide installations.

Advantages:

- works on more systems
- no installation required

Disadvantages:

- larger portable package
- runtime updates require updating the bundled files

---

## Option 3 — Ship a Portable .NET Runtime

Modern .NET allows applications to load a runtime from a local directory.

Example:

```
App
├── MyProgram.exe
└── dotnet
    ├── host
    ├── shared
    └── ...
```

The launcher directs the application to use this local runtime.

Advantages:

- completely portable
- isolated from the host system
- consistent behavior across machines

---

## Option 4 — Self-Contained Build

The developer publishes the application as self-contained.

Example:

```
App
├── MyProgram.exe
├── hostfxr.dll
├── coreclr.dll
├── System.Private.CoreLib.dll
└── ...
```

No runtime installation is necessary because the runtime is included alongside the application.

---

# Portable Launchers

A portable launcher may perform runtime detection before starting the application.

Typical tasks include:

1. Detect installed VC Runtime.
2. Detect installed .NET Runtime.
3. Prefer bundled runtimes when available.
4. Configure environment variables or DLL search paths.
5. Launch the application.
6. Restore the environment after exit.

This allows the portable package to run reliably across different Windows systems.

---

# Private Assemblies

Windows allows applications to load DLLs located beside the executable.

For VC runtimes, this is known as using **private assemblies**.

Example:

```
App
├── MyProgram.exe
├── vcruntime140.dll
├── msvcp140.dll
└── concrt140.dll
```

Windows searches the application directory before many system locations, allowing the program to use its 
local copies without affecting other software.

---

# Why Not Always Bundle Everything?

Bundling every dependency is not always desirable.

Potential drawbacks include:

- larger download sizes
- duplicate runtime files across applications
- more frequent updates
- increased maintenance
- possible licensing or redistribution considerations for certain components

Some projects instead rely on runtimes already present on most modern Windows installations.

---

# Best Practices for Portable Apps

- Detect runtime requirements before launch.
- Bundle runtimes when licensing permits and portability is a priority.
- Prefer private/local runtime copies over modifying the host system.
- Avoid installing runtimes globally unless explicitly requested by the user.
- Clearly document any runtime requirements.
- Keep bundled runtimes updated to supported versions.

---

# Summary

Runtime dependencies provide the shared libraries required for many Windows applications to execute.

| Dependency | Used By | Typical Requirement |
|------------|----------|---------------------|
| Visual C++ Runtime | Native C/C++ applications | VC Redistributable or private DLLs |
| .NET Framework | Legacy managed applications | Installed .NET Framework |
| Modern .NET | Current managed applications | Installed runtime or self-contained deployment |

Portable Apps strive to remain self-contained and non-invasive. When runtime dependencies are 
required, portable launchers typically detect, bundle, or redirect the application to use local copies 
rather than installing software onto the host system. This approach preserves portability while maintaining 
compatibility across a wide range of Windows environments.
