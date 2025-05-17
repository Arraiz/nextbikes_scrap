#!/bin/bash

# Script para configurar e iniciar NextBikes Scraper

# 1. Crear carpeta de datos
echo "Creando carpeta data..."
mkdir -p data

# 2. Establecer permisos
echo "Configurando permisos..."
sudo chown -R $USER:$USER data
sudo chmod -R 755 data

# 3. Verificar/crear .env
echo "Verificando .env..."
if [ ! -f .env ]; then
    echo "Creando archivo .env con valores predeterminados"
    cat > .env << EOF
TARGET_URL=https://iframe.nextbike.net/maps/nextbike-live.xml?&city=532&domains=bo
INTERVAL_SECONDS=10
FILE_NAME=nextbikes_bilbao
EOF
fi

# 4. Configurar scripts de compresión
echo "Configurando scripts..."
if [ -d scripts ]; then
    chmod +x scripts/*.sh
    chmod +x compress.sh
fi

# 5. Iniciar aplicación
echo "Iniciando aplicación..."
docker compose down 2>/dev/null
docker compose up -d

echo "Configuración completada. Contenedores:"
docker compose ps 