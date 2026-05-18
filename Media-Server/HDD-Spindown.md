# hd-idle Setup Guide (Debian Minimal + USB HDD + mergerfs)

This guide explains how to:

- Install `hd-idle`
- Identify the correct disks
- Configure automatic HDD spindown
- Test that it works

This is ideal for USB enclosures (e.g., ASMedia ASM235CM) where `hdparm -S` may not work reliably.

---

# 1️⃣ Install hd-idle

```bash
sudo apt update
sudo apt install hd-idle
```

---

# 2️⃣ Identify Your Disks (IMPORTANT)

We must use **stable disk IDs**, not `/dev/sdb` or `/dev/sdc` (those can change after reboot).

List disks:

```bash
ls -l /dev/disk/by-id/
```

Example output:

```
usb-ASMedia_ASM235CM_ABAABBBB04A8-0:0 -> ../../sdb
usb-ASMedia_ASM235CM_ABAABBBB04A9-0:0 -> ../../sdc
```

Use the **whole disk**, NOT `-part1`.

✅ Correct:
```
/dev/disk/by-id/usb-ASMedia_ASM235CM_ABAABBBB04A8-0:0
```

❌ Wrong:
```
/dev/disk/by-id/usb-ASMedia_ASM235CM_ABAABBBB04A8-0:0-part1
```

---

# 3️⃣ Enable hd-idle

Edit configuration:

```bash
sudo nano /etc/default/hd-idle
```

Make sure this line is set:

```bash
START_HD_IDLE=true
```

If it says `false`, change it to `true`.

---

# 4️⃣ Configure Spindown Time

`hd-idle` uses **seconds**, not minutes.

| Minutes | Seconds |
|----------|----------|
| 1 min    | 60       |
| 20 min   | 1200     |
| 30 min   | 1800     |
| 60 min   | 3600     |

Example: **20-minute spindown**

```bash
START_HD_IDLE=true
HD_IDLE_OPTS="-i 0 \
-a /dev/disk/by-id/usb-ASMedia_ASM235CM_ABAABBBB04A8-0:0 -i 1200 \
-a /dev/disk/by-id/usb-ASMedia_ASM235CM_ABAABBBB04A9-0:0 -i 1200"
```

Explanation:

- `-i 0` → default (do not affect other drives)
- `-a <disk> -i 1200` → spin down that disk after 1200 seconds (20 min) idle

Save and exit.

---

# 5️⃣ Restart and Enable Service

```bash
sudo systemctl enable hd-idle
sudo systemctl restart hd-idle
```

Check status:

```bash
sudo systemctl status hd-idle --no-pager
```

It should show:

```
Active: active (running)
```

---

# 6️⃣ Test if Spindown Works

Wait for the configured idle time.

Then check disk state:

```bash
sudo hdparm -C /dev/sdb
sudo hdparm -C /dev/sdc
```

If working, you should see:

```
drive state is:  standby
```

---

# 7️⃣ If Disks Do Not Spin Down

Something is accessing them.

Check active disk usage:

```bash
sudo iotop -o
```

Check open files:

```bash
sudo lsof | grep /mnt
```

Common causes:

- Plex / Jellyfin / Emby scans
- Samba access
- Docker containers
- `atime` updates

---

# 8️⃣ Recommended Mount Options (Very Important)

To prevent constant wake-ups, use `noatime`.

Edit `/etc/fstab` and add:

```
UUID=xxxx  /mnt/disk1  xfs  defaults,noatime  0 2
UUID=yyyy  /mnt/disk2  xfs  defaults,noatime  0 2
```

Then remount:

```bash
sudo mount -o remount /mnt/disk1
sudo mount -o remount /mnt/disk2
```

---

# ✅ Done

Your HDDs will now automatically spin down after the configured idle time.
