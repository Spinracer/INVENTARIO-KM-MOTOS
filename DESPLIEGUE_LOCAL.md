# Documento de Despliegue Local - Snipe-IT KM Motos

## 📋 Resumen del Despliegue

Este documento detalla el proceso completo de despliegue local del sistema de inventario Snipe-IT para KM Motos, realizado el 18 de febrero de 2026.

---

## 🎯 Objetivo

Desplegar el sistema Snipe-IT de forma local utilizando Docker Compose para desarrollo y pruebas antes del despliegue en producción con los discos sdb (500TB) y sdc (500TB).

---

## 🛠️ Arquitectura Implementada

### Servicios Desplegados

```
┌─────────────────────────────────────────┐
│  Puerto 8000 - Snipe-IT Web Interface   │
└─────────────────┬───────────────────────┘
                  │
      ┌───────────▼───────────┐
      │   snipeit-app-local   │
      │   snipe-it:v7.0.13    │
      │   (Laravel 11)        │
      └────┬──────────────┬───┘
           │              │
    ┌──────▼─────┐   ┌───▼──────────┐
    │ MariaDB    │   │   Redis      │
    │ 11.4.7     │   │   7.4.3      │
    │ Puerto     │   │   Cache/     │
    │ 33060      │   │   Sessions   │
    └────────────┘   └──────────────┘
```

### Contenedores Creados

| Container Name | Image | Puerto | Función |
|----------------|-------|--------|---------|
| snipeit-app-local | snipe/snipe-it:v7.0.13 | 8000:80 | Aplicación web principal |
| snipeit-db-local | mariadb:11.4.7 | 33060:3306 | Base de datos |
| snipeit-redis-local | redis:7.4.3-alpine | 6379 | Cache y sesiones |

---

## 📁 Estructura de Archivos Creados

```
INVENTARIO-KM-MOTOS/
├── docker-compose.local.yml      # Configuración Docker local
├── docker-compose.production.yml # Configuración Docker producción (sdb/sdc)
├── .env                          # Variables de entorno local
├── .env.production               # Variables de entorno producción
├── install-production.sh         # Script instalación automática producción
├── docker/
│   └── nginx.conf                # Configuración Nginx para producción
├── local-storage/                # Almacenamiento local (gitignored)
│   ├── snipeit-data/             # Datos aplicación (uploads, attachments)
│   ├── snipeit-db/               # Base de datos MariaDB
│   ├── snipeit-redis/            # Datos persistentes Redis
│   ├── snipeit-backups/          # Respaldos
│   └── nginx-logs/               # Logs Nginx (para producción)
└── Documentación/
    ├── GUIA_DESPLIEGUE.md        # Guía detallada producción
    ├── RUTAS_ALMACENAMIENTO.md   # Mapeo rutas con líneas código
    ├── REFERENCIA_RUTAS.md       # Referencia rápida rutas
    ├── POST_DESPLIEGUE.md        # Checklist post-despliegue
    ├── README_DESPLIEGUE.md      # README principal proyecto
    └── DESPLIEGUE_LOCAL.md       # Este documento
```

---

## 🔧 Proceso de Implementación

### Fase 1: Análisis del Proyecto

1. **Análisis de código fuente**: Se revisó el código completo de Snipe-IT v7.0.13 para identificar todas las rutas de almacenamiento
2. **Identificación de puntos de configuración**: Se documentaron todas las referencias en código con números de línea exactos
3. **Mapeo de volúmenes**: Se determinó qué datos van en disco sdb vs sdc

### Fase 2: Creación de Configuraciones

#### A. Docker Compose Local

**Archivo**: `docker-compose.local.yml`

Características:
- Simplificado para desarrollo rápido
- Sin Nginx (acceso directo puerto 8000)
- Volúmenes locales en `./local-storage/`
- Healthchecks optimizados para MariaDB y Redis
- Red bridge interna `snipeit-network`

**Servicios configurados**:
```yaml
- app: Snipe-IT v7.0.13
- db: MariaDB 11.4.7
- redis: Redis 7.4.3-alpine
```

