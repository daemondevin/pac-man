# pac-man Roadmap to Production-Ready

## Phase 0 — Current State: Experimental

**Status:** Under heavy construction

**Audience:** Core developers, advanced testers

**Characteristics**

- Segment SDK still evolving
- Recovery logic implemented but not yet proven under failure
- Configuration schemas not frozen
- Limited Windows version validation

**Exit Criteria**

- All core segments exist and compile
- Recovery dispatcher present and callable
- No known destructive bugs in basic test paths

---

## Phase 1 — Architecture Stabilization

**Goal:** Freeze the foundation before adding polish

### Objectives

- Finalize Segment SDK contracts
- Lock macro/function signatures
- Establish strict lifecycle phases:

  - `PrePrimary`
  - `Primary`
  - `PostPrimary`
  - `Cleanup`
  - `Recovery`

### Required Work

- Document segment interfaces and guarantees
- Remove experimental flags or rename them explicitly
- Eliminate undefined execution paths
- Enforce naming conventions and isolation rules

### Exit Criteria

- No breaking changes without version bump
- All segments conform to the same lifecycle model
- SDK documentation matches implementation

---

## Phase 2 — Recovery Hardening & Failure Modeling

**Goal:** Make failure safe and predictable

### Objectives

- Prove crash-recovery works under real failures
- Ensure no persistent system damage after abnormal exit

### Required Work

- Inject controlled crashes at every segment boundary
- Validate:

  - Power loss mid-execution
  - Forced process termination
  - Partial registry/file writes
- Ensure recovery dispatcher:

  - Detects incomplete runs
  - Executes only required cleanup
  - Is idempotent

### Exit Criteria

- All segments pass forced-failure tests
- Recovery leaves host system in pre-launch state
- No orphaned registry keys, services, tasks, or files

---

## Phase 3 — Windows Compatibility & Policy Compliance

**Goal:** Ensure behavior is correct and acceptable on supported systems

### Objectives

- Validate Windows 10 and Windows 11 behavior
- Ensure PortableApps.com policy compliance (even if not submitting)

### Required Work

- Test on:

  - Clean systems
  - Locked-down user accounts
  - Systems with existing associations/services
- Confirm:

  - No machine-wide writes without explicit opt-in
  - Windows 11 association strategies are respected
  - All system changes are reversible

### Exit Criteria

- No undocumented system modifications
- Explicit user intent required for elevated actions
- Behavior matches documented guarantees

---

## Phase 4 — Tooling, Diagnostics & Observability

**Goal:** Make failures understandable and debuggable

### Objectives

- Improve logging, tracing, and diagnostics
- Enable reproducible bug reports

### Required Work

- Structured logging per segment
- Recovery logs separated from normal execution
- Debug/verbose modes
- Clear exit codes and failure states

### Exit Criteria

- Every failure produces actionable logs
- Maintainers can reconstruct execution paths
- No “silent” recovery failures

---

## Phase 5 — Documentation & Developer Readiness

**Goal:** Make the project usable by others safely

### Objectives

- Complete developer and user documentation
- Reduce tribal knowledge

### Required Work

- Segment SDK documentation
- Recovery model explanation
- Security & safety guarantees
- “Do not do this” sections for contributors

### Exit Criteria

- New contributors can add a segment correctly
- Users understand risks and limits
- Documentation matches reality

---

## Phase 6 — Release Candidate (RC)

**Goal:** Lock behavior and test real-world usage

### Objectives

- Stop feature development
- Focus on stability and regressions

### Required Work

- Versioning policy enforced
- Backward compatibility rules defined
- Upgrade/downgrade paths tested

### Exit Criteria

- No known critical bugs
- No breaking changes planned
- Recovery passes full test matrix

---

## Phase 7 — Production-Ready Release

**Goal:** Safe, predictable, and supportable use

### Characteristics

- Stable APIs
- Documented guarantees
- Proven recovery
- Controlled scope of responsibility

### Requirements

- Formal versioning
- Changelog discipline
- Clear support boundaries

---

## Definition of “Production-Ready” for pac-man

pac-man is considered production-ready when:

- **A crash cannot leave the host system modified**
- **Every segment can fail safely**
- **Recovery is automatic, deterministic, and tested**
- **Behavior is documented and enforced**
- **No hidden system state is introduced**
