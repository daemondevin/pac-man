# PAC-MAN Code of Conduct

PAC-MAN (PortableApps Compiler & Management) is built on one promise: **every change can be undone.** The launcher records what it is about to do before it does it, and anything it changes can be put back. This code of conduct asks the same of the people who build it: take responsibility for what you change, leave things as good as you found them, and fix what you break.

It applies everywhere the project lives: the GitHub repository, issues, pull requests, discussions, release notes, and anywhere else you speak for PAC-MAN or about it.

## The principles

### 1. Journal before you act

The launcher never makes a change it hasn't recorded first. Do the same when you talk to people.

* Say what you intend before you do it. Open an issue before a large pull request, and explain why before you change something other people rely on.
* Show your reasoning. "This breaks X because Y" helps people; "this is wrong" doesn't.
* Disagree with code and ideas, not with the person behind them.

### 2. Every action has a rollback

Mistakes happen, in code and in conversation. What matters is that they get undone.

* If you were wrong, say so plainly and fix it. You don't need to apologize at length or defend the mistake.
* If someone points out a problem in your work, treat it like a bug report: thank them, look into it, and fix it or explain why it isn't one.
* When something you said hurt someone, the rollback is to acknowledge it and change course, not to argue about intent.

### 3. Leave the host the way you found it

A portable app must not leave traces on someone else's machine. Contributors shouldn't leave damage in someone else's space either.

* Respect people's time. Search existing issues first, include the information asked for, and keep threads on topic.
* Respect people's work. Credit what you build on, including PortableApps.com Launcher (PAL), which PAC-MAN extends but does not replace, and the authors of the applications that get packaged.
* Don't take over someone else's issue, pull request or discussion with your own unrelated problem.

### 4. Crash-resilient, not fragile

The framework is designed to recover from crashes, power cuts and pulled USB drives. The community should handle pressure just as well.

* Newcomers will ask basic questions. Answer them, or point to the documentation kindly. Everyone starts somewhere.
* Stay calm when a bug is frustrating. A stack trace is never the reporter's fault.
* Harsh words don't fix bugs. Patches and clear reproduction steps do.

### 5. Portable means for everyone

People use PAC-MAN on school computers, library PCs, work laptops and their own machines, in many countries and many languages.

* Welcome people regardless of age, body, disability, ethnicity, sex characteristics, gender identity and expression, experience level, education, socio-economic status, nationality, appearance, race, religion, or sexual identity and orientation.
* Use language that people who aren't native English speakers can follow. Explain jargon, or link to where it is explained.
* Don't assume someone's skill level, setup or reasons from one message.

### 6. Honest packaging

PAC-MAN packages other people's software. That comes with obligations to the people who make it.

* **No cracks, keygens, licence bypasses or piracy.** Launchers, examples, issues and pull requests must not include serial numbers, patched binaries, licence-check blocking (such as firewall rules aimed at a vendor's activation servers), or any other way of using software without a licence. Contributions that do will be closed, and repeated attempts are a conduct violation.
* Don't ship anyone's personal data. Licence keys, registration files, account tokens and personal projects never belong in `DefaultData` or in a published package.
* Describe what a launcher really does to the host: what it writes, what it registers, and what needs administrator rights. Users trust a launcher to tell the truth about their computer.
* Don't misrepresent a package. Don't claim a vendor endorses it, and don't label commercial software as freeware or open source.

## Unacceptable behaviour

These are not acceptable in any PAC-MAN space:

* Harassment, intimidation or threats, in public or in private
* Insults, slurs, or derogatory comments about anyone's identity or background
* Sexualized language or imagery, and unwelcome attention of any kind
* Publishing someone's private information (addresses, real names they haven't shared, contact details, licence keys) without their explicit permission
* Deliberately disrupting discussions, or repeatedly trolling
* Submitting malware, or code built to damage, spy on or take control of a user's machine
* Sharing or requesting pirated software, cracks or licence circumvention, as described in principle 6
* Encouraging or advocating any of the above

## Enforcement

### Reporting

If you experience or witness unacceptable behaviour, report it to the maintainer, **daemon.devin**, at **daemon.devin@gmail.com**. Include links or screenshots if you can. Reports are read promptly and kept confidential. Information is shared only as far as needed to deal with the problem, and the reporter's identity is protected.

Reporting a problem in good faith will never count against you.

### Consequences

The maintainer decides what action to take, based on what happened and its effect on others. As with the journal, the response is proportionate, and the aim is to restore a working state rather than to punish.

| Level | When | What happens |
| --- | --- | --- |
| **1. Note** | Unprofessional or unwelcoming behaviour, likely unintended | A private note explaining the problem. A public correction may be asked for. |
| **2. Warning** | A clear violation, or repeated level 1 behaviour | A formal warning with stated consequences. No interaction with the people involved for a set time. |
| **3. Temporary ban** | A serious violation, or continuing after a warning | A temporary ban from all project spaces, including issues, pull requests and discussions. |
| **4. Permanent ban** | A pattern of violations, harassment, malware, or deliberate piracy | A permanent ban from all project spaces. |

Content that breaks this code may be edited, hidden or removed whatever the level, including comments, commits, issues, pull requests and release assets.

### Appeals

If you think an enforcement decision was wrong, email the maintainer within 30 days and explain why. Appeals are reviewed with a fresh look, and a decision can be reversed. That's a rollback too.

## Scope

This code applies in all PAC-MAN spaces, and when someone represents the project in public, for example when posting as the project, sharing a PAC-MAN package, or acting as a project representative at an event. Behaviour outside project spaces may be taken into account when it affects the safety or wellbeing of people in them.

## Credits

The structure of the enforcement section is adapted from the [Contributor Covenant](https://www.contributor-covenant.org/), version 2.1. The principles, the packaging rules and everything else here were written for PAC-MAN.
