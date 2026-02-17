# 🗺️ REFERENCIA RÁPIDA - RUTAS Y LÍNEAS DE CÓDIGO

## 📍 RESUMEN EJECUTIVO

Este documento proporciona una **referencia rápida** de las ubicaciones exactas en el código donde se configuran las rutas de almacenamiento para imágenes y archivos.

---

## 🔧 ARCHIVOS DE CONFIGURACIÓN PRINCIPALES

### 1. docker-compose.production.yml
**Propósito**: Definir volúmenes Docker que mapean directorios del servidor a los contenedores

#### 📂 Datos de Aplicación (Imágenes, Uploads, Archivos)
```yaml
Archivo: docker-compose.production.yml
Líneas: 16-22
Sección: services.app.volumes
```
**Código:**
```yaml
volumes:
  - /mnt/sdb/snipeit-data:/var/lib/snipeit
  - ./.env:/var/www/html/.env:ro
```
**¿Qué hace?**  
Monta el directorio `/mnt/sdb/snipeit-data` del servidor en `/var/lib/snipeit` dentro del contenedor donde se almacenan TODOS los uploads de la aplicación.

**¿Qué contiene?**
- Imágenes de activos (laptops, monitores, etc.)
- Fotos de usuarios y avatares
- Logos de la empresa
- Documentos adjuntos
- Archivos privados de usuarios

**Para cambiar**: Edita línea 19, reemplaza `/mnt/sdb/snipeit-data` por la nueva ruta.

---

#### 🗄️ Base de Datos
```yaml
Archivo: docker-compose.production.yml
Líneas: 65-68
Sección: services.db.volumes
```
**Código:**
```yaml
volumes:
  - /mnt/sdc/snipeit-db:/var/lib/mysql
```
**¿Qué hace?**  
Monta el directorio donde MariaDB guarda toda la base de datos del inventario.

**¿Qué contiene?**
- Todas las tablas de activos
- Usuarios y permisos
- Historial de auditoría
- Configuraciones del sistema

**Para cambiar**: Edita línea 66, reemplaza `/mnt/sdc/snipeit-db` por la nueva ruta.

---

#### 💨 Cache Redis
```yaml
Archivo: docker-compose.production.yml
Líneas: 110-112
Sección: services.redis.volumes
```
**Código:**
```yaml
volumes:
  - /mnt/sdb/snipeit-redis:/data
```
**¿Qué hace?**  
Almacena datos de cache y sesiones de usuarios para mejorar rendimiento.

**Para cambiar**: Edita línea 111.

---

#### 📝 Logs de Nginx
```yaml
Archivo: docker-compose.production.yml
Líneas: 143-146
Sección: services.nginx.volumes
```
**Código:**
```yaml
volumes:
  - ./docker/nginx.conf:/etc/nginx/nginx.conf:ro
  - ./docker/ssl:/etc/nginx/ssl:ro
  - /mnt/sdb/nginx-logs:/var/log/nginx
```
**¿Qué hace?**  
Guarda logs de acceso y errores del servidor web.

**Para cambiar**: Edita línea 145.

---

#### 💾 Backups Automáticos
```yaml
Archivo: docker-compose.production.yml
Líneas: 167-169
Sección: services.backup.volumes
```
**Código:**
```yaml
volumes:
  - /mnt/sdc/snipeit-backups:/backup
```
**¿Qué hace?**  
Directorio donde se guardan los backups diarios automáticos de la base de datos.

**Para cambiar**: Edita línea 168.

---

### 2. .env.production
**Propósito**: Variables de entorno que controlan el comportamiento de la aplicación

#### 📦 Tipo de Almacenamiento
```bash
Archivo: .env.production
Líneas: 50-57
Sección: CONFIGURACIÓN DE ALMACENAMIENTO DE ARCHIVOS
```
**Código:**
```bash
PRIVATE_FILESYSTEM_DISK=local
PUBLIC_FILESYSTEM_DISK=local_public
```
**¿Qué hace?**
- **Línea 51**: Define que archivos PRIVADOS se guardan en disco local (en `/var/lib/snipeit/data/private_uploads`)
- **Línea 52**: Define que archivos PÚBLICOS se guardan en disco local (en `/var/lib/snipeit/data/uploads`)

