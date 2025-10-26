#!/bin/bash

echo "CONFIGURACIÓN DE APACHE"

apt-get update
apt-get install --yes apache2 bind9 dnsutils ufw
a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests

cp "/vagrant/servidor1/000-default.conf" "/etc/apache2/sites-available/000-default.conf"
apache2ctl configtest

systemctl restart apache2

echo "CONFIGURACIÓN DE DNS"

cp "/vagrant/servidor1/named.conf.local" "/etc/bind/named.conf.local"

mkdir "/etc/bind/zones"
cp "/vagrant/servidor1/db.proyectofinal.local" "/etc/bind/zones/db.proyectofinal.local"
cp "/vagrant/servidor1/db.192" "/etc/bind/zones/db.192"

named-checkconf
named-checkzone proyectofinal.local /etc/bind/zones/db.proyectofinal.local
named-checkzone 56.168.192.in-addr.arpa /etc/bind/zones/db.192

systemctl restart bind9

echo "CONFIGURACIÓN DE FIREWALL"

ufw allow ssh # Vagrant
ufw allow http # Apache
ufw allow Bind9 # DNS

echo "y" | ufw enable
