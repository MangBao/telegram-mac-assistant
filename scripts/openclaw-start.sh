#!/usr/bin/env bash
# scripts/openclaw-start.sh
# Start the OpenClaw Gateway.
# Uses the daemon (LaunchAgent) if installed; otherwise starts in foreground.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

if ! command -v openclaw >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} openclaw not found. Run: ./scripts/install-openclaw.sh" >&2
    exit 1
fi

# Try daemon first (installed via openclaw onboard --install-daemon)
if launchctl list | grep -q "ai.openclaw.gateway" 2>/dev/null; then
    echo -e "${GREEN}[INFO]${NC} Starting OpenClaw LaunchAgent daemon..."
    launchctl start ai.openclaw.gateway
    sleep 2
    openclaw gateway status
else
    echo -e "${YELLOW}[WARN]${NC} LaunchAgent not installed. Starting in foreground (Ctrl+C to stop)."
    echo -e "${YELLOW}[WARN]${NC} Install daemon permanently with: openclaw gateway install"
    openclaw gateway start
fi
