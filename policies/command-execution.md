# Command Execution Policy

## Permission Levels

The system uses 5 permission levels, applied cumulatively (each level includes all levels above it).

| Level       | Phase 3 Status | Description                                              |
|-------------|----------------|----------------------------------------------------------|
| READ        | ✅ **ENABLED** | Read files, check status, list directories, system info  |
| WRITE       | ❌ DISABLED    | Create, modify, or rename files                          |
| EXECUTE     | ❌ DISABLED    | Run shell commands or scripts                            |
| AUTOMATION  | ❌ DISABLED    | UI control, screenshot, mouse/keyboard                   |
| DESTRUCTIVE | ❌ DISABLED    | Delete files, format disks, push force to Git            |

To enable a higher level in a future phase, update `tools.deny` in `~/.openclaw/openclaw.json`
and update this policy document accordingly.

---

## READ Level (Phase 3)

### Allowed Operations

| Operation                              | Notes                                        |
|----------------------------------------|----------------------------------------------|
| List files in `~/AI-Workspace`         | Any depth; no system paths                   |
| Read file contents from `~/AI-Workspace` | Excluding `.env` and credential files       |
| Check system status (CPU, RAM, disk)   | Via OpenClaw built-in tools                  |
| List running processes                 | Read-only `ps` equivalent                    |
| Check network status                   | Read-only; no configuration changes          |
| Query Git repository status            | `git status`, `git log` within workspace     |

### Forbidden at READ Level

The following operations are forbidden even with READ access:

| Pattern                         | Risk                                    |
|---------------------------------|-----------------------------------------|
| Read `~/.ssh/`                  | SSH private keys                        |
| Read `~/.aws/`                  | AWS credentials                         |
| Read `~/.openclaw/.env`         | Gateway secrets (bot tokens, API keys)  |
| Read any `.env` file            | Any environment secrets                 |
| Read `*.pem`, `*.key` files     | Private keys                            |
| Read `~/Library/`               | macOS application data and keychain     |
| Output API keys or tokens       | Even if found in readable files         |

---

## WRITE Level (Future Phase 4+)

When enabled, allows:
- Creating/modifying files within `~/AI-Workspace`
- Requires user confirmation for files >10KB
- Git commits within workspace (not push)

**Not yet enabled.**

---

## EXECUTE Level (Future Phase 4+)

When enabled, allows running shell commands within a restricted allowlist:
- `git`, `ls`, `cat`, `grep`, `find` within workspace
- `python3`, `node` scripts within workspace
- Requires approval for any command not in the allowlist

**Not yet enabled.** See `policies/command-execution.md` for allowlist design.

---

## AUTOMATION Level (Future Phase 5+)

When enabled, allows:
- Screenshots (requires Screen Recording permission)
- UI control (requires Accessibility permission)
- Browser automation in isolated profile

**Not yet enabled.** Requires macOS TCC permissions first.

---

## DESTRUCTIVE Level (Requires explicit approval per action)

Operations in this category ALWAYS require explicit user approval, even when other
DESTRUCTIVE-level actions are enabled:

- `rm -rf` on any directory
- `git push --force`
- Format or wipe any drive
- Delete more than 10 files in a single operation
- Any system-wide configuration change

**Not yet enabled. Will always require approval even in future phases.**

---

## OpenClaw Enforcement

Permission levels are enforced in `~/.openclaw/openclaw.json` via:

```json5
{
  agents: {
    defaults: {
      tools: {
        deny: [
          "write",   // WRITE level
          "edit",    // WRITE level
          "delete",  // DESTRUCTIVE level
          "exec",    // EXECUTE level
          "browser", // AUTOMATION level
          "screenshot",    // AUTOMATION level
          "accessibility", // AUTOMATION level
        ],
      },
    },
  },
}
```

---

## Forbidden Commands (Hard Limits — All Phases)

These patterns must NEVER be executed regardless of permission level:

| Pattern                              | Risk                              |
|--------------------------------------|-----------------------------------|
| `rm -rf /` or `rm -rf $HOME`         | Wipes filesystem                  |
| `sudo` without explicit task         | Privilege escalation              |
| `curl ... \| bash` (arbitrary URLs)  | Remote code execution             |
| Modify `~/.ssh/` or `~/.aws/`        | Credential access                 |
| `git push --force` (production)      | Destructive to shared history     |
| `launchctl unload` (arbitrary)       | Disrupts macOS services           |
| Access to `~/.openclaw/.env`         | Exposes Gateway secrets           |
