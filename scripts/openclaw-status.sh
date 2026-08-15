#!/usr/bin/env bash
# scripts/openclaw-status.sh
# Show the current status of the OpenClaw Gateway.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

if ! command -v openclaw >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} openclaw not found. Run: ./scripts/install-openclaw.sh" >&2
    exit 1
fi

echo "=== OpenClaw Gateway Status ==="
openclaw gateway status || echo -e "${YELLOW}[WARN]${NC} Gateway does not appear to be running."

echo ""
echo "=== Daemon (LaunchAgent) ==="
if launchctl list | grep -q "ai.openclaw.gateway" 2>/dev/null; then
    echo -e "${GREEN}✓ LaunchAgent registered${NC}"
    launchctl list ai.openclaw.gateway 2>/dev/null || true
else
    echo -e "${YELLOW}⚠ LaunchAgent not installed${NC}"
    echo "  Install with: openclaw onboard --install-daemon"
fi