#### B. Docker Compose Producción

**Archivo**: `docker-compose.production.yml`

Características:
- Configurado para discos montados en `/mnt/sdb` y `/mnt/sdc`
- Incluye Nginx como reverse proxy (puertos 80/443)
- Servicio adicional de backups automáticos
- Configuración optimizada para alta disponibilidad
- SSL/TLS con Let's Encrypt

**Distribución de almacenamiento**:
- **/mnt/sdb**: Datos aplicación, cache Redis, logs Nginx
- **/mnt/sdc**: Base de datos MariaDB, backups

#### C. Variables de Entorno

**Archivo**: `.env` (local)

```bash
# Aplicación
APP_ENV=local
APP_DEBUG=true
APP_KEY=base64:/4ir1ue+AnnzQ7KhOFkpHXF/zojxa5K4IWy+NAR2KLI=
APP_URL=http://localhost:8000

# Base de datos
DB_CONNECTION=mysql
DB_HOST=db
DB_PORT=3306
DB_DATABASE=snipeit_kmmotos
DB_USERNAME=snipeit_user
DB_PASSWORD=snipeit_password_local_123
MYSQL_ROOT_PASSWORD=root_password_local_456

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# Mail (deshabilitado en local)
MAIL_DRIVER=log
```

**Nota**: Para producción usar `.env.production` con contraseñas fuertes.

### Fase 3: Resolución de Problemas Técnicos

#### Problema 1: Healthcheck Fallando

**Síntoma**: Container `snipeit-db-local` se marcaba como "unhealthy"

**Causa**: 
1. Primer intento usó `healthcheck.sh` que no existe en el contenedor
2. Segundo intento usó `mysqladmin` que tampoco existe en MariaDB 11.4.7

**Solución**:
```yaml
healthcheck:
  test: ["CMD", "mariadb", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}", "-e", "SELECT 1"]
  interval: 10s
  timeout: 5s
  retries: 10
  start_period: 60s
```

Se cambió a usar el cliente `mariadb` nativo con query simple `SELECT 1`.

#### Problema 2: Dependencias entre Contenedores

**Síntoma**: Aplicación intentaba iniciar antes de que la DB estuviera lista

**Solución**:
```yaml
depends_on:
  db:
    condition: service_healthy
    restart: true
  redis:
    condition: service_started
```

Se configuró `depends_on` con condición `service_healthy` para DB.

### Fase 4: Inicialización del Sistema

#### Comandos Ejecutados

1. **Crear directorios de almacenamiento**:
```bash
mkdir -p ./local-storage/{snipeit-data,snipeit-redis,snipeit-db,snipeit-backups,nginx-logs}
```

2. **Generar APP_KEY**:
```bash
docker run --rm snipe/snipe-it:v7.0.13 php artisan key:generate --show
# Resultado: base64:/4ir1ue+AnnzQ7KhOFkpHXF/zojxa5K4IWy+NAR2KLI=
```

3. **Iniciar servicios**:
```bash
docker compose -f docker-compose.local.yml up -d
```

4. **Ejecutar migraciones** (automático al iniciar):
```bash
docker compose -f docker-compose.local.yml exec app php artisan migrate --force
# Resultado: Nothing to migrate (ya ejecutado automáticamente)
```

5. **Crear usuario administrador**:
```bash
docker compose -f docker-compose.local.yml exec app php artisan snipeit:create-admin \
  --username=admin \
  --email=admin@kmmotos.local \
  --password=Admin123! \
  --first_name=Admin \
  --last_name=KMMotos
# Resultado: New user created
```

---

## ✅ Estado Final del Despliegue

### Verificación de Servicios

```bash
$ docker compose -f docker-compose.local.yml ps

NAME                  STATUS                    PORTS
snipeit-app-local     Up (healthy)             0.0.0.0:8000->80/tcp
snipeit-db-local      Up (healthy)             0.0.0.0:33060->3306/tcp
snipeit-redis-local   Up (healthy)             6379/tcp
```

