#!/bin/bash

# Stop execution on any error
set -e

# Step 1: Install prerequisites
echo "Installing prerequisites..."
dnf install -y gcc libtool cairo-devel libjpeg-turbo-devel \
libpng-devel uuid-devel pango-devel libssh2-devel libtelnet-devel \
libvncserver-devel libvorbis-devel pulseaudio-libs-devel \
openssl-devel freerdp-devel libwebsockets-devel libwebp-devel \
autoconf automake wget

# Step 2: Download the source code
echo "Downloading guacamole-server source code..."
wget -O guacamole-server-1.5.2.tar.gz "https://apache.org/dyn/closer.lua/guacamole/1.5.2/source/guacamole-server-1.5.2.tar.gz?action=download"

# Step 3: Extract the source code
echo "Extracting guacamole-server source code..."
tar -xzf guacamole-server-1.5.2.tar.gz

# Step 4: Navigate to the source directory
cd guacamole-server-1.5.2

# Step 5: Configure the build
echo "Configuring the build..."
./configure --with-init-dir=/etc/init.d

# Step 6: Build the software
echo "Building guacamole-server..."
make

# Step 7: Install the software
echo "Installing guacamole-server..."
make install
ldconfig

# Step 8: Create guacd service file
echo "Creating guacd service file..."
cat <<EOL | sudo tee /etc/systemd/system/guacd.service
[Unit]
Description=Guacamole proxy daemon
After=network.target
StartLimitIntervalSec=0

[Service]
ExecStart=/usr/local/sbin/guacd -f
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=3s

[Install]
WantedBy=multi-user.target
EOL

# Reload SystemD
echo "Reloading SystemD..."
sudo systemctl daemon-reload

# Step 9: Start the Guacamole server
echo "Starting guacd..."
systemctl start guacd

# Step 10: Enable Guacamole server on boot
echo "Enabling guacd to start on boot..."
systemctl enable guacd

# Step 11: Verify the service status
echo "Checking guacd status..."
systemctl status guacd

echo "Guacamole server installed and running!"
