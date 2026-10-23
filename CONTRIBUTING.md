# Contributing to PAC-MAN

Thanks for wanting to help with PAC-MAN (PortableApps Compiler & Management). This guide covers how to report problems, propose changes, write segments and launchers, and get a pull request merged.

Everyone taking part is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).

## Before you start

**PAC-MAN is not PAL.** It is built on top of the PortableApps.com Launcher (PAL) and still produces packages in the PortableApps.com Format, but it is a separate project with its own lifecycle, segments and rollback journal. Please don't report PAC-MAN problems to PortableApps.com, and don't open issues here about PAL itself.

**The project is pre-production.** Configuration formats aren't frozen yet, and behaviour can change between revisions (see [Project Status](README.md#project-status-pre-production--under-heavy-construction)). The [roadmap](Other/Source/docs/ROADMAP.md) says what is being worked on and in what order. Contributions that move a segment onto the journal, or test the recovery paths, are the most valuable right now.

**Work on the `master-rewrite` branch.** Fork the repository, branch from `master-rewrite`, and open your pull request against it.

## Ways to contribute

| You want to | Start with |
| --- | --- |
| Report a bug | An [issue](#reporting-a-bug) with a journal export |
| Suggest a feature or a new segment | An issue describing the problem it solves, before any code |
| Fix a bug | A pull request that links the issue |
| Write or journal a segment | An issue first, then the [segment rules](#writing-a-segment) |
| Share a launcher for an app | The [packaging rules](#contributing-a-launcher) |
| Improve the docs or the Wiki | A pull request, or an issue pointing at what's wrong |
| Test | Run the [forced-failure scenarios](#testing) on real Windows and report what you find |

For anything larger than a small fix, open an issue first and say what you plan to do. It saves you from writing code that clashes with work already under way.

## Reporting a bug

PAC-MAN records every change it makes before making it, so most bugs can be diagnosed from the journal. Please include:

1. **What happened and what you expected**, in a sentence or two each.
2. **Steps to reproduce**, starting from a clean state if you can.
3. **Your setup:** Windows version and edition (and 32-bit, 64-bit or ARM64), whether the launcher ran elevated, and where the package lives (internal drive, USB stick, network share).
4. **The package's configuration:** `App\AppInfo\Launcher\<AppID>.ini`, `App\AppInfo\appinfo.ini`, `custom.nsh` if there is one, and the user's `<AppID>.ini`.
5. **The journal**, especially after a crash or a failed recovery:
   - an export of `HKEY_CURRENT_USER\Software\pac-man\Journal`, from `reg export HKCU\Software\pac-man\Journal journal.reg`
   - the contents of `%LOCALAPPDATA%\pac-man\Journal`
6. **Debug output** if you can reproduce it: put a `Debug.nsh` with `!define DEBUG_ALL` (or `!define DEBUG_JOURNAL` for journal problems) in `App\AppInfo\Launcher`, recompile, and attach what it shows.

> [!IMPORTANT]
> Remove license keys, serial numbers, account tokens and personal paths from anything you attach. Registry exports of an app's settings often contain them.

**Security problems** (a launcher that can be made to run code, escalate privileges, or delete something it didn't create) shouldn't go in a public issue. Email daemon.devin@gmail.com instead.

## Setting up

You need:

- **Windows 10 or 11**, for building and real-world testing. A virtual machine with snapshots is strongly recommended, because launchers change the system they run on.
- **NSIS 3.0 or later.** The build refuses older versions. PAC-MAN compiles as Unicode.
- **The NSIS plugins the compiler ships with.** The launcher is a 32-bit process, so only x86-unicode plugin builds work.
- An editor that keeps **CRLF** line endings and saves **UTF-8**.

To build a launcher, run the PortableApps Compiler and point it at a package folder. `LauncherCompiler.nsi` reads the package's `[Activate]` section, writes the feature flags into `GlobalDefines.nsh`, and compiles `PortableAppsCompiler.nsi` with them.

## Code style

The codebase follows a consistent style. Pull requests that don't follow it will be asked to.

**Files**

- UTF-8, CRLF line endings, tabs for indentation.
- Every source file starts with the standard header (the `;=#` block naming the project and the file), followed by a short description of what the file does.
- Segment files also document `USAGE` (every key, its default and its values) and `HOW IT IS UNDONE`. The header is the documentation, so keep it exact.

**Comments**

- Plain `;` comments only. No decorated banners such as `;= ---- SECTION ---- =;` or boxes of dashes.
- Write comments as sentences, explaining **why**, not restating the code.
- Spell "-ize" words with a z: initialize, normalize, recognize.

**Names**

- Prefix every `Var`, `Function` and `!define` in a segment with the segment's name (`Hosts_`, `$HostsLine`, `HOSTS_`). NSIS names share one namespace and are effectively case-insensitive.
- Feature flags are spelled `SEGMENTS_<NAME>`, identically everywhere they appear.

**NSIS habits**

- Use LogicLib (`${If}`, `${Do}`) rather than relative jumps (`Goto +3`). Relative jumps break silently when someone adds a line.
- `ClearErrors` right before every `ReadINIStr` or `ReadRegStr` whose missing case you check.
- Always `Pop` both values `nsExec::ExecToStack` pushes.
- `Push` and `Pop` every register a function changes. Functions are called from hooks that rely on their registers.
- Compare strings with `==`, numbers with `=`, `<` and `>`, and versions with `${VersionCompare}`.
- Don't put a `Function` or a label inside a hook. Hooks are macros pasted into other functions.

## Writing a segment

A segment that changes anything outside the app's own folders must go through the rollback journal. The full guide is [Writing PAC-MAN Segments](Other/Source/docs/SEGMENTS.md). In short, these rules are not negotiable:

1. **Journal before you mutate.** Call `${Journal::Record}` before the change it guards, never after.
2. **Clean up with `${Journal::Rollback}` only.** Don't re-read the configuration on exit to work out what to remove. The normal path and crash recovery must run the same code.
3. **Record state; never infer it.** Store the exact previous value, including its registry type, or a backup in the journal store.
4. **Never delete what you didn't create.** Tag what you create, leave anything that existed before launch alone, and only remove parent keys and folders when they're empty.
5. **Fail closed.** No admin rights means no changes and one warning, never a silent escalation.
6. **User scope first.** Use `HKCU` and per-user locations unless the feature truly needs machine scope.
7. **Don't parse localized tool output.** Check exit codes, and check the resulting state wherever an exit code is ambiguous.
8. **Undo must not need the portable drive.** Recovery may run from another drive letter, or after the drive is gone.
9. **Let the user opt out** of anything that changes their system, with a key in their `<AppID>.ini`.

When the segment is done, wire it in everywhere:

- the `[Activate]` key in `LauncherCompiler.nsi`
- both the apply and cleanup lists in `PortableAppsCompiler.nsi`
- `JOURNAL_RECOVERY_ORDER` in `Journal.nsh`
- `FeatureFlags.nsh` if it has aliases or dependencies
- the README: the `[Activate]` list, a section for the segment, and its row in the implementation status table

A new undo operation must be idempotent and work with no context: run twice, or on something that never happened, it must succeed and change nothing. Document it in `Journal.nsh` and in the README's undo operations table.

## Contributing a launcher

Launchers for individual apps (`custom.nsh`, the launcher `.ini` and `appinfo.ini`) are welcome as examples, and they're often the best test of a segment. A launcher must:

- **Journal everything it changes on the host**, using the journal API from `custom.nsh` just as segments do. Prefer declared segments (`[SymlinkN]`, `[ServiceN]`, `[RegisterDLLN]`) over custom code.
- **Work without administrator rights** unless the app truly needs them. If it needs them, start the app itself without elevation where possible, so drag and drop from Explorer keeps working.
- **Survive a crash.** Kill the launcher while the app runs, launch again, and check that the host matches what it was before.
- **Use the app's own licensing.** No serial numbers, license values, patched binaries, keygens, or firewall rules that stop an app from checking its license. Pull requests that include any of these are closed (see the [Code of Conduct](CODE_OF_CONDUCT.md#6-honest-packaging)).
- **Ship no personal data.** `App\DefaultData` must not contain license or registration files, account data, personal projects or caches.
- **Describe itself honestly** in `appinfo.ini`. Commercial software isn't `Freeware=true` or `OpenSource=true`.
- **Come with a README** in `Other\Source` that says what the launcher changes on the host, what's kept in `Data`, and how it's undone.

## Testing

"It ran" isn't a test. Compare the host's state before and after each scenario: export the registry keys involved, list the files, rules, services or tasks, and diff them.

**Compile matrix:** your change must compile with no features enabled, with only the feature you touched, and with every feature enabled.

**Runtime scenarios:**

| Scenario | Expected result |
| --- | --- |
| Normal run | The app sees the change; afterwards the host matches the baseline and the journal key is gone |
| Crash (kill the launcher while the app runs) | The journal holds exactly the entries you expect |
| Next launch after the crash | Recovery runs and the host matches the baseline |
| Something already exists | `skip`: left untouched. `replace`: restored exactly, including type and attributes. |
| Changes made by someone else during the session | They survive the rollback |
| Not elevated | Nothing changed, one warning, no journal entries |
| User opt-out | Nothing changed, no journal entries |
| Second launch while the app runs | The segment does nothing |
| `WaitForProgram=false` | Changes stay while the app runs; the next launch rolls them back silently |

Wine is useful for quick runs and crash tests, but it can't create junctions, always reports admin rights, and lacks several Windows tools. Anything tested only in Wine needs a run on real Windows 10 or 11, including once as a standard user, before it can be marked **Journaled** in the implementation status table. Say in your pull request where you tested.

## Commits and pull requests

**Commits**

- One logical change per commit. Don't mix a fix with reformatting.
- Write the subject line in the imperative, under about 72 characters: `Journal the Fonts segment`, `Fix REGKEY rollback in the 64-bit view`.
- Use the body to explain why, and reference the issue (`Fixes #123`).

**Pull requests**

Your pull request description should cover:

- what it changes, and why
- the issue it closes
- which Windows versions you tested on, elevated or not, and with which scenarios from the table above
- anything a reviewer should look at closely, or anything you're unsure of

Before you ask for review, check:

- [ ] Branched from, and targeting, `master-rewrite`
- [ ] Compiles across the feature matrix with no new warnings
- [ ] Follows the code style, including headers and `;` comments
- [ ] Every system change journaled before it's made; cleanup only through `${Journal::Rollback}`
- [ ] Crash and recovery tested, with the host diffed against a baseline
- [ ] README and segment headers updated
- [ ] No license keys, personal data or circumvention code anywhere in the change

Reviews look first at whether a crash at any point can leave the host modified. Expect questions about edge cases. They aren't a judgement of your work; finding those cases before release is the point of review.

## Licensing

By contributing, you agree that your contribution is released under the same license as the rest of PAC-MAN, and that you have the right to contribute it. Code taken from elsewhere must be under a compatible license, and credited in the file header.

## Questions

Ask in [Discussions](https://github.com/daemondevin/pac-man/discussions), or check the [Wiki](https://github.com/daemondevin/pac-man/wiki). Use [Issues](https://github.com/daemondevin/pac-man/issues) for bugs you can reproduce.

Thanks for helping make PAC-MAN something people can trust with their computers.