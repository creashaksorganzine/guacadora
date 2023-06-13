#!/bin/bash

# Stop execution on any error
set -e

# Step 1: Install KDE Plasma Desktop Environment with X11
echo "Installing KDE Plasma Desktop Environment with X11..."
dnf groupinstall -y "KDE Plasma Workspaces" "base-x"

# Step 2: Install Java and Apache Maven
echo "Installing Java and Apache Maven..."
dnf install -y java-11-openjdk-devel maven

# Step 3: Download the Guacamole client source code
echo "Downloading guacamole-client source code..."
wget -O guacamole-client-1.5.2.tar.gz "https://apache.org/dyn/closer.lua/guacamole/1.5.2/source/guacamole-client-1.5.2.tar.gz?action=download"

# Step 4: Extract the source code
echo "Extracting guacamole-client source code..."
tar -xzf guacamole-client-1.5.2.tar.gz

# Step 5: Navigate to the source directory
cd guacamole-client-1.5.2

# Step 6: Build guacamole-client
echo "Building guacamole-client..."
mvn package

# Step 7: Install Apache Tomcat
echo "Installing Apache Tomcat..."
dnf install -y tomcat

# Step 8: Deploy guacamole-client to Tomcat
echo "Deploying guacamole-client to Tomcat..."
cp guacamole/target/guacamole-1.5.2.war /var/lib/tomcat/webapps/guacamole.war

# Step 9: Start and enable Tomcat
echo "Starting and enabling Tomcat..."
systemctl start tomcat
systemctl enable tomcat

# Step 10: Create Guacamole configuration directory
echo "Creating Guacamole configuration directory..."
mkdir /etc/guacamole

# Step 11: Create guacamole.properties
echo "Creating guacamole.properties..."
cat <<EOL | tee /etc/guacamole/guacamole.properties
guacd-hostname: localhost
guacd-port:     4822
EOL

# Step 12: Create symbolic links for guacamole.properties
echo "Creating symbolic links for guacamole.properties..."
ln -s /etc/guacamole/guacamole.properties /usr/share/tomcat/.guacamole/guacamole.properties

# Step 13: Restart Tomcat
echo "Restarting Tomcat..."
systemctl restart tomcat

echo "Guacamole client installed and running!"

# Step 14: Set graphical target (runlevel 5)
echo "Setting graphical target..."
systemctl set-default graphical.target

echo "Rebooting the system in 10 seconds to apply changes..."
sleep 10
reboot
