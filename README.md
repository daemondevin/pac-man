# PortableApps Compiler – Segment & Recovery Framework
## Overview

Welcome! `PortableApps Compiler & Management` (_PortableApps Compiler_ or _Pac-Man_ for short), is an enhanced, compatibility-aware launcher framework inspired by the PortableApps.com Launcher (PAL). It is designed to support complex, modern, and legacy Windows applications that PAL intentionally does not target. **pac-man's** framework is built on top of **PAL**. It introduces a **deterministic, crash-resilient segment system** for controlled interaction with Windows subsystems while preserving portability principles.

pac-man does **not** replace PAL. It augments PAL by adding:

- Structured lifecycle segments  
- Crash-recovery guarantees  
- Explicit rollback journaling  
- Windows 10/11–compliant integration patterns  

pac-man is designed to behave like a **transactional runtime environment**, not an installer. pac-man is **not a replacement for PAL**. It exists to solve a different class of problems.

---

## Project Status: Pre-Production / Under Heavy Construction

pac-man is not ready for production deployment. The project is currently under active, foundational development, with core systems still evolving. While major architectural components are designed and implemented, the following remain incomplete or unstable:

- Segment APIs are still subject to change
- Recovery and rollback paths are being hardened and audited
- Edge cases across Windows versions are still being validated
- Long-term compatibility guarantees have not yet been established
- Internal tooling, documentation, and safety checks are incomplete

As a result:

- Behavior may change between revisions
- Configuration formats are not yet frozen
- Backward compatibility is not guaranteed
- Use in production environments may result in unintended system changes

At this stage, pac-man should be considered suitable only for development, testing, and experimentation by advanced users who understand the risks.

Production use is explicitly discouraged until:

- The segment SDK stabilizes
- Crash-recovery logic is fully verified
- Windows 10/11 behavior is exhaustively tested
- Formal release guarantees are documented

### Definition of “Production-Ready” for pac-man

pac-man is considered production-ready when:

- **A crash cannot leave the host system modified**
- **Every segment can fail safely**
- **Recovery is automatic, deterministic, and tested**
- **Behavior is documented and enforced**
- **No hidden system state is introduced**

For more information on what's planned for pac-man visit our [roadmap](Other/Source/docs/ROADMAP.md)

## Design Philosophy Differences

### PortableApps.com Launcher (PAL)

- Conservative system interaction
- Optimized for simple, well-behaved portable applications
- Avoids modifying:
  - File associations
  - Protocol handlers
  - Services
  - Firewall rules
  - Hosts file
- Prefers portability purity over compatibility

### pac-man (PortableApps Compiler)

- Compatibility-first design
- Supports complex and legacy applications
- Allows temporary system modification with:
  - Explicit scope
  - Journaling
  - Guaranteed rollback
- Treats crash recovery as mandatory

---

### Functional Comparison

| Feature | PAL | pac-man |
|------|-----|--------|
| Crash Recovery | Limited | Journal-based |
| File Associations | Not supported | User-scoped |
| URL Protocols | Not supported | Supported |
| Windows Services | Not supported | Temporary |
| Firewall Rules | Not supported | Reversible |
| Scheduled Tasks | Not supported | Session-bound |
| COM Registration | Minimal | Fully tracked |
| Fonts | Limited | Fully reversible |
| Hosts File | Not supported | Transactional |
| Windows 11 Compliance | Partial | Explicit |

To learn more about the differences between `PAL` and `pac-man` visit [pac-man vs. PAL](Other/Source/docs/pac-man-vs-pal.md)

---

## Design Principles

pac-man adheres to the following principles:

1. No permanent system mutation  
2. Every mutation must be reversible  
3. Recovery must not depend on successful startup  
4. User scope first, system scope only when required  
5. Deterministic execution order  
6. Fail closed, not open  

---

## Crash Recovery Model

### Recovery Philosophy

Crash recovery in pac-man is:

- **Deterministic**, not heuristic  
- **Journal-driven**, not best-effort  
- **Idempotent**, safe to re-run  

If pac-man detects that a previous session ended unexpectedly, it **recovers first**, before any new changes are made.

### Recovery Order

Recovery always runs in **reverse dependency order**:

1. Tasks  
2. Services  
3. Hosts  
4. Firewall  
5. Associations  
6. Symlinks  
7. Fonts  
8. RegDLL  
9. Runtime  

This mirrors how Windows itself unwinds dependent resources.

---

## Journaling System

### Purpose

The journal records **only what is necessary to undo a change**.  
It is not a log; it is a rollback ledger.

### Storage

- Location: `HKCU\Software\pac-man\Journal`  
- One subkey per segment  
- No shared keys between segments  

### Rules

- Journal **before** mutation  
- Never infer state  
- Never delete data you did not create  
- Cleanup must clear the journal  

---

## Segment Architecture

Each segment must fully comply with a strict criteria.

A compliant segment must:
- Be self-contained
- Never assume admin rights
- Never assume it completes
- Never assume a successful cleanup
- Never leak filesystem state
- Have every mutation reversible without context
- Declare changes before mutation
- Be callable from:
  - normal lifecycle
  - crash recovery
  - secondary instance (safe no-op)

---

## Official Segment Set

pac-man defines the following **first-class segments**:

### Runtime
- PATH manipulation  
- Portable VC++ / .NET handling  
- Process-scoped environment setup  

### RegDLL
- COM registration/unregistration  
- DLL lifecycle tracking  

### Fonts
- User-scoped font registration  
- Temporary font availability  

### Symlinks
- Junctions  
- Hard links  
- Symbolic links  

### Associations
- File extensions  
- Protocol handlers  
- Shell verbs  
- Application capabilities (Windows 10/11 compliant)  

### Firewall
- Program-specific firewall rules  
- Named, reversible entries  

### Hosts
- Temporary hostname overrides  
- Full snapshot restoration  

### Services
- On-demand Windows services  
- Explicit creation and deletion  

### Tasks
- Scheduled tasks  
- Explicit naming and teardown  

---

## Execution Order

### Apply Order

1. Runtime  
2. RegDLL  
3. Fonts  
4. Symlinks  
5. Associations  
6. Firewall  
7. Hosts  
8. Services  
9. Tasks  

### Cleanup / Recovery Order

Exact reverse order.

This ensures no consumer exists without its provider.

---

## Windows 10 / 11 Compliance

pac-man explicitly avoids:

- `UserChoice` hash tampering  
- Silent default-app hijacking  
- Undocumented Explorer hooks  
- Global COM pollution  

All shell integration follows **documented registry contracts** and respects OS safeguards.

---

## Security & Privilege Model

- Default execution is **non-admin**  
- Admin-only segments must explicitly check elevation  
- No silent privilege escalation  
- No persistent background components  

This aligns pac-man with least-privilege principles.

---

## Failure Handling

pac-man treats failure conservatively:

- Partial apply → full recovery  
- Uncertain state → rollback  
- Missing journal → do nothing  

Data safety is prioritized over feature completeness.

---

## Extending pac-man

Third-party segments must:

- Follow the lifecycle contract  
- Use the journal API  
- Register with the dispatcher  
- Declare privilege requirements  

Segments that violate these rules are considered **unsafe**.

---

## Intended Use Cases

pac-man is suitable for:

- Portable developer tools  
- Security tooling  
- Controlled enterprise environments  
- Forensic or sandbox workflows  

pac-man is **not** intended for:

- Silent system takeover  
- Persistent background services  
- Circumventing OS security policies  

--- 

This README is still being written...
