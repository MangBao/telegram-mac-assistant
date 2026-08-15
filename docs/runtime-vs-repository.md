# Runtime vs Repository

To maintain a clean Infrastructure-as-Code paradigm, there is a strict boundary between what is stored in Git (Portable) and what is generated/stored on the host machine (Machine-Local).

## PORTABLE (Tracked in Git)
These artifacts define the *desired state* and behavior of the assistant.
- **Scripts**: Bootstrap, update, and maintenance scripts.
- **Configs/Templates**: Structural configurations, OpenClaw config templates, and `.env.example`.
- **Skills**: Custom JavaScript/TypeScript tools and plugins for OpenClaw.
- **Policies**: Filesystem whitelists, allowed terminal commands, and Telegram allowlists.
- **Prompts**: System instructions and agent personas.
- **Documentation**: Architecture, security models, and ADRs.
- **Machine Profiles**: Declarative definitions for different target hosts (e.g., company vs. personal).

## MACHINE-LOCAL (Ignored by Git)
These artifacts represent the *current state*, secrets, or transient data of the specific machine. They MUST be excluded via `.gitignore`.
- **Credentials & Tokens**: `.env` file, Telegram Bot Token, Model API keys.
- **Authentication State**: OAuth tokens, SSH private keys.
- **Browser State**: Isolated browser profiles, cookies, and local storage used by the assistant.
- **Runtime State**: OpenClaw database, daemon PIDs, and local machine identifiers.
- **Telemetry & Logs**: Application logs, crash reports, and audit trails.
- **Temporary Files**: Cache, downloads, and workspace scratchpads.
