# OpenClaw Tools Policy
# Defines which OpenClaw built-in capabilities are permitted in this deployment.

## Philosophy

OpenClaw provides many tools out of the box. This policy defines what is
**enabled by default** for this AI assistant, following the principle of
**least privilege**. New tools must be explicitly enabled and documented here.

## Phase 2 Defaults (initial baseline)

| Tool                      | Status      | Reason                                        |
|---------------------------|-------------|-----------------------------------------------|
| Read files (workspace)    | ALLOWED     | Within `~/AI-Workspace` only                  |
| Write files (workspace)   | ALLOWED     | Within `~/AI-Workspace` only                  |
| Terminal / shell          | REVIEW REQ. | Must be explicitly enabled per task           |
| Browser automation        | DISABLED    | Enable in Phase 3 with isolated profile       |
| Screenshot                | DISABLED    | Requires Screen Recording permission first    |
| Accessibility / UI ctrl   | DISABLED    | Requires Accessibility permission first       |
| Camera                    | DISABLED    | Enable only in personal-mac profile           |
| Microphone                | DISABLED    | Enable only in personal-mac profile           |
| GitHub / Git              | DISABLED    | Enable after policy review                    |
| Coding agents (MCP)       | DISABLED    | Enable after explicit vetting                 |
| Community plugins (ClawHub)| DISABLED   | Never auto-install; require manual review     |
| Heartbeat                 | DISABLED    | Enable after Telegram is configured           |
| Webhooks (hooks)          | DISABLED    | Enable per use-case with dedicated token      |
| Cron jobs                 | DISABLED    | Enable per task after review                  |

## Rules

1. Tools not in this table are **disabled by default**.
2. Enabling a new tool requires an update to this policy and a code review.
3. Terminal tool must use a command allowlist when enabled (see `command-execution.md`).
4. Any tool that can make outbound network requests must be documented.
5. Community plugins from ClawHub must be manually reviewed before installation.
