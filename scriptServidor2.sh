#!/bin/bash
set -euo pipefail

# Script de provisión para servidor2 (VM con IP 192.168.56.3)
# Uso: Vagrant lo ejecuta automáticamente como root.

SHARED_DIR="/vagrant/servidor2"
LOCAL_CONF_SRC="${SHARED_DIR}/apache/apache2.conf"
SITE_CONF_SRC="${SHARED_DIR}/apache/000-servidor.conf"
WEB_SRC="${SHARED_DIR}/web"
DB_SRC="${SHARED_DIR}/db/init.sql"
BACKUP_DIR="/root/apache2_backup_$(date +%Y%m%d%H%M%S)"
BALANCER_IP="192.168.56.2"

echo "=== Inicio de provisión servidor2 ==="
echo ""
echo "0) CONFIGURAR DNS PERSISTENTE"
echo ""

sudo bash -c 'cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4 1.0.0.1
EOF'
sudo systemctl restart systemd-resolved

echo ""
echo "1) ACTUALIZAR PAQUETES E INSTALAR UTILIDADES"
echo ""

apt-get update -y #se agregan las dependencias de fastapi y de mysql
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 ufw python3 python3-pip python3-virtualenv pkg-config default-libmysqlclient-dev build-essential mysql-server libapache2-mod-wsgi-py3

echo ""
echo "2) INSTALACIÓN DE MÓDULOS DE APACHE"
echo ""

a2enmod status heartbeat

echo ""
echo "3) INSTALACIÓN DE PAQUETES DE PYTHON"
echo ""

mkdir -p /var/www/web
virtualenv /var/www/web/flaskServer
#source /var/www/web/flaskServer/bin/activate
pip3 install flask Flask-SQLAlchemy mysqlclient==2.1.1

echo ""
echo "4) BACKUP Y PARADA DE APACHE"
echo ""

systemctl stop apache2 || true
mkdir -p "${BACKUP_DIR}"
cp -a /etc/apache2 "${BACKUP_DIR}/" || true
echo "  -> backup guardado en ${BACKUP_DIR}"

echo ""
echo "5) COPIAR CONFIGURACIONES LOCALES"
echo ""

cp "${LOCAL_CONF_SRC}" "/etc/apache2/"
cp "${SITE_CONF_SRC}" "/etc/apache2/sites-available/"
a2ensite "000-servidor.conf"
a2dissite "000-default.conf" || true

echo ""
echo "6) CONFIGURAR MOD_STATUS PARA ACCESO DEL BALANCEADOR"
echo ""

#cat > /etc/apache2/conf-available/server-status.conf <<EOF
#<Location /server-status>
#    SetHandler server-status
#    Require ip ${BALANCER_IP}
#    Require local
#</Location>
#ExtendedStatus On
#EOF
#a2enconf server-status

echo ""
echo "7) COPIAR ARCHIVOS WEB"
echo ""

cp -r "${WEB_SRC}"/* /var/www/web/

#DEPLOY_TIME="$(TZ='America/Bogota' date '+%Y-%m-%d %H:%M:%S %Z')"
#sed -i "s|<!--TIMESTAMP-->|$DEPLOY_TIME|" /var/www/web/templates/index.html

chown -R www-data:www-data /var/www/web
chmod -R 755 /var/www/web

export FLASK_APP=/var/www/web/app

echo ""
echo "8) CONFIGURAR API FLASK Y BASE DE DATOS"
echo ""

mysql -u root < "${DB_SRC}"

echo ""
echo "9) PROBAR CONFIGURACIÓN Y REINICIAR SERVICIO"
echo ""

apache2ctl configtest
systemctl enable apache2
systemctl restart apache2

echo ""
echo "10) VERIFICACIÓN RÁPIDA"
echo ""

sleep 1
curl -sS --max-time 5 http://127.0.0.1/ | head -n 5 || true
curl -sS --max-time 5 http://127.0.0.1/health || true

echo ""
echo "11) CONFIGURACIÓN DE FIREWALL"
echo ""

ufw allow ssh # Vagrant
ufw allow from 192.168.56.2 to any port 80 # Apache
ufw allow in proto udp from 239.0.0.2 to any port 27999 # Multicast

echo "y" | ufw enable

echo ""
echo "=== Provisión servidor2 finalizada correctamente ==="
