# 🚀 PASOS POST-DESPLIEGUE - INVENTARIO KM MOTOS

## ✅ Lista de Verificación Inicial

Una vez que hayas ejecutado `./install-production.sh` o seguido la guía manual de despliegue, estos son los pasos que debes completar:

---

## 1. 🔐 Crear Usuario Administrador

**PRIMER PASO OBLIGATORIO** - Sin este usuario no podrás acceder al sistema.

```bash
cd ~/INVENTARIO-KM-MOTOS
docker compose -f docker-compose.production.yml exec app php artisan snipeit:create-admin
```

El sistema te pedirá:
- **Nombre**: Tu nombre
- **Apellido**: Tu apellido  
- **Email**: correo@ejemplo.com
- **Username**: admin (o el que prefieras)
- **Password**: (password seguro, mínimo 8 caracteres)

⚠️ **IMPORTANTE**: Guarda estas credenciales en un lugar seguro.

---

## 2. 🌐 Acceder al Sistema

Abre tu navegador y accede a:

```
http://IP_DEL_SERVIDOR:8000
```

O si configuraste Nginx:
```
http://tu-dominio.com
```

Inicia sesión con las credenciales del administrador que acabas de crear.

---

## 3. ⚙️ Configuración Inicial de la Aplicación

### 3.1 Configuración General

1. Ir a: **Admin → Settings → General Settings**
2. Configurar:
   - **Site Name**: `KM Motos - Inventario`
   - **Default Language**: `Español - Spanish`
   - **Default Currency**: `COP` (Peso Colombiano) o tu moneda
   - **Timezone**: `America/Bogota` (o tu zona horaria)

### 3.2 Subir Logo de la Empresa

1. Ir a: **Admin → Settings → General Settings**
2. Buscar sección **Branding**
3. Subir logo de KM Motos (recomendado: PNG transparente, 300x80px)
4. Click en **Save**

### 3.3 Configurar Formato de Códigos

1. Ir a: **Admin → Settings → Auto-Increment**
2. Configurar formato de códigos de activos:
   - **Asset ID Prefix**: `KM-` (para que los activos sean KM-0001, KM-0002, etc.)
   - **Next Auto-Increment Number**: `1`
   - **Digit Length**: `4` (generará: 0001, 0002, etc.)
3. Click en **Save**

---

## 4. 📊 Configurar Categorías Básicas

### 4.1 Crear Categorías

1. Ir a: **Admin → Categories → Create New**
2. Crear estas categorías iniciales:
   - **Motos** (Category Type: Asset)
   - **Herramientas** (Category Type: Asset)
   - **Equipos de Taller** (Category Type: Asset)
   - **Computadoras** (Category Type: Asset)
   - **Repuestos** (Category Type: Consumable)

---

## 5. 📍 Configurar Ubicaciones

1. Ir a: **Admin → Locations → Create New**
2. Crear ubicaciones de tu negocio:
   - **Sede Principal**
   - **Taller**
   - **Bodega**
   - **Sala de Ventas**
   (Agregar más según necesites)

---

## 6. 👥 Configurar Departamentos

1. Ir a: **Admin → Departments → Create New**
2. Crear departamentos:
   - **Ventas**
   - **Taller**
   - **Administración**
   - **Bodega**

---

## 7. 🏢 Configurar Compañías (si aplica)

Si tu negocio tiene múltiples sucursales o empresas:

1. Ir a: **Admin → Companies → Create New**
2. Agregar tus compañías/sucursales

---

## 8. 📧 Configurar Correo Electrónico

### 8.1 Configuración en .env

Editar el archivo `.env`:

```bash
nano ~/INVENTARIO-KM-MOTOS/.env
```

Configurar sección de correo (ejemplo con Gmail):

```bash
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=tu-correo@gmail.com
MAIL_PASSWORD=tu-contraseña-de-aplicacion
MAIL_FROM_ADDR=noreply@kmmotos.com
MAIL_FROM_NAME='KM Motos Inventario'
MAIL_REPLYTO_ADDR=soporte@kmmotos.com
MAIL_REPLYTO_NAME='Soporte KM Motos'
MAIL_TLS_VERIFY_PEER=true
```

