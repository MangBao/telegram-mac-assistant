#!/usr/bin/env bash
# scripts/audit-log.sh
# Lightweight audit logging helper for the AI assistant.
#
# Log location: ~/AI-Workspace/logs/audit.log
# Format: <timestamp> | <user_id_hash> | <category> | <action> | <status> | <duration>ms
#
# NEVER call this script with raw tokens, API keys, or passwords as arguments.
# User IDs are SHA-256 hashed before logging (first 12 chars of hash).
#
# Usage:
#   source scripts/audit-log.sh
#   audit_log "telegram" "123456789" "READ" "list_workspace_files" "success" "142"
#
# Or standalone:
#   ./scripts/audit-log.sh "telegram" "123456789" "READ" "list_workspace_files" "success" "142"

set -euo pipefail

AUDIT_LOG_DIR="$HOME/AI-Workspace/logs"
AUDIT_LOG_FILE="$AUDIT_LOG_DIR/audit.log"
AUDIT_LOG_MAX_BYTES=$((10 * 1024 * 1024))  # 10 MB rotation threshold

# audit_log <channel> <user_id> <category> <action> <status> <duration_ms>
audit_log() {
    local channel="${1:-unknown}"
    local user_id="${2:-unknown}"
    local category="${3:-UNKNOWN}"
    local action="${4:-unknown}"
    local status="${5:-unknown}"
    local duration_ms="${6:-0}"

    # Validate category
    case "$category" in
        READ|WRITE|EXECUTE|AUTOMATION|DESTRUCTIVE) ;;
        *)
            category="UNKNOWN"
            ;;
    esac

    # Validate status
    case "$status" in
        success|denied|error|approval_required) ;;
        *)
            status="unknown"
            ;;
    esac

    # Hash the user ID — never store plain
    local user_id_hash
    if command -v sha256sum >/dev/null 2>&1; then
        user_id_hash=$(printf "%s:%s" "$channel" "$user_id" | sha256sum | cut -c1-12)
    elif command -v shasum >/dev/null 2>&1; then
        # macOS fallback
        user_id_hash=$(printf "%s:%s" "$channel" "$user_id" | shasum -a 256 | cut -c1-12)
    else
        # Fallback: obfuscate without hashing (not ideal but prevents plain ID)
        user_id_hash="nohash_$(echo -n "$channel:$user_id" | wc -c | tr -d ' ')chars"
    fi

    # Sanitize action (remove any potential secrets from action description)
    # Strip anything that looks like a token: long alphanumeric strings with special chars
    local safe_action
    safe_action=$(echo "$action" | sed 's/[A-Za-z0-9]\{20,\}/[REDACTED]/g' | head -c 200)

    # Timestamp (UTC)
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Ensure log directory exists with restricted permissions
    mkdir -p "$AUDIT_LOG_DIR"
    chmod 700 "$AUDIT_LOG_DIR"

    # Rotate if too large
    if [ -f "$AUDIT_LOG_FILE" ] && [ "$(wc -c < "$AUDIT_LOG_FILE")" -gt "$AUDIT_LOG_MAX_BYTES" ]; then
        mv "$AUDIT_LOG_FILE.2" "$AUDIT_LOG_FILE.3" 2>/dev/null || true
        mv "$AUDIT_LOG_FILE.1" "$AUDIT_LOG_FILE.2" 2>/dev/null || true
        mv "$AUDIT_LOG_FILE"   "$AUDIT_LOG_FILE.1" 2>/dev/null || true
    fi

    # Write log entry
    local entry="${timestamp} | ${user_id_hash} | ${category} | ${safe_action} | ${status} | ${duration_ms}ms"
    echo "$entry" >> "$AUDIT_LOG_FILE"

    # Set file permissions on first write
    chmod 600 "$AUDIT_LOG_FILE" 2>/dev/null || true
}

# If called directly (not sourced), run with arguments
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ "$#" -lt 5 ]; then
        echo "Usage: $0 <channel> <user_id> <category> <action> <status> [duration_ms]"
        echo "Example: $0 telegram 123456789 READ list_workspace_files success 142"
        echo ""
        echo "Categories: READ | WRITE | EXECUTE | AUTOMATION | DESTRUCTIVE"
        echo "Status:     success | denied | error | approval_required"
        exit 1
    fi
    audit_log "$1" "$2" "$3" "$4" "$5" "${6:-0}"
fi
