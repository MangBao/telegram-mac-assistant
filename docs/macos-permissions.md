# macOS Permissions Guide

This document lists the macOS Privacy & Security permissions required for each
OpenClaw feature, and how to grant them safely.

**IMPORTANT:** This repository never grants permissions automatically.
All permission grants must be performed manually by the system owner
in **System Settings > Privacy & Security**.

---

## Permission Matrix

| Feature                         | Permission Needed         | Phase    | Notes                               |
|---------------------------------|---------------------------|----------|-------------------------------------|
| Basic Gateway (Telegram bot)    | None required             | Phase 2  | Network access only                 |
| Screenshot / screen reading     | Screen Recording          | Phase 3  | Required for screen-aware tasks     |
| Mouse / keyboard control        | Accessibility             | Phase 3  | Required for UI automation          |
| App automation (AppleScript)    | Automation                | Phase 3  | Per-app; prompt appears on use      |
| Camera                          | Camera                    | Future   | Disabled by default; personal only  |
| Microphone                      | Microphone                | Future   | Disabled by default; personal only  |
| Contacts, Calendar, Reminders   | Contacts / Calendar       | Future   | Off unless explicitly needed        |

---

## How to Grant Each Permission

### Screen Recording

Grants the ability to capture screen contents.

1. Open **System Settings** → **Privacy & Security** → **Screen Recording**
2. Click the `+` button
3. Add the **Terminal** app (or the OpenClaw app if using the macOS companion)
4. Toggle it **ON**
5. You may need to restart the affected application

> **Security note:** Screen Recording is a high-privilege permission. Only grant
> it to the application that runs the OpenClaw daemon — not to every app.

---

### Accessibility

Required for controlling mouse, keyboard, and UI elements of other apps.

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Click the `+` button
3. Add the **Terminal** app (or the signed OpenClaw helper)
4. Toggle it **ON**

> **Security note:** Prefer granting Accessibility to the **signed OpenClaw app**
> (if you install the macOS Companion from the official release) rather than to
> the generic `node` binary or `Terminal`. Granting it to `node` would give any
> Node.js process on your machine the same rights.

---

### Automation

macOS prompts for Automation access the first time a script tries to control
another app (e.g., via AppleScript). You do not need to pre-grant this.

When prompted, click **OK** to allow. To revoke:

1. Open **System Settings** → **Privacy & Security** → **Automation**
2. Locate the terminal / OpenClaw entry
3. Uncheck the specific app it should not control

---

### Camera & Microphone

These must be opted in **explicitly** in the machine profile and are disabled by default.

1. Open **System Settings** → **Privacy & Security** → **Camera** (or **Microphone**)
2. Toggle **ON** for the relevant app only when the feature is activated in the profile
3. For `company-mac-mini` profile: keep these **OFF**

---

## Daemon Startup

The OpenClaw daemon is installed as a macOS **LaunchAgent** (runs as the current
user, not as root):

```bash
# Install daemon (run once after onboarding)
openclaw gateway install

# Daemon plist location (machine-local, not in Git)
~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

LaunchAgent runs without `sudo`. It does not require root or administrator access.

---

## Remote Access

To access the Gateway from outside the local network:

- **Tailscale** (recommended): install Tailscale, and access the Gateway at
  the machine's Tailscale IP: `http://<tailscale-ip>:18789`
- **SSH tunnel**: `ssh -L 18789:127.0.0.1:18789 user@remote-mac`

**Never** open port 18789 directly to the internet.

---

## TCC Database Notes

macOS stores permission grants in the TCC (Transparency, Consent, and Control)
database. These are not transferable between machines. On a new Mac, all
permissions must be re-granted manually after running `bootstrap.sh`.

This is by design. The repository tracks **which permissions are needed**
(this file), not the grants themselves.