**Para cambiar a S3/Nube**:
```bash
PRIVATE_FILESYSTEM_DISK=s3_private
PUBLIC_FILESYSTEM_DISK=s3_public
```
Luego configurar credenciales en líneas 202-232.

---

#### 📤 Límites de Carga de Archivos
```bash
Archivo: .env.production
Líneas: 269-274
Sección: LÍMITES DE CARGA PHP
```
**Código:**
```bash
PHP_UPLOAD_LIMIT=100M
PHP_POST_MAX_SIZE=100M
PHP_UPLOAD_MAX_FILESIZE=100M
PHP_MEMORY_LIMIT=512M
```
**¿Qué hace?**  
Controla el tamaño máximo de archivos que se pueden subir (100 MB por defecto).

**Para cambiar**: Modifica los valores (ejemplo: `500M` para 500 MB).  
⚠️ Después de cambiar, reiniciar: `docker compose -f docker-compose.production.yml restart app`

---

### 3. Dockerfile
**Propósito**: Define cómo se construye la imagen Docker y configura enlaces simbólicos internos

#### 🔗 Enlaces Simbólicos Internos
```dockerfile
Archivo: Dockerfile
Líneas: 94-100
Sección: Creación de enlaces simbólicos para almacenamiento
```

##### 📁 Uploads Privados (Línea 94)
**Código:**
```dockerfile
rm -r "/var/www/html/storage/private_uploads" && ln -fs "/var/lib/snipeit/data/private_uploads" "/var/www/html/storage/private_uploads"
```
**¿Qué hace?**  
Enlaza `/var/www/html/storage/private_uploads` → `/var/lib/snipeit/data/private_uploads`

**Contenido:**
- Documentos de usuarios
- Licencias escaneadas
- Archivos sensibles

---

##### 🌐 Uploads Públicos (Línea 95)
**Código:**
```dockerfile
rm -rf "/var/www/html/public/uploads" && ln -fs "/var/lib/snipeit/data/uploads" "/var/www/html/public/uploads"
```
**¿Qué hace?**  
Enlaza `/var/www/html/public/uploads` → `/var/lib/snipeit/data/uploads`

**Contenido (subdirectorios):**
- `/assets/*` - Fotos de activos físicos
- `/avatars/*` - Avatares de usuarios
- `/logo.*` - Logos de empresa
- `/models/*` - Imágenes de modelos
- `/suppliers/*` - Logos de proveedores
- `/accessories/*` - Fotos de accesorios
- `/locations/*` - Fotos de ubicaciones
- `/manufacturers/*` - Logos de fabricantes
- `/components/*` - Fotos de componentes
- `/consumables/*` - Fotos de consumibles
- `/companies/*` - Logos de compañías
- `/categories/*` - Iconos de categorías
- `/departments/*` - Imágenes de departamentos
- `/barcodes/*.png` - Códigos de barras generados

---

##### 💾 Backups Manuales (Línea 96)
**Código:**
```dockerfile
rm -r "/var/www/html/storage/app/backups" && ln -fs "/var/lib/snipeit/dumps" "/var/www/html/storage/app/backups"
```
**¿Qué hace?**  
Enlaza carpeta de backups generados desde la interfaz web.

**Contenido:**
- Exportaciones CSV/Excel
- Dumps SQL manuales
- Exportaciones de datos

---

##### 🔐 Claves de Seguridad (Líneas 97-100)
**Código:**
```dockerfile
mkdir -p "/var/lib/snipeit/keys" && ln -fs "/var/lib/snipeit/keys/oauth-private.key" "/var/www/html/storage/oauth-private.key" \
&& ln -fs "/var/lib/snipeit/keys/oauth-public.key" "/var/www/html/storage/oauth-public.key" \
&& ln -fs "/var/lib/snipeit/keys/ldap_client_tls.cert" "/var/www/html/storage/ldap_client_tls.cert"
```
**¿Qué hace?**  
Enlaza archivos de claves de seguridad.

