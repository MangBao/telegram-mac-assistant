#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "=== Telegram Mac Assistant Doctor ==="

# 1. OS & Architecture
if [ "$(uname -s)" == "Darwin" ]; then
    echo -e "${GREEN}✓ macOS${NC}"
else
    echo -e "${RED}✗ Not macOS${NC}"
fi

if [ "$(uname -m)" == "arm64" ]; then
    echo -e "${GREEN}✓ Apple Silicon${NC}"
else
    echo -e "${YELLOW}⚠ Not Apple Silicon ($(uname -m))${NC}"
fi

# 2. Hardware limits
RAM_GB=$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))
if [ "$RAM_GB" -ge 8 ]; then
    echo -e "${GREEN}✓ RAM: ${RAM_GB}GB${NC}"
else
    echo -e "${YELLOW}⚠ RAM: ${RAM_GB}GB (8GB+ recommended)${NC}"
fi

FREE_DISK=$(df -g "$HOME" | awk 'NR==2 {print $4}')
if [ "$FREE_DISK" -ge 10 ]; then
    echo -e "${GREEN}✓ Disk Space: ${FREE_DISK}GB free${NC}"
else
    echo -e "${YELLOW}⚠ Disk Space: ${FREE_DISK}GB free (10GB+ recommended)${NC}"
fi

# 3. Binaries
if command -v brew >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Homebrew ($(brew --version | head -n1))${NC}"
else
    echo -e "${RED}✗ Homebrew missing${NC}"
fi

if command -v git >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Git ($(git --version | awk '{print $3}'))${NC}"
else
    echo -e "${RED}✗ Git missing${NC}"
fi

if command -v node >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Node ($(node -v))${NC}"
else
    echo -e "${RED}✗ Node missing${NC}"
fi

if command -v python3 >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Python ($(python3 --version | awk '{print $2}'))${NC}"
else
    echo -e "${RED}✗ Python missing${NC}"
fi

# 4. Workspace & Repository
WORKSPACE="$HOME/AI-Workspace"
if [ -d "$WORKSPACE" ] && [ -d "$WORKSPACE/projects" ]; then
    echo -e "${GREEN}✓ Workspace initialized ($WORKSPACE)${NC}"
else
    echo -e "${RED}✗ Workspace not initialized properly${NC}"
fi

if [ -d ".git" ]; then
    echo -e "${GREEN}✓ Repository structure intact${NC}"
else
    echo -e "${RED}✗ Not run from repository root${NC}"
fi

# 5. OpenClaw CLI
echo ""
echo "=== OpenClaw Runtime ==="
if command -v openclaw >/dev/null 2>&1; then
    echo -e "${GREEN}✓ OpenClaw CLI installed ($(openclaw --version 2>/dev/null || echo 'version unknown'))${NC}"
else
    echo -e "${RED}✗ OpenClaw CLI not installed${NC}"
    echo "  Run: ./scripts/install-openclaw.sh"
fi

# 6. Config file
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
if [ -f "$CONFIG_PATH" ]; then
    if [ -L "$CONFIG_PATH" ]; then
        echo -e "${RED}✗ Config is a symlink (NOT supported by OpenClaw): $CONFIG_PATH${NC}"
    else
        echo -e "${GREEN}✓ Config (regular file): $CONFIG_PATH${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Config not found at $CONFIG_PATH${NC}"
    echo "  Render with: ./scripts/render-config.sh"
fi

# 7. .env secrets file
ENV_FILE="$HOME/.openclaw/.env"
if [ -f "$ENV_FILE" ]; then
    echo -e "${GREEN}✓ .env file: $ENV_FILE${NC}"
else
    echo -e "${YELLOW}⚠ .env missing: $ENV_FILE${NC}"
    echo "  Create from: cp config/.env.example ~/.openclaw/.env"
fi

# 8. Daemon (LaunchAgent)
if launchctl list | grep -q "ai.openclaw.gateway" 2>/dev/null; then
    echo -e "${GREEN}✓ LaunchAgent registered${NC}"
else
    echo -e "${YELLOW}⚠ LaunchAgent not installed${NC}"
    echo "  Install after onboarding: openclaw gateway install"
fi

# 9. Permissions (heuristic/safe check)
echo -e "\n=== macOS Permissions Status ==="
echo "Note: Cannot securely automate TCC check without root/entitlements."
echo "Please verify the following manually in System Settings > Privacy & Security:"
echo -e "${YELLOW}⚠ Accessibility: Check if Terminal/OpenClaw is enabled.${NC}"
echo -e "${YELLOW}⚠ Screen Recording: Check if Terminal/OpenClaw is enabled.${NC}"
echo -e "${YELLOW}⚠ Full Disk Access: Only grant if explicitly needed.${NC}"
echo ""
echo "See: docs/macos-permissions.md"
