#!/bin/bash
# By Tirumala Krishna Mohan Gudimalla
# Version: v0.1.0
# Date: 2021-08-29
# The script is used to install Gophish on most supported Linux distributions.

# Determine whether to use sudo or not
if [[ "$EUID" -ne 0 ]]; then
    SUDO="sudo"
    echo "=> Running with sudo"
else
    SUDO=""
    echo "=> Running as root"
fi

# Variables
GOPHISH_DIR="/opt/gophish"
MYSQL_DB="gophish"
MYSQL_USER="gophish"
MYSQL_PASS="GophishSecurePass123"
CURRENT_USER=$(whoami)

# Function: Install Dependencies
install_dependencies() {
    echo "=> Installing dependencies..."
    $SUDO apt update -qq
    $SUDO apt install -y -qq mysql-server unzip wget curl openssl
}

# Function: Download & Extract Gophish
install_gophish() {
    echo "=> Downloading Gophish..."
    GOPHISH_LATEST=$(curl -s https://api.github.com/repos/gophish/gophish/releases/latest | grep "browser_download_url.*linux-64bit.zip" | cut -d '"' -f 4)
    $SUDO wget -O gophish.zip $GOPHISH_LATEST
    $SUDO unzip gophish.zip -d $GOPHISH_DIR
    $SUDO rm gophish.zip
}

# Function: Ensure Gophish is Executable
fix_gophish_permissions() {
    echo "=> Fixing permissions..."
    $SUDO chmod +x $GOPHISH_DIR/gophish
    $SUDO chown -R $CURRENT_USER:$CURRENT_USER $GOPHISH_DIR
}

# Function: Setup MySQL Database
setup_mysql() {
    echo "=> Configuring MySQL..."
    $SUDO mysql -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"
    $SUDO mysql -e "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASS';"
    $SUDO mysql -e "GRANT ALL PRIVILEGES ON $MYSQL_DB.* TO '$MYSQL_USER'@'localhost';"
    $SUDO mysql -e "FLUSH PRIVILEGES;"
}

# Function: Update last_login to Current Time
fix_last_login() {
    echo "=> Waiting for MySQL to start..."
    sleep 3
    echo "=> Updating last_login column in MySQL..."
    $SUDO mysql -D $MYSQL_DB -e "UPDATE users SET last_login = NOW() WHERE last_login = '0000-00-00 00:00:00';"
    echo "✅ last_login updated successfully!"
}

# Function: Configure Systemd Service
setup_systemd() {
    echo "=> Configuring Gophish systemd service..."
    $SUDO tee /etc/systemd/system/gophish.service > /dev/null <<EOL
[Unit]
Description=Gophish Phishing Server
After=network.target

[Service]
User=$CURRENT_USER
WorkingDirectory=$GOPHISH_DIR
ExecStart=$GOPHISH_DIR/gophish
Restart=always
LimitNOFILE=100000

[Install]
WantedBy=multi-user.target
EOL

    echo "=> Reloading systemd and starting services..."
    $SUDO systemctl daemon-reload
    $SUDO systemctl enable mysql gophish
    $SUDO systemctl restart mysql
    sleep 5  # Ensure MySQL starts before fixing last_login
    fix_last_login  # Update last_login before Gophish starts
    $SUDO systemctl restart gophish
}

# Function: Verify Services Are Running
verify_services() {
    echo "=> Checking MySQL & Gophish status..."
    SERVICES=(mysql gophish)
    for SERVICE in "${SERVICES[@]}"; do
        if $SUDO systemctl is-active --quiet $SERVICE; then
            echo "✅ $SERVICE is running!"
        else
            echo "❌ $SERVICE failed to start!"
            echo "🔍 Run: sudo journalctl -u $SERVICE --no-pager --lines=50"
            exit 1
        fi
    done
}

# Main function
main() {
    echo "📌 Starting Gophish installation..."
    
    install_dependencies
    install_gophish
    fix_gophish_permissions
    setup_mysql
    setup_systemd
    verify_services

    echo "✅ Gophish installation completed!"
    echo "🌍 Admin Panel: https://<server-ip>:3333"
}

# Run the main function
main
