# 📲 Configuración de Telegram para alertas

Este documento explica paso a paso cómo obtener el **TELEGRAM_TOKEN** y **TELEGRAM_CHAT_ID** para recibir alertas vía Telegram.

---

## 1️⃣ Crear un bot de Telegram

1. Abre Telegram y busca el usuario `@BotFather`.
2. Envía el comando:

```

/newbot

```

3. BotFather te pedirá:
   - **Nombre del bot**: ejemplo `NVMeMonitorBot`
   - **Username**: debe terminar en `bot`, ejemplo `nvme_monitor_bot`

4. Al finalizar, BotFather te dará un **token de acceso** (TELEGRAM_TOKEN), similar a:

```

123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11

```

> Este es tu `TELEGRAM_TOKEN`.

---

## 2️⃣ Obtener tu Chat ID

Para enviar mensajes a ti mismo:

1. Abre Telegram y busca el usuario `@userinfobot`.
2. Envía cualquier mensaje y usa el comando `/start`.
3. `@userinfobot` te responderá con tu **Chat ID**, un número similar a:

```

987654321

````

> Este es tu `TELEGRAM_CHAT_ID`.

---

## 3️⃣ Guardar las credenciales de forma segura

1. Crea el archivo de configuración:

```bash
mkdir -p ~/.config
touch ~/.config/nvme-monitor.env
chmod 600 ~/.config/nvme-monitor.env
````

1.1. Abre el archivo de configuración:
```bash
nano ~/.config/nvme-monitor.env
````

2. Pega el contenido:

```ini
TELEGRAM_TOKEN=123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
TELEGRAM_CHAT_ID=987654321
```

3. Guardar y salir.

> Opcional: exportar temporalmente en la terminal para pruebas:
>
> ```bash
> export TELEGRAM_TOKEN="123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"
> export TELEGRAM_CHAT_ID="987654321"
> ```

---

## 4️⃣ Probar el bot

Puedes probar que tu bot funciona con `curl`:

```bash
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
-d chat_id=$TELEGRAM_CHAT_ID \
-d text="✅ Telegram Bot configurado correctamente"
```

Si todo está correcto, recibirás un mensaje en Telegram.

---

## ⚠️ Notas de seguridad

* No compartas tu **TELEGRAM_TOKEN** con nadie.
* `~/.config/nvme-monitor.env` debe tener permisos `600`.
* El script leerá estas variables para enviar alertas automáticamente.
