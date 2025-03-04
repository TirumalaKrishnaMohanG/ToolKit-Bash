#!/bin/bash
# By Tirumala Krishna Mohan Gudimalla

check_admin_rights() {
    if [ "$EUID" -ne 0 ]; then
        echo "You must run this script as root."
        exit 1
    fi
}

detect_platform() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        echo "Detected OS: $OS"
    else
        echo "Cannot detect the OS platform."
        exit 1
    fi
}

install_nginx_ubuntu() {
    echo "Installing Nginx on Ubuntu"
    apt update
    apt install -y curl gnupg2 ca-certificates lsb-release
    echo "deb http://nginx.org/packages/ubuntu/ $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
    apt update
    apt install -y nginx
}

install_nginx_debian() {
    echo "Installing Nginx on Debian"
    apt update
    apt install -y curl gnupg2 ca-certificates lsb-release
    echo "deb http://nginx.org/packages/debian/ $(lsb_release -cs) nginx" | tee /etc/apt/sources.list.d/nginx.list
    curl -fsSL https://nginx.org/keys/nginx_signing.key | apt-key add -
    apt update
    apt install -y nginx
}

install_nginx_centos() {
    echo "Installing Nginx on CentOS"
    yum install -y epel-release
    yum install -y https://nginx.org/packages/centos/7/x86_64/RPMS/nginx-1.20.1-1.el7.ngx.x86_64.rpm
}

install_nginx_fedora() {
    echo "Installing Nginx on Fedora"
    yum install -y epel-release
    yum install -y https://nginx.org/packages/mainline/fedora/34/x86_64/RPMS/nginx-1.21.1-1.fc34.ngx.x86_64.rpm
}

install_nginx_rhel() {
    echo "Installing Nginx on RHEL"
    yum install -y epel-release
    yum install -y https://nginx.org/packages/rhel/7/x86_64/RPMS/nginx-1.20.1-1.el7.ngx.x86_64.rpm
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
        *)
            echo "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

check_installation() {
    if command -v nginx &> /dev/null; then
        echo "Nginx installation successful"
    else
        echo "Nginx installation failed"
        exit 1
    fi
}

start_nginx() {
    echo "Starting Nginx service"
    systemctl start nginx
}

check_service_status() {
    if systemctl is-active --quiet nginx; then
        echo -e "Nginx is running"
    else
        echo -e "Nginx failed to start"
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
