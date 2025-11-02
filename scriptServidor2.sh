#!/bin/bash
set -euo pipefail

# Script de provisión para servidor2 (VM con IP 192.168.56.3)
# Uso: Vagrant lo ejecuta automáticamente como root.

VAGRANT_SHARED_DIR="/vagrant"
LOCAL_CONF_SRC="${VAGRANT_SHARED_DIR}/servidor2/apache2.conf"
SITE_CONF_SRC="${VAGRANT_SHARED_DIR}/servidor2/servidor2.conf"
INDEX_SRC="${VAGRANT_SHARED_DIR}/servidor2/index.html"
HEALTH_SRC="${VAGRANT_SHARED_DIR}/servidor2/health.html"
BACKUP_DIR="/root/apache2_backup_$(date +%Y%m%d%H%M%S)"
BALANCER_IP="192.168.56.2"

echo "=== Inicio de provisión servidor2 ==="

echo "0) Configurar DNS persistente"
sudo bash -c 'cat > /etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=8.8.8.8 1.1.1.1
FallbackDNS=8.8.4.4 1.0.0.1
EOF'
sudo systemctl restart systemd-resolved

echo "1) Actualizar paquetes e instalar utilidades"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 curl htop tmux

echo "2) Backup y parada de Apache"
systemctl stop apache2 || true
mkdir -p "${BACKUP_DIR}"
cp -a /etc/apache2 "${BACKUP_DIR}/" || true
echo "  -> backup guardado en ${BACKUP_DIR}"

echo "3) Copiar configuraciones locales"
cp "${LOCAL_CONF_SRC}" /etc/apache2/apache2.conf
cp "${SITE_CONF_SRC}" /etc/apache2/sites-available/servidor2.conf
a2ensite servidor2.conf
a2dissite 000-default.conf || true

echo "4) Configurar mod_status para acceso del balanceador"
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

echo "5) Copiar archivos web"
mkdir -p /var/www/html
cp "${INDEX_SRC}" /var/www/html/index.html
cp "${HEALTH_SRC}" /var/www/html/health.html

DEPLOY_TIME="$(TZ='America/Bogota' date '+%Y-%m-%d %H:%M:%S %Z')"
sed -i "s|<!--TIMESTAMP-->|$DEPLOY_TIME|" /var/www/html/index.html

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

echo "6) Probar configuración y reiniciar servicio"
apache2ctl configtest
systemctl enable apache2
systemctl restart apache2

echo "7) Verificación rápida"
sleep 1
curl -sS --max-time 5 http://127.0.0.1/ | head -n 5 || true
curl -sS --max-time 5 http://127.0.0.1/health.html || true

echo "=== Provisión servidor2 finalizada correctamente ==="