**Contenido:**
- `oauth-private.key` - Clave privada API OAuth
- `oauth-public.key` - Clave pública API OAuth  
- `ldap_client_tls.cert` - Certificado LDAP

⚠️ **CRÍTICO**: Sin estos archivos la API no funciona.

---

## 🗂️ MAPA COMPLETO DE RUTAS

### Servidor → Docker → Aplicación

```
SERVIDOR                          DOCKER VOLUME           APLICACIÓN (Laravel)
├─ /mnt/sdb/
│  ├─ snipeit-data/          →   /var/lib/snipeit/
│  │  ├─ data/
│  │  │  ├─ uploads/         →   /var/www/html/public/uploads/
│  │  │  │  ├─ assets/       →   public/uploads/assets/         [IMÁGENES DE ACTIVOS]
│  │  │  │  ├─ avatars/      →   public/uploads/avatars/        [FOTOS DE USUARIOS]
│  │  │  │  ├─ logo.*        →   public/uploads/logo.*          [LOGOS DE EMPRESA]
│  │  │  │  ├─ models/       →   public/uploads/models/         [IMÁGENES DE MODELOS]
│  │  │  │  ├─ suppliers/    →   public/uploads/suppliers/      [LOGOS DE PROVEEDORES]
│  │  │  │  ├─ accessories/  →   public/uploads/accessories/    [FOTOS DE ACCESORIOS]
│  │  │  │  ├─ locations/    →   public/uploads/locations/      [FOTOS DE UBICACIONES]
│  │  │  │  ├─ manufacturers/→   public/uploads/manufacturers/  [LOGOS DE FABRICANTES]
│  │  │  │  ├─ components/   →   public/uploads/components/     [FOTOS DE COMPONENTES]
│  │  │  │  ├─ consumables/  →   public/uploads/consumables/    [FOTOS DE CONSUMIBLES]
│  │  │  │  ├─ companies/    →   public/uploads/companies/      [LOGOS DE COMPAÑÍAS]
│  │  │  │  ├─ categories/   →   public/uploads/categories/     [ICONOS DE CATEGORÍAS]
│  │  │  │  ├─ departments/  →   public/uploads/departments/    [FOTOS DE DEPARTAMENTOS]
│  │  │  │  └─ barcodes/     →   public/uploads/barcodes/       [CÓDIGOS DE BARRAS]
│  │  │  └─ private_uploads/ →   storage/private_uploads/       [ARCHIVOS PRIVADOS]
│  │  ├─ dumps/              →   storage/app/backups/           [BACKUPS MANUALES]
│  │  └─ keys/               →   storage/*.key                  [CLAVES OAUTH/LDAP]
│  ├─ snipeit-redis/         →   /data (redis)                  [CACHE Y SESIONES]
│  └─ nginx-logs/            →   /var/log/nginx                 [LOGS DE ACCESO]
│
└─ /mnt/sdc/
   ├─ snipeit-db/            →   /var/lib/mysql                 [BASE DE DATOS]
   └─ snipeit-backups/       →   /backup                        [BACKUPS AUTOMÁTICOS]
```

---

## 🎯 GUÍA RÁPIDA DE MODIFICACIÓN

### ¿Quieres cambiar dónde se guardan las imágenes?

**Opción 1: Cambiar disco de montaje**
```bash
# 1. Detener servicios
docker compose -f docker-compose.production.yml down

# 2. Editar docker-compose.production.yml línea 19
# Cambiar: /mnt/sdb/snipeit-data
# Por: /nueva/ruta/datos

# 3. Copiar datos existentes
rsync -avz /mnt/sdb/snipeit-data/ /nueva/ruta/datos/

# 4. Reiniciar
docker compose -f docker-compose.production.yml up -d
```

**Opción 2: Usar S3/Nube**
```bash
# 1. Editar .env líneas 51-52
PRIVATE_FILESYSTEM_DISK=s3_private
PUBLIC_FILESYSTEM_DISK=s3_public

# 2. Configurar credenciales en .env líneas 202-232
PUBLIC_AWS_BUCKET=mi-bucket-publico
PUBLIC_AWS_ACCESS_KEY_ID=mi_key
# ... etc

# 3. Reiniciar app
docker compose -f docker-compose.production.yml restart app
```