### 8.2 Reiniciar Aplicación

```bash
docker compose -f docker-compose.production.yml restart app
```

### 8.3 Probar Correo

1. Ir a: **Admin → Settings → Alerts**
2. Click en **Send Test Email**
3. Verificar que llegue el correo

---

## 9. 🔒 Configurar SSL/HTTPS (RECOMENDADO)

### Opción A: Con Let's Encrypt (Gratis)

```bash
# Instalar Certbot
sudo apt install -y certbot

# Obtener certificado (reemplaza tu-dominio.com)
sudo certbot certonly --standalone -d tu-dominio.com

# Copiar certificados
mkdir -p ~/INVENTARIO-KM-MOTOS/docker/ssl
sudo cp /etc/letsencrypt/live/tu-dominio.com/fullchain.pem ~/INVENTARIO-KM-MOTOS/docker/ssl/
sudo cp /etc/letsencrypt/live/tu-dominio.com/privkey.pem ~/INVENTARIO-KM-MOTOS/docker/ssl/
sudo chown $USER:$USER ~/INVENTARIO-KM-MOTOS/docker/ssl/*

# Editar .env para forzar HTTPS
nano ~/INVENTARIO-KM-MOTOS/.env
# Cambiar: APP_FORCE_TLS=true
# Cambiar: APP_URL=https://tu-dominio.com

# Reiniciar servicios
cd ~/INVENTARIO-KM-MOTOS
docker compose -f docker-compose.production.yml restart
```

### Opción B: Certificado Propio

Si ya tienes certificados:

```bash
# Copiar certificados
mkdir -p ~/INVENTARIO-KM-MOTOS/docker/ssl
cp /ruta/a/tu/certificado.crt ~/INVENTARIO-KM-MOTOS/docker/ssl/fullchain.pem
cp /ruta/a/tu/clave.key ~/INVENTARIO-KM-MOTOS/docker/ssl/privkey.pem

# Reiniciar
cd ~/INVENTARIO-KM-MOTOS
docker compose -f docker-compose.production.yml restart nginx
```

---

## 10. 👨‍💼 Crear Usuarios Adicionales

1. Ir a: **Admin → Users → Create New**
2. Completar formulario:
   - **First Name / Last Name**
   - **Username**
   - **Email**
   - **Password**
   - **Location**: Asignar ubicación
   - **Department**: Asignar departamento
   - **Permissions**: 
     - **Admin** - Acceso total
     - **User** - Solo puede ver/usar activos
     - **Superadmin** - Control absoluto

---

## 11. 🏍️ Crear Fabricantes de Motos

1. Ir a: **Admin → Manufacturers → Create New**
2. Agregar fabricantes comunes:
   - Yamaha
   - Honda
   - Suzuki
   - Kawasaki
   - Bajaj
   - AKT
   - Auteco
   - (Agregar los que manejes)

---

## 12. 🔧 Crear Modelos de Activos

1. Ir a: **Admin → Asset Models → Create New**
2. Crear modelos ejemplo:
   - **Nombre**: `Yamaha FZ 150`
     - Manufacturer: Yamaha
     - Category: Motos
     - Model Number: FZ150
   
   - **Nombre**: `Computadora Dell Optiplex 7040`
     - Manufacturer: Dell
     - Category: Computadoras
     - Model Number: OPTIPLEX-7040

---

## 13. ➕ Agregar Tu Primer Activo

1. Ir a: **Assets → Create New**
2. Completar formulario:
   - **Asset Tag**: Se generará automáticamente (KM-0001)
   - **Model**: Seleccionar modelo
   - **Status**: Available / Ready to Deploy
   - **Location**: Seleccionar ubicación
   - **Purchase Date**: Fecha de compra
   - **Purchase Cost**: Costo
   - **Supplier**: Proveedor (opcional)
   - **Notes**: Notas adicionales
