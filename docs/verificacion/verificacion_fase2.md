# Verificación Final de Fases

# 1.Fase 2 - Docker y Servicios

## Contenedores
Se verificó que los 10 contenedores del proyecto estaban activos mediante
docker compose ps. Todos mostraron estado Up con sus puertos correctamente
expuestos.

## Servicio Web
La página de Transmilenio respondió correctamente a través del balanceador
SRV-LB en el puerto 80, confirmando que Nginx sirve contenido correctamente.

## Base de datos
MySQL respondió correctamente mostrando las tablas rutas y estaciones,
confirmando que el script de inicialización transmilenio.sql se ejecutó
correctamente al levantar el contenedor.

## Samba
Los recursos compartidos transmilenio y publico aparecieron disponibles.
El mensaje SMB1 disabled confirma uso del protocolo SMB2/3 más seguro.

## SSH — Problema y solución
Durante la verificación el contenedor SRV-SSH-NTP estaba en estado
restarting debido a que el comando inline del docker-compose intentaba
instalar paquetes en cada arranque, causando un loop de reinicios.
Se solucionó creando un Dockerfile dedicado en ssh/Dockerfile que
instala los paquetes durante la construcción de la imagen y no en el
arranque. Se modificó el docker-compose.yml para usar build: ./ssh
en lugar de image: ubuntu:22.04.

Al reconectar apareció el error REMOTE HOST IDENTIFICATION HAS CHANGED
porque el contenedor nuevo generó claves SSH diferentes. Se resolvió
con ssh-keygen -f ~/.ssh/known_hosts -R [localhost]:2222.

## Verificación dentro del contenedor
Una vez dentro del contenedor con el usuario tm_admin se verificó:
- Sistema operativo: Ubuntu 22.04.5 LTS Jammy Jellyfish
- Procesos activos: únicamente sshd y la sesión bash — contenedor minimalista
- Memoria: 2.7Gi total, 1.2Gi usado, sin swap configurado
- Red: interfaz eth0 con IP 10.0.40.10/24 — VLAN 40 Gestión TI correcta
- NTP: chronyc retornó 506 Cannot talk to daemon, limitación conocida
  de Docker por falta de acceso al reloj del kernel. En producción NTP
  correría directamente en el servidor físico.

## Redes y volúmenes
Las 4 redes Docker correspondientes a las VLANs del diseño están activas.
Los volúmenes de MySQL y Samba persisten correctamente entre reinicios.

# 2.Verificación Fase 3 — RAID y LVM

## RAID 1
El array md0 mostró estado clean con ambos discos sdb y sdc en estado
active sync, confirmado por el indicador [UU]. Sin discos fallidos ni
degradaciones. El RAID opera correctamente protegiendo los datos ante
el fallo de cualquiera de los dos discos.

## LVM
El volumen físico /dev/sdd de 5GB está activo dentro del grupo
vg_transmilenio. Los dos volúmenes lógicos operan correctamente:
- lv_datos de 3GB montado en /mnt/datos con 2.8GB disponibles
- lv_backups de 1GB montado en /mnt/backups con 906MB disponibles

## Montajes permanentes
Los tres puntos de montaje del proyecto — /mnt/raid1, /mnt/datos y
/mnt/backups — están activos y se montan automáticamente al arranque
gracias a las entradas configuradas en /etc/fstab.
