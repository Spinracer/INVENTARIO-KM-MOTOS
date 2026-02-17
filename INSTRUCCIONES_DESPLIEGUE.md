# 🚀 INSTRUCCIONES RÁPIDAS DE DESPLIEGUE EN SERVIDOR

## 📋 Pre-requisitos Completados
✅ Servidor Ubuntu listo  
✅ Discos SDB y SDC particionados  
✅ Permisos configurados  

---

## 🎯 PASOS PARA DESPLEGAR

### 1. Conectarse al Servidor vía SSH

```bash
ssh usuario@IP_DEL_SERVIDOR
```

### 2. Clonar el Repositorio

```bash
cd ~
git clone https://github.com/Spinracer/INVENTARIO-KM-MOTOS.git
cd INVENTARIO-KM-MOTOS
```

### 3. Ejecutar Script de Instalación Automática

```bash
chmod +x install-production.sh
./install-production.sh
```

El script te preguntará:
- ✅ Ruta del disco SDB (por defecto: `/mnt/sdb`)
- ✅ Ruta del disco SDC (por defecto: `/mnt/sdc`)
- ✅ URL de la aplicación (ejemplo: `http://192.168.1.100`)
- ✅ Credenciales de base de datos

**El script hace automáticamente:**
- 🐳 Instala Docker y Docker Compose
- 🔥 Configura el firewall
- 📁 Crea directorios en discos SDB y SDC
- ⚙️ Configura variables de entorno
- 🚀 Descarga imágenes Docker
- ▶️ Inicia todos los servicios
- 🗄️ Ejecuta migraciones de base de datos

---

### 4. Crear Usuario Administrador

Una vez termine el script, crear tu usuario admin:

```bash
docker compose -f docker-compose.production.yml exec app php artisan snipeit:create-admin
```

Te pedirá:
- Nombre
- Apellido
- Email
- Username
- Password

---

### 5. Acceder al Sistema

Abre tu navegador:

```
http://IP_DEL_SERVIDOR:8000
```

Inicia sesión con las credenciales del paso 4.

---

## 📂 UBICACIÓN DE LOS DISCOS

### Disco SDB (/mnt/sdb) - 500TB
```
/mnt/sdb/
├── snipeit-data/        ← IMÁGENES Y UPLOADS (lo más importante)
│   ├── uploads/         ← Fotos de activos, avatares, logos
│   └── private_uploads/ ← Documentos privados
├── snipeit-redis/       ← Cache Redis
└── nginx-logs/          ← Logs del servidor web
```

### Disco SDC (/mnt/sdc) - 500TB
```
/mnt/sdc/
├── snipeit-db/          ← BASE DE DATOS MariaDB
└── snipeit-backups/     ← BACKUPS AUTOMÁTICOS DIARIOS
```

---

## 🔧 COMANDOS ÚTILES POST-INSTALACIÓN

### Ver estado de servicios
```bash
cd ~/INVENTARIO-KM-MOTOS
docker compose -f docker-compose.production.yml ps
```

### Ver logs en tiempo real
```bash
docker compose -f docker-compose.production.yml logs -f
```

### Reiniciar servicios
```bash
docker compose -f docker-compose.production.yml restart
```

### Detener servicios
```bash
docker compose -f docker-compose.production.yml down
```

### Iniciar servicios
```bash
docker compose -f docker-compose.production.yml up -d
```

### Ver uso de discos
```bash
df -h | grep sdb
df -h | grep sdc
```

### Ver espacio usado por datos
```bash
du -sh /mnt/sdb/snipeit-data/
du -sh /mnt/sdc/snipeit-db/
```

---

## 📚 SIGUIENTE PASO IMPORTANTE

**Después de acceder al sistema, sigue la guía:**

```bash
# En el servidor
cat ~/INVENTARIO-KM-MOTOS/POST_DESPLIEGUE.md
```

O visitar el archivo [POST_DESPLIEGUE.md](POST_DESPLIEGUE.md) que contiene:
- ⚙️ Configuración inicial de la aplicación
- 👥 Creación de usuarios adicionales
- 📊 Configuración de categorías y ubicaciones
- 📧 Configuración de correo electrónico
- 🔒 Configuración de SSL/HTTPS
- 🏍️ Agregar tu primer activo
- Y mucho más...

---

## 🆘 SI ALGO SALE MAL

### Ver logs de errores
```bash
docker compose -f docker-compose.production.yml logs app | grep -i error
docker compose -f docker-compose.production.yml logs db | grep -i error
```

### Verificar que los discos estén montados
```bash
df -h | grep -E "sdb|sdc"
```

### Verificar permisos
```bash
ls -lah /mnt/sdb/
ls -lah /mnt/sdc/
```

### Reiniciar todo
```bash
cd ~/INVENTARIO-KM-MOTOS
docker compose -f docker-compose.production.yml down
docker compose -f docker-compose.production.yml up -d
```

---

## 📖 DOCUMENTACIÓN COMPLETA

| Archivo | Descripción |
|---------|-------------|
| **POST_DESPLIEGUE.md** | 📋 Pasos después de instalación |
| **GUIA_DESPLIEGUE.md** | 📚 Guía completa paso a paso |
| **RUTAS_ALMACENAMIENTO.md** | 📂 Documentación de rutas |
| **REFERENCIA_RUTAS.md** | ⚡ Referencia rápida |
| **README_DESPLIEGUE.md** | 📖 Resumen del proyecto |

---

## ✅ VERIFICACIÓN RÁPIDA

Después de la instalación, verifica:

```bash
# 1. Contenedores corriendo
docker compose -f docker-compose.production.yml ps
# Deben estar: app, db, redis, nginx, backup (todos healthy/running)

# 2. Discos montados
df -h | grep -E "sdb|sdc"
# Deben aparecer /mnt/sdb y /mnt/sdc

# 3. Directorios creados
ls /mnt/sdb/
# Debe mostrar: snipeit-data, snipeit-redis, nginx-logs

ls /mnt/sdc/
# Debe mostrar: snipeit-db, snipeit-backups

# 4. Acceso web
curl -I http://localhost:8000
# Debe responder con HTTP/1.1 200 OK
```

---

## 🎯 RESUMEN DEL FLUJO

```
1. SSH al servidor
   ↓
2. git clone del repositorio
   ↓
3. ./install-production.sh
   ↓
4. Crear usuario admin
   ↓
5. Acceder vía web
   ↓
6. Seguir POST_DESPLIEGUE.md
   ↓
7. ¡Sistema listo! 🎉
```

---

## 🔗 ENLACES ÚTILES

- **Repositorio**: https://github.com/Spinracer/INVENTARIO-KM-MOTOS
- **Documentación Snipe-IT**: https://snipe-it.readme.io/
- **Soporte Snipe-IT**: https://github.com/grokability/snipe-it/issues

---

## 🏍️ ¡LISTO PARA COMENZAR!

Tu sistema de inventario KM Motos está a solo **3 comandos** de distancia:

```bash
git clone https://github.com/Spinracer/INVENTARIO-KM-MOTOS.git
cd INVENTARIO-KM-MOTOS
./install-production.sh
```

**¡Suerte con el despliegue!** 🚀
