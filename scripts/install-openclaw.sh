#!/usr/bin/env bash
# scripts/install-openclaw.sh
# Install OpenClaw CLI on macOS using the official npm package.
#
# IMPORTANT: This script only installs the CLI binary.
# Daemon setup and interactive onboarding (openclaw onboard) must be done manually
# because they require Telegram bot tokens, API keys, and macOS permission grants.
#
# Usage: ./scripts/install-openclaw.sh

set -euo pipefail

# -- Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

# -- Environment checks
check_macos() {
    if [ "$(uname -s)" != "Darwin" ]; then
        error "This script only supports macOS."
        exit 1
    fi
}

check_node() {
    if ! command -v node >/dev/null 2>&1; then
        error "Node.js is required but not found."
        error "Install Node 22.22.3+ (Node 26 recommended) via Homebrew: brew install node"
        exit 1
    fi
    local node_version
    node_version=$(node --version | tr -d 'v')
    local major
    major=$(echo "$node_version" | cut -d. -f1)
    # OpenClaw requires Node 22.22.3+, 24.15+, 25.9+, or Node 26+
    if [ "$major" -lt 22 ]; then
        error "Node $node_version is too old. OpenClaw requires Node 22.22.3+, 24.15+, 25.9+, or 26+."
        exit 1
    fi
    success "Node $node_version found."
}

check_npm() {
    if ! command -v npm >/dev/null 2>&1; then
        error "npm is required but not found."
        exit 1
    fi
    success "npm $(npm --version) found."
}

# -- Check if already installed
detect_existing() {
    if command -v openclaw >/dev/null 2>&1; then
        local installed_version
        installed_version=$(openclaw --version 2>/dev/null || echo "unknown")
        success "OpenClaw is already installed: $installed_version"
        info "To update: npm install -g openclaw@latest --allow-scripts openclaw"
        info "Skipping re-installation. Run 'openclaw doctor' to verify."
        return 0 # Already installed - exit success
    fi
    return 1 # Not installed
}

# -- Install
install_openclaw() {
    info "Installing OpenClaw via npm (official method)..."
    # --allow-scripts is needed on npm 12+ to allow pre/post install hooks
    npm install -g openclaw@latest --allow-scripts openclaw
    success "OpenClaw CLI installed."
}

# -- Verify
verify_install() {
    if ! command -v openclaw >/dev/null 2>&1; then
        error "OpenClaw command not found after installation."
        error "This is likely a PATH issue. Check: echo \$PATH"
        error "npm global bin dir: $(npm prefix -g)/bin"
        error "Add it to your shell profile if missing."
        exit 1
    fi
    local version
    version=$(openclaw --version 2>/dev/null || echo "unknown")
    success "OpenClaw $version installed successfully."
    info "Running 'openclaw doctor' to verify health..."
    openclaw doctor || warn "doctor reported issues. Review output above."
}

# -- Main
main() {
    echo ""
    echo "=== OpenClaw Installation (Phase 2) ==="
    echo ""

    check_macos
    check_node
    check_npm

    if detect_existing; then
        # Already installed — run doctor and exit cleanly
        openclaw doctor || true
        exit 0
    fi

    install_openclaw
    verify_install

    echo ""
    echo "=== Next Steps (Manual) ==="
    echo ""
    echo "1. Set your secrets in ~/.openclaw/.env (see config/.env.example)"
    echo "2. Render the config template:"
    echo "   scripts/render-config.sh <profile>"
    echo "3. Set OPENCLAW_CONFIG_PATH to point at the rendered config:"
    echo "   export OPENCLAW_CONFIG_PATH=~/.openclaw/openclaw.json"
    echo "4. Run interactive onboarding to connect Telegram and install daemon:"
    echo "   openclaw onboard --install-daemon"
    echo "5. See docs/macos-permissions.md for required macOS Privacy settings."
    echo ""
}

main "$@"
