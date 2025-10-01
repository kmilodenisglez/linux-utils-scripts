# 📲 Telegram Setup for alert

This document explains step by step how to get the **TELEGRAM_TOKEN** and **TELEGRAM_CHAT_ID** to receive alerts via Telegram.

---

## 1️⃣ Create a Telegram Bot

1. Open Telegram and search for `@BotFather`.
2. Send the command:

````

/newbot

```

3. BotFather will ask for:
   - **Bot name**: e.g. `NVMeMonitorBot`
   - **Username**: must end with `bot`, e.g. `nvme_monitor_bot`

4. Once finished, BotFather will give you an **access token** (TELEGRAM_TOKEN), like:

```

123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11

```

> This is your `TELEGRAM_TOKEN`.

---

## 2️⃣ Get your Chat ID

To send messages to yourself:

1. Open Telegram and search for `@userinfobot`.
2. Send any message and use the `/start` command.
3. `@userinfobot` will reply with your **Chat ID**, a number like:

```

987654321

````

> This is your `TELEGRAM_CHAT_ID`.

---

## 3️⃣ Save credentials securely

1. Create the configuration file:

```bash
mkdir -p ~/.config
touch ~/.config/nvme-monitor.env
chmod 600 ~/.config/nvme-monitor.env
````

1.1. Open the configuration file:

```bash
nano ~/.config/nvme-monitor.env
````

2. Paste the content:

```ini
TELEGRAM_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=987654321
```

3. Save and exit.

> Optional: temporarily export in the terminal for testing:
>
> ```bash
> export TELEGRAM_TOKEN="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
> export TELEGRAM_CHAT_ID="987654321"
> ```

---

## 4️⃣ Test the bot

You can test your bot with `curl`:

```bash
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
-d chat_id=$TELEGRAM_CHAT_ID \
-d text="✅ Telegram Bot configured successfully"
```

If everything is correct, you will receive a message in Telegram.

---

## ⚠️ Security Notes

* Do **not** share your **TELEGRAM_TOKEN** with anyone.
* `~/.config/nvme-monitor.env` must have `600` permissions.
* The script will read these variables to automatically send alerts.
