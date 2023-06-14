#!/bin/bash

# Stop execution on any error
set -e

# Step 1: Install prerequisites
echo "Installing prerequisites..."
dnf install -y gcc libtool cairo-devel libjpeg-turbo-devel \
libpng-devel uuid-devel pango-devel libssh2-devel libtelnet-devel \
libvncserver-devel libvorbis-devel pulseaudio-libs-devel \
openssl-devel freerdp-devel libwebsockets-devel libwebp-devel \
autoconf automake wget libavcodec-free libavformat-free libavutil-free \
libswscale-free libguac-*

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

# Additional Steps:
# Download the Guacamole Client
# Prompt the user for the initial yes/no response
read -p "Would you like to download the Guac Client? Enter 'y' or 'n': " response

# Loop until a valid response is entered
while [[ ! "$response" =~ ^(y|n)$ ]]; do
    read -p "Invalid input. Please enter 'y' or 'n': " response
done

# Process the response
if [[ "$response" == "y" ]]; then
    # Prompt the user for the download option
    read -p "Enter the number of the file you want to download:
    1. guacamole-client-1.5.2.tar.gz
    2. guacamole-1.5.2.war
    3. exit
    Your choice: " download_choice

    # Loop until a valid response is entered
    while [[ ! "$download_choice" =~ ^[1-3]$ ]]; do
    read -p "Invalid input. Please enter a number between 1 and 3: " download_choice
    done

    # Process the download choice
    case "$download_choice" in
        1)
        echo "Downloading guacamole-client-1.5.2.tar.gz..."
        wget https://apache.org/dyn/closer.lua/guacamole/1.5.2/source/guacamole-client-1.5.2.tar.gz?action=download
        ;;
        2)
        echo "Downloading guacamole-1.5.2.war..."
        wget https://apache.org/dyn/closer.lua/guacamole/1.5.2/binary/guacamole-1.5.2.war?action=download
        ;;
        3)
        echo "You can also use a Docker container. For more information vist;
        https://guacamole.apache.org/doc/gug/installing-guacamole.html 
        Exiting..."
        exit 0
        ;;
    esac

else
    echo "No download option selected. Exiting..."
fi


