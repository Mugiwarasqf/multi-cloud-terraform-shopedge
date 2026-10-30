#!/bin/bash
yum update -y
yum install -y java-17-amazon-corretto

# Create a simple application
mkdir -p /opt/app
cat <<EOF > /opt/app/app.sh
#!/bin/bash
echo "Application Server ${instance_id} is running"
echo "Database endpoint: ${db_endpoint}"
echo "Listening on port 8080"
while true; do
    echo "App server ${instance_id} - \$(date)" >> /var/log/app.log
    sleep 60
done
EOF

chmod +x /opt/app/app.sh

# Create systemd service
cat <<EOF > /etc/systemd/system/app.service
[Unit]
Description=Application Server
After=network.target

[Service]
Type=simple
User=ec2-user
ExecStart=/opt/app/app.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start app
systemctl enable app
