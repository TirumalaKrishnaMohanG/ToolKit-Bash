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
        echo "=> Detected platform: $OS"
    else
        echo "Cannot detect the OS platform."
        exit 1
    fi
}

install_apache_ubuntu() {
    echo "=> Installing Apache on Ubuntu"

    apt update -qq &> /dev/null
    apt install -y -qq curl gnupg2 ca-certificates lsb-release &> /dev/null

    KEY_FILE="/usr/share/keyrings/apache-ondrej-keyring.gpg"

    # Check if the key already exists
    if gpg --quiet --no-default-keyring --keyring "$KEY_FILE" --list-keys 4F4EA0AAE5267A6C &> /dev/null; then
        echo "=> GPG key already exists. Skipping key retrieval."
    else
        echo "=> Retrieving the GPG key..."
        gpg --no-default-keyring --keyring "$KEY_FILE" --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4F4EA0AAE5267A6C &> /dev/null
        if [[ $? -ne 0 ]]; then
            echo "=> Failed to retrieve the GPG key! Exiting."
            exit 1
        fi
    fi

    # Add the repository securely
    echo "deb [signed-by=$KEY_FILE] http://ppa.launchpad.net/ondrej/apache2/ubuntu $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/apache2.list > /dev/null

    apt update -qq &> /dev/null
    apt install -y -qq apache2 &> /dev/null
}

install_apache_debian() {
    echo "=> Installing Apache on Debian"

    apt update -qq &> /dev/null
    apt install -y -qq curl gnupg2 ca-certificates lsb-release &> /dev/null

    KEY_FILE="/usr/share/keyrings/apache-ondrej-keyring.gpg"

    if gpg --quiet --no-default-keyring --keyring "$KEY_FILE" --list-keys 4F4EA0AAE5267A6C &> /dev/null; then
        echo "=> GPG key already exists. Skipping key retrieval."
    else
        echo "=> Retrieving the GPG key..."
        gpg --no-default-keyring --keyring "$KEY_FILE" --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 4F4EA0AAE5267A6C &> /dev/null
        if [[ $? -ne 0 ]]; then
            echo "=> Failed to retrieve the GPG key! Exiting."
            exit 1
        fi
    fi

    echo "deb [signed-by=$KEY_FILE] http://ppa.launchpad.net/ondrej/apache2/debian $(lsb_release -cs) main" \
        | tee /etc/apt/sources.list.d/apache2.list > /dev/null

    apt update -qq &> /dev/null
    apt install -y -qq apache2 &> /dev/null
}

install_apache_centos() {
    echo "=> Installing Apache on CentOS"
    yum install -y -q epel-release &> /dev/null
    yum install -y -q httpd &> /dev/null
}

install_apache_fedora() {
    echo "=> Installing Apache on Fedora"
    dnf install -y -q httpd &> /dev/null
}

install_apache_rhel() {
    echo "=> Installing Apache on RHEL"
    yum install -y -q epel-release &> /dev/null
    yum install -y -q httpd &> /dev/null
}

install_apache_amzn() {
    echo "=> Installing Apache on Amazon Linux"
    amazon-linux-extras enable epel &> /dev/null
    yum install -y -q httpd &> /dev/null
    systemctl enable httpd &> /dev/null
}

install_apache() {
    case $OS in
        ubuntu)
            install_apache_ubuntu
            ;;
        debian)
            install_apache_debian
            ;;
        centos)
            install_apache_centos
            ;;
        fedora)
            install_apache_fedora
            ;;
        rhel)
            install_apache_rhel
            ;;
        amzn)
            install_apache_amzn
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

check_installation() {
    if command -v apache2 &> /dev/null || command -v httpd &> /dev/null; then
        echo "=> Apache installation successful"
    else
        echo "=> Apache installation failed"
        exit 1
    fi
}

start_apache() {
    echo "=> Starting Apache service"
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        systemctl start apache2 &> /dev/null
        systemctl enable apache2 &> /dev/null
    else
        systemctl start httpd &> /dev/null
        systemctl enable httpd &> /dev/null
    fi
}

check_service_status() {
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        service_name="apache2"
    else
        service_name="httpd"
    fi

    if systemctl is-active --quiet $service_name; then
        echo "=> Apache is running"
    else
        echo "=> Apache failed to start"
    fi
}

main() {
    echo "Starting Apache installation"
    check_admin_rights
    detect_platform
    install_apache
    check_installation
    start_apache
    check_service_status
    echo "Apache installation completed"
}

main