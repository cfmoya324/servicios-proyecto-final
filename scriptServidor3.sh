#!/bin/bash
set -euo pipefail

# Script de provisión para servidor3 (VM con IP 192.168.56.4)
# Uso: Vagrant lo ejecuta automáticamente como root.

VAGRANT_SHARED_DIR="/vagrant"
LOCAL_CONF_SRC="${VAGRANT_SHARED_DIR}/servidor3/apache2.conf"
SITE_CONF_SRC="${VAGRANT_SHARED_DIR}/servidor3/000-servidor3.conf"
INDEX_SRC="${VAGRANT_SHARED_DIR}/servidor3/index.html"
HEALTH_SRC="${VAGRANT_SHARED_DIR}/servidor3/health.html"
BACKUP_DIR="/root/apache2_backup_$(date +%Y%m%d%H%M%S)"
BALANCER_IP="192.168.56.2"

echo "=== Inicio de provisión servidor3 ==="
echo ""
echo "0) Configurar DNS persistente"
echo ""

sudo bash -c 'cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4 1.0.0.1
EOF'
sudo systemctl restart systemd-resolved

echo ""
echo "1) Actualizar paquetes e instalar utilidades"
echo ""

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 curl htop tmux

echo ""
echo "2) Backup y parada de Apache"
echo ""

systemctl stop apache2 || true
mkdir -p "${BACKUP_DIR}"
cp -a /etc/apache2 "${BACKUP_DIR}/" || true
echo "  -> backup guardado en ${BACKUP_DIR}"

echo ""
echo "3) Copiar configuraciones locales"
echo ""

cp "${LOCAL_CONF_SRC}" "/etc/apache2/"
cp "${SITE_CONF_SRC}" "/etc/apache2/sites-available/"
a2ensite "000-servidor3.conf"
a2dissite "000-default.conf" || true

echo ""
echo "4) Configurar mod_status para acceso del balanceador"
echo ""

a2enmod status
cat > /etc/apache2/conf-available/server-status.conf <<EOF
<Location /server-status>
    SetHandler server-status
    Require ip ${BALANCER_IP}
    Require local
</Location>
ExtendedStatus On
EOF
a2enconf server-status

echo ""
echo "5) Copiar archivos web"
echo ""

mkdir -p /var/www/html
cp "${INDEX_SRC}" /var/www/html/index.html
cp "${HEALTH_SRC}" /var/www/html/health.html

DEPLOY_TIME="$(TZ='America/Bogota' date '+%Y-%m-%d %H:%M:%S %Z')"
sed -i "s|<!--TIMESTAMP-->|$DEPLOY_TIME|" /var/www/html/index.html

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo ""
echo "6) Probar configuración y reiniciar servicio"
echo ""

apache2ctl configtest
systemctl enable apache2
systemctl restart apache2

echo ""
echo "7) Verificación rápida"
echo ""

sleep 1
curl -sS --max-time 5 http://127.0.0.1/ | head -n 5 || true
curl -sS --max-time 5 http://127.0.0.1/health.html || true

echo ""
echo "8) Configuración de firewall"
echo ""

ufw allow ssh # Vagrant
ufw allow from 192.168.56.2 to any port 80 # Apache

echo "y" | ufw enable

echo ""
echo "=== Provisión servidor3 finalizada correctamente ==="
