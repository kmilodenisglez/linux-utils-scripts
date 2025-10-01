# 📘 NVMe Monitor - English

This project provides an **automatic NVMe disk monitor** that runs `smartctl`, stores reports, and sends desktop notifications (notify-send) and/or Telegram alerts when issues are detected.  
It runs as a **systemd user service** with a **weekly timer**.

---

## 1) Final script (`/home/myuser/nvme-monitor.sh`)
> Replace `myuser` with your username.

Save this file in `/home/myuser/nvme-monitor.sh` and make it executable:

```bash
chmod +x /home/myuser/nvme-monitor.sh
````

---

## 2) Environment file (optional, recommended)

For Telegram alerts, create:

```bash
mkdir -p ~/.config
nano ~/.config/nvme-monitor.env
chmod 600 ~/.config/nvme-monitor.env
```

Content (`~/.config/nvme-monitor.env`):

```ini
TELEGRAM_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=987654321
```

> You can also export the variables in your shell for testing, run:
> ```bash
> source ~/.config/nvme-monitor.env
> ```

---

## 3) Dependencies

```bash
sudo apt update
sudo apt install -y smartmontools libnotify-bin curl
```

---

## 4) Secure sudo permission for `smartctl` (optional)

```bash
sudo visudo
```

Add at the end:

```
myuser ALL=(ALL) NOPASSWD: /usr/sbin/smartctl
```

> Replace `myuser` with your username.

---

## 5) Systemd user: service and timer

### Service (`~/.config/systemd/user/nvme-monitor.service`)

#### Create service file:
```bash
nano ~/.config/systemd/user/nvme-monitor.service
```

Content:
```ini
[Unit]
Description=NVMe Health Monitor

[Service]
Type=oneshot
ExecStart=/home/myuser/nvme-monitor.sh
EnvironmentFile=%h/.config/nvme-monitor.env
```
> Replace `myuser` with your username.

### Timer (`~/.config/systemd/user/nvme-monitor.timer`)

#### Create timer file:
```bash
nano ~/.config/systemd/user/nvme-monitor.timer
```

Content:
```ini
[Unit]
Description=Run NVMe Health Monitor weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

---

## 6) Enable and start

```bash
systemctl --user daemon-reload
systemctl --user enable --now nvme-monitor.timer
systemctl --user start nvme-monitor.service
systemctl --user list-timers | grep nvme
```

---

## 7) Verification and testing
> Replace `myuser` with your username.
```bash
/home/myuser/nvme-monitor.sh
ls -l ~/nvme_logs
tail -n 200 ~/nvme_logs/alerts_accumulated.txt
journalctl --user -u nvme-monitor.service --since "1 hour ago"

# Simulate alert
echo "⚠️ TEST - manual alert" | tee -a ~/nvme_logs/alerts_accumulated.txt
```

---

## 8) Security notes

* Metrics files are read **safely** (no `source`).
* `sudoers` entry must only include `/usr/sbin/smartctl`.
* Env file must have `600` permissions.
* Desktop notifications require an active graphical session.
* Telegram works only if `TELEGRAM_TOKEN` and `TELEGRAM_CHAT_ID` are defined.
