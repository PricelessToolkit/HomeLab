# Debian Home Server Setup  
## XFS Data Disks + mergerfs (fill-first policy) + ext4 SSD Backup + Samba

This guide sets up:

- ✅ 2 or 3 HDDs formatted as **XFS**
- ✅ Combined using **mergerfs**
- ✅ Fill-first policy (disk1 → disk2 → disk3 only when full)
- ✅ SSD formatted as **ext4** for backup
- ✅ Samba with dedicated SMB-only user
- ✅ Proper permissions
- ✅ Spin-down friendly mount options

---

# 1️⃣ Install Required Packages

```bash
sudo apt update
sudo apt install xfsprogs mergerfs samba samba-common-bin
```

---

# 2️⃣ Prepare HDDs (XFS for mergerfs)

## Identify disks

```bash
lsblk -f
```

Example:

```
sdb
└─sdb1
sdc
└─sdc1
sdd
└─sdd1
```

---

## Partition each disk (if new)

Example for /dev/sdb:

```bash
sudo fdisk /dev/sdb
```

Inside fdisk:
- `n` → new
- `p` → primary
- accept defaults
- `w` → write

Repeat for other disks.

---

## Format as XFS

⚠️ This erases data.

```bash
sudo mkfs.xfs -f /dev/sdb1
sudo mkfs.xfs -f /dev/sdc1
sudo mkfs.xfs -f /dev/sdd1   # if 3rd disk
```

---

# 3️⃣ Create Mount Points

```bash
sudo mkdir -p /srv/disk1
sudo mkdir -p /srv/disk2
sudo mkdir -p /srv/disk3   # optional
sudo mkdir -p /srv/media
```

---

# 4️⃣ Get UUIDs

```bash
sudo blkid /dev/sdb1
sudo blkid /dev/sdc1
sudo blkid /dev/sdd1
```

Copy UUIDs.

---

# 5️⃣ Add HDDs to fstab (spin-down friendly)

Edit:

```bash
sudo nano /etc/fstab
```

Add:

```
# Enclosure Disk1
UUID=945ecc60-41dc-4e90-9bc4-04a3fa19c1ff  /srv/disk1  xfs  defaults,noatime,nofail,x-systemd.device-timeout=10  0  2

# Enclosure Disk2
UUID=4a0fe748-b42a-45f3-b069-95d0aff1c3f0  /srv/disk2  xfs  defaults,noatime,nofail,x-systemd.device-timeout=10  0  2

Enclosure Disk3
UUID=4a0fe748-b42a-45f3-b069-95d0aff1c6f8  /srv/disk3  xfs  defaults,noatime,nofail,x-systemd.device-timeout=10  0  2
```

Test:

```bash
sudo mount -a
```

---

# 6️⃣ Configure mergerfs (Fill First Policy)

Edit fstab again and add:

```
/srv/disk1:/srv/disk2:/srv/disk3  /srv/media  fuse.mergerfs  defaults,allow_other,use_ino,category.create=ff,minfreespace=50G,moveonenospc=true,cache.files=partial  0  0
```

Explanation:

- `category.create=ff` → Fill first disk completely before writing to next
- `minfreespace=50G` → Prevent disk from filling 100%
- `allow_other` → Required for Samba access
- `moveonenospc=true` → mergerfs automatically continues on next disk instead of failing write

If only 2 disks:

```
/srv/disk1:/srv/disk2  /srv/media  fuse.mergerfs  defaults,allow_other,use_ino,category.create=ff,minfreespace=50G,moveonenospc=true,cache.files=partial  0  0
```

Mount:

```bash
sudo systemctl daemon-reload
sudo mount -a
```

Verify:

```bash
df -h | grep media
```

Creating data folder on disk! when mounted!

```bash
sudo mkdir -p /srv/media/data
```



---

# 7️⃣ Setup Backup SSD (ext4)

Identify SSD:

```bash
lsblk -f
```

Partition if needed:

```bash
sudo fdisk /dev/sda
```

Format ext4:

```bash
sudo mkfs.ext4 -F /dev/sda1
```

Create mount:

```bash
sudo mkdir -p /srv/backup
```

Get UUID:

```bash
sudo blkid /dev/sda1
```

Add to fstab:

```
UUID=076e7d9a-4de6-4a1b-841b-1cbe8f5ced69  /srv/backup  ext4  defaults,noatime  0  2
```

Mount:

```bash
sudo mount -a
```

Create clean data folder:

```bash
sudo mkdir -p /srv/backup/data
```

---

# 8️⃣ Create SMB-Only User

```bash
sudo useradd -M -s /usr/sbin/nologin smbuser
sudo passwd smbuser
sudo smbpasswd -a smbuser
sudo smbpasswd -e smbuser
```

---

# 9️⃣ Create Shared Group & Permissions

```bash
sudo groupadd smbshare
sudo usermod -aG smbshare smbuser
sudo usermod -aG smbshare $USER
```

Set ownership:

```bash
sudo chgrp -R smbshare /srv/backup /srv/media/data
sudo chmod -R 2775 /srv/backup /srv/media/data
```

---

# 🔟 Configure Samba

Edit:

```bash
sudo nano /etc/samba/smb.conf
```

Ensure inside `[global]`:

```
[global]
   workgroup = WORKGROUP
   server min protocol = SMB2
```

Add at bottom:

```
[backup]
   path = /srv/backup/data
   browseable = yes
   writable = yes
   read only = no
   valid users = smbuser
   force group = smbshare
   create mask = 0664
   directory mask = 2775

[media]
   path = /srv/media/data
   browseable = yes
   writable = yes
   read only = no
   valid users = smbuser
   force group = smbshare
   create mask = 0664
   directory mask = 2775
```

---

# 1️⃣1️⃣ Restart Samba

```bash
sudo testparm
sudo systemctl restart smbd
```

---

# 1️⃣2️⃣ Test

Linux:

```bash
smbclient -L //<SERVER_IP> -U smbuser
```

Windows:

```
\\SERVER_IP\backup
\\SERVER_IP\media
```

---

# ✅ Final Result

You now have:

- XFS HDDs
- mergerfs with fill-first policy
- ext4 SSD backup disk
- Spin-down friendly mount options
- Dedicated SMB user
- Clean Samba shares
- Proper Linux permissions
- Stable home server layout
