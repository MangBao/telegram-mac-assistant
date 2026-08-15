#!/usr/bin/env bash
# scripts/telegram-health.sh
# Telegram channel health check for OpenClaw Gateway.
#
# Checks:
#   1. TELEGRAM_BOT_TOKEN set in ~/.openclaw/.env (value NEVER printed)
#   2. TELEGRAM_OWNER_ID set in ~/.openclaw/.env
#   3. Config has channels.telegram.enabled
#   4. Config has dmPolicy set (not "open")
#   5. Config does NOT have a "groups" key (groups blocked in Phase 3)
#   6. OpenClaw Gateway is running and reachable
#   7. No token appears in any tracked Git file
#
# Usage: ./scripts/telegram-health.sh

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[⚠]${NC} $*"; }
fail() { echo -e "${RED}[✗]${NC} $*"; FAILED=$((FAILED+1)); }
info() { echo -e "${BLUE}[i]${NC} $*"; }

FAILED=0
ENV_FILE="$HOME/.openclaw/.env"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"

echo "=== Telegram Channel Health Check ==="
echo ""

# ── 1. Token presence (NEVER print value) ────────────────────────────────────

echo "--- Secrets ---"
if [ -f "$ENV_FILE" ]; then
    if grep -q "^TELEGRAM_BOT_TOKEN=.\+" "$ENV_FILE" 2>/dev/null; then
        ok "TELEGRAM_BOT_TOKEN: [SET] (value hidden)"
    else
        fail "TELEGRAM_BOT_TOKEN: [NOT SET] or empty in $ENV_FILE"
        warn "Add: TELEGRAM_BOT_TOKEN=<your_token> to $ENV_FILE"
    fi

    if grep -q "^TELEGRAM_OWNER_ID=.\+" "$ENV_FILE" 2>/dev/null; then
        ok "TELEGRAM_OWNER_ID: [SET] (value hidden)"
    else
        warn "TELEGRAM_OWNER_ID: [NOT SET] in $ENV_FILE"
        info "Set after pairing. See docs/telegram-setup.md §3 for how to find your ID."
    fi
else
    fail "~/.openclaw/.env not found"
    info "Create from template: cp config/.env.example ~/.openclaw/.env"
fi

# ── 2. Config file ────────────────────────────────────────────────────────────

echo ""
echo "--- Config ---"
if [ ! -f "$CONFIG_PATH" ]; then
    fail "Config not found at $CONFIG_PATH"
    info "Render from template: ./scripts/render-config.sh"
else
    if [ -L "$CONFIG_PATH" ]; then
        fail "Config is a symlink (not supported by OpenClaw)"
    else
        ok "Config is a regular file: $CONFIG_PATH"
    fi

    # Check Telegram enabled
    if grep -q '"enabled"[[:space:]]*:[[:space:]]*true\|enabled: true' "$CONFIG_PATH" 2>/dev/null; then
        ok "Telegram: enabled: true found in config"
    else
        warn "Telegram may not be explicitly enabled in config"
    fi

    # Check dmPolicy is set and not "open"
    if grep -q 'dmPolicy' "$CONFIG_PATH" 2>/dev/null; then
        if grep -q '"dmPolicy"[[:space:]]*:[[:space:]]*"open"\|dmPolicy: "open"' "$CONFIG_PATH" 2>/dev/null; then
            fail "dmPolicy: \"open\" — INSECURE for single-owner bot. Use \"allowlist\"."
        elif grep -q '"dmPolicy"[[:space:]]*:[[:space:]]*"allowlist"\|dmPolicy: "allowlist"' "$CONFIG_PATH" 2>/dev/null; then
            ok "dmPolicy: \"allowlist\" (most secure for single-owner)"
        elif grep -q '"dmPolicy"[[:space:]]*:[[:space:]]*"pairing"\|dmPolicy: "pairing"' "$CONFIG_PATH" 2>/dev/null; then
            ok "dmPolicy: \"pairing\" (safe for initial setup)"
            warn "Switch to \"allowlist\" after pairing. See docs/telegram-setup.md §4."
        else
            warn "dmPolicy not found or unrecognized value"
        fi
    else
        warn "dmPolicy not set in config (OpenClaw defaults to \"pairing\")"
    fi

    # Check groups NOT present (Phase 3: groups must be blocked)
    if grep -qE '"groups"[[:space:]]*:|groups:' "$CONFIG_PATH" 2>/dev/null; then
        warn "\"groups\" key found in config — ensure group access is intentionally configured"
        info "Phase 3 goal: no groups. Remove \"groups\" key to block all group chats."
    else
        ok "No \"groups\" key in config (all group chats blocked — correct for Phase 3)"
    fi

    # Check botToken uses env var substitution, not a hardcoded value
    if grep -qE 'botToken[[:space:]]*:[[:space:]]*"\$\{TELEGRAM' "$CONFIG_PATH" 2>/dev/null; then
        ok "botToken uses \${ENV_VAR} substitution (not hardcoded)"
    elif grep -qE 'botToken[[:space:]]*:[[:space:]]*"[0-9]{8,12}:' "$CONFIG_PATH" 2>/dev/null; then
        fail "botToken appears to contain a HARDCODED token! Remove immediately."
    else
        warn "botToken not found in config or uses unexpected format"
        info "Expected: botToken: \"\${TELEGRAM_BOT_TOKEN}\""
    fi
