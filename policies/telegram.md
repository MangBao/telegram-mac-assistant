# Telegram Channel Policy

## Access Control

### dmPolicy

The OpenClaw Telegram channel must use either:
- `"pairing"` — during initial setup (default); unknown users receive a one-time
  pairing code and must be explicitly approved.
- `"allowlist"` — after initial setup; only users whose Telegram numeric IDs are
  listed in `allowFrom` can interact with the bot.

**Never use `"open"` in a production deployment.**

### allowFrom Format

After pairing, add your Telegram user ID to the config:

```json5
channels: {
  telegram: {
    dmPolicy: "allowlist",
    allowFrom: ["tg:YOUR_NUMERIC_USER_ID"],
  },
}
```

The `tg:` prefix is required by the OpenClaw schema.
Your numeric user ID can be found using `@userinfobot` on Telegram.

### Group Chats

Group chats should default to **requireMention = true** to prevent the bot from
responding to every message in a group.

```json5
channels: {
  telegram: {
    groups: { "*": { requireMention: true } },
  },
}
```

## Gateway Security

- The Gateway port (`18789`) must only be bound to `127.0.0.1` (localhost).
- Never expose port 18789 to the public internet.
- For remote access, use Tailscale or an SSH tunnel (see `docs/macos-permissions.md`).

## Bot Token

- The Telegram Bot Token must be stored in `~/.openclaw/.env` as `TELEGRAM_BOT_TOKEN`.
- The token must never appear in any file tracked by Git.
- If a token is accidentally committed, rotate it immediately via `@BotFather`.
