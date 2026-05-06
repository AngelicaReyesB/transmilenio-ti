#!/bin/bash
# ================================================
# monitoreo.sh - Monitoreo Transmilenio TI
# ================================================

LOG="/var/log/transmilenio_monitor.log"
FECHA=$(date +%Y-%m-%d_%H:%M:%S)

echo "================================================"
echo "  MONITOREO TRANSMILENIO TI — $FECHA"
echo "================================================"

# ── CPU y Memoria ─────────────────────────────────
echo ""
echo "[ CPU y MEMORIA ]"
top -bn1 | grep "Cpu(s)" | awk '{print "CPU uso: " $2 "%"}'
free -h | awk '/Mem/{print "RAM total: " $2 " | Usado: " $3 " | Libre: " $4}'

# ── Disco ─────────────────────────────────────────
echo ""
echo "[ DISCO ]"
df -h | grep -E "Filesystem|/dev/|/mnt/"

# ── RAID ──────────────────────────────────────────
echo ""
echo "[ RAID ]"
cat /proc/mdstat | grep -E "md0|blocks|bitmap"
RAID_STATUS=$(sudo mdadm --detail /dev/md0 | grep "State :" | awk '{print $3}')
echo "Estado RAID: $RAID_STATUS"
if [ "$RAID_STATUS" != "clean" ]; then
  echo "⚠ ADVERTENCIA: RAID no está limpio!" | tee -a $LOG
fi

# ── Contenedores Docker ───────────────────────────
echo ""
echo "[ CONTENEDORES DOCKER ]"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null

# Verificar contenedores caídos
CAIDOS=$(docker ps -a --filter "status=exited" --format "{{.Names}}" 2>/dev/null)
if [ ! -z "$CAIDOS" ]; then
  echo "⚠ Contenedores caídos: $CAIDOS" | tee -a $LOG
else
  echo "✓ Todos los contenedores activos"
fi

# ── Red ───────────────────────────────────────────
echo ""
echo "[ RED ]"
echo "IP del servidor:"
ip a | grep "inet " | grep -v "127.0.0.1"
echo "Puertos abiertos:"
sudo ss -tlnp | grep -E "80|443|22|3306|445|2222"

# ── Logs recientes ────────────────────────────────
echo ""
echo "[ LOGS RECIENTES DEL SISTEMA ]"
sudo journalctl -n 5 --no-pager 2>/dev/null

# ── Guardar en log ────────────────────────────────
echo "[$FECHA] Monitoreo ejecutado OK" >> $LOG
echo "================================================"
echo "Log guardado en: $LOG"
