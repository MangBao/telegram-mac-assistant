#!/usr/bin/env bash
# tests/test_phase3.sh
# Automated test suite for Phase 3: Telegram MVP.
# Tests are offline — no Gateway, no network, no secrets required.

set -euo pipefail

PASS=0
FAIL=0
SKIP=0

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
pass() { echo -e "${GREEN}[PASS]${NC} $*"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}[FAIL]${NC} $*"; FAIL=$((FAIL+1)); }
skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; SKIP=$((SKIP+1)); }

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== Phase 3 Tests: Telegram MVP ==="
echo ""

# ── 1. Required files exist ────────────────────────────────────────────────────

echo "--- Required Files ---"
required_files=(
    "docs/telegram-setup.md"
    "config/examples/telegram.example.json5"
    "agents/system-prompt.md"
    "policies/command-execution.md"
    "policies/audit-log.md"
    "scripts/telegram-health.sh"
    "scripts/audit-log.sh"
)
for f in "${required_files[@]}"; do
    if [ -f "$f" ]; then
        pass "File exists: $f"
    else
        fail "Missing file: $f"
    fi
done

# ── 2. Scripts are executable ──────────────────────────────────────────────────

echo ""
echo "--- Script Permissions ---"
executable_scripts=(
    "scripts/telegram-health.sh"
    "scripts/audit-log.sh"
)
for s in "${executable_scripts[@]}"; do
    if [ -x "$s" ]; then
        pass "Executable: $s"
    else
        fail "Not executable: $s (run: chmod +x $s)"
    fi
done

# ── 3. No real tokens in any tracked file ─────────────────────────────────────

echo ""
echo "--- Secret Leakage: Telegram Token ---"
# Telegram bot token pattern: 8-12 digits, colon, "AA", then 33 alphanumeric chars
LEAK=0
if git grep -rnE "[0-9]{8,12}:AA[a-zA-Z0-9_-]{33}" \
    --include="*.sh" --include="*.json5" --include="*.yaml" \
    --include="*.json" --include="*.md" --include="*.txt" \
    . 2>/dev/null; then
    fail "Possible Telegram bot token found in tracked files!"
    LEAK=1
fi
if [ "$LEAK" -eq 0 ]; then
    pass "No Telegram bot token pattern in tracked files"
fi

# ── 4. Token only as env var placeholder ──────────────────────────────────────

echo ""
echo "--- Config Template Correctness ---"
# Main config template: botToken must use ${...} substitution
if grep -qE 'botToken[[:space:]]*:[[:space:]]*"\$\{TELEGRAM_BOT_TOKEN\}"' \
    "config/openclaw/openclaw.example.json5"; then
    pass "Main template: botToken uses \${TELEGRAM_BOT_TOKEN} placeholder"
else
    fail "Main template: botToken not using \${TELEGRAM_BOT_TOKEN} substitution"
fi

# Telegram example config: botToken must use ${...}
if grep -qE 'botToken[[:space:]]*:[[:space:]]*"\$\{TELEGRAM_BOT_TOKEN\}"' \
    "config/examples/telegram.example.json5"; then
    pass "Telegram example: botToken uses \${TELEGRAM_BOT_TOKEN} placeholder"
else
    fail "Telegram example: botToken not using \${TELEGRAM_BOT_TOKEN} substitution"
fi

# ── 5. allowFrom has correct format (numeric or ${VAR}) ───────────────────────

echo ""
echo "--- allowFrom Config ---"
# Example must NOT use @username format
if grep -qE '"allowFrom"[[:space:]]*:[[:space:]]*\["@[a-z]' \
    "config/examples/telegram.example.json5"; then
    fail "allowFrom uses @username format — must use numeric user IDs"
else
    pass "allowFrom does not use @username format (correct)"
fi

# dmPolicy must not be "open"
if grep -qE 'dmPolicy[[:space:]]*:[[:space:]]*"open"' \
    "config/examples/telegram.example.json5"; then
    fail "Telegram example has dmPolicy: \"open\" — INSECURE"
else
    pass "Telegram example does not have dmPolicy: \"open\" (correct)"
fi

# ── 6. No "groups" key in Phase 3 config ──────────────────────────────────────

echo ""
echo "--- Groups Policy (Phase 3: blocked) ---"
# The main template should NOT have a "groups" key with active entries for Phase 3
# The example file should either omit groups or explicitly show them as blocked

# Check main config template has no active groups
if ! grep -qE '^[[:space:]]*groups:' \
    "config/openclaw/openclaw.example.json5"; then
    pass "Main config template: no 'groups' key (groups blocked by default)"
else
    fail "Main config template has 'groups' key — groups should be blocked in Phase 3"
fi

# ── 7. READ-only tools.deny present ───────────────────────────────────────────

echo ""
echo "--- Permission Policy ---"
for denied_tool in "write" "edit" "delete" "exec"; do
    if grep -q "\"$denied_tool\"" "config/openclaw/openclaw.example.json5" || \
       grep -q "\"$denied_tool\"" "config/examples/telegram.example.json5"; then
        pass "tools.deny includes: \"$denied_tool\""
    else
        fail "tools.deny missing: \"$denied_tool\" — Phase 3 should be READ-only"
    fi
done

# Permission levels in policies
if grep -q "READ" "policies/command-execution.md" && \
   grep -q "WRITE" "policies/command-execution.md" && \
   grep -q "EXECUTE" "policies/command-execution.md" && \
   grep -q "AUTOMATION" "policies/command-execution.md" && \
   grep -q "DESTRUCTIVE" "policies/command-execution.md"; then
    pass "All 5 permission levels defined in command-execution policy"
