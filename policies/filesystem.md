# Filesystem Access Policy

## Agent Workspace

The OpenClaw agent workspace is set to:

```
~/AI-Workspace/
```

This is the **only directory** the agent is permitted to read and write
without explicit approval.

## Allowed Paths

| Path                        | Access     | Notes                              |
|-----------------------------|------------|------------------------------------|
| `~/AI-Workspace/**`         | Read/Write | Full agent workspace               |
| `~/AI-Workspace/projects`   | Read/Write | Coding projects                    |
| `~/AI-Workspace/documents`  | Read/Write | Documents and notes                |
| `~/AI-Workspace/downloads`  | Read/Write | Downloads staging area             |
| `~/AI-Workspace/scratch`    | Read/Write | Temporary/scratch files            |
| `/tmp/**`                   | Read/Write | Temporary files (OS-managed)       |

## Forbidden Paths (Initially)

The agent must NOT access these paths without explicit user approval:

| Path              | Reason                                          |
|-------------------|-------------------------------------------------|
| `~/.ssh/`         | SSH private keys — never expose to agent        |
| `~/.aws/`         | AWS credentials                                 |
| `~/.config/`      | Application configs and credentials             |
| `~/Library/`      | macOS Library (contains sensitive app data)     |
| `/etc/`           | System configuration                            |
| `/usr/`           | System binaries                                 |
| `/System/`        | macOS system files                              |
| `.env*` files     | Any `.env` files anywhere on the system         |
| `*.pem`, `*.key`  | Private key files                               |
| `~/.openclaw/.env`| Secrets file for OpenClaw itself                |
| Production repos  | No access to production codebases by default    |

## Principles

- **Read before write**: The agent should confirm before overwriting files.
- **No recursive delete**: The agent must never run `rm -rf` on important paths.
- **Audit log**: All filesystem writes within workspace should be logged by OpenClaw sessions.
- **No Git commit with secrets**: The agent must not commit `.env` files or credential files.
