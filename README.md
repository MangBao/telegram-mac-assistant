# Telegram Mac Assistant

> A self-hosted AI assistant running on macOS, remotely controlled through Telegram and capable of interacting with the local machine, browser, files, applications, and coding tools.

`telegram-mac-assistant` is an **Infrastructure-as-Code and automation repository** for building a personal AI assistant that runs on a Mac and can be recreated on another machine with minimal manual setup.

The project is designed around a simple idea:

> **The repository contains the AI workstation's blueprint. The Mac contains its runtime state.**

The long-term goal is to turn a dedicated Mac mini into an always-available AI workstation that can receive tasks remotely, reason about them, interact with the computer, use development tools, and execute controlled workflows.

---

## Goals

The assistant is expected to eventually support:

* Receive commands and conversations through Telegram.
* Authenticate and restrict access to authorized Telegram users.
* Run continuously as a background service on macOS.
* Read and write files inside explicitly approved directories.
* Execute terminal commands according to a defined security policy.
* Inspect the macOS screen.
* Control mouse and keyboard.
* Interact with native macOS applications.
* Use an isolated browser for web automation and research.
* Take screenshots.
* Optionally access the camera.
* Run coding agents such as Claude Code, Qwen Code, OpenCode, or other supported agents.
* Work with Git and GitHub.
* Review code and pull requests.
* Run tests and development commands.
* Use project-specific skills and automation workflows.
* Support local AI models as well as external AI providers.
* Be portable across multiple Macs through repeatable bootstrap scripts.

---

## Non-Goals

This repository is **not** intended to:

* Store API keys or authentication tokens.
* Store Telegram bot tokens.
* Store SSH private keys.
* Store browser cookies or browser profiles.
* Store OpenClaw runtime state.
* Backup the entire user's home directory.
* Grant unrestricted access to the host machine.
* Automatically modify macOS security/privacy permissions.
* Automatically install arbitrary third-party AI skills or plugins.
* Allow autonomous access to production environments by default.

Security and explicit permission boundaries are part of the architecture, not optional features.

---

# Architecture

At a high level:

```text
                         User
                          │
                          ▼
                     Telegram
                          │
                          ▼
                 ┌─────────────────┐
                 │   AI Runtime    │
                 │    OpenClaw     │
                 └────────┬────────┘
                          │
          ┌───────────────┼────────────────┐
          │               │                │
          ▼               ▼                ▼
     Filesystem         Browser         Computer
      sandbox          automation        control
          │               │                │
          └───────────────┼────────────────┘
                          │
                          ▼
                  Coding / AI Agents
                 ┌────────┼────────┐
                 ▼        ▼        ▼
              Claude    Qwen    OpenCode
                 │
                 ▼
               GitHub
```

The exact runtime implementation may evolve.

OpenClaw is currently the primary candidate for the agent runtime, but the repository should remain as implementation-independent as reasonably possible.

---

# Repository vs Runtime

One of the most important architectural rules is the separation between **portable configuration** and **machine-local runtime state**.

## Repository

The Git repository contains things that should be reproducible:

```text
telegram-mac-assistant/
├── bootstrap/
├── config/
├── profiles/
├── scripts/
├── skills/
├── agents/
├── policies/
├── tests/
├── docs/
└── README.md
```

Expected repository-managed content includes:

* installation scripts
* bootstrap scripts
* configuration templates
* machine profiles
* AI agent instructions
* skills
* policies
* prompts
* health checks
* tests
* documentation

## Local machine

The Mac contains things that are machine-specific or sensitive:

```text
~/.openclaw/
    ├── credentials/
    ├── runtime state
    ├── sessions
    ├── logs
    └── cache
```

and:

```text
~/AI-Workspace/
    ├── projects/
    ├── documents/
    ├── downloads/
    └── scratch/
```

Runtime state and secrets must never be committed to Git.

---

# Security Model

The assistant may eventually have access to extremely powerful capabilities:

```text
Screen
Mouse
Keyboard
Terminal
Filesystem
Browser
Camera
GitHub
Coding Agents
```

Therefore this project follows a **least-privilege architecture**.

## Core principles

### 1. Least privilege

Only grant the minimum permissions required for a feature.

### 2. Explicit boundaries

Filesystem, command execution, browser access, and external services must have explicit policy boundaries.

### 3. Read before write

The assistant should inspect and understand a target before modifying it.

### 4. Approval for destructive operations

Actions such as:

* deleting files
* force-pushing
* merging pull requests
* changing production systems
* modifying security configuration

should require explicit approval unless a documented workflow says otherwise.

### 5. Secrets stay outside Git

Never commit:

```text
.env
.env.*
API keys
Telegram bot tokens
GitHub tokens
OAuth credentials
SSH private keys
*.pem
*.key
browser cookies
session data
```

### 6. No implicit full-machine access

The fact that the assistant runs on the Mac does not mean it should automatically have access to the entire filesystem.

The default workspace should be explicitly defined.

---

# Workspace

The default AI workspace is expected to be:

```text
~/AI-Workspace/
```

with:

```text
~/AI-Workspace/
├── projects/
├── documents/
├── downloads/
└── scratch/
```

This directory is intended to become the primary working area for the AI assistant.

Access outside this workspace should be controlled by explicit policy.

Sensitive locations such as the following should be considered protected by default:

```text
~/.ssh
~/.aws
~/.config
~/Library
/System
/etc
.env*
private keys
credentials
```

---

# Telegram

Telegram is intended to be the primary remote interface for the assistant.

The expected flow is:

```text
Phone
  │
  ▼
Telegram
  │
  ▼
Telegram Bot
  │
  ▼
AI Runtime
  │
  ▼
Mac mini
```

The Telegram layer should:

* only accept authorized users
* use a secure pairing or allowlist mechanism
* reject unauthorized requests
* never expose secrets
* support human approval for sensitive operations

Telegram is a user interface, not the security boundary by itself.

---

# Browser Automation

The assistant should use an isolated browser profile instead of the user's personal browser session.

The browser may eventually be used for:

* research
* web navigation
* reading documentation
* testing web applications
* downloading files
* interacting with web services

The assistant should not automatically access personal browser cookies, saved passwords, or existing authenticated sessions.

---

# Computer Use

Computer-use is a core long-term capability.

The assistant should eventually be able to:

```text
Screenshot
    ↓
Understand screen
    ↓
Move mouse
    ↓
Click
    ↓
Type
    ↓
Observe result
    ↓
Continue
```

macOS permissions such as Accessibility and Screen Recording should be enabled only when the corresponding feature is intentionally activated.

The repository may document required permissions, but it should not bypass or silently modify macOS privacy controls.

---

# Coding Agents

The assistant is intended to orchestrate existing coding agents rather than replace them.

Potential integrations include:

* Claude Code
* Qwen Code
* OpenCode
* other local or cloud coding agents

The conceptual flow is:

```text
Telegram
   │
   ▼
AI Assistant
   │
   ▼
Coding Agent
   │
   ├── Inspect repository
   ├── Modify code
   ├── Run tests
   ├── Review diff
   └── Report result
```

Coding agents should follow the rules and conventions of the target project.

---

# Skills

Skills are reusable instructions and workflows that teach the assistant how to perform specific tasks.

Examples:

```text
skills/
├── analyze-project/
├── review-code/
├── create-pr/
├── review-pr/
├── run-tests/
├── fix-typescript/
├── browser-research/
├── macos-control/
└── github/
```

Skills should be:

* version-controlled
* documented
* reviewed before installation
* scoped to a specific purpose
* free of embedded secrets

Third-party skills must not be installed automatically without review.

---

# Machine Profiles

The repository should support multiple machine profiles.

Examples:

```text
profiles/
├── company-mac-mini/
└── personal-mac/
```

A profile may define:

* machine capabilities
* enabled features
* workspace location
* installed tools
* expected permissions
* AI providers
* coding agents
* browser support
* camera/microphone usage

The goal is to support commands such as:

```bash
./bootstrap.sh company-mac-mini
```

or:

```bash
./bootstrap.sh personal-mac
```

without duplicating the entire configuration.

---

# Bootstrap

A new machine should eventually be reproducible using:

```bash
git clone <repository>
cd telegram-mac-assistant
./bootstrap.sh
```

The bootstrap process should be:

* deterministic
* idempotent
* safe to re-run
* explicit about manual actions
* careful with permissions
* safe with secrets

A typical bootstrap flow:

```text
Detect system
      ↓
Validate prerequisites
      ↓
Install required tools
      ↓
Install AI runtime
      ↓
Create workspace
      ↓
Deploy configuration
      ↓
Install approved skills
      ↓
Validate permissions
      ↓
Run health check
      ↓
Ready
```

---

# Health Checks

The project should provide a diagnostic command capable of validating the entire workstation.

Example:

