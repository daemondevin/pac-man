# pac-man vs PortableApps.com Launcher (PAL)

## Overview

`pac-man` (PortableApps Compiler) is an enhanced, compatibility-aware launcher framework inspired by the PortableApps.com Launcher (PAL). It is designed to support complex, modern, and legacy Windows applications that PAL intentionally does not target.

pac-man is **not a replacement for PAL**. It exists to solve a different class of problems.

---

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

## Functional Comparison

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

---

## Windows 10 / 11 Default App Handling

PAL avoids Windows default app APIs entirely.

pac-man:
- Registers application capabilities
- Uses RegisteredApplications
- Avoids UserChoice hash tampering
- Aligns with Windows 11 default app policy

---

## Segment-Based Architecture

pac-man introduces a segment execution model:

- Each system interaction is isolated
- Segments declare mutations
- All changes are journaled
- Recovery is enforced on next launch if needed

---

## Failure Model

**PAL**
- Assumes clean startup and exit
- Cleanup is best-effort

**pac-man**
- Assumes crashes occur
- Enforces rollback on next launch
- Designed for power loss and forced termination

---

## Intended Audience

**PAL**
- General end users
- Strict portability requirements

**pac-man**
- Power users
- Developers
- Complex applications requiring controlled system integration

---

## Summary

PAL prioritizes portability purity.  
pac-man prioritizes correctness, compatibility, and recovery.

Both tools are valid and serve different needs.
