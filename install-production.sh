#!/bin/bash
# ============================================================================
# SCRIPT DE INSTALACIÓN RÁPIDA - INVENTARIO KM MOTOS
# ============================================================================
# Este script automatiza la instalación inicial del sistema
# Uso: ./install.sh
# ============================================================================

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "============================================================================"
echo "    INSTALACIÓN DE INVENTARIO KM MOTOS - SNIPE-IT"
echo "============================================================================"
echo -e "${NC}"

# Verificar si se ejecuta como root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}No ejecutar este script como root. Usar un usuario normal con sudo.${NC}"
    exit 1
fi

# Función para imprimir mensajes
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar sistema operativo
print_info "Verificando sistema operativo..."
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
    print_success "Sistema: $OS $VER"
else
    print_error "No se puede determinar el sistema operativo"
    exit 1
fi

# Verificar si es Ubuntu
if [[ ! "$OS" =~ "Ubuntu" ]]; then
    print_warning "Este script está optimizado para Ubuntu. Tu sistema es: $OS"
    read -p "¿Continuar de todos modos? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

# 1. Actualizar sistema
print_info "Actualizando sistema..."
sudo apt update && sudo apt upgrade -y
print_success "Sistema actualizado"

# 2. Instalar paquetes básicos
print_info "Instalando paquetes básicos..."
sudo apt install -y curl wget git vim nano htop net-tools ufw ca-certificates gnupg lsb-release
print_success "Paquetes básicos instalados"

# 3. Configurar firewall
print_info "Configurando firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp
print_success "Firewall configurado"

# 4. Instalar Docker
print_info "Verificando Docker..."
if ! command -v docker &> /dev/null; then
    print_info "Docker no encontrado. Instalando..."
    
    # Limpiar versiones antiguas
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Agregar repositorio de Docker
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Agregar usuario al grupo docker
    sudo usermod -aG docker $USER
    
    print_success "Docker instalado"
    print_warning "Necesitas cerrar sesión y volver a entrar para aplicar permisos de Docker"
else
    print_success "Docker ya está instalado: $(docker --version)"
fi

# Verificar Docker Compose
if ! command -v docker compose &> /dev/null; then
    print_error "Docker Compose no encontrado. Instala Docker Compose V2"
    exit 1
else
    print_success "Docker Compose instalado: $(docker compose version)"
fi

# 5. Solicitar configuración de discos
echo ""
print_info "Configuración de discos de almacenamiento"
echo "Este sistema requiere 2 discos grandes para almacenamiento."
echo "Discos detectados: SDB (disco 1) y SDC (disco 2)"
echo ""
read -p "Punto de montaje del disco SDB (ejemplo: /mnt/sdb): " DISCO_SDB
read -p "Punto de montaje del disco SDC (ejemplo: /mnt/sdc): " DISCO_SDC

DISCO_SDB=${DISCO_SDB:-/mnt/sdb}
DISCO_SDC=${DISCO_SDC:-/mnt/sdc}

# Verificar que los discos existan
if [ ! -d "$DISCO_SDB" ]; then
    print_warning "El directorio $DISCO_SDB no existe"
    read -p "¿Crear el directorio? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        sudo mkdir -p "$DISCO_SDB"
        print_success "Directorio $DISCO_SDB creado"
    fi
fi

if [ ! -d "$DISCO_SDC" ]; then
    print_warning "El directorio $DISCO_SDC no existe"
    read -p "¿Crear el directorio? (s/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        sudo mkdir -p "$DISCO_SDC"
        print_success "Directorio $DISCO_SDC creado"
    fi
fi

# 6. Crear directorios necesarios
print_info "Creando directorios de almacenamiento..."
sudo mkdir -p "$DISCO_SDB/snipeit-data"
sudo mkdir -p "$DISCO_SDB/snipeit-redis"
sudo mkdir -p "$DISCO_SDB/nginx-logs"
sudo mkdir -p "$DISCO_SDC/snipeit-db"
sudo mkdir -p "$DISCO_SDC/snipeit-backups"

sudo chown -R $USER:$USER "$DISCO_SDB"
sudo chown -R $USER:$USER "$DISCO_SDC"
print_success "Directorios creados"

# 7. Actualizar docker-compose.yml con las rutas
print_info "Configurando rutas en docker-compose..."
cd "$(dirname "$0")"

if [ -f "docker-compose.production.yml" ]; then
    cp docker-compose.production.yml docker-compose.production.yml.backup
    sed -i "s|/mnt/sdb|$DISCO_SDB|g" docker-compose.production.yml
    sed -i "s|/mnt/sdc|$DISCO_SDC|g" docker-compose.production.yml
    print_success "Rutas actualizadas en docker-compose.production.yml"