3. **Subir foto** del activo
4. Click en **Save**

---

## 14. 📸 Verificar que las Imágenes se Guarden Correctamente

```bash
# Verificar que se crearon archivos en el disco SDB
ls -lah /mnt/sdb/snipeit-data/uploads/assets/

# Ver tamaño usado
du -sh /mnt/sdb/snipeit-data/
```

Deberías ver archivos de imágenes si subiste fotos.

---

## 15. 💾 Verificar Backups Automáticos

```bash
# Ver logs del servicio de backup
docker compose -f docker-compose.production.yml logs backup

# Ver archivos de backup creados
ls -lah /mnt/sdc/snipeit-backups/

# Verificar último backup
ls -lth /mnt/sdc/snipeit-backups/ | head -5
```

Los backups se crean automáticamente cada 24 horas a las 2:00 AM.

---

## 16. 📊 Configurar Panel de Control

1. Ir a: **Dashboard**
2. Personalizar widgets según necesites:
   - Total de activos por categoría
   - Activos desplegados vs disponibles
   - Últimas auditorías
   - Alertas de mantenimiento

---

## 17. 🔔 Configurar Alertas

1. Ir a: **Admin → Settings → Alerts**
2. Configurar:
   - **Email Alert if Asset Expires**: Días antes de expiración
   - **Send Email to Admins**: Activar
   - **Default Alert Email**: Correo para alertas

---

## 18. 🛡️ Configurar Permisos de Seguridad

1. Ir a: **Admin → Settings → Security**
2. Configurar:
   - **Enable 2FA**: Considerarlo para admins
   - **Require users to confirm their email**: Activar
   - **Password Security Requirements**: 
     - Minimum length: 10
     - Require uppercase
     - Require numbers

---

## 19. 📱 Configurar Códigos QR/Barcodes

1. Ir a: **Admin → Settings → Barcodes**
2. Configurar:
   - **Barcode Type**: QR Code (recomendado)
   - **Alt Barcode**: Code 128
3. Imprimir códigos para tus activos

---

## 20. 🔄 Crear Scripts de Mantenimiento

### Script de Monitoreo Diario

```bash
nano ~/check_snipeit_daily.sh
```

Agregar:

```bash
#!/bin/bash
# Script de monitoreo diario de Snipe-IT

LOG_FILE=~/snipeit_health_$(date +%Y%m%d).log

echo "=== Health Check Snipe-IT - $(date) ===" > $LOG_FILE

# Estado de contenedores
echo "Estado de contenedores:" >> $LOG_FILE
docker compose -f ~/INVENTARIO-KM-MOTOS/docker-compose.production.yml ps >> $LOG_FILE

# Uso de disco SDB
echo -e "\nUso de disco SDB:" >> $LOG_FILE
du -sh /mnt/sdb/snipeit-data >> $LOG_FILE

# Uso de disco SDC
echo -e "\nUso de disco SDC:" >> $LOG_FILE
du -sh /mnt/sdc/snipeit-db >> $LOG_FILE
du -sh /mnt/sdc/snipeit-backups >> $LOG_FILE

# Último backup
echo -e "\nÚltimo backup:" >> $LOG_FILE
ls -lth /mnt/sdc/snipeit-backups/ | head -3 >> $LOG_FILE

# Errores recientes
echo -e "\nErrores recientes en logs:" >> $LOG_FILE
docker compose -f ~/INVENTARIO-KM-MOTOS/docker-compose.production.yml logs --tail=50 | grep -i error >> $LOG_FILE

echo -e "\n=== Fin del reporte ===" >> $LOG_FILE

# Mostrar resumen en pantalla
cat $LOG_FILE
```

Dar permisos y programar:

```bash
chmod +x ~/check_snipeit_daily.sh

# Agregar a cron para que corra todos los días a las 8 AM
crontab -e
# Agregar línea:
0 8 * * * ~/check_snipeit_daily.sh
```

---

