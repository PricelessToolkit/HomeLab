# 📂 Samba (SMB) Configuration

This device exposes `/volume1/backup` over SMB for controlled remote access.

The configuration is minimal, restricted to a dedicated user, and logging is fully disabled to avoid unnecessary eMMC writes.

---

## Install Samba

```bash
sudo apt update
sudo apt install samba
```

Enable and start the service:

```bash
sudo systemctl enable smbd
sudo systemctl start smbd
```

---

## Create SMB User

Create a system user:

```bash
sudo adduser smbuser
```

Add the user to Samba:

```bash
sudo smbpasswd -a smbuser
```

Set directory ownership and permissions:

```bash
sudo chown -R smbuser:smbuser /volume1/backup
sudo chmod -R 0770 /volume1/backup
```

---

## Samba Configuration

Edit:

```bash
sudo nano /etc/samba/smb.conf
```

Minimal configuration:

```ini
[global]
   log level = 0
   logging = none

[backup]
   path = /volume1/backup
   browseable = yes
   writable = yes
   valid users = smbuser
   create mask = 0660
   directory mask = 0770
```

Restart Samba:

```bash
sudo systemctl restart smbd
sudo systemctl restart nmbd
```

---

## Result

- No Samba logs written to disk
- No Samba logs sent to journald
- Reduced eMMC wear
- Minimal and controlled SMB access
