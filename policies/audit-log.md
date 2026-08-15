# Audit Log Policy

## Purpose

All significant interactions with the AI assistant are logged for security
auditing, troubleshooting, and usage analysis.

## Log Location

```
~/AI-Workspace/logs/audit.log
```

This path is:
- Inside the agent workspace (`~/AI-Workspace`) — not in the Git repository
- Created automatically by the assistant on first use
- Machine-local, never synced to Git or remote storage

## Log Format

Each log entry is a single line in structured format:

```
<timestamp_iso8601> | <user_id_hash> | <command_category> | <action> | <status> | <duration_ms>ms
```

### Fields

| Field              | Type    | Description                                              |
|--------------------|---------|----------------------------------------------------------|
| `timestamp_iso8601`| String  | UTC timestamp, ISO 8601 format: `2026-01-15T10:30:00Z`  |
| `user_id_hash`     | String  | SHA-256 of `channel:user_id` (first 12 chars)           |
| `command_category` | Enum    | `READ`, `WRITE`, `EXECUTE`, `AUTOMATION`, `DESTRUCTIVE`  |
| `action`           | String  | Human-readable action description (sanitized)            |
| `status`           | Enum    | `success`, `denied`, `error`, `approval_required`        |
| `duration_ms`      | Integer | Time taken in milliseconds                               |

### Example Entries

```
2026-08-13T06:45:00Z | a3f9c2b1d4e5 | READ | list_workspace_files | success | 142ms
2026-08-13T06:45:30Z | a3f9c2b1d4e5 | READ | system_status_check | success | 89ms
2026-08-13T06:46:00Z | a3f9c2b1d4e5 | DESTRUCTIVE | delete_file | denied | 12ms
2026-08-13T06:47:00Z | b2e8f4a6c7d9 | READ | list_workspace_files | denied | 8ms
```

The last entry shows an unauthorized user (`b2e8f4a6c7d9`) being denied — a
different hash from the authorized owner (`a3f9c2b1d4e5`).

## User ID Hashing

Telegram user IDs are **never stored in plain text** in the audit log.

Hash algorithm:
```bash
echo -n "telegram:123456789" | sha256sum | cut -c1-12
```

This provides:
- Consistent identification (same user → same hash)
- No direct re-identification from log alone
- Sufficient for correlating actions in an audit

## MUST LOG

| Event                              | category     | action                    |
|------------------------------------|--------------|---------------------------|
| File read request                  | READ         | read_file                 |
| Directory listing                  | READ         | list_workspace_files      |
| System status query                | READ         | system_status_check       |
| File write attempt                 | WRITE        | write_file                |
| Shell command execution            | EXECUTE      | exec_command              |
| Screenshot request                 | AUTOMATION   | screenshot                |
| File delete attempt                | DESTRUCTIVE  | delete_file               |
| Unauthorized access attempt        | READ+        | (any action) → `denied`   |
| Tool permission denied             | (any)        | tool_denied               |
| Gateway start/stop                 | READ         | gateway_lifecycle         |

## MUST NOT LOG

The following must **never** appear in audit log entries:

| What                          | Why                                       |
|-------------------------------|-------------------------------------------|
| Telegram bot token            | Secret — would be a security breach       |
| API keys (Anthropic, OpenAI)  | Secrets                                   |
| User's plain Telegram user ID | Use hash instead                          |
| File contents                 | May contain sensitive data                |
| Command arguments with secrets | e.g., `curl -H "Authorization: Bearer X"` |
| Browser cookies               | Session credentials                       |
| SSH private key contents      | Credentials                               |
| Passwords                     | Credentials                               |
| `.env` file contents          | All secrets                               |

## Retention Policy

- **Default retention**: 90 days
- **Rotation**: When log exceeds 10MB, rotate to `audit.log.1` (keep last 3 rotations)
- **Deletion**: Logs older than 90 days may be deleted
- **No remote sync**: Audit logs are never synced to cloud storage or Git

## Log File Permissions

```bash
chmod 600 ~/AI-Workspace/logs/audit.log
```

The log file should be readable only by the current user.

## Querying Logs

```bash
# View recent entries
tail -50 ~/AI-Workspace/logs/audit.log

# Find denied actions
grep "denied" ~/AI-Workspace/logs/audit.log

# Find actions from a specific time window
grep "2026-08-13" ~/AI-Workspace/logs/audit.log

# Count actions by category
awk -F' | ' '{print $3}' ~/AI-Workspace/logs/audit.log | sort | uniq -c
```
