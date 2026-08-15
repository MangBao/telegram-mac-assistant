# Telegram Setup Guide

Hướng dẫn thiết lập Telegram channel cho AI assistant trên Mac mini.

> **Nguyên tắc bảo mật**: Bot token tuyệt đối không được commit, hard-code,
> hay xuất hiện trong log. Token chỉ được lưu tại `~/.openclaw/.env` trên máy
> của bạn — không bao giờ trong repository này.

---

## Mục lục

1. [Tạo Telegram Bot](#1-tạo-telegram-bot)
2. [Cấu hình Bot Token](#2-cấu-hình-bot-token)
3. [Pairing lần đầu](#3-pairing-lần-đầu)
4. [Chuyển sang Allowlist](#4-chuyển-sang-allowlist)
5. [Kiểm tra kết nối](#5-kiểm-tra-kết-nối)
6. [Revoke / Rotate Token](#6-revoke--rotate-token)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Tạo Telegram Bot

### Cách 1: Qua chat với BotFather

1. Mở Telegram, tìm **@BotFather** (xác nhận handle chính xác là `@BotFather`).
2. Gửi lệnh `/newbot`.
3. Đặt tên hiển thị (ví dụ: `My Mac Assistant`).
4. Đặt username kết thúc bằng `bot` (ví dụ: `my_mac_mini_bot`).
5. BotFather gửi lại **bot token** — lưu lại ngay, chỉ hiển thị một lần.

### Cách 2: Qua BotFather Web App

Mở [t.me/BotFather?startapp](https://t.me/BotFather?startapp) trong bất kỳ
Telegram client nào (kể cả [web.telegram.org](https://web.telegram.org)).

### Cấu hình tùy chọn (BotFather)

Sau khi tạo bot, nên cấu hình thêm:

```
/setjoingroups → Disable    # Không cho thêm bot vào group
/setprivacy    → Enable     # Chỉ nhận tin nhắn được mention
```

Vì Phase 3 không dùng group chat, tắt join groups là best practice.

---

## 2. Cấu hình Bot Token

### Bước 1: Tạo file `.env`

```bash
mkdir -p ~/.openclaw
cp config/.env.example ~/.openclaw/.env
```

### Bước 2: Điền token vào `.env`

Mở `~/.openclaw/.env` bằng editor và điền:

```
TELEGRAM_BOT_TOKEN=<your_bot_token_here>
TELEGRAM_OWNER_ID=<your_numeric_telegram_user_id>
```

> **Lưu ý**: `TELEGRAM_OWNER_ID` cần được điền sau bước Pairing (xem mục 3).

### Bước 3: Render config

```bash
./scripts/render-config.sh
```

Script này copy template `config/openclaw/openclaw.example.json5` thành
`~/.openclaw/openclaw.json` — là **regular file**, không phải symlink
(yêu cầu của OpenClaw).

### Bước 4: Xác nhận token không bị lộ

```bash
# Kiểm tra token KHÔNG nằm trong bất kỳ file tracked nào
git grep -r "TELEGRAM_BOT_TOKEN" --include="*.json5" --include="*.sh"
# Kết quả chỉ được chứa placeholder ${TELEGRAM_BOT_TOKEN} — không phải token thật
```

---

## 3. Pairing lần đầu

Pairing là cơ chế OpenClaw yêu cầu user không quen biết phải xác nhận trước
khi được phép tương tác. Đây là thiết lập an toàn cho lần đầu.

### Bước 1: Start Gateway

```bash
./scripts/openclaw-start.sh
# hoặc
openclaw gateway start
```

### Bước 2: Gửi tin nhắn lần đầu

Mở Telegram, tìm bot của bạn theo username và gửi `/start`.

Bot sẽ reply với **pairing code** (dạng 6 ký tự).

### Bước 3: Approve pairing trên Mac

```bash
# Xem các pairing request đang chờ
openclaw pairing list telegram

# Approve theo code
openclaw pairing approve telegram <CODE>
```

Pairing codes hết hạn sau **1 giờ**.

### Tìm Telegram User ID của bạn

Sau khi pair, chạy lệnh này trên Mac:

```bash
openclaw logs --follow
```

Rồi gửi bất kỳ tin nhắn nào từ Telegram. Trong log bạn sẽ thấy `from.id` —
đây là numeric Telegram user ID của bạn. Ví dụ: `123456789`.

Cách an toàn hơn so với dùng third-party bot như `@userinfobot`.

---

## 4. Chuyển sang Allowlist

Sau khi đã biết Telegram user ID của mình, chuyển sang allowlist để bảo mật
hơn (pairing chỉ nên dùng trong lần đầu).

### Bước 1: Cập nhật `.env`

Thêm vào `~/.openclaw/.env`:

```
TELEGRAM_OWNER_ID=123456789
```

(Thay `123456789` bằng user ID thật của bạn.)

### Bước 2: Cập nhật config

Mở `~/.openclaw/openclaw.json`, tìm phần `channels.telegram` và chỉnh:

```json5
{
  channels: {
    telegram: {
      dmPolicy: "allowlist",           // Đổi từ "pairing" sang "allowlist"
      allowFrom: ["${TELEGRAM_OWNER_ID}"],  // Đã được inject từ .env
    },
  },
}
```

Hoặc dùng CLI:

```bash
openclaw config set channels.telegram.dmPolicy allowlist
```

### Bước 3: Verify

```bash
openclaw doctor
./scripts/telegram-health.sh
```

---

## 5. Kiểm tra kết nối

```bash
# Health check tổng hợp
./scripts/telegram-health.sh

# Gateway status
openclaw gateway status

# Xem log realtime
openclaw logs --follow

# Kiểm tra Telegram channel cụ thể
openclaw channels status telegram
```

Để test từ Telegram:

- Gửi `/status` → Bot reply với system status
- Gửi `/help` → Bot reply với danh sách commands
- Gửi `"Máy đang làm gì?"` → Agent trả lời tự nhiên

---

## 6. Revoke / Rotate Token

### Khi cần rotate (token bị lộ hoặc định kỳ)

1. **Tạo token mới** từ BotFather:
   ```
   /mybots → chọn bot → API Token → Revoke current token
   ```
   BotFather sẽ cấp token mới.

2. **Cập nhật `.env`** trên Mac mini:
   ```bash
   # Mở file và thay giá trị TELEGRAM_BOT_TOKEN
   nano ~/.openclaw/.env
   ```

3. **Restart Gateway** để apply token mới:
   ```bash
   ./scripts/openclaw-stop.sh
   ./scripts/openclaw-start.sh
   ```

4. **Verify** token mới hoạt động:
   ```bash
   ./scripts/telegram-health.sh
   ```

> **Quan trọng**: Token cũ sẽ bị vô hiệu hóa ngay lập tức sau khi revoke.
> Nếu token bị commit vào Git, cần revoke ngay và force-push để rewrite history
> (hoặc coi Git history là compromised và rotate token ngay).

---

## 7. Troubleshooting

### Bot không trả lời

```bash
# 1. Check Gateway có chạy không
openclaw gateway status

# 2. Check Telegram channel có connected không
openclaw channels status telegram

# 3. Xem log
openclaw logs --follow
# Rồi gửi tin nhắn từ Telegram → xem có log entry không

# 4. Run doctor
openclaw doctor
```

### "getMe returned 401" — Token không hợp lệ

Token bị sai hoặc đã bị revoke. Kiểm tra:

```bash
# Xác nhận token đã được set (KHÔNG in ra giá trị)
grep -q "TELEGRAM_BOT_TOKEN=." ~/.openclaw/.env && echo "Token IS set" || echo "Token NOT set"
```

Nếu set đúng nhưng vẫn lỗi → token đã expire hoặc bị revoke. Tạo token mới từ BotFather.

### "Conflict: terminated by other getUpdates" (409)

Có một process OpenClaw khác đang chạy với cùng token.

```bash
# Dừng tất cả OpenClaw instances
./scripts/openclaw-stop.sh
# Chờ 5 giây
sleep 5
# Khởi động lại
./scripts/openclaw-start.sh
```

### "DM policy blocked" — User bị reject

Nếu bạn đang dùng `dmPolicy: "allowlist"` nhưng user ID chưa được thêm:

```bash
# Thêm user ID vào config
openclaw config set channels.telegram.allowFrom '["YOUR_NUMERIC_USER_ID"]'
```

Hoặc switch tạm về `"pairing"` để re-pair:

```bash
openclaw config set channels.telegram.dmPolicy pairing
```

### Config validation error — Gateway không start

```bash
# Check lỗi cụ thể
openclaw config validate

# Tự sửa lỗi tự động
openclaw doctor --fix
```

### Pairing code đã hết hạn (> 1 giờ)

Gửi lại `/start` từ Telegram để nhận pairing code mới.

---

## Security Checklist

Trước khi sử dụng production:

- [ ] Token lưu trong `~/.openclaw/.env`, không trong Git
- [ ] `dmPolicy: "allowlist"` với numeric user ID
- [ ] Không có `groups` key trong config (groups bị block)
- [ ] Gateway chỉ bind `127.0.0.1` (không expose ra internet)
- [ ] `git grep TELEGRAM_BOT_TOKEN` chỉ thấy placeholder `${...}`
- [ ] `openclaw doctor` không báo lỗi
- [ ] `./scripts/telegram-health.sh` pass tất cả checks
