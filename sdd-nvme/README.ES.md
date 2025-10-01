# 📘 Monitor NVMe - Español

Este proyecto implementa un **monitor automático de discos NVMe** que ejecuta `smartctl`, guarda reportes, y envía notificaciones al escritorio (notify-send) y/o Telegram cuando detecta alertas.  
Se despliega como un **servicio systemd user** con un **timer semanal**.

---

## 1) Script final (`/home/myuser/nvme-monitor.sh`)

Guarda exactamente este archivo en `/home/myuser/nvme-monitor.sh` y hazlo ejecutable:

```bash
chmod +x /home/myuser/nvme-monitor.sh
````

---

## 2) Archivo de entorno (opcional, recomendado)

Si deseas alertas en Telegram, crea:

```bash
mkdir -p ~/.config
nano ~/.config/nvme-monitor.env
chmod 600 ~/.config/nvme-monitor.env
```

Contenido (`~/.config/nvme-monitor.env`):

```ini
TELEGRAM_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=987654321
```

> También puedes exportar las variables en tu sesión para pruebas, ejecutando:
> ```bash
> source ~/.config/nvme-monitor.env
> ```

---

## 3) Dependencias

```bash
sudo apt update
sudo apt install -y smartmontools libnotify-bin curl
```

---

## 4) Permiso sudo seguro para `smartctl` (opcional)

```bash
sudo visudo
```

Agrega al final:

```
myuser ALL=(ALL) NOPASSWD: /usr/sbin/smartctl
```

> Reemplaza `myuser` por tu usuario.

---

## 5) Systemd user: servicio y timer

### Servicio (`~/.config/systemd/user/nvme-monitor.service`)

```ini
[Unit]
Description=NVMe Health Monitor

[Service]
Type=oneshot
ExecStart=/home/myuser/nvme-monitor.sh
EnvironmentFile=%h/.config/nvme-monitor.env
```

### Timer (`~/.config/systemd/user/nvme-monitor.timer`)

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

## 6) Habilitar y arrancar

```bash
systemctl --user daemon-reload
systemctl --user enable --now nvme-monitor.timer
systemctl --user start nvme-monitor.service
systemctl --user list-timers | grep nvme
```

---

## 7) Verificación y pruebas

```bash
/home/myuser/nvme-monitor.sh
ls -l ~/nvme_logs
tail -n 200 ~/nvme_logs/alerts_accumulated.txt
journalctl --user -u nvme-monitor.service --since "1 hour ago"

# Simular alerta
echo "⚠️ TEST - alerta manual" | tee -a ~/nvme_logs/alerts_accumulated.txt
```

---

## 8) Notas de seguridad

* Archivos de métricas se leen de forma **segura** (sin `source`).
* `sudoers` solo debe incluir `/usr/sbin/smartctl`.
* `~/.config/nvme-monitor.env` debe tener permisos `600`.
* Notify-send funciona solo si hay sesión gráfica activa.
* Telegram funciona si `TELEGRAM_TOKEN` y `TELEGRAM_CHAT_ID` están definidos.

