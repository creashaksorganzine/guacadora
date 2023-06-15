#!/bin/bash

set -e

# Check if script is run as root or if user has sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo privileges" >&2
   exit 1
fi

# Variables
GUACD_CONTAINER_NAME="guacd"
MYSQL_CONTAINER_NAME="mysql"
GUACAMOLE_CONTAINER_NAME="guacamole"
MYSQL_DATABASE="guacamole_db"
MYSQL_USER="thor"
MYSQL_PASSWORD="TdJddrxcjK7CSCkY"
MYSQL_ROOT_PASSWORD="TdJddrxcjK7CSCkY"
DOCKER_COMPOSE_FILE="/tmp/docker-compose.yml"
INITDB_FILE="/tmp/initdb.sql"

# Function to clean up if script exits
cleanup() {
    rm -f $DOCKER_COMPOSE_FILE
    rm -f $INITDB_FILE
}

trap cleanup EXIT

# Function to install and start Docker
install_docker() {
    echo "Updating the system..."
    dnf update -y

    echo "Installing Docker..."
    dnf config-manager --add-repo=https://download.docker.com/linux/fedora/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-compose

    echo "Starting Docker..."
    systemctl start docker
    systemctl enable docker
}

# Function to create and start containers with docker-compose
create_and_start_containers() {
    echo "Creating docker-compose file..."
    cat <<EOL > $DOCKER_COMPOSE_FILE
version: "3.1"
services:
  guacd:
    image: guacamole/guacd
    container_name: $GUACD_CONTAINER_NAME
    ports:
      - "4822:4822"

  mysql:
    image: mysql:5.7
    container_name: $MYSQL_CONTAINER_NAME
    environment:
      MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD
    volumes:
      - mysql-data:/var/lib/mysql

  guacamole:
    image: guacamole/guacamole
    container_name: $GUACAMOLE_CONTAINER_NAME
    ports:
      - "8080:8080"
    environment:
      MYSQL_DATABASE: $MYSQL_DATABASE
      MYSQL_USER: $MYSQL_USER
      MYSQL_PASSWORD: $MYSQL_PASSWORD
      MYSQL_HOSTNAME: $MYSQL_CONTAINER_NAME
      MYSQL_PORT: "3306"
      GUACD_HOSTNAME: $GUACD_CONTAINER_NAME
    depends_on:
      - guacd
      - mysql

volumes:
  mysql-data:
    driver: local
EOL

    echo "Starting containers with docker-compose..."
    docker-compose -f $DOCKER_COMPOSE_FILE up -d

    echo "Waiting for MySQL to initialize..."
    sleep 30
}

# Function to initialize the MySQL database
initialize_mysql() {
    echo "Generating database initialization script..."
    docker run --rm guacamole/guacamole /opt/guacamole/bin/initdb.sh --mysql > $INITDB_FILE

    docker cp $INITDB_FILE ${MYSQL_CONTAINER_NAME}:/initdb.sql

    echo "Initializing MySQL database..."
    docker exec -i $MYSQL_CONTAINER_NAME mysql -u root -p$MYSQL_ROOT_PASSWORD <<QUERY_INPUT
CREATE DATABASE $MYSQL_DATABASE;
CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
USE $MYSQL_DATABASE;
SOURCE /initdb.sql;
QUERY_INPUT
}

# Function to optionally open ports in the firewall
open_firewall_ports() {
    echo "Opening ports in the firewall..."
    firewall-cmd --add-port=8080/tcp --permanent
    firewall-cmd --add-port=4822/tcp --permanent
    firewall-cmd --reload
}

# Main Script
install_docker
create_and_start_containers
initialize_mysql
open_firewall_ports

echo "Guacamole setup complete. Access it at http://<HOSTNAME>:8080/guacamole/ using default credentials guacadmin/guacadmin."
