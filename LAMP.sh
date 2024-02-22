#!/bin/bash

function print_color(){
    case $1 in 
        "green") COLOR="\033[0;32m"
            ;;
        "red") COLOR="\033[0;31m"
            ;;
        "yellow") COLOR= "\033[0;33m"
            ;;
        "blue") COLOR= "\033[0;34m"
            ;;
        "purple") COLOR= "\033[0;35m"
            ;;
        "cyan") COLOR= "\033[0;36m"
            ;;
        "white") COLOR= "\033[0;37m"
            ;;
        "*") COLOR="\033[0m"
            ;;
    esac
    echo -e "${COLOR} $2 ${NC}"
}

function check_service_status(){
    is_service_active=$(sudo systemctl is-active $1)

    if [ $is_service_active = "active"]
    then
        print_color "green" "$1 service is active"
    else
        print_color "red" "$1 service is inactive"
        exit 1
    fi
}

function is_firewalld_rule_configured(){
    firewalld_ports=$(sudo firewall-cmd --list-all --zone=public | grep ports)

    if [[ $firewalld_ports = *$1* ]]
    then
        print_color "green" "Port $1 configured"
    else
        print_color "red" "Port $1 not configured"
        exit 1
    fi
}

#function print_green(){
#    GREEN="\033[0;32m"
#    NC="\033[0m"
#    echo -e "${GREEN} $1 ${NC}"
#}

print_color "green" "Install and configure firewall"
sudo yum install -y firewalld
sudo service firewalld start
sudo systemctl enable firewalld

check_service_status firewalld

print_color "green" "Install mariadb..."
sudo yum install -y mariadb-server
sudo service mariadb start
sudo systemctl enable mariadb

check_service_status mariadb

print_color "green" "Adding firewall rule for DB..."
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

is_firewalld_rule_configured 3306

print_color "green" "configure DB..."
cat > configure-db.sql <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF

cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products
EOF

print_color "green" "Install apache web and php..."
sudo yum install -y httpd php php-mysql git
sudo service httpd start
sudo systemctl enable httpd

check_service_status httpd


print_color "green" "Adding firewall rule for apache web..."
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

is_firewalld_rule_configured 80

sudo git clone <link> /var/www/html/ 

print_color "green" "All set."
