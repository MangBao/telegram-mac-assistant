# Security Model

## Core Principles
1. **Least Privilege**: The AI assistant runs with the minimum required macOS permissions. It cannot grant itself new permissions.
2. **Read Before Write**: Destructive operations require explicit user approval via Telegram.
3. **Ephemeral/Isolated Access**: The browser session used by the assistant is strictly isolated from any personal browser data.
4. **No Secrets in Git**: No API keys, tokens, or personal data will ever be committed to the repository.

## Filesystem & Terminal Controls
- **Filesystem Whitelist**: The agent operates within a strictly defined workspace path. Access to critical system directories or personal files outside the workspace is blocked or requires explicit policy overrides.
- **Terminal Policy**: Dangerous commands (e.g., `rm -rf /`, `sudo`) are intercepted. The agent cannot modify its own runtime or SSH keys.

## OpenClaw Specific Security
Based on official OpenClaw recommendations:
- **Gateway Security**: The OpenClaw Gateway port (`18789`) is bound to localhost and never exposed to the public internet.
- **Telegram Allowlist**: Only pre-authorized Telegram User IDs are allowed to interact with the assistant. Inbound messages from unknown users are treated as untrusted and rejected.
- **Sandboxing**: Untrusted or third-party skills run in a restricted sandbox where possible.

## Secret Management Strategy
- **Mechanism**: The repository only contains a `.env.example` file. Actual secrets are managed outside of version control.
- **Deployment**: During bootstrap, secrets (like the Telegram Bot Token, API keys, OAuth credentials) are either injected manually by the user or fetched securely via a local secrets manager (e.g., 1Password CLI, keychain) if configured in the machine profile.
- **Banned Files**: `.env`, `*.key`, `*.pem`, and browser cookie databases are strictly ignored via `.gitignore`.
