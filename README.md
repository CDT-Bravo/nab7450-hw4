# iptables_flusher.sh

## Overview
This script sets up a systemd service and timer to periodically flush all iptables rules every 2-3 minutes. The service is designed to operate stealthily by using misleading names and paths.

## Features
- Creates a hidden script (`/usr/local/bin/.cache-cleaner`) that flushes iptables rules.
- Sets up a systemd service (`networkd-help.service`) to execute the script.
- Configures a systemd timer (`networkd-help.timer`) to run the service at randomized intervals (every 2-3 minutes).
- Automatically starts and enables the service and timer on system boot.
- Includes a restart mechanism if the service fails.

## Installation
Run the script as root to install the service and timer:
```bash
chmod +x iptables_flusher.sh
sudo ./iptables_flusher.sh
```

## How It Works
1. **Hidden Script (`.cache-cleaner`)**
   - Flushes all iptables rules (nat, mangle, and filter tables).
   - Stored in `/usr/local/bin/.cache-cleaner`.
   
2. **Systemd Service (`networkd-help.service`)**
   - Runs the `.cache-cleaner` script as root.
   - Restarts if it fails.
   
3. **Systemd Timer (`networkd-help.timer`)**
   - Runs 3 minutes after boot.
   - Repeats every 2-3 minutes with a randomized delay.
   - Ensures persistence across reboots.

## Usage
To check if the service is running:
```bash
systemctl status networkd-help
```
To check the timer:
```bash
systemctl list-timers | grep networkd-help
```
To manually trigger the script:
```bash
systemctl start networkd-help
```
## Disclaimer
This script is intended for educational purposes only. Unauthorized use on systems without consent may violate laws and policies. Use responsibly.


