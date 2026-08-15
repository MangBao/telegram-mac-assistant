# Bootstrap Design

The bootstrapping process transforms a fresh macOS installation into a fully configured AI assistant node, solely by cloning this repository and running the bootstrap script.

## Core Requirement: Idempotency
The bootstrap script (`bootstrap.sh`) must be strictly idempotent. Running it multiple times must not break the system, corrupt configurations, or duplicate services.

## Execution Flow

1. **Environment Detection**:
   - Detect OS (must be macOS).
   - Detect Architecture (must be Apple Silicon / `arm64`).

2. **Prerequisites Check & Install**:
   - Check for Homebrew; install if missing.
   - Install required system tools (e.g., Git).
   - Install required Node.js version (22.22.3+ as required by OpenClaw).

3. **OpenClaw Installation**:
   - Check if OpenClaw CLI is installed.
   - If not, run official installer: `curl -fsSL https://openclaw.ai/install.sh | bash`.
   - *Note: We do not configure the daemon manually if `openclaw onboard --install-daemon` handles it, but we automate the configuration generation.*

4. **Workspace & Profile Initialization**:
   - Accept machine profile as an argument (e.g., `./bootstrap.sh company-mac-mini`).
   - Create the designated workspace directory (e.g., `~/openclaw-workspace`).
   - Generate `.env` from `.env.example` if it doesn't exist, prompting the user for missing secrets.

5. **Configuration Deployment**:
   - Template the machine profile configurations into the OpenClaw configuration directory.
   - Symlink or copy skills and security policies into the runtime environment.

6. **Permissions Validation**:
   - Check if Terminal/Node has necessary macOS Accessibility/Screen Recording permissions.
   - Output clear, manual instructions to the user if permissions are missing (we do not auto-grant macOS permissions for security).

7. **Health Check & Startup**:
   - Verify OpenClaw daemon status.
   - Verify Telegram connection.
   - Verify filesystem whitelists are enforced.