else
    fail "Not all permission levels defined in policies/command-execution.md"
fi

# ── 8. Audit log location inside workspace ────────────────────────────────────

echo ""
echo "--- Audit Log ---"
if grep -q 'AI-Workspace/logs' "scripts/audit-log.sh"; then
    pass "Audit log points to ~/AI-Workspace/logs (inside workspace)"
else
    fail "Audit log path not in ~/AI-Workspace/logs"
fi

if grep -q 'AI-Workspace/logs' "policies/audit-log.md"; then
    pass "Audit log policy documents ~/AI-Workspace/logs location"
else
    fail "Audit log policy missing log path documentation"
fi

# Verify MUST NOT LOG section exists
if grep -q "MUST NOT LOG" "policies/audit-log.md"; then
    pass "Audit log policy has MUST NOT LOG section"
else
    fail "Audit log policy missing MUST NOT LOG section"
fi

# ── 9. System prompt security ─────────────────────────────────────────────────

echo ""
echo "--- System Prompt ---"
# Should not contain hardcoded user IDs (numbers 8+ digits)
if grep -qE '[0-9]{8,}' "agents/system-prompt.md"; then
    fail "System prompt may contain hardcoded numeric user IDs"
else
    pass "System prompt: no hardcoded numeric user IDs"
fi

# Should not contain any token-like strings
if grep -qE '[A-Za-z0-9]{40,}' "agents/system-prompt.md"; then
    fail "System prompt may contain token-like strings (40+ char sequences)"
else
    pass "System prompt: no token-like strings"
fi

# Should mention READ-only or similar constraint
if grep -qiE "read.?only|READ level|cannot|CANNOT" "agents/system-prompt.md"; then
    pass "System prompt documents READ-only constraints"
else
    fail "System prompt missing READ-only constraint documentation"
fi

# ── 10. Bootstrap handles --enable-telegram ───────────────────────────────────

echo ""
echo "--- Bootstrap Telegram Flag ---"
if grep -q -- '--enable-telegram' "bootstrap.sh"; then
    pass "bootstrap.sh supports --enable-telegram flag"
else
    fail "bootstrap.sh missing --enable-telegram flag"
fi

# Bootstrap should NOT fail without Telegram configured
OUTPUT=$(bash bootstrap.sh 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ]; then
    pass "bootstrap.sh exits 0 without --enable-telegram (Telegram not required)"
else
    fail "bootstrap.sh fails without --enable-telegram (must be optional)"
fi

# Bootstrap with --enable-telegram should also succeed (just prints guidance)
OUTPUT=$(bash bootstrap.sh --enable-telegram 2>&1)
EXIT_CODE=$?
if [ "$EXIT_CODE" -eq 0 ]; then
    pass "bootstrap.sh --enable-telegram exits 0"
else
    fail "bootstrap.sh --enable-telegram fails unexpectedly"
fi

# ── 11. Telegram health script never prints token ─────────────────────────────

echo ""
echo "--- Health Check Safety ---"
# The health script must not use "echo $TELEGRAM_BOT_TOKEN" or equivalent
if grep -qE 'echo[[:space:]].*TELEGRAM_BOT_TOKEN|print.*TELEGRAM_BOT_TOKEN|cat.*TELEGRAM' \
    "scripts/telegram-health.sh"; then
    fail "telegram-health.sh may print the bot token — SECURITY ISSUE"
else
    pass "telegram-health.sh does not echo TELEGRAM_BOT_TOKEN"
fi

# Health script must show [SET] or [NOT SET] pattern (not the value)
if grep -q '\[SET\]' "scripts/telegram-health.sh"; then
    pass "telegram-health.sh uses [SET]/[NOT SET] pattern (no value exposed)"
else
    fail "telegram-health.sh missing [SET]/[NOT SET] token safety pattern"
fi

# ── 12. Telegram setup doc completeness ───────────────────────────────────────

echo ""
echo "--- Documentation ---"
required_sections=(
    "BotFather"
    "pairing"
    "allowlist"
    "allowFrom"
    "Revoke"
    "troubleshoot"
)
for section in "${required_sections[@]}"; do
    if grep -qi "$section" "docs/telegram-setup.md"; then
        pass "telegram-setup.md documents: $section"
    else
        fail "telegram-setup.md missing section: $section"
    fi
done

# Verify no real token examples in docs
if grep -qE "[0-9]{8,12}:AA[a-zA-Z0-9_-]{33}" "docs/telegram-setup.md"; then
    fail "telegram-setup.md contains a real-looking bot token!"
else
    pass "telegram-setup.md: no real bot token patterns"
fi

# ── 13. .env.example has required vars ───────────────────────────────────────

echo ""
echo "--- .env.example ---"
required_env_vars=("TELEGRAM_BOT_TOKEN" "TELEGRAM_OWNER_ID" "ANTHROPIC_API_KEY")
for var in "${required_env_vars[@]}"; do
    if grep -q "$var" "config/.env.example"; then
        pass ".env.example has placeholder: $var"
    else
        fail ".env.example missing: $var"
    fi
done

# ── Summary ────────────────────────────────────────────────────────────────────

echo ""
echo "=============================="
echo " Phase 3 Results: PASS=$PASS  FAIL=$FAIL  SKIP=$SKIP"
echo "=============================="
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Some tests failed. Fix issues above.${NC}"
    exit 1
else
    echo -e "${GREEN}All Phase 3 tests passed!${NC}"
    exit 0
fi