```bash
./scripts/doctor.sh
```

Expected checks include:

```text
System
Runtime
OpenClaw
AI providers
Browser
Workspace
Skills
Coding agents
Git
GitHub
macOS permissions
Telegram connectivity
```

The doctor command should clearly distinguish:

```text
✓ Ready
⚠ Manual action required
✗ Broken
```

---

# Development Principles

This project follows several engineering principles.

## Configuration over hard-coding

Prefer declarative configuration and templates.

## Idempotency

Scripts should be safe to execute multiple times.

## Explicit dependencies

Do not silently rely on tools that are not documented.

## Small phases

Major capabilities should be implemented independently and verified before moving to the next phase.

## Observable behavior

Every important automation should have:

* clear logs
* health checks
* predictable exit codes
* useful error messages

## Security before convenience

A slightly inconvenient approval flow is preferable to giving an AI unrestricted access to a workstation.

---

# Development Roadmap

The project is intentionally developed in phases.

```text
Phase 0   Architecture
   ↓
Phase 1   Bootstrap foundation
   ↓
Phase 2   OpenClaw runtime
   ↓
Phase 3   Telegram MVP
   ↓
Phase 4   Filesystem sandbox
   ↓
Phase 5   Browser automation
   ↓
Phase 6   Screen + mouse + keyboard
   ↓
Phase 7   Coding agent integration
   ↓
Phase 8   GitHub integration
   ↓
Phase 9   Skills ecosystem
   ↓
Phase 10  Autonomous workflows
```

Each phase should have:

1. Clear scope
2. Explicit security boundaries
3. Automated validation
4. Documentation
5. Definition of Done

A phase should not silently implement functionality belonging to a later phase.

---

# Example Future Workflow

A long-term goal is to support workflows such as:

```text
User
 │
 │ "Review my open PRs"
 ▼
Telegram
 │
 ▼
AI Assistant
 │
 ├── GitHub
 │
 ├── Coding Agent
 │
 ├── Run tests
 │
 └── Analyze changes
 │
 ▼
Summary
 │
 ▼
Telegram
```

Or:

```text
User
 │
 │ "Open project X and investigate the failing test"
 ▼
AI Assistant
 │
 ├── Open workspace
 ├── Inspect repository
 ├── Open IDE
 ├── Run tests
 ├── Analyze failure
 └── Report findings
 │
 ▼
Telegram
```

Eventually, approved workflows may be able to modify code, create commits, create pull requests, and request human approval before sensitive actions.

---

# Portability

The project is intentionally designed so that the AI workstation can be recreated on another Mac.

The desired experience is:

```bash
git clone <repository>
cd telegram-mac-assistant
./bootstrap.sh
```

followed by only the machine-specific steps that cannot safely be automated, such as:

* macOS privacy permissions
* signing in to external services
* entering secrets
* authenticating personal accounts

The repository should therefore act as the **portable source of truth for the workstation's architecture and behavior**.

---

# Repository Philosophy

This project is not just a collection of shell scripts.

It is intended to become a reusable:

> **AI Workstation Operating Layer**

The runtime may change over time.

OpenClaw may be replaced.
Models may change.
Coding agents may change.
Browser automation technology may change.

The repository should preserve the higher-level architecture:

```text
                         AI Workstation
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
       Remote Interface     Agent Runtime      Tools
            │                  │                  │
         Telegram           OpenClaw           Browser
                                                Files
                                                macOS
                                                GitHub
                                                Coding
            │                  │                  │
            └──────────────────┼──────────────────┘
                               │
                           Policies
                               │
                         Skills & Rules
                               │
                            Git Repo
```

The implementation can evolve without losing the underlying system.

---

# Documentation

The architecture and design decisions are documented in the `docs/` folder:
- [Architecture](docs/architecture.md)
- [Security Model](docs/security-model.md)
- [Bootstrap Design](docs/bootstrap-design.md)
- [Runtime vs Repository](docs/runtime-vs-repository.md)
- [ADR 0001: Initial Architecture](docs/adr/0001-initial-architecture.md)

---

# Status

> 🚧 **Early development**

The project is currently being built incrementally.

At the current stage, architecture and security boundaries are more important than feature count.

Do not treat the assistant as an autonomous system until each capability has been explicitly implemented, tested, and reviewed.

---

# License

License to be determined.

---

# Maintainer

`telegram-mac-assistant` is maintained as a personal AI workstation project and is intended to evolve together with the tooling and workflows used on the host Mac.