### Verificación de Acceso Web

```bash
$ curl -I http://localhost:8000
HTTP/1.1 302 Found
Location: /login
```

✅ **Código 302** = Redirección esperada a página de login

---

## 🔐 Credenciales de Acceso

### Usuario Administrador

- **URL**: http://localhost:8000
- **Usuario**: `admin`
- **Contraseña**: `Admin123!`
- **Email**: admin@kmmotos.local

### Base de Datos MariaDB

- **Host**: localhost:33060
- **Database**: snipeit_kmmotos
- **User**: snipeit_user
- **Password**: snipeit_password_local_123
- **Root Password**: root_password_local_456

### Redis

- **Host**: localhost (interno en contenedor)
- **Port**: 6379 (no expuesto externamente)

---

## 📊 Recursos del Sistema

### Almacenamiento Utilizado

```bash
$ du -sh local-storage/*
4.0K    local-storage/nginx-logs
152M    local-storage/snipeit-data
248M    local-storage/snipeit-db
8.0K    local-storage/snipeit-redis
4.0K    local-storage/snipeit-backups
```

### Imágenes Docker

```bash
$ docker images | grep -E "snipe-it|mariadb|redis"
snipe/snipe-it    v7.0.13          ~800MB
mariadb           11.4.7           ~415MB
redis             7.4.3-alpine     ~50MB
```

**Total aprox**: 1.3GB de imágenes

---

## 🚀 Comandos de Gestión

### Iniciar Sistema

```bash
docker compose -f docker-compose.local.yml up -d
```

### Detener Sistema

```bash
docker compose -f docker-compose.local.yml down
```

### Ver Logs

```bash
# Todos los servicios
docker compose -f docker-compose.local.yml logs -f

# Solo aplicación
docker compose -f docker-compose.local.yml logs -f app

# Solo base de datos
docker compose -f docker-compose.local.yml logs -f db
```

### Reiniciar Servicio

```bash
docker compose -f docker-compose.local.yml restart app
```

### Acceder al Contenedor

```bash
# Aplicación
docker compose -f docker-compose.local.yml exec app bash

# Base de datos
docker compose -f docker-compose.local.yml exec db mariadb -u root -p

# Redis
docker compose -f docker-compose.local.yml exec redis redis-cli
```

### Ejecutar Comandos Artisan

```bash
# Limpiar cache
docker compose -f docker-compose.local.yml exec app php artisan cache:clear

# Ver rutas
docker compose -f docker-compose.local.yml exec app php artisan route:list

# Crear usuario adicional
docker compose -f docker-compose.local.yml exec app php artisan snipeit:create-admin
```

### Backup Manual

```bash
# Exportar base de datos
docker compose -f docker-compose.local.yml exec db mariadb-dump \
  -u root -proot_password_local_456 snipeit_kmmotos \
  > backup_$(date +%Y%m%d_%H%M%S).sql

# Exportar datos aplicación
tar -czf snipeit-data_$(date +%Y%m%d_%H%M%S).tar.gz local-storage/snipeit-data/
```

---

## 🔍 Verificación Post-Despliegue

### Checklist de Validación

- [x] Contenedor app en estado "healthy"
- [x] Contenedor db en estado "healthy"
- [x] Contenedor redis en estado "healthy"
- [x] Aplicación responde en puerto 8000
- [x] Migraciones de base de datos ejecutadas
- [x] Usuario administrador creado
- [x] Redirección a /login funciona
- [x] Volúmenes persistentes creados
- [ ] Login exitoso con usuario admin (pendiente prueba manual)
- [ ] Creación de categoría de prueba (pendiente prueba manual)
- [ ] Carga de imagen de prueba (pendiente prueba manual)

---

## 🌐 Acceso al Sistema

1. **Abrir navegador**: http://localhost:8000
2. **Login**: 
   - Usuario: `admin`
   - Contraseña: `Admin123!`
3. **Navegar**: Dashboard aparecerá después del login

---

## 📈 Próximos Pasos

