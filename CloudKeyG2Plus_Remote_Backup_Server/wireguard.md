# Cloud Key Gen2 Plus – WireGuard Client Setup (Debian 11, Kernel 3.18)

This guide documents how to install and run **WireGuard in userspace mode** on a **Ubiquiti Cloud Key Gen2 Plus** running:

- Debian 11 (bullseye)
- Kernel 3.18.44-ui-qcom (no native WireGuard module)

Because the kernel is too old for the WireGuard module, we use **wireguard-go (userspace implementation)**.

---

# 1. Update system

```bash
apt update
apt upgrade -y
```

---

# 2. Install required packages

```bash
apt install wireguard-tools build-essential git -y
```

- `wireguard-tools` → provides `wg` and `wg-quick`
- `build-essential` → required to build wireguard-go
- `git` → to clone source

---

# 3. Install a newer Go version (if required)

Bullseye default Go may be too old. Install from backports:

```bash
apt -t bullseye-backports install golang -y
```

Verify:

```bash
go version
```

You need Go ≥ 1.17.

---

# 4. Build wireguard-go (userspace engine)

```bash
cd /tmp
git clone https://git.zx2c4.com/wireguard-go
cd wireguard-go
make
```

Install binary:

```bash
cp wireguard-go /usr/local/bin/
chmod +x /usr/local/bin/wireguard-go
```

Verify:

```bash
/usr/local/bin/wireguard-go -version
```

---

# 5. Create WireGuard configuration

Create directory:

```bash
mkdir -p /etc/wireguard
```

Create config file:

```bash
nano /etc/wireguard/wg0.conf
```

Example **client configuration (full tunnel)**:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY
Address = 10.0.0.4/32

[Peer]
PublicKey = YOUR_SERVER_PUBLIC_KEY
Endpoint = your.ddns.domain:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

⚠ If you want split tunnel instead of full tunnel:

```
AllowedIPs = 10.0.0.0/24
```

Secure the file:

```bash
chmod 600 /etc/wireguard/wg0.conf
```

---

# 6. Bring the tunnel up

Because the kernel module is missing, `wg-quick` will automatically fall back to userspace mode.

```bash
wg-quick up wg0
```

You should see:

```
Missing WireGuard kernel module. Falling back to slow userspace implementation.
```

That is expected.

Check status:

```bash
wg
```

You should see:

```
latest handshake: X seconds ago
transfer: ...
```

---

# 7. Verify routing (full tunnel)

Test public IP:

```bash
curl ifconfig.me
```

If full tunnel works, it should show your **home public IP**, not the remote ISP IP.

Check routing rules:

```bash
ip rule
ip route
```

wg-quick creates policy routing table `51820` automatically.

---

# 8. Enable auto-start at boot

```bash
systemctl enable wg-quick@wg0
```

To start immediately:

```bash
systemctl start wg-quick@wg0
```

---

# 9. Performance Notes

On Cloud Key Gen2 Plus:

- Kernel: 3.18
- Userspace WireGuard
- ARM CPU (no crypto acceleration)

Expected throughput:

- ~200–400 Mbps
- ~25–50 MB/s file transfer
- CPU usage ~50-60% during heavy transfers

This is normal and hardware-limited.

---

# 10. Troubleshooting

### If you see:

```
RTNETLINK answers: Operation not supported
```

This is normal — kernel module is missing. Userspace fallback will activate automatically.

---

### If you see:

```
resolvconf: command not found
```

Either:

- Remove `DNS=` line from config  
or  
- Install resolvconf:

```bash
apt install resolvconf -y
```

---

### Check handshake

```bash
wg
```

If handshake shows `never`, generate traffic:

```bash
ping 10.0.0.1
```

---

# Result

You now have:

- Cloud Key Gen2 Plus
- Working WireGuard client
- Userspace fallback mode
- Optional full-tunnel routing
- Persistent startup

No firmware flashing required.
No kernel upgrade required.
Stable and production-ready.
