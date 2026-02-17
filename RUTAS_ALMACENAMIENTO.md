# 📂 DOCUMENTACIÓN DE RUTAS DE ALMACENAMIENTO - INVENTARIO KM MOTOS

## 📋 Índice
1. [Resumen de Rutas](#resumen-de-rutas)
2. [Configuración en Docker](#configuración-en-docker)
3. [Configuración en Variables de Entorno](#configuración-en-variables-de-entorno)
4. [Rutas Internas de la Aplicación](#rutas-internas-de-la-aplicación)
5. [Cómo Cambiar las Rutas](#cómo-cambiar-las-rutas)
6. [Tipos de Archivos por Ubicación](#tipos-de-archivos-por-ubicación)
7. [Migraciones de Almacenamiento](#migraciones-de-almacenamiento)

---

## 📊 Resumen de Rutas

### Rutas en el Sistema Anfitrión (Ubuntu Server)

| Ruta en Servidor | Montaje en Container | Tipo de Datos | Tamaño Estimado |
|------------------|---------------------|---------------|-----------------|
| `/mnt/sdb/snipeit-data` | `/var/lib/snipeit` | Datos de aplicación | Alto (crecimiento continuo) |
| `/mnt/sdb/snipeit-redis` | `/data` (redis) | Cache y sesiones | Bajo (500MB-2GB) |
| `/mnt/sdb/nginx-logs` | `/var/log/nginx` | Logs de acceso | Medio (depende del tráfico) |
| `/mnt/sdc/snipeit-db` | `/var/lib/mysql` | Base de datos MySQL | Alto (crecimiento continuo) |
| `/mnt/sdc/snipeit-backups` | `/backup` | Backups de DB | Muy Alto (acumulativo) |

### Subdirectorios en `/var/lib/snipeit` (dentro del container)

| Sub-ruta | Mapeo interno | Tipo de Contenido | Observaciones |
|----------|---------------|-------------------|---------------|
| `/var/lib/snipeit/data/uploads` | `/var/www/html/public/uploads` | Imágenes y archivos públicos | Accesible vía web |
| `/var/lib/snipeit/data/private_uploads` | `/var/www/html/storage/private_uploads` | Archivos privados | Solo accesible con autenticación |
| `/var/lib/snipeit/dumps` | `/var/www/html/storage/app/backups` | Backups generados por la app | Exportaciones manuales |
| `/var/lib/snipeit/keys` | Varios en `/var/www/html/storage/` | Claves OAuth y certificados | Crítico para seguridad |

---

## 🐳 Configuración en Docker

### Archivo: `docker-compose.production.yml`

#### 1. Volúmenes del Servicio 'app' (Aplicación Principal)

**Ubicación**: Líneas 16-22  
**Sección**: `services.app.volumes`

```yaml
volumes:
  # Volumen principal de datos (montado en disco de 500TB #1)
  # Este contiene uploads, backups y archivos importantes
  - /mnt/sdb/snipeit-data:/var/lib/snipeit
  
  # Archivo de configuración local
  - ./.env:/var/www/html/.env:ro
```

**¿Qué hace?**
- **Línea 19**: Monta el directorio `/mnt/sdb/snipeit-data` del servidor en `/var/lib/snipeit` dentro del contenedor. Este es el volumen MÁS IMPORTANTE donde se guardan todos los uploads de imágenes, documentos y archivos de activos.
- **Línea 22**: Monta el archivo `.env` como solo lectura para configuración.

**Para cambiar esta ruta:**
```yaml
# Cambiar de:
- /mnt/sdb/snipeit-data:/var/lib/snipeit

# A (ejemplo con ruta diferente):
- /ruta/nueva/almacenamiento:/var/lib/snipeit
```

---

#### 2. Volúmenes del Servicio 'db' (Base de Datos)

**Ubicación**: Líneas 65-68  
**Sección**: `services.db.volumes`

```yaml
volumes:
  - /mnt/sdc/snipeit-db:/var/lib/mysql
  # Opcional: Configuraciones personalizadas
  # - ./docker/mysql-custom.cnf:/etc/mysql/conf.d/custom.cnf:ro
```

**¿Qué hace?**
- **Línea 66**: Monta el directorio donde MariaDB guarda todas las bases de datos. Contiene tablas de activos, usuarios, historial, etc. Es CRÍTICO para la persistencia de datos.

**Para cambiar esta ruta:**
```yaml
# Cambiar de:
- /mnt/sdc/snipeit-db:/var/lib/mysql

# A:
- /ruta/nueva/base-datos:/var/lib/mysql
```

---

#### 3. Volúmenes del Servicio 'redis' (Cache)

**Ubicación**: Líneas 110-112  
**Sección**: `services.redis.volumes`

```yaml
volumes:
  - /mnt/sdb/snipeit-redis:/data
```

**¿Qué hace?**
- **Línea 111**: Guarda los datos de Redis (cache y sesiones de usuarios). Si se pierde, solo afecta el rendimiento temporalmente.

**Para cambiar esta ruta:**
```yaml
# Cambiar de:
- /mnt/sdb/snipeit-redis:/data

# A:
- /ruta/nueva/cache:/data
```

---

#### 4. Volúmenes del Servicio 'nginx' (Proxy Reverso)

**Ubicación**: Líneas 143-146  
**Sección**: `services.nginx.volumes`

```yaml
volumes:
  - ./docker/nginx.conf:/etc/nginx/nginx.conf:ro
  - ./docker/ssl:/etc/nginx/ssl:ro
  - /mnt/sdb/nginx-logs:/var/log/nginx
```

**¿Qué hace?**
- **Línea 143**: Configuración de Nginx (no cambiar)
- **Línea 144**: Certificados SSL (no cambiar)
- **Línea 145**: Logs de acceso y errores de Nginx. Puede crecer mucho con alto tráfico.

**Para cambiar la ruta de logs:**
```yaml
# Cambiar de:
- /mnt/sdb/nginx-logs:/var/log/nginx

# A:
- /ruta/nueva/logs:/var/log/nginx
```

---

#### 5. Volúmenes del Servicio 'backup' (Backups Automáticos)

**Ubicación**: Líneas 167-169  
**Sección**: `services.backup.volumes`

```yaml
volumes:
  - /mnt/sdc/snipeit-backups:/backup
```

**¿Qué hace?**
- **Línea 168**: Directorio donde se guardan los backups diarios automáticos de la base de datos. Estos backups se comprimen con gzip y pueden acumular MUCHO espacio.

**Para cambiar esta ruta:**
```yaml
# Cambiar de:
- /mnt/sdc/snipeit-backups:/backup

# A:
- /ruta/nueva/backups:/backup
```

---

## 🔧 Configuración en Variables de Entorno

### Archivo: `.env.production` o `.env`

#### 1. Sistema de Archivos (Filesystem)

**Ubicación**: Líneas 50-57  
**Sección**: `# CONFIGURACIÓN DE ALMACENAMIENTO DE ARCHIVOS`

```bash
# Utilizar almacenamiento local (en discos de 500TB)
PRIVATE_FILESYSTEM_DISK=local
PUBLIC_FILESYSTEM_DISK=local_public

# Para usar S3 (AWS, MinIO, etc) descomenta y configura:
#PRIVATE_FILESYSTEM_DISK=s3_private
#PUBLIC_FILESYSTEM_DISK=s3_public
```

**¿Qué hace?**
- **Línea 51**: Define que los archivos PRIVADOS (documentos de usuarios, archivos sensibles) se guardan en `local`, es decir, en `/var/lib/snipeit/data/private_uploads`
- **Línea 52**: Define que los archivos PÚBLICOS (logos, imágenes de activos) se guardan en `local_public`, es decir, en `/var/lib/snipeit/data/uploads`

**Para cambiar a S3 o almacenamiento en nube:**
```bash
# Descomentar y configurar:
PRIVATE_FILESYSTEM_DISK=s3_private
PUBLIC_FILESYSTEM_DISK=s3_public

# Luego configurar credenciales de S3 en las líneas 202-232
```

---

#### 2. Configuración de S3 Pública (Opcional)

**Ubicación**: Líneas 202-211  
**Sección**: `# CONFIGURACIÓN S3 PÚBLICA`

```bash
#PUBLIC_AWS_SECRET_ACCESS_KEY=null
#PUBLIC_AWS_ACCESS_KEY_ID=null
#PUBLIC_AWS_DEFAULT_REGION=us-east-1
#PUBLIC_AWS_BUCKET=kmmotos-public
#PUBLIC_AWS_URL=null
#PUBLIC_AWS_ENDPOINT=null
#PUBLIC_AWS_PATH_STYLE=false
#PUBLIC_AWS_BUCKET_ROOT=null
```

**¿Qué hace?**
- Si cambias `PUBLIC_FILESYSTEM_DISK=s3_public`, estas variables controlan dónde se suben las imágenes públicas (logos, fotos de activos, etc.)
- **PUBLIC_AWS_BUCKET**: Nombre del bucket de S3
- **PUBLIC_AWS_ENDPOINT**: URL del servicio (puede ser AWS, MinIO, DigitalOcean Spaces, etc.)

---

#### 3. Configuración de S3 Privada (Opcional)

**Ubicación**: Líneas 215-223  
**Sección**: `# CONFIGURACIÓN S3 PRIVADA`

```bash
#PRIVATE_AWS_ACCESS_KEY_ID=null
#PRIVATE_AWS_SECRET_ACCESS_KEY=null
#PRIVATE_AWS_DEFAULT_REGION=us-east-1
#PRIVATE_AWS_BUCKET=kmmotos-private
#PRIVATE_AWS_URL=null
#PRIVATE_AWS_ENDPOINT=null
#PRIVATE_AWS_PATH_STYLE=false
#PRIVATE_AWS_BUCKET_ROOT=null
```

**¿Qué hace?**
- Controla dónde se suben archivos privados (documentos adjuntos, archivos de usuarios, etc.)
- Similar a la configuración pública pero para archivos sensibles

---

#### 4. Límites de Carga de Archivos

**Ubicación**: Líneas 269-274  
**Sección**: `# LÍMITES DE CARGA PHP`

```bash
PHP_UPLOAD_LIMIT=100M
PHP_POST_MAX_SIZE=100M
PHP_UPLOAD_MAX_FILESIZE=100M
PHP_MEMORY_LIMIT=512M
```

**¿Qué hace?**
- **Línea 269**: Límite máximo para cargar archivos individuales (100 MB)
- **Línea 270**: Límite de datos POST (debe ser igual o mayor que UPLOAD_LIMIT)
- **Línea 271**: Límite alternativo de tamaño de archivo
- **Línea 272**: Memoria máxima que PHP puede usar por solicitud

**Para subir archivos más grandes:**
```bash
# Cambiar a valores mayores si necesitas subir archivos grandes:
PHP_UPLOAD_LIMIT=500M
PHP_POST_MAX_SIZE=500M
PHP_UPLOAD_MAX_FILESIZE=500M
PHP_MEMORY_LIMIT=1024M
```

⚠️ **IMPORTANTE**: Después de cambiar estos valores, debes reiniciar los contenedores:
```bash
docker compose -f docker-compose.production.yml restart app
```

---

## 📁 Rutas Internas de la Aplicación

### Archivo: `Dockerfile`

**Ubicación**: Líneas 94-100  
**Sección**: Creación de enlaces simbólicos

```dockerfile
RUN \
	rm -r "/var/www/html/storage/private_uploads" && ln -fs "/var/lib/snipeit/data/private_uploads" "/var/www/html/storage/private_uploads" \
      && rm -rf "/var/www/html/public/uploads" && ln -fs "/var/lib/snipeit/data/uploads" "/var/www/html/public/uploads" \
      && rm -r "/var/www/html/storage/app/backups" && ln -fs "/var/lib/snipeit/dumps" "/var/www/html/storage/app/backups" \
      && mkdir -p "/var/lib/snipeit/keys" && ln -fs "/var/lib/snipeit/keys/oauth-private.key" "/var/www/html/storage/oauth-private.key" \
      && ln -fs "/var/lib/snipeit/keys/oauth-public.key" "/var/www/html/storage/oauth-public.key" \
      && ln -fs "/var/lib/snipeit/keys/ldap_client_tls.cert" "/var/www/html/storage/ldap_client_tls.cert"
```

**¿Qué hace cada línea?**

#### Línea 94: Private Uploads
```dockerfile
rm -r "/var/www/html/storage/private_uploads" && ln -fs "/var/lib/snipeit/data/private_uploads" "/var/www/html/storage/private_uploads"
```
- **Acción**: Elimina el directorio original y crea un enlace simbólico
- **Origen real**: `/var/lib/snipeit/data/private_uploads` (en disco externo)
- **Enlace en app**: `/var/www/html/storage/private_uploads`
- **Contenido**: Archivos privados cargados por usuarios (documentos, licencias, etc.)
- **Acceso**: Solo usuarios autenticados

#### Línea 95: Public Uploads
```dockerfile
rm -rf "/var/www/html/public/uploads" && ln -fs "/var/lib/snipeit/data/uploads" "/var/www/html/public/uploads"
```
- **Acción**: Enlaza carpeta de uploads públicos
- **Origen real**: `/var/lib/snipeit/data/uploads` (en disco externo)
- **Enlace en app**: `/var/www/html/public/uploads`
- **Contenido**: 
  - `/public/uploads/assets/*` - Fotos de activos (laptops, monitores, etc.)
  - `/public/uploads/avatars/*` - Fotos de perfil de usuarios
  - `/public/uploads/logo.*` - Logos de la empresa
  - `/public/uploads/models/*` - Imágenes de modelos de activos
  - `/public/uploads/suppliers/*` - Logos de proveedores
  - `/public/uploads/accessories/*` - Fotos de accesorios
  - `/public/uploads/locations/*` - Fotos de ubicaciones
  - `/public/uploads/manufacturers/*` - Logos de fabricantes
  - `/public/uploads/components/*` - Fotos de componentes
  - `/public/uploads/consumables/*` - Fotos de consumibles
  - `/public/uploads/companies/*` - Logos de compañías
  - `/public/uploads/categories/*` - Iconos de categorías
  - `/public/uploads/users/*` - Documentos de usuarios
  - `/public/uploads/departments/*` - Imágenes de departamentos
- **Acceso**: Públicamente accesible vía HTTP

#### Línea 96: Backups
```dockerfile
rm -r "/var/www/html/storage/app/backups" && ln -fs "/var/lib/snipeit/dumps" "/var/www/html/storage/app/backups"
```
- **Acción**: Enlaza carpeta de backups manuales
- **Origen real**: `/var/lib/snipeit/dumps` (en disco externo)
- **Enlace en app**: `/var/www/html/storage/app/backups`
- **Contenido**: Backups generados desde la interfaz web (exportaciones de datos, SQL dumps manuales)
- **Acceso**: Solo administradores

#### Línea 97-100: Claves y Certificados
```dockerfile
mkdir -p "/var/lib/snipeit/keys" && ln -fs "/var/lib/snipeit/keys/oauth-private.key" "/var/www/html/storage/oauth-private.key" \
&& ln -fs "/var/lib/snipeit/keys/oauth-public.key" "/var/www/html/storage/oauth-public.key" \
&& ln -fs "/var/lib/snipeit/keys/ldap_client_tls.cert" "/var/www/html/storage/ldap_client_tls.cert"
```
- **Acción**: Crea enlaces para claves de seguridad
- **Origen real**: `/var/lib/snipeit/keys/` (en disco externo)
- **Contenido**:
  - `oauth-private.key` - Clave privada para API OAuth
  - `oauth-public.key` - Clave pública para API OAuth
  - `ldap_client_tls.cert` - Certificado para conexión LDAP segura
- **Importancia**: CRÍTICO - Sin estas claves la autenticación API no funciona

---

## 🔄 Cómo Cambiar las Rutas

### Método 1: Cambiar Discos de Montaje (Recomendado)

Si necesitas mover los datos a otros discos:

```bash
# 1. Detener servicios
docker compose -f docker-compose.production.yml down

# 2. Copiar datos al nuevo disco (ejemplo: mover de SDB a nuevo_disco)
sudo rsync -avz --progress /mnt/sdb/snipeit-data/ /mnt/nuevo_disco/snipeit-data/

# 3. Editar docker-compose.production.yml
nano docker-compose.production.yml
# Cambiar todas las referencias de /mnt/sdb a /mnt/nuevo_disco

# 4. Reiniciar servicios
docker compose -f docker-compose.production.yml up -d

# 5. Verificar que funciona
docker compose -f docker-compose.production.yml ps
docker compose -f docker-compose.production.yml logs -f
```

### Método 2: Cambiar a Almacenamiento S3

Si el disco local no es suficiente o prefieres almacenamiento en nube:

```bash
# 1. Configurar bucket de S3 (AWS, MinIO, DigitalOcean, etc.)

# 2. Editar .env
nano .env

# Cambiar:
PRIVATE_FILESYSTEM_DISK=s3_private
PUBLIC_FILESYSTEMPRIVATE_FILESYSTEM_DISK=s3_public

# Configurar credenciales:
PUBLIC_AWS_ACCESS_KEY_ID=tu_access_key
PUBLIC_AWS_SECRET_ACCESS_KEY=tu_secret_key
PUBLIC_AWS_DEFAULT_REGION=us-east-1
PUBLIC_AWS_BUCKET=kmmotos-public
PUBLIC_AWS_ENDPOINT=https://s3.amazonaws.com

PRIVATE_AWS_ACCESS_KEY_ID=tu_access_key
PRIVATE_AWS_SECRET_ACCESS_KEY=tu_secret_key
PRIVATE_AWS_DEFAULT_REGION=us-east-1
PRIVATE_AWS_BUCKET=kmmotos-private

# 3. Migrar archivos existentes (opcional)
# Usar AWS CLI o script de migración

# 4. Reiniciar
docker compose -f docker-compose.production.yml restart app
```

### Método 3: NFS o Almacenamiento en Red

Si quieres usar un NAS o almacenamiento compartido:

```bash
# 1. Montar NFS
sudo apt install nfs-common
sudo mkdir -p /mnt/nfs-storage

# 2. Editar /etc/fstab
sudo nano /etc/fstab
# Agregar:
192.168.1.100:/export/snipeit  /mnt/nfs-storage  nfs  defaults  0  0

# 3. Montar
sudo mount -a

# 4. Editar docker-compose.production.yml
nano docker-compose.production.yml
# Cambiar rutas a /mnt/nfs-storage/...

# 5. Reiniciar servicios
docker compose -f docker-compose.production.yml restart
```

---

## 📊 Tipos de Archivos por Ubicación

### `/mnt/sdb/snipeit-data/uploads` (Públicos)

| Subcarpeta | Tipo de Archivo | Tamaño Promedio | Frecuencia de Cambio |
|------------|----------------|-----------------|---------------------|
| `/assets` | JPG, PNG, PDF | 1-5 MB | Alta (cada vez que se agrega un activo con foto) |
| `/avatars` | JPG, PNG | 100-500 KB | Baja (solo cuando usuarios cambian foto) |
| `/logo.*` | PNG, SVG, JPG | 100-500 KB | Muy baja (solo cambios de branding) |
| `/models` | JPG, PNG | 500 KB - 2 MB | Media (al agregar nuevos modelos) |
| `/suppliers` | JPG, PNG, PDF | 500 KB - 2 MB | Baja (solo al agregar proveedores) |
| `/accessories` | JPG, PNG | 500 KB - 2 MB | Media |
| `/manufacturers` | JPG, PNG, PDF | 100 KB - 1 MB | Baja |
| `/components` | JPG, PNG | 500 KB - 2 MB | Media |
| `/consumables` | JPG, PNG | 500 KB - 2 MB | Media |
| `/locations` | JPG, PNG | 1-5 MB | Baja |
| `/barcodes` | PNG (generadas) | 5-20 KB | Alta (automáticas) |

**Espacio estimado total**: 50-500 GB (dependiendo de cuántos activos tengas)
**Crecimiento**: 100-500 MB por mes en uso normal

### `/mnt/sdb/snipeit-data/private_uploads` (Privados)

| Contenido | Tipo de Archivo | Tamaño Promedio |
|-----------|----------------|-----------------|
| Documentos de usuarios | PDF, DOCX | 1-10 MB |
| Licencias escaneadas | PDF, JPG | 2-5 MB |
| Contratos | PDF | 500 KB - 5 MB |
| Facturas | PDF | 200 KB - 2 MB |

**Espacio estimado**: 10-100 GB
**Crecimiento**: 50-200 MB por mes

### `/mnt/sdc/snipeit-db` (Base de Datos)

| Contenido | Tamaño Inicial | Crecimiento |
|-----------|---------------|-------------|
| Tablas de activos | 50-100 MB | 10-50 MB/mes |
| Historial de auditoría | 10-50 MB | 20-100 MB/mes |
| Usuarios y permisos | 5-10 MB | 1-5 MB/mes |
| Índices | 20-50 MB | 5-20 MB/mes |

**Espacio estimado**: 100 MB - 5 GB
**Crecimiento**: 50-200 MB por mes (dependiendo de actividad)

### `/mnt/sdc/snipeit-backups` (Backups)

**Tamaño por backup**: 50 MB - 2 GB (comprimido con gzip)
**Frecuencia**: Diario (configurable)
**Retención**: 6 días por defecto (configurable en docker-compose.production.yml línea 178)

**Espacio estimado**:
- Con 6 días de retención: 300 MB - 12 GB
- Con 30 días: 1.5 GB - 60 GB
- Con 1 año: 18 GB - 730 GB

---

## 🚚 Migraciones de Almacenamiento

### Script de Migración Completa

Si necesitas mover todo el almacenamiento a nuevos discos:

```bash
#!/bin/bash
# Script: migrate_storage.sh
# Uso: ./migrate_storage.sh /mnt/disco_nuevo1 /mnt/disco_nuevo2

ORIGEN_DISCO1="/mnt/sdb"
ORIGEN_DISCO2="/mnt/sdc"
DESTINO_DISCO1="$1"
DESTINO_DISCO2="$2"

if [ -z "$DESTINO_DISCO1" ] || [ -z "$DESTINO_DISCO2" ]; then
    echo "Uso: $0 /ruta/nuevo/SDB /ruta/nuevo/SDC"
    exit 1
fi

echo "=== MIGRACIÓN DE ALMACENAMIENTO SNIPE-IT ==="
echo "Origen Disco SDB: $ORIGEN_DISCO1"
echo "Destino Disco SDB: $DESTINO_DISCO1"
echo "Origen Disco SDC: $ORIGEN_DISCO2"
echo "Destino Disco SDC: $DESTINO_DISCO2"
echo ""
read -p "¿Continuar? (s/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    exit 1
fi

# 1. Detener servicios
echo "1. Deteniendo servicios..."
cd ~/INVENTARIO-KM-MOTOS
docker compose -f docker-compose.production.yml down

# 2. Migrar Disco SDB (Datos de aplicación)
echo "2. Migrando datos del Disco SDB..."
sudo rsync -avz --progress "$ORIGEN_DISCO1/snipeit-data/" "$DESTINO_DISCO1/snipeit-data/"
sudo rsync -avz --progress "$ORIGEN_DISCO1/snipeit-redis/" "$DESTINO_DISCO1/snipeit-redis/"
sudo rsync -avz --progress "$ORIGEN_DISCO1/nginx-logs/" "$DESTINO_DISCO1/nginx-logs/"

# 3. Migrar Disco SDC (Base de datos y backups)
echo "3. Migrando datos del Disco SDC..."
sudo rsync -avz --progress "$ORIGEN_DISCO2/snipeit-db/" "$DESTINO_DISCO2/snipeit-db/"
sudo rsync -avz --progress "$ORIGEN_DISCO2/snipeit-backups/" "$DESTINO_DISCO2/snipeit-backups/"

# 4. Actualizar docker-compose.yml
echo "4. Actualizando configuración de Docker..."
sed -i "s|/mnt/sdb|$DESTINO_DISCO1|g" docker-compose.production.yml
sed -i "s|/mnt/sdc|$DESTINO_DISCO2|g" docker-compose.production.yml

# 5. Reiniciar servicios
echo "5. Reiniciando servicios..."
docker compose -f docker-compose.production.yml up -d

# 6. Verificar
echo "6. Verificando servicios..."
sleep 10
docker compose -f docker-compose.production.yml ps

echo ""
echo "=== MIGRACIÓN COMPLETADA ==="
echo "Verifica que todo funcione correctamente antes de eliminar los datos antiguos."
echo "Para eliminar datos antiguos (¡CUIDADO!):"
echo "  sudo rm -rf $ORIGEN_DISCO1/snipeit-*"
echo "  sudo rm -rf $ORIGEN_DISCO2/snipeit-*"
```

**Uso del script:**
```bash
chmod +x migrate_storage.sh
./migrate_storage.sh /mnt/nuevo_SDB /mnt/nuevo_SDC
```

---

## 🔍 Verificación de Rutas

### Script de Verificación

```bash
#!/bin/bash
# Script: check_storage.sh
# Verifica que todas las rutas estén correctamente configuradas

echo "=== VERIFICACIÓN DE ALMACENAMIENTO SNIPE-IT ==="
echo ""

# Verificar montajes
echo "1. Discos montados:"
df -h | grep -E "mnt/disco|Filesystem"
echo ""

# Verificar directorios
echo "2. Directorios de aplicación:"
for dir in /mnt/sdb/snipeit-data /mnt/sdb/snipeit-redis /mnt/sdb/nginx-logs /mnt/sdc/snipeit-db /mnt/sdc/snipeit-backups; do
    if [ -d "$dir" ]; then
        echo "[OK] $dir - $(du -sh $dir | cut -f1)"
    else
        echo "[ERROR] $dir - NO EXISTE"
    fi
done
echo ""

# Verificar permisos
echo "3. Permisos:"
ls -ld /mnt/sdb/snipeit-* /mnt/sdc/snipeit-*
echo ""

# Verificar contenedores
echo "4. Estado de contenedores:"
cd ~/INVENTARIO-KM-MOTOS
docker compose -f docker-compose.production.yml ps
echo ""

# Verificar volúmenes internos
echo "5. Rutas internas (dentro de contenedor app):"
docker compose -f docker-compose.production.yml exec app ls -lah /var/lib/snipeit/
echo ""

echo "=== FIN DE VERIFICACIÓN ==="
```

**Uso:**
```bash
chmod +x check_storage.sh
./check_storage.sh
```

---

## 📞 Resumen para Cambios Manuales

### Pasos Rápidos para Cambiar Rutas

1. **Detener servicios**:
   ```bash
   docker compose -f docker-compose.production.yml down
   ```

2. **Editar `docker-compose.production.yml`**:
   - Buscar y reemplazar rutas antiguas por nuevas
   - Asegurarse que los directorios existan

3. **Crear directorios (si no existen)**:
   ```bash
   sudo mkdir -p /nueva/ruta/datos
   sudo chown -R $USER:$USER /nueva/ruta/datos
   ```

4. **Copiar datos (si es necesario)**:
   ```bash
   sudo rsync -avz /ruta/vieja/ /ruta/nueva/
   ```

5. **Reiniciar servicios**:
   ```bash
   docker compose -f docker-compose.production.yml up -d
   ```

6. **Verificar**:
   ```bash
   docker compose -f docker-compose.production.yml ps
   docker compose -f docker-compose.production.yml logs -f
   ```

---

## ⚠️ IMPORTANTE - Rutas Críticas

### NO modificar sin respaldo:
- `/var/lib/snipeit/data/uploads` - Contiene TODAS las imágenes de activos
- `/var/lib/mysql` - Contiene toda la base de datos
- `/var/lib/snipeit/keys` - Contiene claves de seguridad

### Modificar con cuidado:
- `/var/log/nginx` - Solo logs, se puede vaciar
- `/data` (redis) - Solo cache, se regenera

### Recomendaciones:
1. **SIEMPRE** hacer backup antes de cambiar rutas
2. Verificar espacio disponible en nuevas ubicaciones
3. Mantener permisos correctos (755 para directorios, 644 para archivos)
4. Documentar todos los cambios realizados

---

**Fin del documento de rutas de almacenamiento**