### Para Despliegue en Producción

1. **Preparar servidor Ubuntu**:
   - Instalar Ubuntu Server 20.04 o superior
   - Configurar acceso SSH
   - Instalar Docker y Docker Compose

2. **Configurar discos**:
   ```bash
   # Formatear discos sdb y sdc
   sudo mkfs.ext4 /dev/sdb
   sudo mkfs.ext4 /dev/sdc
   
   # Crear puntos de montaje
   sudo mkdir -p /mnt/sdb /mnt/sdc
   
   # Montar discos
   sudo mount /dev/sdb /mnt/sdb
   sudo mount /dev/sdc /mnt/sdc
   
   # Agregar a fstab para montaje automático
   echo "/dev/sdb /mnt/sdb ext4 defaults 0 2" | sudo tee -a /etc/fstab
   echo "/dev/sdc /mnt/sdc ext4 defaults 0 2" | sudo tee -a /etc/fstab
   ```

3. **Transferir archivos**:
   ```bash
   scp -r /workspaces/INVENTARIO-KM-MOTOS usuario@servidor:/opt/snipeit-kmmotos/
   ```

4. **Ejecutar instalación**:
   ```bash
   cd /opt/snipeit-kmmotos
   chmod +x install-production.sh
   sudo ./install-production.sh
   ```

5. **Configurar dominio y SSL**:
   - Apuntar DNS a IP del servidor
   - El script install-production.sh configurará SSL automáticamente con Let's Encrypt

### Configuraciones Adicionales Recomendadas

- **Email**: Configurar SMTP en `.env.production` para notificaciones
- **Backup automático**: El servicio ya está incluido en docker-compose.production.yml
- **Monitoreo**: Instalar Portainer o similar para gestión visual
- **Firewall**: Configurar UFW para permitir solo puertos 22, 80, 443
- **Usuarios**: Crear usuarios con roles específicos (admin, manager, user)
- **Categorías**: Definir categorías de activos (Motos, Repuestos, Herramientas)
- **Ubicaciones**: Configurar sucursales/almacenes

---

## 🛡️ Seguridad

### Configuraciones Aplicadas

1. **Contraseñas**: Todas configuradas (cambiar en producción)
2. **Red Interna**: Contenedores en red bridge privada
3. **Puertos**: Solo 8000 expuesto (80/443 en producción con Nginx)
4. **Variables de entorno**: Almacenadas en archivo `.env` (no en código)
5. **Volúmenes**: Persistencia de datos fuera de contenedores

### Recomendaciones para Producción

- [ ] Cambiar todas las contraseñas por valores fuertes
- [ ] Habilitar SSL/TLS con certificado válido
- [ ] Configurar firewall (UFW)
- [ ] Implementar rate limiting en Nginx
- [ ] Configurar fail2ban para protección contra ataques
- [ ] Habilitar auditoría de accesos en Snipe-IT
- [ ] Configurar backups automáticos diarios
- [ ] Implementar monitoreo de recursos (CPU, RAM, disco)

---

## 📚 Documentación Relacionada

- [GUIA_DESPLIEGUE.md](GUIA_DESPLIEGUE.md) - Guía paso a paso para producción
- [RUTAS_ALMACENAMIENTO.md](RUTAS_ALMACENAMIENTO.md) - Mapeo detallado de rutas con líneas de código
- [REFERENCIA_RUTAS.md](REFERENCIA_RUTAS.md) - Referencia rápida de rutas
- [POST_DESPLIEGUE.md](POST_DESPLIEGUE.md) - Checklist post-instalación
- [README_DESPLIEGUE.md](README_DESPLIEGUE.md) - README principal del proyecto

---

## 🐛 Troubleshooting

### Contenedor DB no inicia

**Síntoma**: `snipeit-db-local` se marca como unhealthy

**Solución**:
```bash
# Ver logs
docker compose -f docker-compose.local.yml logs db

# Verificar healthcheck manualmente
docker exec snipeit-db-local mariadb -u root -proot_password_local_456 -e "SELECT 1"
```

