#!/bin/bash

# Define file paths
SYSTEMD_SERVICE="/etc/systemd/system/iptables-restore.service"
SYSTEMD_TIMER="/etc/systemd/system/iptables-restore.timer"
HIDDEN_SCRIPT="/usr/local/bin/.iptables-restore"

# Create hidden script that sets iptables rules
echo "[+] Creating hidden iptables rule script..."
echo "#!/bin/bash" > $HIDDEN_SCRIPT
echo "iptables -F" >> $HIDDEN_SCRIPT
echo "iptables -X" >> $HIDDEN_SCRIPT
echo "iptables -P INPUT DROP" >> $HIDDEN_SCRIPT
echo "iptables -P FORWARD DROP" >> $HIDDEN_SCRIPT
echo "iptables -P OUTPUT DROP" >> $HIDDEN_SCRIPT

echo "iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT" >> $HIDDEN_SCRIPT
echo "iptables -A INPUT -p tcp --dport 22 -j ACCEPT" >> $HIDDEN_SCRIPT  # Fully allow SSH
echo "iptables -A OUTPUT -p tcp --sport 22 -j ACCEPT" >> $HIDDEN_SCRIPT  # Fully allow SSH outbound
echo "iptables -A INPUT -p tcp --dport 139 -j ACCEPT" >> $HIDDEN_SCRIPT  # Fully allow SMB
echo "iptables -A INPUT -p tcp --dport 445 -j ACCEPT" >> $HIDDEN_SCRIPT  # Fully allow SMB
echo "iptables -A OUTPUT -p tcp --sport 139 -j ACCEPT" >> $HIDDEN_SCRIPT  # Fully allow SMB outbound
echo "iptables -A OUTPUT -p tcp --sport 445 -j ACCEPT" >> $HIDDEN_SCRIPT  # Fully allow SMB outbound
echo "iptables -A INPUT -i lo -j ACCEPT" >> $HIDDEN_SCRIPT  # Allow localhost

echo "iptables -A OUTPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT" >> $HIDDEN_SCRIPT  # Allow response traffic
echo "iptables -A OUTPUT -p udp --dport 53 -j ACCEPT" >> $HIDDEN_SCRIPT  # Allow DNS lookups

echo "# Allow HTTP/HTTPS only to Ubuntu repositories" >> $HIDDEN_SCRIPT
echo "iptables -A OUTPUT -p tcp --dport 80 -d archive.ubuntu.com -j ACCEPT" >> $HIDDEN_SCRIPT
echo "iptables -A OUTPUT -p tcp --dport 443 -d archive.ubuntu.com -j ACCEPT" >> $HIDDEN_SCRIPT
echo "iptables -A OUTPUT -p tcp --dport 80 -d security.ubuntu.com -j ACCEPT" >> $HIDDEN_SCRIPT
echo "iptables -A OUTPUT -p tcp --dport 443 -d security.ubuntu.com -j ACCEPT" >> $HIDDEN_SCRIPT

chmod +x $HIDDEN_SCRIPT

# Create systemd service file
echo "[+] Creating systemd service file..."
cat <<EOF > $SYSTEMD_SERVICE
[Unit]
Description=Periodic restores iptables
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
OnBootSec=1min
OnUnitInactiveSec=1min
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd, enable, and start the service & timer
echo "[+] Reloading systemd and enabling the service and timer..."
systemctl daemon-reload
systemctl enable iptables-restore
systemctl enable iptables-restore.timer
systemctl start iptables-restore
systemctl start iptables-restore.timer

# Verify service and timer status
echo "[+] Checking service status..."
systemctl status iptables-restore --no-pager

echo "[+] Checking timer status..."
systemctl list-timers --no-pager | grep iptables-restore

echo "[✔] Iptables rule setup complete! Rules will be applied every 1-2 minutes."
