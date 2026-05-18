# 🧾 RAM-Only Logging (Reduce eMMC Wear)

## Why

The UniFi Cloud Key Gen2 uses internal eMMC storage.  
To reduce unnecessary write wear and extend hardware lifespan, persistent system logs were disabled.

Since this device runs as a stable remote backup node, long-term local log retention is not required.

---

## What Was Changed

systemd-journald storage mode was switched from:

- `Storage=persistent`

to:

- `Storage=volatile`

This stores logs in RAM (`/run/log/journal`) instead of writing to eMMC (`/var/log/journal`).

---

## How To Apply

Edit:

```bash
sudo nano /etc/systemd/journald.conf
```

Set:

```ini
[Journal]
Storage=volatile
RuntimeMaxUse=40M
```

Restart journald:

```bash
sudo systemctl restart systemd-journald
```

Optional cleanup:

```bash
sudo rm -rf /var/log/journal
```

Logs will now exist only during runtime and will be cleared on reboot.
