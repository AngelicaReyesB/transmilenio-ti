# Infraestructura TI — Transmilenio Bogotá
## Documento Técnico Final

**Institución:** Universidad del Quindío  
**Asignatura:** Administración de Infraestructura de TI  
**Integrantes:** Angelica Reyes, Andrés Zambrano, Steban Martínez  
**Fecha:** Mayo 2026  

---

## 1. Introducción

El presente documento describe el diseño, implementación y documentación 
de la infraestructura TI para Transmilenio Bogotá. El proyecto contempla 
una arquitectura segura, escalable y de alta disponibilidad que soporta 
los servicios críticos del sistema de transporte masivo más importante 
de Colombia.

---

## 2. Justificación de decisiones técnicas

### 2.1 Diseño de red
Se adoptó el esquema de direccionamiento privado RFC 1918 con el bloque 
10.0.0.0/8 por su amplia capacidad de hosts (más de 16 millones), 
permitiendo una segmentación clara por función mediante el tercer octeto: 
10.0.VLAN_ID.host.

Se definieron 5 VLANs funcionales:
- VLAN 10 — DMZ: servicios públicos (Web)
- VLAN 20 — Servidores: base de datos y archivos
- VLAN 30 — Operaciones: terminales de operadores
- VLAN 40 — Gestión TI: administración y SSH
- VLAN 50 — Seguridad: monitoreo y logs

### 2.2 Equipos Cisco seleccionados
- RTR-BORDE: Cisco ISR 4331 — router de borde con NAT y firewall
- SW-CORE: Cisco 3560-24PS — switch multilayer L3 con inter-VLAN routing
- SW-Acceso x5: Cisco 2960 — switches de acceso por VLAN

### 2.3 Docker y contenedores
Se eligió Docker por su capacidad de aislar servicios en contenedores 
independientes, garantizando que el fallo de un servicio no afecte a los 
demás. Docker Compose orquesta los 9 contenedores del proyecto.

### 2.4 RAID 1
Se eligió RAID 1 porque Transmilenio es un sistema crítico de transporte 
público. RAID 1 garantiza que si un disco falla, el servidor sigue 
operando sin interrupción. Se priorizó disponibilidad sobre capacidad.

### 2.5 LVM
LVM permite gestionar el almacenamiento de forma flexible. Si lv_datos 
se llena, puede expandirse sin apagar el servidor agregando discos al 
grupo de volúmenes vg_transmilenio.

---

## 3. Arquitectura del sistema

### 3.1 Diagrama de red
Ver archivo: Packet Tracer — transmilenio_red.pkt

### 3.2 Servicios implementados

| Contenedor | Servicio | IP | Puerto |
|---|---|---|---|
| SRV-LB | Nginx balanceador | 10.0.10.5 | 80 |
| SRV-WEB-01 | Nginx web primario | 10.0.10.10 | interno |
| SRV-WEB-02 | Nginx web respaldo | 10.0.10.11 | interno |
| SRV-DB-01 | MySQL primario | 10.0.20.10 | 3306 |
| SRV-DB-02 | MySQL réplica | 10.0.20.11 | 3306 |
| SRV-FILES-01 | Samba | 10.0.20.20 | 445 |
| SRV-SSH-NTP | SSH + NTP | 10.0.40.10 | 22, 123 |
| SRV-PROMETHEUS | Prometheus | 10.0.50.10 | 9090 |
| SRV-GRAFANA | Grafana | 10.0.50.11 | 3000 |
| SRV-NODE-EXPORTER | Node Exporter | 10.0.50.12 | 9100 |

### 3.3 Almacenamiento

| Componente | Dispositivo | Montaje | Uso |
|---|---|---|---|
| RAID 1 | /dev/md0 (sdb+sdc) | /mnt/raid1 | Datos redundantes |
| LV datos | /dev/vg_transmilenio/lv_datos | /mnt/datos | Datos aplicación |
| LV backups | /dev/vg_transmilenio/lv_backups | /mnt/backups | Copias de seguridad |

---

## 4. Seguridad implementada

### 4.1 Firewall UFW
- Política por defecto: denegar todo el tráfico entrante
- Puertos permitidos: 22, 80, 443, 445, 2222, 9090, 3000, 9100
- MySQL restringido solo a red interna 10.0.20.0/24

### 4.2 Usuarios y grupos

| Usuario | Grupo | Rol |
|---|---|---|
| tm_admin | ti_admins, sudo | Administrador TI |
| tm_operador | ti_operadores | Operador Transmilenio |
| tm_database | ti_database | Acceso base de datos |
| tm_backup | — | Copias de seguridad |

### 4.3 Permisos especiales
- SETGID en carpetas de trabajo — archivos heredan grupo automáticamente
- Sticky bit en /srv/transmilenio/compartido — solo el dueño puede borrar
- SETUID en /usr/local/bin/tm_status — script corre como root

---

## 5. Alta disponibilidad

### 5.1 Niveles de redundancia
1. Almacenamiento: RAID 1 con mdadm — espejo de discos en tiempo real
2. Web: Balanceo de carga Nginx — SRV-LB distribuye entre WEB-01 y WEB-02
3. Base de datos: SRV-DB-01 primario + SRV-DB-02 réplica
4. Servicios: Docker restart always — reinicio automático de contenedores

### 5.2 Pruebas de fallo realizadas
- Fallo de disco sdb: sistema continuó con sdc, recuperación automática ✓
- Fallo de SRV-WEB-01: SRV-WEB-02 tomó el tráfico sin interrupción ✓
- Fallo total: despliegue.sh recuperó los 9 servicios en menos de 2 min ✓

---

## 6. Automatización

### 6.1 Scripts Bash
- backup.sh — backup diario de MySQL y configuraciones
- monitoreo.sh — revisión de CPU, RAM, RAID, Docker y red
- despliegue.sh — levanta todos los servicios automáticamente

### 6.2 Cron configurado
- Backup: todos los días a las 2:00am
- Monitoreo: cada hora, log en /var/log/transmilenio_monitor.log

---

## 7. Monitoreo

- htop: monitor de procesos en tiempo real
- journalctl: logs del sistema operativo
- Prometheus: recolección de métricas cada 15 segundos
- Grafana: dashboard Node Exporter Full (ID 1860) con métricas visuales

---

## 8. Repositorio Git

URL: https://github.com/AngelicaReyesB/transmilenio-ti

Estructura:
- docker-compose.yml — orquestación de servicios
- nginx/ — configuraciones web y balanceador
- mysql/ — scripts de base de datos
- samba/ — carpetas compartidas
- ntp/ — configuración NTP
- prometheus/ — configuración de monitoreo
- scripts/ — backup, monitoreo y despliegue
- docs/ — evidencias de cada fase