else
    print_error "Archivo docker-compose.production.yml no encontrado"
    exit 1
fi

# 8. Configurar archivo .env
echo ""
print_info "Configuración de variables de entorno"

if [ -f ".env" ]; then
    print_warning "Ya existe un archivo .env"
    read -p "¿Sobrescribir? (s/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        print_info "Manteniendo archivo .env existente"
    else
        cp .env.production .env
        print_success "Archivo .env creado desde .env.production"
    fi
else
    cp .env.production .env
    print_success "Archivo .env creado"
fi

# Solicitar configuración básica
echo ""
print_info "Configuración básica de la aplicación"
read -p "URL de la aplicación (ejemplo: http://192.168.1.100): " APP_URL
read -p "Nombre de base de datos [snipeit_kmmotos]: " DB_NAME
DB_NAME=${DB_NAME:-snipeit_kmmotos}
read -p "Usuario de base de datos [snipeit_user]: " DB_USER
DB_USER=${DB_USER:-snipeit_user}
read -sp "Password de base de datos: " DB_PASS
echo
read -sp "Password de root MySQL: " MYSQL_ROOT_PASS
echo

# Generar APP_KEY
print_info "Generando APP_KEY..."
APP_KEY=$(docker run --rm snipe/snipe-it:v7.0.13 php artisan key:generate --show | tail -1)
print_success "APP_KEY generada"

# Actualizar .env
sed -i "s|APP_URL=.*|APP_URL=$APP_URL|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=$DB_NAME|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=$DB_USER|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|g" .env
sed -i "s|MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASS|g" .env
sed -i "s|APP_KEY=.*|APP_KEY=$APP_KEY|g" .env

print_success "Archivo .env configurado"

# 9. Descargar imágenes
echo ""
print_info "Descargando imágenes de Docker..."
docker compose -f docker-compose.production.yml pull
print_success "Imágenes descargadas"

# 10. Iniciar servicios
print_info "Iniciando servicios..."
docker compose -f docker-compose.production.yml up -d
print_success "Servicios iniciados"

# 11. Esperar a que los servicios estén listos
print_info "Esperando a que los servicios estén listos (esto puede tardar 2-3 minutos)..."
sleep 30

# Verificar estado
docker compose -f docker-compose.production.yml ps

# 12. Ejecutar migraciones
print_info "Ejecutando migraciones de base de datos..."
sleep 10
docker compose -f docker-compose.production.yml exec -T app php artisan migrate --force
print_success "Migraciones completadas"

# 13. Crear usuario administrador
echo ""
print_info "Creación de usuario administrador"
echo "Ejecuta el siguiente comando para crear tu usuario administrador:"
echo ""
echo -e "${GREEN}docker compose -f docker-compose.production.yml exec app php artisan snipeit:create-admin${NC}"
echo ""

# Resumen final
echo ""
echo -e "${GREEN}"
echo "============================================================================"
echo "    ¡INSTALACIÓN COMPLETADA!"
echo "============================================================================"
echo -e "${NC}"
echo ""
echo "🎉 Snipe-IT está instalado y funcionando"
echo ""
echo "📍 Acceso:"
echo "   URL: $APP_URL"
echo "   Puerto alternativo: $APP_URL:8000"
echo ""
echo "📁 Rutas de almacenamiento:"
echo "   Disco SDB (datos): $DISCO_SDB"
echo "   Disco SDC (DB/backups): $DISCO_SDC"
echo ""
echo "🔐 Próximos pasos:"
echo "   1. Crear usuario administrador con el comando mostrado arriba"
echo "   2. Acceder a la URL y configurar la aplicación"
echo "   3. Configurar SSL/HTTPS (recomendado)"
echo ""
echo "📚 Documentación:"
echo "   - Guía de despliegue: GUIA_DESPLIEGUE.md"
echo "   - Rutas de almacenamiento: RUTAS_ALMACENAMIENTO.md"
echo ""
echo "🔧 Comandos útiles:"
echo "   Ver logs: docker compose -f docker-compose.production.yml logs -f"
echo "   Reiniciar: docker compose -f docker-compose.production.yml restart"
echo "   Detener: docker compose -f docker-compose.production.yml down"
echo ""
echo -e "${YELLOW}⚠️  Importante:${NC}"
echo "   - Guarda las credenciales de forma segura"
echo "   - Configura backups externos regularmente"
echo "   - Actualiza el sistema periódicamente"
echo ""
