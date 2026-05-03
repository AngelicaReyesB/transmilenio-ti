# Bitácora del Proyecto — Transmilenio TI

## Fase 1 — Diseño de red
**Fecha:** Mayo 2026  
**Actividades:**
- Diseño de topología con 5 VLANs en Packet Tracer
- Configuración de RTR-BORDE, SW-CORE y 5 switches de acceso
- Tabla de direccionamiento IP completa

**Problemas encontrados:**
- Error SPANTREE PVID: cable conectado al puerto equivocado
- CDP Native VLAN mismatch: native vlan diferente en cada extremo
- Solución: native vlan 99 en ambos extremos de cada trunk

**Resultado:** Red funcional con inter-VLAN routing operativo ✓

---

## Fase 2 — Docker y servicios
**Fecha:** Mayo 2026  
**Actividades:**
- Instalación de Docker y configuración de VM Ubuntu Server 24.04
- Creación de docker-compose.yml con 5 servicios
- Configuración de Nginx, MySQL, Samba, SSH y NTP

**Problemas encontrados:**
- MySQL en loop de reinicios por volumen corrupto
- GitHub rechazó contraseña — necesario Personal Access Token
- Solución: borrar volúmenes corruptos y recrear + token GitHub

**Resultado:** 5 contenedores UP, página web visible, MySQL con tablas ✓

---

## Fase 3 — RAID y LVM
**Fecha:** Mayo 2026  
**Actividades:**
- Agregar 3 discos virtuales de 5GB en VirtualBox
- Crear RAID 1 con mdadm usando sdb y sdc
- Crear LVM con vg_transmilenio, lv_datos y lv_backups en sdd

**Problemas encontrados:**
- Aviso de systemctl daemon-reload al montar volúmenes
- Solución: ejecutar sudo systemctl daemon-reload

**Resultado:** RAID 1 clean [UU], LVM montado en /mnt/datos y /mnt/backups ✓

---

## Fase 4 — Seguridad
**Fecha:** Mayo 2026  
**Actividades:**
- Configuración de UFW con 8 reglas de firewall
- Creación de 4 usuarios y 3 grupos con roles
- Aplicación de SETUID, SETGID y sticky bit

**Problemas encontrados:**
- Contraseñas con caracteres especiales daban error en useradd
- Solución: usar contraseñas simples para usuarios del sistema

**Resultado:** Firewall activo, usuarios con permisos correctos ✓

---

## Fase 5 — Scripts Bash
**Fecha:** Mayo 2026  
**Actividades:**
- Creación de backup.sh, monitoreo.sh y despliegue.sh
- Configuración de cron para automatización

**Problemas encontrados:**
- Access denied en mysqldump — faltaba privilegio PROCESS
- Ruta ~ no se expandía con sudo — usar ruta absoluta
- tar devuelve código 1 con rutas absolutas — aceptar como exitoso

**Resultado:** 3 scripts funcionando, cron configurado ✓

---

## Fase 6 — Monitoreo
**Fecha:** Mayo 2026  
**Actividades:**
- Documentación de htop y journalctl
- Instalación de Prometheus, Grafana y Node Exporter
- Importación de dashboard Node Exporter Full ID 1860

**Problemas encontrados:**
- Carpeta docs/fase6 no existía al guardar evidencias
- Solución: mkdir -p antes de guardar

**Resultado:** Stack de monitoreo completo, dashboard con métricas ✓

---

## Fase 7 — Alta disponibilidad
**Fecha:** Mayo 2026  
**Actividades:**
- Simulación de fallo de disco RAID y recuperación
- Implementación de balanceo de carga con SRV-LB
- Simulación de fallo de servidor web

**Problemas encontrados:**
- 502 Bad Gateway al configurar proxy en un solo contenedor
- Permission denied en log de despliegue
- Solución: rediseñar con 3 contenedores + chmod 666 en log

**Resultado:** HA demostrada en 3 niveles: RAID, web y servicios ✓