fi

# ── 3. Gateway running ────────────────────────────────────────────────────────

echo ""
echo "--- Gateway ---"
if command -v openclaw >/dev/null 2>&1; then
    ok "OpenClaw CLI available: $(openclaw --version 2>/dev/null || echo 'installed')"

    GATEWAY_PORT="${OPENCLAW_GATEWAY_PORT:-18789}"
    if curl -s --max-time 2 "http://127.0.0.1:${GATEWAY_PORT}/health" >/dev/null 2>&1; then
        ok "Gateway is reachable at http://127.0.0.1:${GATEWAY_PORT}"

        # Try to get channel status
        if openclaw channels status telegram >/dev/null 2>&1; then
            ok "Telegram channel: connected"
        else
            warn "Could not verify Telegram channel status (gateway may need a moment)"
            info "Run: openclaw channels status telegram"
        fi
    else
        warn "Gateway not reachable at http://127.0.0.1:${GATEWAY_PORT}"
        info "Start with: ./scripts/openclaw-start.sh"
    fi
else
    warn "OpenClaw CLI not installed"
    info "Install with: ./scripts/install-openclaw.sh"
fi

# ── 4. Secret leakage check ───────────────────────────────────────────────────

echo ""
echo "--- Secret Leakage (Git tracked files) ---"
# Check for Telegram bot token pattern in tracked files
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo '.')"
if git -C "$REPO_ROOT" grep -rqE "[0-9]{8,12}:AA[a-zA-Z0-9_-]{33}" \
    --include="*.sh" --include="*.json5" --include="*.yaml" \
    --include="*.json" --include="*.md" 2>/dev/null; then
    fail "Possible Telegram bot token found in tracked files!"
    git -C "$REPO_ROOT" grep -rnE "[0-9]{8,12}:AA[a-zA-Z0-9_-]{33}" \
        --include="*.sh" --include="*.json5" --include="*.yaml" \
        --include="*.json" --include="*.md" 2>/dev/null || true
else
    ok "No Telegram bot token pattern in tracked files"
fi

# Check placeholder text is correct
if git -C "$REPO_ROOT" grep -rq '\${TELEGRAM_BOT_TOKEN}' \
    --include="*.json5" 2>/dev/null; then
    ok "Config templates use \${TELEGRAM_BOT_TOKEN} placeholder (correct)"
fi

# ── 5. Summary ────────────────────────────────────────────────────────────────

echo ""
if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}=== Health check passed (${FAILED} failures) ===${NC}"
    echo ""
    echo "Next steps if Telegram is not yet configured:"
    echo "  1. Fill in ~/.openclaw/.env (see config/.env.example)"
    echo "  2. ./scripts/render-config.sh"
    echo "  3. ./scripts/openclaw-start.sh"
    echo "  4. DM your bot /start → approve pairing"
    echo "  5. See docs/telegram-setup.md for full setup guide"
else
    echo -e "${RED}=== Health check FAILED (${FAILED} issue(s) above) ===${NC}"
    echo "Fix the issues above and re-run: ./scripts/telegram-health.sh"
    exit 1
fi