### Aplicación no conecta a DB

**Síntoma**: Error "SQLSTATE[HY000] [2002] Connection refused"

**Solución**:
```bash
# Verificar que DB esté healthy
docker compose -f docker-compose.local.yml ps

# Reiniciar aplicación
docker compose -f docker-compose.local.yml restart app
```

### Puerto 8000 ocupado

**Síntoma**: Error "bind: address already in use"

**Solución**:
```bash
# Identificar proceso
sudo lsof -i :8000

# Cambiar puerto en docker-compose.local.yml
ports:
  - "8001:80"  # Usar 8001 en lugar de 8000
```

### Redis sin conexión

**Síntoma**: Logs muestran "Connection refused to Redis"

**Solución**:
```bash
# Verificar estado Redis
docker compose -f docker-compose.local.yml logs redis

# Reiniciar Redis
docker compose -f docker-compose.local.yml restart redis
```

---

## 📝 Notas Técnicas

### Cambios Respecto a Configuración Original

1. **Healthcheck MariaDB**: Se modificó de `healthcheck.sh` a comando `mariadb` nativo
2. **Estructura de directorios**: Se creó `local-storage/` para separar desarrollo de producción
3. **Puertos**: Puerto 8000 para local, 80/443 para producción
4. **Nginx**: Omitido en local, incluido en producción
5. **Backups**: Servicio omitido en local, activo en producción

### Diferencias Local vs Producción

| Aspecto | Local | Producción |
|---------|-------|------------|
| Almacenamiento | ./local-storage/ | /mnt/sdb y /mnt/sdc |
| Reverse Proxy | No (directo) | Sí (Nginx) |
| SSL/TLS | No | Sí (Let's Encrypt) |
| Puerto Web | 8000 | 80/443 |
| Backups | Manual | Automático (diario) |
| Debug | Habilitado | Deshabilitado |
| Logs | Docker | Nginx + Docker |

---

## ⚡ Rendimiento

### Configuraciones Optimizadas

**MariaDB**:
- InnoDB buffer pool: 128M (ajustar según RAM disponible)
- Max connections: 100
- Query cache: Habilitado

**Redis**:
- Max memory: 256M
- Eviction policy: allkeys-lru
- Persistence: RDB + AOF

**PHP-FPM** (en contenedor app):
- pm.max_children: 5
- pm.start_servers: 2
- pm.min_spare_servers: 1
- pm.max_spare_servers: 3

### Recomendaciones para Producción

- Aumentar buffer pool de MariaDB a 4-8GB
- Configurar Redis con 2GB de memoria (en disco sdb)
- Ajustar workers de PHP según CPU disponible
- Habilitar OPcache de PHP
- Configurar compresión Gzip en Nginx

---

## 📞 Soporte

Para problemas o consultas:

1. **Verificar logs**: `docker compose -f docker-compose.local.yml logs -f`
2. **Revisar documentación**: Ver archivos MD en el proyecto
3. **Documentación oficial**: https://snipe-it.readme.io/docs
4. **Foro comunidad**: https://gitter.im/snipe/snipe-it

---

## ✨ Conclusión

El despliegue local de Snipe-IT para KM Motos se completó exitosamente:

✅ **Sistema funcional** con 3 contenedores en estado healthy  
✅ **Base de datos** inicializada con migraciones ejecutadas  
✅ **Usuario administrador** creado y listo para uso  
✅ **Aplicación web** accesible en http://localhost:8000  
✅ **Documentación completa** generada con todos los detalles  
✅ **Configuración de producción** lista para despliegue con discos sdb/sdc  

El sistema está **listo para uso en desarrollo** y la configuración de producción está **preparada para despliegue en servidor Ubuntu** con los discos de 500TB.

---

**Documento generado el**: 18 de febrero de 2026  
**Versión Snipe-IT**: 7.0.13  
**Versión MariaDB**: 11.4.7  
**Versión Redis**: 7.4.3-alpine  
**Autor**: Despliegue automatizado KM Motos
