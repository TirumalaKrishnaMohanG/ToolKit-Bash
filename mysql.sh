#!/bin/bash
# By Tirumala Krishna Mohan Gudimalla

check_admin_rights() {
    if [ "$EUID" -ne 0 ]; then
        echo "You must run this script as root."
        exit 1
    else
        echo "=> Checking admin rights: OK"
    fi
}

detect_platform() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=${VERSION_ID%%.*} # Extract major version only
        echo "=> Detected platform: $OS $VERSION_ID"
    else
        echo "Cannot detect the OS platform."
        exit 1
    fi
}

install_mysql_ubuntu() {
    echo "=> Installing MySQL on Ubuntu"
    apt update -qq &> /dev/null
    apt install -y -qq mysql-server &> /dev/null
}

install_mysql_debian() {
    echo "=> Installing MySQL on Debian"
    apt update -qq &> /dev/null
    apt install -y -qq mysql-server &> /dev/null
}

install_mysql_centos() {
    echo "=> Installing MySQL on CentOS"
    yum install -y -q mysql-server &> /dev/null
}

install_mysql_rhel() {
    echo "=> Installing MySQL on RHEL"
    yum install -y -q mysql-server &> /dev/null
}

install_mysql_fedora() {
    echo "=> Installing MySQL on Fedora"
    dnf install -y -q mysql-server &> /dev/null
}

install_mysql_amzn() {
    echo "=> Installing MySQL on Amazon Linux $VERSION_ID"

    if [[ "$VERSION_ID" -ge 2023 ]]; then
        dnf install -y mysql-server &> /dev/null
    else
        amazon-linux-extras enable mysql8.0 &> /dev/null
        yum clean metadata &> /dev/null
        yum install -y mysql-server &> /dev/null
    fi

    # Check if MySQL was installed successfully
    if ! command -v mysqld &> /dev/null; then
        echo "=> MySQL installation failed. Attempting MariaDB installation."
        dnf install -y mariadb-server &> /dev/null
    fi

    systemctl enable --now mysqld &> /dev/null
}

install_mysql_opensuse() {
    echo "=> Installing MySQL on OpenSUSE"
    zypper install -y mysql-server &> /dev/null
}

install_mysql_arch() {
    echo "=> Installing MySQL on Arch Linux"
    pacman -Sy --noconfirm mysql &> /dev/null
}

install_mysql() {
    case "$OS" in
        ubuntu) install_mysql_ubuntu ;;
        debian) install_mysql_debian ;;
        centos) install_mysql_centos ;;
        rhel) install_mysql_rhel ;;
        fedora) install_mysql_fedora ;;
        amzn) install_mysql_amzn ;;
        opensuse*|sles) install_mysql_opensuse ;;
        arch) install_mysql_arch ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

check_installation() {
    if command -v mysql &> /dev/null || command -v mariadb &> /dev/null; then
        echo "=> MySQL/MariaDB installation successful"
    else
        echo "=> MySQL/MariaDB installation failed"
        exit 1
    fi
}

start_mysql() {
    echo "=> Starting MySQL service"
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        systemctl start mysql &> /dev/null
        systemctl enable mysql &> /dev/null
    else
        systemctl start mysqld &> /dev/null
        systemctl enable mysqld &> /dev/null
    fi
}

check_service_status() {
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        service_name="mysql"
    else
        service_name="mysqld"
    fi

    if systemctl is-active --quiet $service_name; then
        echo "=> MySQL/MariaDB is running"
    else
        echo "=> MySQL/MariaDB failed to start"
    fi
}

main() {
    echo "Starting MySQL installation"
    check_admin_rights
    detect_platform
    install_mysql
    check_installation
    start_mysql
    check_service_status
    echo "MySQL installation completed"
}

main