## 21. 📋 Importar Datos Existentes (si aplica)

Si ya tienes datos en Excel/CSV:

1. Ir a: **Admin → Import**
2. Descargar template CSV
3. Llenar con tus datos
4. Importar archivo
5. Revisar y confirmar importación

---

## 22. 🎨 Personalizar Tema (Opcional)

1. Ir a: **Admin → Settings → General Settings**
2. Sección **Appearance**:
   - Subir logo personalizado
   - Cambiar colores del tema
   - Personalizar footer

---

## 23. 📖 Capacitación de Usuarios

### Documentos a Crear:

1. **Manual de Usuario Básico**
   - Cómo hacer check-in/check-out de activos
   - Cómo reportar mantenimientos
   - Cómo ver historial

2. **Manual de Administrador**
   - Agregar nuevos activos
   - Gestionar usuarios
   - Generar reportes

---

## 24. 🔐 Backup Manual Inicial

Hacer un backup manual después de la configuración inicial:

```bash
cd ~/INVENTARIO-KM-MOTOS

# Backup de base de datos
docker compose -f docker-compose.production.yml exec db mysqldump -u root -p snipeit_kmmotos > backup_inicial_$(date +%Y%m%d).sql

# Backup de archivos de configuración
tar -czf config_backup_$(date +%Y%m%d).tar.gz .env docker-compose.production.yml

# Mover a lugar seguro
mkdir -p ~/backups_manuales
mv backup_inicial_*.sql ~/backups_manuales/
mv config_backup_*.tar.gz ~/backups_manuales/

echo "Backups guardados en ~/backups_manuales/"
```

---

## 25. 📊 Generar Primer Reporte

1. Ir a: **Reports → Activity Report**
2. Generar reporte de actividad
3. Exportar a PDF/Excel
4. Verificar que la funcionalidad de reportes funcione correctamente

---

## ✅ Checklist Final Post-Despliegue

- [ ] Usuario administrador creado
- [ ] Acceso web funcionando correctamente
- [ ] Logo de empresa subido
- [ ] Zona horaria y moneda configurados
- [ ] Categorías básicas creadas
- [ ] Ubicaciones creadas
- [ ] Departamentos configurados
- [ ] Correo electrónico configurado y probado
- [ ] SSL/HTTPS configurado (recomendado)
- [ ] Usuarios adicionales creados
- [ ] Fabricantes agregados
- [ ] Modelos de activos creados
- [ ] Primer activo agregado con foto
- [ ] Verificado que imágenes se guardan en /mnt/sdb
- [ ] Backups automáticos funcionando
- [ ] Backup manual inicial realizado
- [ ] Script de monitoreo configurado
- [ ] Alertas configuradas
- [ ] Permisos de seguridad revisados
- [ ] Códigos QR/Barcodes configurados

---

## 🎉 ¡Sistema Listo!

Tu sistema de inventario KM Motos está completamente configurado y listo para usarse.

### Próximos Pasos Recomendados:

1. **Empezar a agregar activos** regularmente
2. **Capacitar al equipo** en el uso del sistema
3. **Hacer auditorías periódicas** de inventario
4. **Revisar backups semanalmente**
5. **Actualizar el sistema** cuando haya nuevas versiones
6. **Monitorear uso de disco** mensualmente
7. **Generar reportes** mensuales para análisis

### Documentación Adicional:

- [GUIA_DESPLIEGUE.md](GUIA_DESPLIEGUE.md) - Guía completa de instalación
- [RUTAS_ALMACENAMIENTO.md](RUTAS_ALMACENAMIENTO.md) - Documentación de rutas
- [REFERENCIA_RUTAS.md](REFERENCIA_RUTAS.md) - Referencia rápida de rutas

### Soporte:

- Documentación oficial: https://snipe-it.readme.io/
- GitHub: https://github.com/grokability/snipe-it
- Discord: https://discord.gg/yZFtShAcKk

---

**¡Felicidades! El Inventario KM Motos está operativo.** 🏍️✨
