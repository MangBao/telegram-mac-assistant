# ADR 0001: Initial Architecture and Infrastructure-as-Code Strategy

## Status
Accepted

## Context
We are building a macOS-based AI assistant using OpenClaw as the runtime and Telegram as the primary interface. The assistant will operate on Apple Silicon Mac minis and have extensive capabilities including terminal access, filesystem manipulation, and browser automation. Because of the high privileges required, we need a reliable, repeatable, and secure way to deploy and manage this system across multiple machines.

## Decision
1. **Infrastructure-as-Code (IaC)**: The entire configuration, skills, and security policies will be managed in a Git repository.
2. **Machine Profiles**: The bootstrap process will support parameterized machine profiles to allow different configurations (e.g., personal vs. company use) from the same codebase.
3. **Strict Separation of State**: The repository will only contain portable configurations. All secrets, runtime state, and browser data will be strictly machine-local and ignored by Git.
4. **Idempotent Bootstrapping**: We will use an idempotent shell script (`bootstrap.sh`) as the primary entry point to set up a new machine from scratch.

## Consequences
- **Positive**: 
  - Easy to recover a machine or provision a new one.
  - Transparent audit trail of skills and security policies.
  - Development and testing of agent behaviors can happen in a version-controlled environment.
- **Negative**:
  - Requires maintaining custom bootstrap scripts instead of relying solely on standard package managers.
  - Secrets management relies on out-of-band delivery (manual entry or local secrets manager) which adds a step to the initial setup.
