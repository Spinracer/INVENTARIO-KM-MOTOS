# 🏍️ INVENTARIO KM MOTOS - Sistema de Gestión de Activos

Sistema de gestión de inventario basado en **Snipe-IT** dockerizado y optimizado para despliegue en servidores Ubuntu con almacenamiento de alta capacidad.

## 📋 Características

- ✅ **Sistema completo de inventario** para activos de IT y más
- 🐳 **Completamente dockerizado** - Fácil despliegue y mantenimiento
- 💾 **Optimizado para 2 discos de 500TB** - Almacenamiento masivo de imágenes y datos
- 🔒 **Seguro** - HTTPS, backups automáticos, y políticas de seguridad
- 🚀 **Alta disponibilidad** - Redis cache, Nginx reverse proxy
- 📊 **Backups automáticos** - Respaldos diarios de base de datos
- 🌍 **Multi-idioma** - Soporte para español y otros idiomas

## 🚀 Instalación Rápida

### Opción 1: Script Automático (Recomendado)

```bash
# Clonar el repositorio
git clone https://github.com/Spinracer/INVENTARIO-KM-MOTOS.git
cd INVENTARIO-KM-MOTOS

# Ejecutar script de instalación
./install-production.sh
```

El script te guiará paso a paso por la instalación completa.

### Opción 2: Instalación Manual

Sigue la [Guía Completa de Despliegue](GUIA_DESPLIEGUE.md) para instrucciones detalladas paso a paso.

## 📁 Estructura del Proyecto

```
INVENTARIO-KM-MOTOS/
├── docker-compose.production.yml  # Configuración Docker para producción
├── .env.production                 # Template de variables de entorno
├── GUIA_DESPLIEGUE.md             # Guía completa de instalación
├── RUTAS_ALMACENAMIENTO.md        # Documentación de rutas y almacenamiento
├── REFERENCIA_RUTAS.md            # Referencia rápida de rutas
├── POST_DESPLIEGUE.md             # Pasos después de la instalación
├── install-production.sh          # Script de instalación automática
├── docker/
│   ├── nginx.conf                 # Configuración de Nginx
│   └── ssl/                       # Certificados SSL (crear manualmente)
└── README_DESPLIEGUE.md           # Este archivo
```

## 📖 Documentación

| Documento | Descripción |
|-----------|-------------|
| [GUIA_DESPLIEGUE.md](GUIA_DESPLIEGUE.md) | Guía completa paso a paso para desplegar el sistema |
| [RUTAS_ALMACENAMIENTO.md](RUTAS_ALMACENAMIENTO.md) | Documentación detallada de rutas de archivos e imágenes |
| [REFERENCIA_RUTAS.md](REFERENCIA_RUTAS.md) | Referencia rápida con líneas exactas de código |
| [POST_DESPLIEGUE.md](POST_DESPLIEGUE.md) | Pasos a seguir después de la instalación inicial |

## 🔧 Requisitos del Sistema

### Hardware Mínimo
- **CPU**: 4 cores (recomendado 8)
- **RAM**: 8 GB (recomendado 16 GB)
- **Almacenamiento**: 
  - Disco SDB (/dev/sdb): 500 TB (datos de aplicación, imágenes, archivos)
  - Disco SDC (/dev/sdc): 500 TB (base de datos, backups)

### Software
- **OS**: Ubuntu Server 20.04 LTS o superior (recomendado 22.04 o 24.04)
- **Docker**: 24.0+
- **Docker Compose**: V2
- **Conexión a Internet**: Para descarga de imágenes Docker

## 🎯 Acceso Rápido

Una vez instalado, accede al sistema:

```
http://tu-servidor:8000
# o con Nginx configurado:
https://tu-dominio.com
```

**Usuario por defecto**: Crear durante la instalación con:
```bash
docker compose -f docker-compose.production.yml exec app php artisan snipeit:create-admin
```

## 🔐 Configuración Inicial

Después de la instalación:

1. ✅ Crear usuario administrador
2. ✅ Configurar nombre de la compañía
3. ✅ Subir logo de KM Motos
4. ✅ Configurar zona horaria (America/Bogota)
5. ✅ Configurar moneda y idioma (Español)
6. ✅ Configurar correo electrónico
7. ✅ Habilitar SSL/HTTPS

## 📊 Gestión de Servicios

### Ver estado de servicios
```bash
docker compose -f docker-compose.production.yml ps
```

### Ver logs
```bash
# Todos los servicios
docker compose -f docker-compose.production.yml logs -f

# Servicio específico
docker compose -f docker-compose.production.yml logs -f app
```

### Reiniciar servicios
```bash
# Todos
docker compose -f docker-compose.production.yml restart

# Uno específico
docker compose -f docker-compose.production.yml restart app
```

### Detener servicios
```bash
docker compose -f docker-compose.production.yml down
```

### Iniciar servicios
```bash
docker compose -f docker-compose.production.yml up -d
```

## 💾 Ubicaciones de Almacenamiento

| Tipo de Datos | Ubicación en Servidor | Tamaño Estimado |
|---------------|----------------------|-----------------|
| Imágenes de activos | `/mnt/sdb/snipeit-data/uploads` | Alto |
| Documentos privados | `/mnt/sdb/snipeit-data/private_uploads` | Medio |
| Base de datos | `/mnt/sdc/snipeit-db` | Alto |
| Backups | `/mnt/sdc/snipeit-backups` | Muy alto |
| Cache (Redis) | `/mnt/sdb/snipeit-redis` | Bajo |
| Logs | `/mnt/sdb/nginx-logs` | Medio |

