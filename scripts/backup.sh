#!/bin/bash
# ================================================
# backup.sh - Script de backup Transmilenio TI
# ================================================

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/mnt/backups/transmilenio"
LOG="/mnt/backups/backup.log"
DB_CONTAINER="SRV-DB-01"
DB_USER="tm_user"
DB_PASS="Tm_Pass2024!"
DB_NAME="transmilenio_db"

# Crear directorio de backup
mkdir -p $BACKUP_DIR

echo "================================================" >> $LOG
echo "Inicio backup: $FECHA" >> $LOG
echo "================================================" >> $LOG

# ── Backup base de datos ──────────────────────────
echo "[$(date)] Iniciando backup de MySQL..." >> $LOG
docker exec $DB_CONTAINER mysqldump \
  -u $DB_USER -p$DB_PASS $DB_NAME \
  > $BACKUP_DIR/db_$FECHA.sql

TAR_EXIT=$?
if [ $TAR_EXIT -eq 0 ] || [ $TAR_EXIT -eq 1 ]; then
  echo "[$(date)] ✓ Backup configs exitoso: configs_$FECHA.tar.gz" >> $LOG
else
  echo "[$(date)] ✗ Error en backup configs" >> $LOG
fi

# ── Backup archivos de configuración ─────────────
echo "[$(date)] Iniciando backup de configuraciones..." >> $LOG
tar -czf $BACKUP_DIR/configs_$FECHA.tar.gz \
  /home/angelica/transmilenio-ti/nginx \
  /home/angelica/transmilenio-ti/ntp \
  /home/angelica/transmilenio-ti/mysql \
  /etc/fstab \
  /etc/ufw 2>/dev/null

if [ $? -eq 0 ]; then
  echo "[$(date)] ✓ Backup configs exitoso: configs_$FECHA.tar.gz" >> $LOG
else
  echo "[$(date)] ✗ Error en backup configs" >> $LOG
fi

# ── Eliminar backups mayores a 7 días ────────────
echo "[$(date)] Limpiando backups antiguos..." >> $LOG
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
echo "[$(date)] ✓ Limpieza completada" >> $LOG

# ── Resumen ───────────────────────────────────────
echo "[$(date)] Backup finalizado" >> $LOG
echo "Archivos en $BACKUP_DIR:" >> $LOG
ls -lh $BACKUP_DIR >> $LOG
echo "" >> $LOG
