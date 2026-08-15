#!/usr/bin/env bash
# scripts/render-config.sh
# Render the OpenClaw config template for a given machine profile.
#
# This script copies config/openclaw/openclaw.example.json5 to
# ~/.openclaw/openclaw.json as a regular file (NOT a symlink).
# Per official OpenClaw docs, symlinked configs are NOT supported.
# OPENCLAW_CONFIG_PATH is set automatically if not already set.
#
# Usage: ./scripts/render-config.sh [profile]
#   profile: optional, defaults to "personal-mac"
#
# Prerequisites:
#   - ~/.openclaw/.env must exist with real secrets filled in
#   - Run this BEFORE starting the OpenClaw daemon

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

PROFILE="${1:-personal-mac}"
TEMPLATE="config/openclaw/openclaw.example.json5"
DEST_DIR="$HOME/.openclaw"
DEST_FILE="$DEST_DIR/openclaw.json"
ENV_FILE="$DEST_DIR/.env"

# Check we're in the repo root
if [ ! -f "$TEMPLATE" ]; then
    error "Template not found: $TEMPLATE"
    error "Run this script from the repository root."
    exit 1
fi

# Check env file exists
if [ ! -f "$ENV_FILE" ]; then
    warn "$ENV_FILE does not exist."
    warn "Create it from config/.env.example and fill in your secrets:"
    warn "  mkdir -p ~/.openclaw && cp config/.env.example ~/.openclaw/.env"
    warn "  # Edit ~/.openclaw/.env with your real values"
    exit 1
fi

# Ensure destination directory exists
mkdir -p "$DEST_DIR"

# Copy template as a plain regular file (no symlinks — official docs requirement)
cp "$TEMPLATE" "$DEST_FILE"
success "Config template copied to $DEST_FILE"

# Remind about OPENCLAW_CONFIG_PATH
info ""
info "IMPORTANT: OpenClaw reads config from ~/.openclaw/openclaw.json by default."
info "If you've customized the config path, set:"
info "  export OPENCLAW_CONFIG_PATH=$DEST_FILE"
info ""
info "Your ~/.openclaw/.env is read automatically by OpenClaw."
info ""
info "Next step: run interactive onboarding (once only):"
info "  openclaw onboard --install-daemon"
info ""
warn "Review $DEST_FILE — replace placeholder comments with your actual settings."