Ver [RUTAS_ALMACENAMIENTO.md](RUTAS_ALMACENAMIENTO.md) para detalles completos sobre cómo cambiar estas rutas.

## 🔄 Backup y Restauración

### Backups Automáticos
Los backups se ejecutan automáticamente cada 24 horas y se guardan en `/mnt/sdc/snipeit-backups/`

### Backup Manual
```bash
# Backup de base de datos
docker compose -f docker-compose.production.yml exec db mysqldump -u root -p snipeit_kmmotos > backup_$(date +%Y%m%d).sql

# Backup de archivos (tardará con 500TB)
tar -czf backup_files_$(date +%Y%m%d).tar.gz /mnt/sdb/snipeit-data/
```

### Restauración
```bash
# Restaurar base de datos
docker compose -f docker-compose.production.yml exec -T db mysql -u root -p snipeit_kmmotos < backup_20240217.sql
```

## 🛠️ Mantenimiento

### Actualizar a nueva versión
```bash
# 1. Hacer backup
docker compose -f docker-compose.production.yml exec db mysqldump -u root -p snipeit_kmmotos > backup_before_update.sql

# 2. Detener servicios
docker compose -f docker-compose.production.yml down

# 3. Actualizar versión en .env
nano .env
# Cambiar: APP_VERSION=v7.0.14

# 4. Descargar nueva imagen
docker compose -f docker-compose.production.yml pull

# 5. Iniciar servicios
docker compose -f docker-compose.production.yml up -d

# 6. Ejecutar migraciones
docker compose -f docker-compose.production.yml exec app php artisan migrate --force
```

### Limpiar espacio Docker
```bash
# Ver uso de espacio
docker system df

# Limpiar contenedores detenidos
docker container prune -f

# Limpiar imágenes no usadas
docker image prune -a -f
```

### Monitoreo de uso de disco
```bash
# Ver uso de discos
df -h | grep mnt

# Ver uso detallado
du -sh /mnt/sdb/*
du -sh /mnt/sdc/*
```

## 🐛 Solución de Problemas

### Los contenedores no inician
```bash
# Ver logs detallados
docker compose -f docker-compose.production.yml logs

# Verificar discos montados
df -h | grep mnt
```

### Error de conexión a base de datos
```bash
# Verificar contenedor de BD
docker compose -f docker-compose.production.yml ps db
docker compose -f docker-compose.production.yml logs db
```

### No se pueden subir archivos
```bash
# Verificar permisos
docker compose -f docker-compose.production.yml exec app ls -la /var/lib/snipeit/

# Verificar espacio
df -h /mnt/sdb
```

Ver más soluciones en [GUIA_DESPLIEGUE.md](GUIA_DESPLIEGUE.md#troubleshooting)

## 🔒 Seguridad

- ✅ Firewall UFW configurado
- ✅ SSL/HTTPS recomendado (Let's Encrypt)
- ✅ Passwords seguros para DB
- ✅ Backups automáticos diarios
- ✅ Headers de seguridad en Nginx
- ✅ Rate limiting configurado
- ✅ Logs de auditoría habilitados

## 📞 Soporte y Recursos

### Documentación Oficial Snipe-IT
- 📚 [Documentación](https://snipe-it.readme.io/)
- 🐛 [Issues en GitHub](https://github.com/grokability/snipe-it/issues)
- 💬 [Discord](https://discord.gg/yZFtShAcKk)

### Este Proyecto
- 📁 [Repositorio](https://github.com/Spinracer/INVENTARIO-KM-MOTOS)
- 📖 [Guía de Despliegue](GUIA_DESPLIEGUE.md)
- 📂 [Documentación de Rutas](RUTAS_ALMACENAMIENTO.md)

## ⚖️ Licencia

Este proyecto utiliza Snipe-IT, que está licenciado bajo AGPL-3.0-or-later.

## 🎯 Checklist de Instalación

- [ ] Ubuntu Server instalado y actualizado
- [ ] Docker y Docker Compose instalados
- [ ] Discos de 500TB formateados y montados
- [ ] Firewall configurado
- [ ] Repositorio clonado
- [ ] Variables de entorno configuradas (.env)
- [ ] APP_KEY generada
- [ ] Servicios Docker iniciados
- [ ] Migraciones ejecutadas
- [ ] Usuario administrador creado
- [ ] Acceso web funcionando
- [ ] SSL/HTTPS configurado (recomendado)
- [ ] Backups verificados

---

## 🚀 Inicio Rápido - Comandos Esenciales

```bash
# Clonar e instalar
git clone https://github.com/Spinracer/INVENTARIO-KM-MOTOS.git
cd INVENTARIO-KM-MOTOS
./install-production.sh

# Crear admin
docker compose -f docker-compose.production.yml exec app php artisan snipeit:create-admin

# Ver estado
docker compose -f docker-compose.production.yml ps

# Ver logs
docker compose -f docker-compose.production.yml logs -f
```

---

**¡Listo para gestionar el inventario de KM Motos!** 🏍️
