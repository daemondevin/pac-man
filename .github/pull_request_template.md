<!--
Thanks for contributing to PAC-MAN. Please fill in every section; delete
the guidance comments as you go. See CONTRIBUTING.md for the full rules.
-->

## What this changes

<!-- One or two sentences: what it does and why. -->

Closes #

## Type of change

- [ ] Bug fix
- [ ] Journaling an existing segment
- [ ] New segment
- [ ] New journal undo operation
- [ ] Compiler, feature flags or build
- [ ] Launcher for an app (custom.nsh and its configuration)
- [ ] Documentation only

## Host changes and how they're undone

<!--
List every change this makes to the host (registry keys and their view,
files, folders, links, services, tasks, firewall rules...) and the journal
entry that undoes each one. Write "None" if nothing on the host changes.
-->

| Change on the host | Journal entry (Op, A, B, C, D) | Undo |
| --- | --- | --- |
|  |  |  |

## Testing

**Where:**

- [ ] Windows 11, 64-bit
- [ ] Windows 10, 64-bit
- [ ] Windows on ARM
- [ ] Wine only (this needs a real Windows run before it's marked Journaled)

**Scenarios** (compare the host against a baseline, don't just eyeball it):

- [ ] Compiles with no features, with only this feature, and with every feature
- [ ] Normal run: the host matches the baseline afterwards and the journal is gone
- [ ] Crash: the launcher was killed while the app ran, and the journal held the expected entries
- [ ] Recovery: the next launch put the host back to the baseline
- [ ] Something already existing was left alone (skip) or restored exactly (replace)
- [ ] Not elevated: nothing changed and one warning was shown
- [ ] User opt-out: nothing changed
- [ ] Second launch while the app runs: nothing changed
- [ ] `WaitForProgram=false`: changes stayed while the app ran and were rolled back on the next launch
- [ ] Not applicable (documentation only)

<!-- Anything you couldn't test, or results worth mentioning. -->

## Checklist

- [ ] Branched from, and targets, `master-rewrite`
- [ ] Follows the code style: file headers, plain `;` comments, prefixed names, LogicLib instead of relative jumps
- [ ] Every host change is recorded with `${Journal::Record}` before it's made
- [ ] Cleanup only goes through `${Journal::Rollback}`, never by re-reading the configuration
- [ ] Never removes anything it didn't create
- [ ] Works with file-system redirection on and off, and records the registry view where it matters
- [ ] Segment header (USAGE, HOW IT IS UNDONE) and README updated
- [ ] Wiring done for new segments: `LauncherCompiler.nsi`, both lists in `PortableAppsCompiler.nsi`, `JOURNAL_RECOVERY_ORDER`, `FeatureFlags.nsh`
- [ ] No license keys, serials, patched binaries, license-check blocking or personal data anywhere in the change

## Notes for reviewers

<!-- Anything to look at closely, open questions, or follow-up work. -->
