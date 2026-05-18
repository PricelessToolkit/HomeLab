# Cloud Key Gen2 Plus – LED + Battery (UPS) Control from CLI

This page documents how to control the **front LEDs** and read **battery/UPS power state** on a Ubiquiti **Cloud Key Gen2 Plus** using Linux sysfs.

> Notes:
> - When `ls` shows entries ending with `@`, that means **symlink**. The `@` is **not** part of the name.
> - Commands below assume you are `root`.

---

## LED control

### List LEDs
```bash
ls -l /sys/class/leds/
ls /sys/class/leds/
```

On this device we saw:
- `blue`
- `white`
- `ulogo_ctrl`

### Check available triggers
Triggers define what “owns” the LED (system events vs manual control).

```bash
cat /sys/class/leds/blue/trigger
cat /sys/class/leds/white/trigger
cat /sys/class/leds/ulogo_ctrl/trigger
```

The active trigger is shown in brackets, e.g. `[external0]`.

### Take manual control (important)
If a trigger like `external0` is active, setting brightness “on” may not work until you disable the trigger.

```bash
echo none > /sys/class/leds/blue/trigger
echo none > /sys/class/leds/white/trigger
```

### Brightness control
Check the valid range:
```bash
cat /sys/class/leds/blue/max_brightness
cat /sys/class/leds/white/max_brightness
```

Examples (device supports 0–255):
```bash
# Blue LED
echo 255 > /sys/class/leds/blue/brightness   # full on
echo 20  > /sys/class/leds/blue/brightness   # dim
echo 0   > /sys/class/leds/blue/brightness   # off

# White LED
echo 255 > /sys/class/leds/white/brightness
echo 0   > /sys/class/leds/white/brightness
```

### Return control back to the system trigger
If you want the LED to be controlled by the platform again:

```bash
echo external0 > /sys/class/leds/blue/trigger
echo external0 > /sys/class/leds/white/trigger
```

### Optional: Blink (timer trigger)
Only works if `timer` is listed in `trigger`.

```bash
echo timer > /sys/class/leds/blue/trigger
echo 200 > /sys/class/leds/blue/delay_on
echo 200 > /sys/class/leds/blue/delay_off
```

Stop blinking (back to manual):
```bash
echo none > /sys/class/leds/blue/trigger
```

---

## Battery / UPS power status

The CK Gen2 Plus exposes battery + power inputs via `/sys/class/power_supply/`.

### List power supplies
```bash
ls -l /sys/class/power_supply/
ls /sys/class/power_supply/
```

On this device we saw:
- `battery` (internal battery)
- `ext_battery` (external/secondary battery interface)
- `mains` (AC input state)
- `typec` (USB-C power input state)
- `usb` (USB input state)

### Check if AC power is connected
```bash
cat /sys/class/power_supply/mains/online
```

- `1` = AC connected
- `0` = running on battery

### Internal battery status and charge %
```bash
cat /sys/class/power_supply/battery/status
cat /sys/class/power_supply/battery/capacity
```

Common `status` values:
- `Charging`
- `Discharging`
- `Full`
- `Not charging`

### One-line summary
```bash
echo "AC: $(cat /sys/class/power_supply/mains/online) | Status: $(cat /sys/class/power_supply/battery/status) | Charge: $(cat /sys/class/power_supply/battery/capacity)%"
```

Example:
```
AC: 1 | Status: Discharging | Charge: 50%
```

### Dump all battery fields (debug / deep info)
```bash
cat /sys/class/power_supply/battery/uevent
```

This provides key-value fields like:
- `POWER_SUPPLY_STATUS`
- `POWER_SUPPLY_CAPACITY`
- `POWER_SUPPLY_HEALTH`
- `POWER_SUPPLY_TEMP`
- `POWER_SUPPLY_VOLTAGE_NOW`
- etc.

---

## Notes / quirks observed

- It is possible for `mains/online = 1` while `battery/status = Discharging` depending on the charging controller state.
- Some fields (e.g. `voltage_now`) may read `0` depending on driver/firmware; use `battery/uevent` as the most consistent output.
- If “turn on” via `brightness` doesn’t work, ensure the LED `trigger` is set to `none` first.

