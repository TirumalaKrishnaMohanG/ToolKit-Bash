#!/bin/bash
# By Tirumala Krishna Mohan Gudimalla

check_admin_rights() {
    if [ "$EUID" -ne 0 ]; then
        echo "You must run this script as root."
        exit 1
    else
        echo "=> Checking the admin rights, good to install"
    fi
}

detect_platform() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        echo "=> Platform is $OS"
    else
        echo "Cannot detect the OS platform."
        exit 1
    fi
}

install_nginx_ubuntu() {
    echo "=> Download the repository to install the tool - Ubuntu"
    apt update -qq &> /dev/null
    apt install -y -qq curl gnupg2 ca-certificates lsb-release &> /dev/null
    
    # Adding the Nginx repository securely
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
        | tee /etc/apt/sources.list.d/nginx.list > /dev/null

    # Download and store the GPG key in the new standard location
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg

    apt update -qq &> /dev/null
    apt install -y -qq nginx &> /dev/null
}

install_nginx_debian() {
    echo "=> Download the repository to install the tool - Debian"
    apt update -qq &> /dev/null
    apt install -y -qq curl gnupg2 ca-certificates lsb-release &> /dev/null

    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" \
        | tee /etc/apt/sources.list.d/nginx.list > /dev/null

    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor -o /usr/share/keyrings/nginx-archive-keyring.gpg

    apt update -qq &> /dev/null
    apt install -y -qq nginx &> /dev/null
}

install_nginx_centos() {
    echo "=> Download the repository to install the tool - CentOS"
    yum install -y -q epel-release &> /dev/null
    yum install -y -q https://nginx.org/packages/centos/7/x86_64/RPMS/nginx-1.20.1-1.el7.ngx.x86_64.rpm &> /dev/null
}

install_nginx_fedora() {
    echo "=> Download the repository to install the tool - Fedora"
    yum install -y -q epel-release &> /dev/null
    yum install -y -q https://nginx.org/packages/mainline/fedora/34/x86_64/RPMS/nginx-1.21.1-1.fc34.ngx.x86_64.rpm &> /dev/null
}

install_nginx_rhel() {
    echo "=> Download the repository to install the tool - RHEL"
    yum install -y -q epel-release &> /dev/null
    yum install -y -q https://nginx.org/packages/rhel/7/x86_64/RPMS/nginx-1.20.1-1.el7.ngx.x86_64.rpm &> /dev/null
}

install_nginx_amzn() {
    echo "=> Download the repository to install the tool - Amazon Linux"

    # Ensure DNF is up to date
    dnf update -y &> /dev/null
    
    # Install Nginx from Amazon's default repositories
    dnf install -y nginx &> /dev/null

    if command -v nginx &> /dev/null; then
        echo "=> Nginx installed successfully on Amazon Linux"
        systemctl enable nginx &> /dev/null
    else
        echo "=> Installation failed"
        exit 1
    fi
}


install_nginx() {
    case $OS in
        ubuntu)
            install_nginx_ubuntu
            ;;
        debian)
            install_nginx_debian
            ;;
        centos)
            install_nginx_centos
            ;;
        fedora)
            install_nginx_fedora
            ;;
        rhel)
            install_nginx_rhel
            ;;
        amzn)
            install_nginx_amzn
            ;;
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

check_installation() {
    if command -v nginx &> /dev/null; then
        echo "=> Installation successful"
    else
        echo "=> Installation failed"
        exit 1
    fi
}

start_nginx() {
    echo "=> Starting Nginx service"
    systemctl start nginx &> /dev/null
}

check_service_status() {
    if systemctl is-active --quiet nginx; then
        echo "=> Nginx is running"
    else
        echo "=> Nginx failed to start"
    fi
}

main() {
    echo "Starting Nginx installation"
    check_admin_rights
    detect_platform
    install_nginx
    check_installation
    start_nginx
    check_service_status
    echo "Nginx installation completed"
}

main
