#!/usr/bin/env bash
# bootstrap.sh — Idempotent environment setup for telegram-mac-assistant
#
# Usage:
#   ./bootstrap.sh [profile] [--enable-telegram]
#
#   profile:           optional, defaults to "personal-mac"
#   --enable-telegram: optional, enables Telegram setup guidance
#
# Fresh install WITHOUT Telegram (default):
#   ./bootstrap.sh
#
# With Telegram guidance:
#   ./bootstrap.sh --enable-telegram
#   ./bootstrap.sh company-mac-mini --enable-telegram

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# Parse arguments
PROFILE="personal-mac"
ENABLE_TELEGRAM=false

for arg in "$@"; do
    case "$arg" in
        --enable-telegram) ENABLE_TELEGRAM=true ;;
        --*)
            error "Unknown flag: $arg"
            echo "Usage: $0 [profile] [--enable-telegram]"
            exit 1
            ;;
        *) PROFILE="$arg" ;;
    esac
done

echo ""
echo -e "${GREEN}=== Telegram Mac Assistant Bootstrap ===${NC}"
echo ""

# 1. Environment Detection
info "Detecting environment..."
OS=$(uname -s)
if [ "$OS" != "Darwin" ]; then
    error "This project currently only supports macOS."
    exit 1
fi

ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    success "Apple Silicon detected."
else
    warn "Intel Mac detected. Apple Silicon is recommended."
fi

# 2. Check Prerequisites
fail_missing() {
    error "Missing required dependency: $1"
    exit 1
}

info "Checking prerequisites..."
command -v brew >/dev/null 2>&1 || fail_missing "Homebrew (Install from https://brew.sh)"
command -v git  >/dev/null 2>&1 || fail_missing "Git"
command -v node >/dev/null 2>&1 || fail_missing "Node.js (v22+ recommended)"
command -v python3 >/dev/null 2>&1 || fail_missing "Python 3"

success "All basic prerequisites found."
info "Shell: $SHELL"

# 3. Handle Profiles
PROFILE_DIR="profiles/$PROFILE"
if [ ! -d "$PROFILE_DIR" ]; then
    error "Profile '$PROFILE' not found in profiles/ directory."
    exit 1
fi
success "Using profile: $PROFILE"

# 4. Workspace Initialization (idempotent)
WORKSPACE="$HOME/AI-Workspace"
info "Initializing workspace at $WORKSPACE..."

mkdir -p "$WORKSPACE"
mkdir -p "$WORKSPACE/projects"
mkdir -p "$WORKSPACE/documents"
mkdir -p "$WORKSPACE/downloads"
mkdir -p "$WORKSPACE/scratch"
mkdir -p "$WORKSPACE/logs"

success "Workspace directories created/verified."

# Validate disk space
FREE_DISK=$(df -g "$HOME" | awk 'NR==2 {print $4}')
if [ "$FREE_DISK" -lt 5 ]; then
    warn "Less than 5GB of free disk space available (${FREE_DISK}GB)."
else
    success "Disk space sufficient (${FREE_DISK}GB free)."
fi

# 5. OpenClaw runtime directory (machine-local, not in Git)
OPENCLAW_DIR="$HOME/.openclaw"
mkdir -p "$OPENCLAW_DIR"
success "OpenClaw runtime directory: $OPENCLAW_DIR"

# 6. Telegram Setup (optional — only with --enable-telegram)
echo ""
if [ "$ENABLE_TELEGRAM" = "true" ]; then
    echo "=== Telegram Setup ==="
    echo ""

    ENV_FILE="$OPENCLAW_DIR/.env"
    CONFIG_FILE="$OPENCLAW_DIR/openclaw.json"

    # 6a. .env file
    if [ -f "$ENV_FILE" ]; then
        success ".env file exists: $ENV_FILE"
        # Check token is set (NEVER print value)
        if grep -q "^TELEGRAM_BOT_TOKEN=.\+" "$ENV_FILE" 2>/dev/null; then
            success "TELEGRAM_BOT_TOKEN: [SET]"
        else
            warn "TELEGRAM_BOT_TOKEN: [NOT SET] in $ENV_FILE"
            warn "Edit $ENV_FILE and add your bot token."
            warn "See docs/telegram-setup.md for instructions."
        fi
    else
        warn ".env not found. Creating from template..."
        cp config/.env.example "$ENV_FILE"
        success "Created $ENV_FILE — please fill in your secrets."
        warn "Open $ENV_FILE and replace placeholder values."
        warn "See docs/telegram-setup.md for where to get credentials."
    fi

    # 6b. Config file
    if [ -f "$CONFIG_FILE" ]; then
        if [ -L "$CONFIG_FILE" ]; then
            error "Config at $CONFIG_FILE is a symlink — not supported by OpenClaw."
            error "Remove symlink and run: ./scripts/render-config.sh"
        else
            success "OpenClaw config: $CONFIG_FILE"
        fi
    else
        info "Rendering config template to $CONFIG_FILE..."
        ./scripts/render-config.sh "$PROFILE" 2>/dev/null || true
    fi

    echo ""
    echo "=== Telegram Next Steps ==="
    echo ""
    echo "  1. Fill in ~/.openclaw/.env with real secrets"
    echo "  2. Install OpenClaw CLI (if not yet): ./scripts/install-openclaw.sh"
    echo "  3. Start Gateway: ./scripts/openclaw-start.sh"
    echo "  4. DM your bot /start → receive pairing code"
    echo "  5. Approve: openclaw pairing approve telegram <CODE>"
    echo "  6. Run health check: ./scripts/telegram-health.sh"
    echo "  7. See: docs/telegram-setup.md for full setup guide"
    echo ""
else
    info "Telegram setup skipped (use --enable-telegram to include)."
    info "  Example: ./bootstrap.sh $PROFILE --enable-telegram"
fi

# 7. Final summary
echo ""
success "Bootstrap completed successfully!"
echo ""
echo "Next steps:"
echo "  ./scripts/doctor.sh          — system health check"
echo "  ./scripts/install-openclaw.sh — install OpenClaw CLI"
if [ "$ENABLE_TELEGRAM" = "false" ]; then
    echo "  ./bootstrap.sh $PROFILE --enable-telegram — add Telegram setup"
fi
echo ""
