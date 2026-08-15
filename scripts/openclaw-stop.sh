#!/usr/bin/env bash
# scripts/openclaw-stop.sh
# Stop the OpenClaw Gateway.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[0;33m'; RED='\033[0;31m'; NC='\033[0m'

if ! command -v openclaw >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} openclaw not found." >&2
    exit 1
fi

if launchctl list | grep -q "ai.openclaw.gateway" 2>/dev/null; then
    echo -e "${GREEN}[INFO]${NC} Stopping OpenClaw LaunchAgent daemon..."
    launchctl stop ai.openclaw.gateway
    echo -e "${GREEN}[OK]${NC}   Gateway stopped."
else
    echo -e "${YELLOW}[WARN]${NC} LaunchAgent not found. Attempting gateway stop..."
    openclaw gateway stop || echo -e "${YELLOW}[WARN]${NC} Gateway may not have been running."
fi
