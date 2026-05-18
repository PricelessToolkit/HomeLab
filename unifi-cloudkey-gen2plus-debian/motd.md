# Custom MOTD – CloudKey Backup Node

This device was originally a Ubiquiti CloudKey Gen2 Plus and has been repurposed as a dedicated backup node.

Instead of keeping the default vendor login banner, we replaced the startup message (MOTD – *Message of the Day*) to reflect its new purpose and to document important system paths for future maintenance.

---

## Why Change the MOTD?

The original login message:

- Displayed vendor branding
- Included legal warnings
- Contained no useful operational information

Since this device is now a dedicated backup server, we replaced it with:

- A custom ASCII header
- A clear system role label
- Quick-reference configuration paths
- A ready-to-use rsync command

This makes the device feel like our own infrastructure instead of a stock appliance.

---

## What Is MOTD?

MOTD = **Message of the Day**

On most Linux systems, it is stored in:

```bash
/etc/motd
```

This file is displayed automatically after SSH login.

---

## How We Modified the Startup Message

### 1. Edit the MOTD file

```bash
sudo nano /etc/motd
```

Replace its contents with your custom banner.

---

### 2. Example Custom MOTD Used

```text
                .--.__
  ______ __ .--(    ) )-.   __ __                    __
 |      |  (._____.__.___)_|  |  |__ _____ __ __   _|  |_
 |   ---|  ||  _  |  |  |  _  |    <|  -__|  |  | |_    _|
 |______|__||_____|_____|_____|__|__|_____|___  |   |__|
                                          |_____|

          C L O U D K E Y   B A C K U P

====================== SYSTEM HELP ======================

SMB config           : /etc/samba/smb.conf
SMB share root       : /volume1/backup
WireGuard config     : /etc/wireguard/wg0.conf
WireGuard service    : wg-quick@wg0
System logs          : journalctl -xe
Start display script : ./display.sh
Stop display (black) : ck-splash -s black
Rsync push           : rsync -av /volume1/backup/ user@REMOTE_IP:/remote/path/

=========================================================

```

---

## Why Include System Paths in MOTD?

Future maintenance becomes easier.

Instead of remembering:

- Where Samba config lives
- Where the backup volume is mounted
- Where WireGuard config is stored
- The correct rsync syntax

Everything is visible immediately after login.

This reduces troubleshooting time and avoids guesswork months later.

---

## Result

The device now:

- Boots with a clean custom identity
- Clearly documents its purpose
- Provides operational shortcuts
- Functions as a proper dedicated backup node
