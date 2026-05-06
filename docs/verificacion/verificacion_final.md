# Verificación Final de Fases

# 1. Fase 2 - Docker y Servicios

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

# 2. Verificación Fase 3 — RAID y LVM

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

# 3. Verificación Fase 4 — Seguridad

## Firewall UFW
8 reglas activas con política por defecto deny incoming. MySQL restringido
exclusivamente a la red interna 10.0.20.0/24. Puertos permitidos: 22, 80,
443, 445, 2222, 3000, 9090, 9100 y 123/udp.

## Usuarios y grupos
4 usuarios creados correctamente — tm_admin, tm_operador, tm_database y
tm_backup — cada uno con shell /bin/bash. 3 grupos activos — ti_admins,
ti_operadores y ti_database — con sus usuarios correctamente asignados.

## Permisos especiales
Las 4 carpetas de /srv/transmilenio muestran la s en el grupo confirmando
SETGID activo. La carpeta compartido muestra la t confirmando sticky bit.
El script tm_status muestra -rwsr-xr-x confirmando SETUID activo.

## Control de acceso
Se verificó que tm_operador no puede acceder a la carpeta admin,
recibiendo Permission denied, confirmando que el aislamiento por
grupos funciona correctamente.

# 4. Verificación Fase 5 — Scripts y Automatización

## Corrección de permisos
Durante la verificación se detectó que los 3 scripts tenían permisos
-rw-rw-r-- sin bit de ejecución. Se corrigió con chmod +x en los tres
archivos, quedando con permisos -rwxrwxr-x.

## Script monitoreo.sh
Ejecutado correctamente mostrando:
- CPU: 4.3% de uso — servidor operando con carga moderada
- RAM: 2.7Gi total, 1.3Gi usado, 196Mi libre
- Disco: /dev/sda2 al 56%, lv_backups al 1%, lv_datos al 1%, RAID al 1%
- RAID: estado clean con [UU] ambos discos activos
- Contenedores: 10 contenedores Up — mensaje "Todos los contenedores activos"
- Red: IPs de VLANs Docker correctas, puertos 22, 80, 2222 y 445 activos
- Logs: últimas entradas del journal mostrando actividad del sistema
- Log guardado en /var/log/transmilenio_monitor.log

## Script backup.sh
El log en /mnt/backups/backup.log confirmó ejecución automática exitosa
el 4 de mayo a las 2:00 AM por el cron configurado. Se generaron:
- db_20260504_020001.sql — dump completo de MySQL
- configs_20260504_020001.tar.gz — configuraciones del sistema
El directorio acumula 80KB de backups históricos de múltiples ejecuciones
tanto manuales como automáticas. La política de retención de 7 días
funciona correctamente eliminando backups antiguos.

## Script despliegue.sh
Verificó Docker disponible, proyecto encontrado, almacenamiento montado
y levantó los 10 contenedores exitosamente. El log de despliegue
se corrigió con chmod 666 /var/log/transmilenio_deploy.log para
resolver el error Permission denied que aparecía al escribir el log.

## Cron
Dos jobs activos confirmados con crontab -l:
- Backup diario a las 2:00 AM
- Monitoreo cada hora guardando en /var/log/transmilenio_monitor.log

# 5. Verificación Fase 6 — Monitoreo

## Stack de monitoreo
Los 3 contenedores del stack están activos:
- SRV-PROMETHEUS en puerto 9090 — recolectando métricas cada 15 segundos
- SRV-GRAFANA en puerto 3000 — dashboard disponible desde el navegador
- SRV-NODE-EXPORTER en puerto 9100 — exportando métricas del sistema

## Firewall
Los puertos 9090, 3000 y 9100 tienen reglas ALLOW IN activas en UFW,
permitiendo acceso desde el navegador de Windows.

## Prometheus y Grafana
Ambos servicios respondieron correctamente a peticiones HTTP.
El dashboard Node Exporter Full (ID 1860) está importado y muestra
métricas en tiempo real de CPU, RAM, disco y red del servidor.

## Herramientas básicas
htop e journalctl están disponibles y operativos. Los logs del sistema
registran correctamente toda la actividad de los servicios.

# 6. Verificación Fase 7 — Alta Disponibilidad

## Balanceo de carga
SRV-LB es el único contenedor expuesto en puerto 80. SRV-WEB-01 y
SRV-WEB-02 operan únicamente en red interna, garantizando que el
balanceador es el único punto de entrada al servicio web.

## Simulación fallo servidor web
Se detuvo SRV-WEB-01 con docker stop y se verificó con curl que la
página siguió respondiendo a través de SRV-WEB-02 sin interrupción.
Al levantar SRV-WEB-01 ambos servidores volvieron a estar activos.

## Simulación fallo disco RAID
Se marcó sdb como fallido con mdadm --fail. El estado cambió a [_U]
con sdb(F) pero el sistema continuó operando con sdc. Al re-agregar
sdb el RAID se resincronizó automáticamente volviendo a [UU].

## Restart automático Docker
El parámetro restart: always en todos los servicios garantiza que
los contenedores se reinician automáticamente ante cualquier fallo
sin intervención manual.

## Estado final
RAID en estado clean [UU], 10 contenedores activos, balanceo de
carga funcionando y recuperación ante fallos demostrada en los
tres niveles: almacenamiento, web y servicios.
