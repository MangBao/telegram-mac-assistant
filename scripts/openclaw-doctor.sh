#!/usr/bin/env bash
# scripts/openclaw-doctor.sh
# Run OpenClaw's built-in doctor and extend it with repository-level checks.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
fail() { echo -e "${RED}✗${NC} $*"; }
info() { echo -e "${BLUE}[INFO]${NC} $*"; }

echo "=== OpenClaw Doctor (Phase 2) ==="
echo ""

# 1. OpenClaw CLI installed
if command -v openclaw >/dev/null 2>&1; then
    ok "OpenClaw CLI: $(openclaw --version 2>/dev/null || echo 'installed')"
else
    fail "OpenClaw CLI not installed. Run: ./scripts/install-openclaw.sh"
fi

# 2. Official OpenClaw doctor
echo ""
echo "--- Official 'openclaw doctor' ---"
if command -v openclaw >/dev/null 2>&1; then
    openclaw doctor 2>&1 || warn "openclaw doctor reported issues (see above)"
else
    warn "Skipped (openclaw not installed)"
fi

# 3. Gateway reachable on localhost
echo ""
echo "--- Gateway health ---"
GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
if curl -s --max-time 2 "http://127.0.0.1:${GATEWAY_PORT}/health" >/dev/null 2>&1; then
    ok "Gateway is reachable at http://127.0.0.1:${GATEWAY_PORT}"
else
    warn "Gateway not reachable at http://127.0.0.1:${GATEWAY_PORT}"
    info "Start with: ./scripts/openclaw-start.sh"
fi

# 4. Config file
echo ""
echo "--- Config ---"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
if [ -f "$CONFIG_PATH" ]; then
    # Verify it's a regular file (not a symlink — docs requirement)
    if [ -L "$CONFIG_PATH" ]; then
        fail "Config at $CONFIG_PATH is a symlink. Official docs require a regular file."
        info "Fix: remove symlink and copy template: scripts/render-config.sh"
    else
        ok "Config is a regular file: $CONFIG_PATH"
    fi
    # Check for unfilled placeholder tokens
    if grep -q 'your-.*-here\|YOUR_NUMERIC_USER_ID\|REPLACE_ME' "$CONFIG_PATH" 2>/dev/null; then
        warn "Config may contain unfilled placeholders. Review $CONFIG_PATH"
    fi
else
    warn "Config not found at $CONFIG_PATH"
    info "Render from template: ./scripts/render-config.sh"
fi

# 5. .env file (machine-local secrets)
ENV_FILE="$HOME/.openclaw/.env"
if [ -f "$ENV_FILE" ]; then
    ok ".env file exists: $ENV_FILE"
    # Check for unfilled placeholder values
    if grep -qE 'your-.*-here|placeholder|REPLACE_ME' "$ENV_FILE" 2>/dev/null; then
        warn ".env contains placeholder values — fill in your actual secrets."
    fi
else
    warn ".env not found at $ENV_FILE"
    info "Create from template: cp config/.env.example ~/.openclaw/.env"
fi

# 6. Workspace
WORKSPACE="$HOME/AI-Workspace"
if [ -d "$WORKSPACE" ] && [ -d "$WORKSPACE/projects" ]; then
    ok "Workspace initialized: $WORKSPACE"
else
    warn "Workspace missing or incomplete: $WORKSPACE"
    info "Run: ./bootstrap.sh"
fi

# 7. Daemon (LaunchAgent)
echo ""
echo "--- Daemon (LaunchAgent) ---"
if launchctl list | grep -q "ai.openclaw.gateway" 2>/dev/null; then
    ok "LaunchAgent is registered"
else
    warn "LaunchAgent not installed"
    info "Install after onboarding: openclaw gateway install"
fi

# 8. Secret leakage check (ensure no secrets in repo)
echo ""
echo "--- Secret leakage check ---"
LEAK_FOUND=0
for pattern in 'sk-[a-zA-Z0-9]' 'AAAA[a-zA-Z0-9]' 'ghp_' 'xoxb-' 'tgp_\|bot[0-9].*:AA'; do
    if git -C "$(git rev-parse --show-toplevel 2>/dev/null || echo '.')" grep -rq "$pattern" \
        --exclude-dir=".git" 2>/dev/null; then
        fail "Possible secret pattern found in repo: $pattern"
        LEAK_FOUND=1
    fi
done
if [ "$LEAK_FOUND" -eq 0 ]; then
    ok "No obvious secret patterns detected in tracked files"
fi

# 9. macOS permissions (informational only — cannot automate)
echo ""
echo "--- macOS Permissions (manual verification required) ---"
warn "Accessibility: Verify Terminal/OpenClaw is allowed in System Settings > Privacy"
warn "Screen Recording: Verify Terminal/OpenClaw is allowed in System Settings > Privacy"
warn "Full Disk Access: Only grant if explicitly needed"
echo ""
echo "See: docs/macos-permissions.md for details"

echo ""
echo "=== Doctor complete ==="
