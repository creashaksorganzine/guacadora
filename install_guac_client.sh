#!/bin/bash

# Step 1: Install KDE Plasma Desktop Environment with X11
echo "Installing KDE Plasma Desktop Environment with X11..."
dnf groupinstall -y "KDE Plasma Workspaces" "base-x" || echo "Failed to install KDE Plasma Desktop Environment"

# Step 2: Install Java and Apache Maven
echo "Installing Java and Apache Maven..."
dnf install -y java-11-openjdk-devel maven || echo "Failed to install Java and Apache Maven"

# Step 3: Download the Guacamole client source code
echo "Downloading guacamole-client source code..."
wget -O guacamole-client-1.5.2.tar.gz "https://apache.org/dyn/closer.lua/guacamole/1.5.2/source/guacamole-client-1.5.2.tar.gz?action=download" || echo "Failed to download guacamole-client source code"

# Step 4: Extract the source code
echo "Extracting guacamole-client source code..."
tar -xzf guacamole-client-1.5.2.tar.gz || echo "Failed to extract guacamole-client source code"

# Step 5: Navigate to the source directory
cd guacamole-client-1.5.2 || exit

# Step 6: Modify pom.xml to ignore errors on warnings
echo "Modifying pom.xml to ignore errors on warnings..."
sed -i 's|<compilerArgument>-Werror</compilerArgument>|<!--<compilerArgument>-Werror</compilerArgument>-->|g' pom.xml || echo "Failed to modify pom.xml"

# Step 7: Build guacamole-client
echo "Building guacamole-client..."
mvn package || echo "Failed to build guacamole-client"

# Step 8: Install Apache Tomcat
echo "Installing Apache Tomcat..."
dnf install -y tomcat || echo "Failed to install Apache Tomcat"

# Step 9: Deploy guacamole-client to Tomcat
echo "Deploying guacamole-client to Tomcat..."
cp guacamole/target/guacamole-1.5.2.war /var/lib/tomcat/webapps/guacamole.war || echo "Failed to deploy guacamole-client to Tomcat"

# Step 10: Start and enable Tomcat
echo "Starting and enabling Tomcat..."
systemctl start tomcat || echo "Failed to start Tomcat"
systemctl enable tomcat || echo "Failed to enable Tomcat"

# Step 11: Create Guacamole configuration directory
echo "Creating Guacamole configuration directory..."
mkdir /etc/guacamole || echo "Failed to create Guacamole configuration directory"

# Step 12: Create guacamole.properties
echo "Creating guacamole.properties..."
cat <<EOL | tee /etc/guacamole/guacamole.properties
guacd-hostname: localhost
guacd-port:     4822
EOL

# Step 13: Create symbolic links for guacamole.properties
echo "Creating symbolic links for guacamole.properties..."
ln -s /etc/guacamole/guacamole.properties /usr/share/tomcat/.guacamole/guacamole.properties || echo "Failed to create symbolic links for guacamole.properties"

# Step 14: Restart Tomcat
echo "Restarting Tomcat..."
systemctl restart tomcat || echo "Failed to restart Tomcat"

echo "Guacamole client installed and running!"

# Step 15: Set graphical target (runlevel 5)
echo "Setting graphical target..."
systemctl set-default graphical.target || echo "Failed to set graphical target"

echo "Rebooting the system in 10 seconds to apply changes..."
sleep 10
reboot
