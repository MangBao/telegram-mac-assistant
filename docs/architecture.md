# Architecture

## Overview
This repository serves as the Infrastructure-as-Code (IaC) foundation for a macOS-based AI assistant. The system uses **OpenClaw** as the agent runtime and **Telegram** as the remote interface, running on an Apple Silicon Mac mini.

## Core Components
1. **Mac mini (Apple Silicon)**: The physical host providing compute, terminal, filesystem, browser, and UI automation capabilities.
2. **OpenClaw Runtime**: A Node.js-based self-hosted AI agent framework. It runs as a background daemon (installed via `openclaw onboard --install-daemon`), managing tools, permissions, and agent lifecycles.
3. **Telegram Gateway**: The interface for remote control. OpenClaw connects to Telegram to receive commands and send responses.

## Repository Structure Design
To ensure portability and clear separation of concerns, the repository is structured as follows:

```
├── bootstrap/            # OS-level bootstrapping (Homebrew, Node.js, system deps)
├── installation/         # OpenClaw and external tool installation scripts
├── profiles/             # Machine profiles (e.g., company-mac-mini, personal-mac)
├── config/
│   ├── templates/        # Configuration templates (e.g., config.yaml.tpl)
│   └── .env.example      # Example environment variables
├── agents/               # Agent definitions and prompts
├── skills/               # Version-controlled custom skills for OpenClaw
├── policies/             # Security policies, permission definitions, and whitelists
├── scripts/              # Day-to-day operation and maintenance scripts
├── tests/                # Automated tests for configurations and skills
└── docs/                 # Documentation and Architecture Decision Records (ADRs)
```

## Machine Profiles
The repository supports multiple machine profiles (e.g., `company-mac-mini`, `personal-mac`). A profile defines:
- Target workspace path
- Enabled features and skills
- Allowed tools (e.g., browser, camera, microphone)
- Preferred coding agents and model providers
- Expected macOS permissions

## Future Extensibility
- **Sensors**: Camera and microphone integration (disabled by default for security).
- **Coding Agents**: Integration with Claude Code, Qwen Code, or OpenCode via terminal tools.
- **Git/GitHub**: Capabilities to manage repositories within the whitelisted filesystem.