---

### ¿Quieres aumentar el límite de tamaño de archivos?

```bash
# Editar .env líneas 269-274
nano .env

# Cambiar de 100M a 500M (ejemplo):
PHP_UPLOAD_LIMIT=500M
PHP_POST_MAX_SIZE=500M
PHP_UPLOAD_MAX_FILESIZE=500M
PHP_MEMORY_LIMIT=1024M

# Reiniciar
docker compose -f docker-compose.production.yml restart app
```

---

### ¿Quieres cambiar ubicación de backups?

```bash
# Editar docker-compose.production.yml línea 168
# Cambiar: /mnt/sdc/snipeit-backups
# Por: /nueva/ruta/backups

# Reiniciar servicio de backup
docker compose -f docker-compose.production.yml restart backup
```

---

## 📊 TAMAÑOS ESTIMADOS POR DIRECTORIO

| Directorio | Contenido | Tamaño Inicial | Crecimiento Mensual |
|------------|-----------|----------------|---------------------|
| `/mnt/sdb/snipeit-data/uploads/assets` | Fotos de activos | 10-100 GB | 50-500 MB |
| `/mnt/sdb/snipeit-data/uploads/avatars` | Fotos de usuarios | 100 MB - 1 GB | 5-20 MB |
| `/mnt/sdb/snipeit-data/uploads/logo.*` | Logos | 5-50 MB | < 1 MB |
| `/mnt/sdb/snipeit-data/uploads/barcodes` | Códigos de barras | 10-100 MB | 10-50 MB |
| `/mnt/sdb/snipeit-data/private_uploads` | Documentos privados | 1-10 GB | 20-100 MB |
| `/mnt/sdc/snipeit-db` | Base de datos | 100 MB - 5 GB | 50-200 MB |
| `/mnt/sdc/snipeit-backups` | Backups diarios | 500 MB - 10 GB | 1-5 GB |

**Estimación total con 1000 activos**: 50-150 GB  
**Estimación total con 10,000 activos**: 200-500 GB

---

## ⚡ COMANDOS ÚTILES

### Ver uso de espacio por directorio
```bash
du -sh /mnt/sdb/snipeit-data/*
du -sh /mnt/sdc/*
```

### Ver archivos más grandes
```bash
find /mnt/sdb/snipeit-data/uploads -type f -size +10M -exec ls -lh {} \; | sort -k5 -hr | head -20
```

### Limpiar logs viejos
```bash
find /mnt/sdb/nginx-logs -name "*.log" -mtime +30 -delete
```

### Ver espacio en contenedores
```bash
docker compose -f docker-compose.production.yml exec app df -h
docker compose -f docker-compose.production.yml exec db df -h
```

---

## 🔍 VERIFICACIÓN POST-CAMBIOS

Después de cambiar rutas, ejecuta:

```bash
# 1. Verificar montajes
df -h | grep mnt

# 2. Verificar directorios
ls -lah /mnt/sdb/snipeit-data/
ls -lah /mnt/sdc/snipeit-db/

# 3. Verificar contenedores
docker compose -f docker-compose.production.yml ps

# 4. Verificar logs
docker compose -f docker-compose.production.yml logs -f app

# 5. Verificar rutas internas
docker compose -f docker-compose.production.yml exec app ls -lah /var/lib/snipeit/

# 6. Probar subida de archivo
# Ir a la web y subir una imagen de prueba en un activo
```

---

## ⚠️ IMPORTANTE

❌ **NO MODIFICAR DIRECTAMENTE** estos archivos en producción sin hacer backup:
- Dockerfile (solo si recompila imagen)
- docker-compose.production.yml (hacer backup antes)
- Directorios dentro de contenedores en ejecución

✅ **ES SEGURO MODIFICAR**:
- `.env` (variables de entorno)
- Rutas de volúmenes en `docker-compose.production.yml`  
- Configuración de Nginx en `docker/nginx.conf`

🔒 **HACER BACKUP ANTES DE**:
- Cambiar ubicaciones de discos
- Migrar a S3
- Actualizar versiones
- Modificar estructura de directorios

---

**Fin de la referencia rápida**
