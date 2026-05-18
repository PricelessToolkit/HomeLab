<table>
<tr>
<td width="40%">

<img src="https://github.com/PricelessToolkit/Cloudkey-Repurposed/blob/main/img/CKG2.jpeg" width="100%"/>

</td>
<td width="60%">

### 🔧 CloudKey Repurposed

A practical collection of notes and scripts for turning the **UniFi Cloud Key Gen2** into a lightweight (~5W) remote backup node.

This repository focuses on simple, reproducible modifications to extend the hardware beyond UniFi Controller use.

</td>
</tr>
</table>

🤗 Please consider subscribing to my [YouTube channel](https://www.youtube.com/@PricelessToolkit/videos)
Your subscription goes a long way in backing my work. If you feel more generous, you can buy me a coffee

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/U6U2QLAF8)

---

## Why Use a CloudKey Gen2 as a Remote Backup?

The UniFi CloudKey Gen2 is a practical device for remote backups. It consumes only around 5–6 watts, which equals roughly 44–53 kWh per year when running 24/7. This makes it inexpensive to operate long-term, even when hosted at a friend’s or family member’s apartment.

When used with a 2.5" SSD, the system has no fans and no spinning disks, meaning no moving mechanical parts. It runs silently and does not require frequent maintenance.

A strong advantage of the CloudKey Gen2 is its internal battery (built-in UPS). If power is lost, the device detects it and shuts down safely instead of crashing. This reduces the risk of filesystem corruption during outages. On older units, the internal battery may require replacement over time. The newest versions have no integrated battery.

The hardware design is compact and clean, so it can sit on a shelf without looking like a server. It is small enough to ship to another city or country if needed.

Performance is sufficient for remote backups, with transfer speeds up to around 400 Mbps in real-world use. This is fast enough for efficient replication while remaining suitable for typical residential internet connections.


---

## 📦 What’s Included

<table>
<tr>
<td width="50%" valign="top">

### 🗂 Backup Script
- rsync-based backups over SSH to CloudKey  
- Incremental snapshot support (`--link-dest`)  
- Retention handling  
- Remote push configuration  

### 📂 SMB (Samba)
- Secure share for `/volume1/backup`  
- Dedicated restricted user  
- Writable backup target  
- Logging fully disabled (no eMMC writes)  

### 🌐 Networking
- WireGuard client configuration  
- Persistent tunnel setup  
- Auto-start on boot  

</td>
<td width="50%" valign="top">

### 🖥 Display Status Screen
- Custom 128x64 status screen via `ck-splash`  
- Shows LAN IP, WireGuard IP, and free backup space  
- PNG rendered in RAM (`/tmp`) to avoid eMMC wear  
- Optional cron refresh (e.g. every 5 minutes)  

<img src="img/display.png" width="260"/>

### 💡 Hardware
- LED control  
- Battery status monitoring (charge level, power source, health)  

### 🖥 System Customization
- Replaced default vendor login banner  
- Custom MOTD reflecting device purpose  
- Disabled persistent journald storage (RAM-only logging to reduce eMMC wear)  

</td>
</tr>
</table>

---

## 🎯 Goals

- Extend hardware lifespan
- Keep setup minimal and practical
- Avoid unnecessary complexity
- Repurpose instead of discard


---


## Getting Started

Before applying the modifications in this repository, make sure the Cloud Key is updated to the latest firmware.

SSH access must be enabled from the UniFi OS web interface.  
When enabling SSH from the UI, you set the root password there.

Default SSH user:

- `root`

Login example:

```bash
ssh root@<cloudkey-ip>
```

Before proceeding, uninstall any unused UniFi applications from the UI, such as:

- UniFi Network
- UniFi Protect
- Any other UniFi services

This device is being repurposed and should not run unnecessary controller services.

⚠ **Very important:** Disable automatic updates in UniFi OS settings.  
Automatic updates may reinstall services or overwrite custom configurations.

After logging in and cleaning the system, follow the instructions in this repository to convert the device into a minimal remote backup / NAS node.

Use the documentation files provided:

- `motd.md` – Custom login banner configuration  
- `log.md` – RAM-only journald configuration  
- `smb.md` – Samba (SMB) setup for `/volume1/backup`  
- `wireguard.md` – WireGuard client configuration  
- `Led and Battery.md` – LED control and battery monitoring  
- `rsync-snapshots.md` – Snapshot backup script and usage instructions
  
---

## ⚠ Disclaimer

These modifications are unofficial.  
You are responsible for your data, hardware, and network security.
