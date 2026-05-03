# Estrategia de Alta Disponibilidad — Transmilenio TI

## 1. Componentes redundantes implementados

| Componente | Estrategia | Implementación |
|---|---|---|
| Servidor web | Balanceo de carga | Nginx upstream con SRV-WEB-01 y SRV-WEB-02 |
| Base de datos | Replicación | SRV-DB-01 (primario) + SRV-DB-02 (réplica) |
| Almacenamiento | RAID 1 | sdb + sdc en espejo con mdadm |
| Servicios | Contenedores | restart: always en docker-compose |

## 2. Escenarios de fallo y recuperación

### Escenario 1 — Fallo de servidor web
- Detección: Nginx detecta que SRV-WEB-01 no responde
- Acción: Redirige tráfico automáticamente a SRV-WEB-02
- Tiempo de recuperación: menos de 5 segundos
- Comando de verificación: curl http://localhost:80

### Escenario 2 — Fallo de disco
- Detección: mdadm detecta disco fallido en RAID 1
- Acción: El segundo disco continúa operando solo
- Tiempo de recuperación: inmediato, sin pérdida de datos
- Comando de verificación: cat /proc/mdstat

### Escenario 3 — Fallo de contenedor
- Detección: Docker detecta contenedor caído
- Acción: restart: always lo reinicia automáticamente
- Tiempo de recuperación: menos de 30 segundos
- Comando de verificación: docker compose ps

### Escenario 4 — Fallo total del servidor
- Detección: monitoreo.sh detecta servicios caídos
- Acción: ejecutar despliegue.sh para levantar todo
- Tiempo de recuperación: menos de 2 minutos
- Comando: bash scripts/despliegue.sh

## 3. Backups como estrategia de recuperación
- Backup diario automático a las 2am con cron
- Backups guardados en volumen LVM separado (/mnt/backups)
- Retención de 7 días de backups
- Incluye: dump de MySQL + archivos de configuración

## 4. Monitoreo continuo
- Script de monitoreo ejecutándose cada hora
- Prometheus recolectando métricas cada 15 segundos
- Grafana con alertas visuales en tiempo real
- journalctl registrando todos los eventos del sistema
