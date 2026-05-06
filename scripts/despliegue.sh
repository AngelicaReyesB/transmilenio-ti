#!/bin/bash
# ================================================
# despliegue.sh - Despliegue Transmilenio TI
# ================================================

PROYECTO="/home/angelica/transmilenio-ti"
LOG="/var/log/transmilenio_deploy.log"
FECHA=$(date +%Y-%m-%d_%H:%M:%S)

echo "================================================"
echo "  DESPLIEGUE TRANSMILENIO TI — $FECHA"
echo "================================================"

# ── Verificar Docker ──────────────────────────────
echo "[1/5] Verificando Docker..."
if ! command -v docker &> /dev/null; then
  echo "✗ Docker no está instalado" | tee -a $LOG
  exit 1
fi
echo "✓ Docker disponible"

# ── Verificar carpeta del proyecto ────────────────
echo "[2/5] Verificando proyecto..."
if [ ! -d "$PROYECTO" ]; then
  echo "✗ Carpeta del proyecto no existe: $PROYECTO" | tee -a $LOG
  exit 1
fi
echo "✓ Proyecto encontrado en $PROYECTO"

# ── Bajar servicios si están corriendo ────────────
echo "[3/5] Bajando servicios anteriores..."
cd $PROYECTO
docker compose down 2>/dev/null
echo "✓ Servicios anteriores detenidos"

# ── Verificar volúmenes montados ──────────────────
echo "[4/5] Verificando almacenamiento..."
for MOUNT in /mnt/raid1 /mnt/datos /mnt/backups; do
  if mountpoint -q $MOUNT; then
    echo "✓ $MOUNT montado correctamente"
  else
    echo "⚠ $MOUNT no está montado" | tee -a $LOG
  fi
done

# ── Levantar servicios ────────────────────────────
echo "[5/5] Levantando servicios..."
cd $PROYECTO
docker compose up -d

if [ $? -eq 0 ]; then
  echo ""
  echo "✓ Todos los servicios levantados exitosamente"
  echo "[$FECHA] Despliegue exitoso" >> $LOG
else
  echo "✗ Error al levantar servicios" | tee -a $LOG
  exit 1
fi

# ── Estado final ──────────────────────────────────
echo ""
echo "[ ESTADO FINAL ]"
docker compose ps
echo "================================================"
echo "[$FECHA] Despliegue completado" >> $LOG
