#!/bin/bash

# Script de provisión para servidor1 (VM con IP 192.168.56.2)

SHARED_DIR="/vagrant/servidor1"

echo "=== Inicio de provisión servidor1 ==="
echo ""
echo "0) INSTALACIÓN DE PAQUETES"
echo ""

apt-get update
apt-get install --yes apache2 ufw bind9 dnsutils

echo ""
echo "1) INSTALACIÓN DE MÓDULOS DE APACHE"
echo ""

a2enmod proxy proxy_http proxy_balancer status lbmethod_byrequests lbmethod_bytraffic lbmethod_bybusyness lbmethod_heartbeat heartmonitor slotmem_shm

echo ""
echo "2) CONFIGURACIÓN DE APACHE"
echo ""

cp "${SHARED_DIR}/apache/apache2.conf" "/etc/apache2/"
cp "${SHARED_DIR}/apache/000-servidor1.conf" "/etc/apache2/sites-available/"

a2ensite "000-servidor1.conf"
a2dissite "000-default.conf"
apache2ctl configtest

systemctl restart apache2

echo ""
echo "3) CONFIGURACIÓN DE DNS"
echo ""

cp "${SHARED_DIR}/dns/named.conf.local" "/etc/bind/"
cp "${SHARED_DIR}/dns/named.conf.options" "/etc/bind/"

mkdir "/etc/bind/zones"
cp "${SHARED_DIR}/dns/db.proyectofinal.local" "/etc/bind/zones/"
cp "${SHARED_DIR}/dns/db.192" "/etc/bind/zones/"

named-checkconf
named-checkzone proyectofinal.local /etc/bind/zones/db.proyectofinal.local
named-checkzone 56.168.192.in-addr.arpa /etc/bind/zones/db.192

systemctl restart bind9

echo ""
echo "4) CONFIGURACIÓN DE FIREWALL"
echo ""

ufw allow ssh # Vagrant
ufw allow http # Apache
ufw allow Bind9 # DNS
ufw allow in proto udp from 239.0.0.2 to any port 27999 # Multicast

echo "y" | ufw enable

echo ""
echo "=== Provisión servidor1 finalizada correctamente ==="
