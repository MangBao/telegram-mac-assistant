#!/usr/bin/env bash
# tests/test_phase2.sh
# Automated tests for Phase 2: OpenClaw runtime configuration.
# Tests verify file existence, permissions, and policy compliance.
# Does NOT start the daemon or require secrets.

set -euo pipefail

PASS=0
FAIL=0

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}[PASS]${NC} $*"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAIL=$((FAIL+1)); }
skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; }

# Ensure we are in the repository root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== Phase 2 Tests: OpenClaw Runtime ==="
echo ""

# ── File existence ─────────────────────────────────────────────────────────

echo "--- Required Files ---"
required_files=(
    "scripts/install-openclaw.sh"
    "scripts/render-config.sh"
    "scripts/openclaw-start.sh"
    "scripts/openclaw-stop.sh"
    "scripts/openclaw-status.sh"
    "scripts/openclaw-doctor.sh"
    "config/openclaw/openclaw.example.json5"
    "config/.env.example"
    "policies/openclaw-tools.md"
    "policies/filesystem.md"
    "policies/telegram.md"
    "policies/command-execution.md"
    "docs/macos-permissions.md"
)

for f in "${required_files[@]}"; do
    if [ -f "$f" ]; then
        pass "File exists: $f"
    else
        fail "Missing file: $f"
    fi
done

# ── Script executability ───────────────────────────────────────────────────

echo ""
echo "--- Script Permissions ---"
executable_scripts=(
    "scripts/install-openclaw.sh"
    "scripts/render-config.sh"
    "scripts/openclaw-start.sh"
    "scripts/openclaw-stop.sh"
    "scripts/openclaw-status.sh"
    "scripts/openclaw-doctor.sh"
)

for s in "${executable_scripts[@]}"; do
    if [ -x "$s" ]; then
        pass "Executable: $s"
    else
        fail "Not executable (run: chmod +x $s): $s"
    fi
done

# ── No secrets in tracked files ────────────────────────────────────────────

echo ""
echo "--- Secret Leakage Check ---"

# Check for common secret patterns
LEAK=0
# API key patterns (broad)
if grep -rE \
    "sk-[a-zA-Z0-9]{20,}|AAAA[a-zA-Z0-9_-]{20,}|ghp_[a-zA-Z0-9]{36}|xoxb-[0-9]+-" \
    --include="*.sh" --include="*.json5" --include="*.yaml" \
    --include="*.json" --include="*.env" \
    --exclude-dir=".git" \
    . 2>/dev/null; then
    fail "Possible real API key found in repository (see above)."
    LEAK=1
fi

# Bot token pattern (Telegram: digits:alpha)
if grep -rE "[0-9]{8,12}:AA[a-zA-Z0-9_-]{33}" \
    --include="*.sh" --include="*.json5" --include="*.yaml" \
    --include="*.json" --include="*.env" \
    --exclude-dir=".git" \
    . 2>/dev/null; then
    fail "Possible Telegram bot token found in repository."
    LEAK=1
fi

if [ "$LEAK" -eq 0 ]; then
    pass "No obvious secret patterns in tracked files."
fi

# ── No symlink config ──────────────────────────────────────────────────────

echo ""
echo "--- Config Compliance ---"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$HOME/.openclaw/openclaw.json}"
if [ -L "$CONFIG_PATH" ]; then
    fail "Config at $CONFIG_PATH is a symlink — NOT supported by OpenClaw official docs."
elif [ -f "$CONFIG_PATH" ]; then
    pass "Config is a regular file: $CONFIG_PATH"
else
    skip "Config not yet rendered at $CONFIG_PATH (not required for test suite)"
fi

# Template has ${VAR} placeholders — no hardcoded secrets
if grep -q 'your-.*-here\b' "config/openclaw/openclaw.example.json5"; then
    fail "Template contains 'your-...-here' placeholder — use \${VAR} style instead."
elif grep -qE '\$\{[A-Z_]+\}' "config/openclaw/openclaw.example.json5"; then
    pass "Config template uses \${ENV_VAR} placeholders (no hardcoded secrets)."
else
    pass "Config template looks clean."
fi

# .env.example must not have real keys
if grep -qE \
    "sk-[a-zA-Z0-9]{20,}|[0-9]{8,12}:AA[a-zA-Z0-9_-]{33}" \
    "config/.env.example"; then
    fail "config/.env.example contains what looks like a real secret!"
else
    pass "config/.env.example contains only placeholder values."
fi

# ── No symlink in .openclaw dir (if it exists) ─────────────────────────────

echo ""
echo "--- Workspace ---"
if [ -d "$HOME/AI-Workspace" ]; then
    pass "Workspace exists: ~/AI-Workspace"
else
    skip "Workspace ~/AI-Workspace not created yet (run ./bootstrap.sh)"
fi

# ── .gitignore coverage ────────────────────────────────────────────────────

echo ""
echo "--- .gitignore Checks ---"
GITIGNORE=".gitignore"
required_patterns=(
    ".env"
    ".env.*"
    "runtime/"
    "credentials/"
)
for p in "${required_patterns[@]}"; do
    if grep -qF "$p" "$GITIGNORE"; then
        pass ".gitignore covers: $p"
    else
        fail ".gitignore missing pattern: $p"
    fi
done

# ── Summary ────────────────────────────────────────────────────────────────

echo ""
echo "=============================="
echo " Phase 2 Results: PASS=$PASS  FAIL=$FAIL"
echo "=============================="
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Some tests failed. Fix issues above before continuing.${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
