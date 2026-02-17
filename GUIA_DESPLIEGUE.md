# 🚀 GUÍA COMPLETA DE DESPLIEGUE - INVENTARIO KM MOTOS

## 📋 Índice
1. [Pre-requisitos](#pre-requisitos)
2. [Preparación del Servidor Ubuntu](#preparación-del-servidor-ubuntu)
3. [Configuración de Discos de 500TB](#configuración-de-discos)
4. [Instalación de Docker y Docker Compose](#instalación-de-docker)
5. [Preparación de la Aplicación](#preparación-de-la-aplicación)
6. [Despliegue Inicial](#despliegue-inicial)
7. [Configuración Post-Instalación](#configuración-post-instalación)
8. [Comandos Útiles](#comandos-útiles)
9. [Troubleshooting](#troubleshooting)
10. [Mantenimiento](#mantenimiento)

---

## 📦 Pre-requisitos

### Hardware Requerido
- Servidor Ubuntu Server 20.04 LTS o superior
- Mínimo 4 CPU cores (recomendado 8)
- Mínimo 8 GB RAM (recomendado 16 GB)
- 2 Discos de 500 TB para almacenamiento de datos
- Conexión a Internet estable

### Software Necesario
- Ubuntu Server 22.04 LTS o 24.04 LTS
- Docker Engine 24.0+
- Docker Compose V2
- Git
- OpenSSH Server

---

## 🖥️ Preparación del Servidor Ubuntu

### 1. Actualizar el Sistema

```bash
# Conectarse al servidor via SSH
ssh usuario@ip-del-servidor

# Actualizar paquetes
sudo apt update && sudo apt upgrade -y

# Instalar paquetes básicos
sudo apt install -y curl wget git vim nano htop net-tools ufw
```

### 2. Configurar Firewall

```bash
# Habilitar UFW
sudo ufw enable

# Permitir SSH
sudo ufw allow 22/tcp

# Permitir HTTP y HTTPS
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Permitir puerto de la aplicación (si accedes directamente)
sudo ufw allow 8000/tcp

# Verificar estado
sudo ufw status
```

### 3. Configurar Hostname (Opcional)

```bash
# Cambiar hostname
sudo hostnamectl set-hostname inventario-kmmotos

# Editar /etc/hosts
sudo nano /etc/hosts
# Agregar: 127.0.0.1 inventario-kmmotos
```

---

## 💾 Configuración de Discos de 500TB

### 1. Identificar los Discos

```bash
# Listar todos los discos
lsblk

# Ver detalles de discos
sudo fdisk -l

# Ejemplo de salida:
# /dev/sdb    500TB
# /dev/sdc    500TB
```

### 2. Particionar los Discos (si es necesario)

```bash
# Particionar disco 1
sudo fdisk /dev/sdb
# Presionar: n (nuevo) -> p (primaria) -> Enter -> Enter -> w (escribir)

# Particionar disco 2
sudo fdisk /dev/sdc
# Repetir el proceso
```

### 3. Formatear los Discos

```bash
# Formatear disco 1 con ext4
sudo mkfs.ext4 /dev/sdb1

# Formatear disco 2 con ext4
sudo mkfs.ext4 /dev/sdc1
```

### 4. Crear Puntos de Montaje

```bash
# Crear directorios de montaje
sudo mkdir -p /mnt/sdb
sudo mkdir -p /mnt/sdc

# Obtener UUID de los discos
sudo blkid /dev/sdb1
sudo blkid /dev/sdc1
# Copiar los UUID
```

### 5. Configurar Montaje Automático

```bash
# Editar fstab
sudo nano /etc/fstab

# Agregar al final (reemplaza UUID_DISCO1 y UUID_DISCO2 con tus UUIDs):
UUID=UUID_DISCO1  /mnt/sdb  ext4  defaults,nofail  0  2
UUID=UUID_DISCO2  /mnt/sdc  ext4  defaults,nofail  0  2

# Montar todos los discos
sudo mount -a

# Verificar montaje
df -h
```

### 6. Configurar Permisos

```bash
# Dar permisos adecuados
sudo chmod 755 /mnt/sdb
sudo chmod 755 /mnt/sdc

# Crear directorios para la aplicación
sudo mkdir -p /mnt/sdb/snipeit-data
sudo mkdir -p /mnt/sdb/snipeit-redis
sudo mkdir -p /mnt/sdb/nginx-logs
sudo mkdir -p /mnt/sdc/snipeit-db
sudo mkdir -p /mnt/sdc/snipeit-backups

# Ajustar permisos (Docker necesita acceso)
sudo chown -R $USER:$USER /mnt/sdb/
sudo chown -R $USER:$USER /mnt/sdc/
```

---

## 🐳 Instalación de Docker y Docker Compose

### 1. Instalar Docker Engine

```bash
# Desinstalar versiones antiguas (si existen)
sudo apt remove docker docker-engine docker.io containerd runc

# Instalar dependencias
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

# Agregar GPG key oficial de Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Agregar repositorio de Docker
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verificar instalación
sudo docker --version
sudo docker compose version
```

### 2. Configurar Docker

```bash
# Agregar usuario al grupo docker (para no usar sudo)
sudo usermod -aG docker $USER

# Aplicar cambios (cerrar sesión y volver a entrar, o ejecutar)
newgrp docker

# Habilitar Docker al iniciar
sudo systemctl enable docker
sudo systemctl start docker

# Verificar que funciona sin sudo
docker ps
```

### 3. Optimizar Docker para Discos Grandes (Opcional)

```bash
# Crear archivo de configuración de Docker
sudo mkdir -p /etc/docker

sudo nano /etc/docker/daemon.json
# Agregar:
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}

# Reiniciar Docker
sudo systemctl restart docker
```

---

## 📥 Preparación de la Aplicación

### 1. Clonar el Repositorio

```bash
# Navegar al directorio home
cd ~

# Clonar el repositorio
git clone https://github.com/Spinracer/INVENTARIO-KM-MOTOS.git

# Entrar al directorio
cd INVENTARIO-KM-MOTOS
```

### 2. Configurar Variables de Entorno

```bash
# Copiar el archivo de configuración de producción
cp .env.production .env

# Editar el archivo .env
nano .env

# IMPORTANTE: Cambiar los siguientes valores:
# - APP_KEY: Generar nueva clave (ver paso siguiente)
# - APP_URL: URL de tu servidor
# - DB_PASSWORD: Password seguro para la base de datos
# - MYSQL_ROOT_PASSWORD: Password seguro para root de MySQL
# - MAIL_*: Configuración de tu servidor de correo
```

### 3. Generar APP_KEY

```bash
# Generar una clave de aplicación
docker run --rm snipe/snipe-it:v7.0.13 php artisan key:generate --show

# Copiar la salida y pegarla en .env en la variable APP_KEY
# Ejemplo: APP_KEY=base64:tu_clave_generada_aqui
```

### 4. Verificar Configuración de Docker Compose

```bash
# Ver el archivo de docker compose
cat docker-compose.production.yml

# IMPORTANTE: Verificar que las rutas de los volúmenes coincidan con tus discos:
# - /mnt/sdb/snipeit-data
# - /mnt/sdc/snipeit-db
# etc.
```

---

## 🚀 Despliegue Inicial

### 1. Descargar Imágenes

```bash
# Descargar todas las imágenes necesarias
docker compose -f docker-compose.production.yml pull
```

### 2. Iniciar los Contenedores

```bash
# Iniciar en modo detached (background)
docker compose -f docker-compose.production.yml up -d

# Ver logs en tiempo real
docker compose -f docker-compose.production.yml logs -f

# Esperar a que todos los servicios estén saludables (puede tardar 2-3 minutos)
```

### 3. Verificar Estado de los Contenedores

```bash
# Ver estado de contenedores
docker compose -f docker-compose.production.yml ps

# Todos deben estar en estado "healthy" o "running"
```

### 4. Ejecutar Migraciones de Base de Datos

```bash
# Ejecutar migraciones (primera vez)
docker compose -f docker-compose.production.yml exec app php artisan migrate --force

# Si pregunta, confirmar con 'yes'
```

### 5. Crear Usuario Administrador

```bash
# Crear primer usuario administrador
docker compose -f docker-compose.production.yml exec app php artisan snipeit:create-admin

# Seguir las instrucciones en pantalla:
# - Nombre
# - Apellido
# - Email
# - Username
# - Password
```

---

## ⚙️ Configuración Post-Instalación

### 1. Acceder a la Aplicación

```bash
# La aplicación estará disponible en:
http://IP-DEL-SERVIDOR:8000
# o
http://tu-dominio.com:8000

# Si configuraste nginx (puerto 80):
http://IP-DEL-SERVIDOR
```

### 2. Configuración Inicial en la Web

1. Acceder con el usuario administrador creado
2. Ir a **Configuración** → **Configuración de la aplicación**
3. Configurar:
   - Nombre de la compañía: "KM Motos"
   - Logo de la compañía (cargar imagen)
   - Zona horaria
   - Moneda
   - Idioma: Español

### 3. Configurar Backups Automáticos

```bash
# Los backups ya están configurados en docker-compose
# Verificar que funcionan:
docker compose -f docker-compose.production.yml logs backup

# Ver backups creados:
ls -lh /mnt/sdc/snipeit-backups/
```

### 4. Configurar SSL/HTTPS (Recomendado)

#### Opción A: Con Certbot (Let's Encrypt)

```bash
# Instalar Certbot
sudo apt install -y certbot

# Obtener certificado (reemplaza tu-dominio.com)
sudo certbot certonly --standalone -d tu-dominio.com

# Los certificados estarán en:
# /etc/letsencrypt/live/tu-dominio.com/

# Copiar certificados al directorio docker/ssl
mkdir -p docker/ssl
sudo cp /etc/letsencrypt/live/tu-dominio.com/fullchain.pem docker/ssl/
sudo cp /etc/letsencrypt/live/tu-dominio.com/privkey.pem docker/ssl/

# Configurar renovación automática
sudo certbot renew --dry-run
```

#### Opción B: Con certificados propios

```bash
# Copiar tus certificados al directorio docker/ssl
mkdir -p docker/ssl
cp /ruta/a/tu/certificado.crt docker/ssl/
cp /ruta/a/tu/clave.key docker/ssl/
```

### 5. Optimizar Rendimiento

```bash
# Limpiar cache de la aplicación
docker compose -f docker-compose.production.yml exec app php artisan cache:clear
docker compose -f docker-compose.production.yml exec app php artisan config:cache
docker compose -f docker-compose.production.yml exec app php artisan route:cache
docker compose -f docker-compose.production.yml exec app php artisan view:cache
```

---

## 🔧 Comandos Útiles

### Gestión de Contenedores

```bash
# Ver logs de todos los servicios
docker compose -f docker-compose.production.yml logs -f

# Ver logs de un servicio específico
docker compose -f docker-compose.production.yml logs -f app

# Reiniciar todos los servicios
docker compose -f docker-compose.production.yml restart

# Reiniciar un servicio específico
docker compose -f docker-compose.production.yml restart app

# Detener todos los servicios
docker compose -f docker-compose.production.yml stop

# Detener y eliminar contenedores (mantiene datos)
docker compose -f docker-compose.production.yml down

# Ver estado
docker compose -f docker-compose.production.yml ps

# Ver uso de recursos
docker stats
```

### Base de Datos

```bash
# Acceder a MySQL
docker compose -f docker-compose.production.yml exec db mysql -u root -p

# Backup manual de base de datos
docker compose -f docker-compose.production.yml exec db mysqldump -u root -p snipeit_kmmotos > backup_$(date +%Y%m%d).sql

# Restaurar backup
docker compose -f docker-compose.production.yml exec -T db mysql -u root -p snipeit_kmmotos < backup_20240217.sql
```

### Aplicación

```bash
# Entrar al contenedor de la app
docker compose -f docker-compose.production.yml exec app bash

# Ejecutar comandos artisan
docker compose -f docker-compose.production.yml exec app php artisan [comando]

# Ver usuarios
docker compose -f docker-compose.production.yml exec app php artisan snipeit:user-list

# Limpiar cache
docker compose -f docker-compose.production.yml exec app php artisan cache:clear

# Ver versión
docker compose -f docker-compose.production.yml exec app php artisan --version
```

### Monitoreo

```bash
# Ver espacio en disco
df -h

# Ver espacio usado por Docker
docker system df

# Ver uso de volúmenes
du -sh /mnt/sdb/*
du -sh /mnt/sdc/*

# Ver logs del sistema
sudo journalctl -u docker -f
```

---

## 🐛 Troubleshooting

### Problema: Los contenedores no inician

```bash
# Ver logs detallados
docker compose -f docker-compose.production.yml logs

# Ver logs de un servicio específico
docker compose -f docker-compose.production.yml logs app

# Verificar que los discos estén montados
df -h | grep mnt

# Verificar permisos
ls -la /mnt/sdb/
ls -la /mnt/sdc/
```

### Problema: Error de conexión a base de datos

```bash
# Verificar que el contenedor de DB esté corriendo
docker compose -f docker-compose.production.yml ps db

# Ver logs de la base de datos
docker compose -f docker-compose.production.yml logs db

# Verificar variables de entorno
docker compose -f docker-compose.production.yml exec app env | grep DB_

# Probar conexión
docker compose -f docker-compose.production.yml exec app php artisan tinker
# Luego ejecutar: DB::connection()->getPdo();
```

### Problema: No se pueden subir archivos

```bash
# Verificar permisos de directorios
docker compose -f docker-compose.production.yml exec app ls -la /var/lib/snipeit/

# Verificar espacio en disco
df -h /mnt/sdb

# Verificar límites de PHP en .env
# PHP_UPLOAD_LIMIT=100M
# PHP_POST_MAX_SIZE=100M
```

### Problema: La aplicación es lenta

```bash
# Verificar uso de recursos
docker stats

# Limpiar cache de Redis
docker compose -f docker-compose.production.yml exec redis redis-cli FLUSHALL

# Optimizar base de datos
docker compose -f docker-compose.production.yml exec db mysqlcheck -u root -p --optimize --all-databases

# Reiniciar servicios
docker compose -f docker-compose.production.yml restart
```

### Problema: Error 500 en la web

```bash
# Ver logs de Apache/PHP
docker compose -f docker-compose.production.yml logs app | tail -100

# Verificar permisos
docker compose -f docker-compose.production.yml exec app chown -R docker:staff /var/www/html/storage

# Limpiar cache
docker compose -f docker-compose.production.yml exec app php artisan cache:clear
docker compose -f docker-compose.production.yml exec app php artisan config:clear
```

---

## 🔄 Mantenimiento

### Actualizaciones

```bash
# Actualizar a una nueva versión
# 1. Hacer backup
docker compose -f docker-compose.production.yml exec db mysqldump -u root -p snipeit_kmmotos > backup_before_update.sql

# 2. Detener servicios
docker compose -f docker-compose.production.yml down

# 3. Actualizar versión en .env
nano .env
# Cambiar: APP_VERSION=v7.0.14 (o la versión que desees)

# 4. Descargar nueva imagen
docker compose -f docker-compose.production.yml pull

# 5. Iniciar servicios
docker compose -f docker-compose.production.yml up -d

# 6. Ejecutar migraciones
docker compose -f docker-compose.production.yml exec app php artisan migrate --force
```

### Limpieza

```bash
# Limpiar contenedores detenidos
docker container prune -f

# Limpiar imágenes no usadas
docker image prune -a -f

# Limpiar volúmenes no usados
docker volume prune -f

# Limpiar todo (CUIDADO)
docker system prune -a -f
```

### Backups Manuales

```bash
# Backup completo del sistema
# 1. Backup de base de datos
docker compose -f docker-compose.production.yml exec db mysqldump -u root -p --all-databases > backup_db_$(date +%Y%m%d).sql

# 2. Backup de archivos (puede tardar con 500TB)
tar -czf backup_files_$(date +%Y%m%d).tar.gz /mnt/sdb/snipeit-data/

# 3. Backup de configuración
cp .env .env.backup_$(date +%Y%m%d)
cp docker-compose.production.yml docker-compose.production.yml.backup_$(date +%Y%m%d)
```

### Monitoreo de Salud

```bash
# Crear script de monitoreo
nano ~/check_snipeit.sh

# Agregar:
#!/bin/bash
echo "=== Estado de Snipe-IT ==="
echo "Contenedores:"
docker compose -f ~/INVENTARIO-KM-MOTOS/docker-compose.production.yml ps
echo ""
echo "Uso de disco:"
df -h | grep mnt
echo ""
echo "Uso de memoria:"
free -h
echo ""
echo "Últimos logs de errores:"
docker compose -f ~/INVENTARIO-KM-MOTOS/docker-compose.production.yml logs --tail=20 | grep -i error

# Dar permisos
chmod +x ~/check_snipeit.sh

# Ejecutar
~/check_snipeit.sh

# Agregar a cron para ejecutar cada hora
crontab -e
# Agregar: 0 * * * * ~/check_snipeit.sh > ~/snipeit_health.log 2>&1
```

---

## 📞 Soporte

Para problemas o preguntas:
- Documentación oficial: https://snipe-it.readme.io/
- GitHub Issues: https://github.com/grokability/snipe-it/issues
- Discord: https://discord.gg/yZFtShAcKk

---

## ✅ Checklist de Despliegue

- [ ] Servidor Ubuntu actualizado
- [ ] Firewall configurado
- [ ] Discos de 500TB formateados y montados
- [ ] Docker y Docker Compose instalados
- [ ] Repositorio clonado
- [ ] Archivo .env configurado con APP_KEY generada
- [ ] Credenciales de base de datos seguras configuradas
- [ ] Configuración de correo completada
- [ ] Contenedores iniciados correctamente
- [ ] Migraciones de base de datos ejecutadas
- [ ] Usuario administrador creado
- [ ] Acceso web funcionando
- [ ] SSL/HTTPS configurado (recomendado)
- [ ] Backups automáticos verificados
- [ ] Monitoreo configurado

---

**¡Felicidades! Tu sistema de inventario KM Motos está desplegado y listo para usar.**
