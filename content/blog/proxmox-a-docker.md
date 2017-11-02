+++
categories = ["devops"]
date = "2017-11-02"
description = "Comparativa entre Proxmox y Docker"
tags = ["docker","proxmox","linux","archlinux"]
title = "Proxmox a Docker"
draft = true
+++

# Proxmox a Docker

Recientemente conversaba con mis compañeros de trabajo acerca de la viabilidad
de mover la mayoría de los servicios que ahora tenemos en
[Proxmox](http://www.proxmox.com ) hacia [Docker](http://docker.com) exceptuando
alguna que otra máquina virtual ejecutando sabrá dios cuanta cantidad de
software legado de la que no podemos deshacernos. Después de pensar
unos 20 minutos acerca del tema (esto fue a las 7:15 am y no había tomado café)
y sopesar los pro y los contra se me ocurrió este post. Ahí va.

## El problema (o como cambiar de LXC a Docker).

Antes de empezar vamos a dejar algo claro: no hay manera de migrar las máquinas
virtuales a **docker**. Aunque a algunas personas esto les parece obvio (VM !=
container) he encontrado sysadmins que oyen *virtualización* y ya no escuchan
más nada. Si bien la versión de docker para [ese sistema operativo](http://www.microsoft.com) tiene posibilidades de virtualización real
gracias a que utiliza **Hyper-V** para ejecutar los contenedores, la idea es tan
cercana al sacrilégio que la vamos a descartar enseguida. Resumiendo, máquinas
virtuales no.

Con las VM's fuera del camino la mayoría analizemos ahora las posibilidades de ambos productos.

## Proxmox y LXC.

**Proxmox** basa sus contenedores en **LXC** (si tienes **OpenVZ** estás utilizando
una versión muy vieja y necesitas actualizarte). Para crear un nuevo contenedor
simplemente entras por la interfaz web, elijes una plantilla, llenas unos
cuantos espacios en blanco y ¡BAM!, listo.

Bueno, no *listo, listo*, ahora toca conectarse de forma remota (hay varios modos,
virt-viewer me viene a la mente) instalar y configurar servicios, etc. Dado que
muchos (entre los que me incluyo) consideran todo esto un verdadero incordio, la
mayoría de las plantillas vienen con **ssh** configurado para simplificar el
proceso (y utilizar **ansible**). Sea cual sea el método en alrededor de unos 5
minutos (con buena conexión o un repositorio local) es posible levantar el
*webmail* para que el resto de los mortales envíen presentaciones con gaticos,
unicornios, arcoiris y frases sacadas de novelas baratas de los 70.

**Proxmox** incluye además.

1. Un cluster que permite migrar los contenedores entre servidores.
2. Soporte para varias tecnologias de almacenamiento compartido.
3. Backups, orquestación y monitoreo *de los contenedores*.
4. Una interfaz web llena de comodidades a la hora de configurar ciertos
   parámetros como la **RAM**, el espacio en disco interfaces de red, etc.
5. Consolas **VNC** y **SPICE** integradas desde la web, por si no te gusta el
   **ssh**.
6. Super sistema de control de acceso (también en la web).
7. Configuración del firewall (adivinen donde).

Todo esto suena muy bien hasta que te das cuenta de que:

1. Cinco minutos (en el mejor de los casos) para poner un servicio en marcha
   puede ser demasiado tiempo.
2. Cada contenedor **LXC** es su propio universo aislado. Comunicarse con y desde
   el host debe ser configurado mediante servicios.
3. La orquestación y monitoreo *de los servicios* require un poquito más de
   configuración e instalación.


## Docker.

Una de las diferencias más importantes entre **LXC** y **Docker** es el acercamiento
que tienen al concepto de contenedor. En **LXC** (y por ende **Proxmox**) los
contenedores inician toda clase de servicios de apoyo como **systemd**, **ssh**,
**NFS** y **SAMBA**. **Docker** utiliza un enfoque un poco más ligero y eso en cierto
sentido altera su uso. Veamos sus ventajas:

1. En cada contenedor se ejecuta un servicio (casi siempre) esto ayuda mucho al
   monitoreo y orquestación.
2. La configuración del contenedor ocurre desde el momento en que se construye
   (o en el que se inicializa, o en ambos, hay muchas variables aquí)
3. Las imágenes incluyen ya todo lo necesario para arrancar el servicio.
4. Construir imágenes a partir de nuevas es extremadamente sencillo y no
   requiere de muchos conocimientos técnicos.
5. Las imágenes son versionables.
6. Desplegar un nuevo servicio < 2 minutos *en una PC de prestaciones medias o
   bajas* (de nuevo, con repo local o buena internet).
7. Puedes correr **docker** en algo que no sea **Debian**.

Ahora, tanta simplicidad no viene sin un costo:

1. Ya no hay *UI* que resuelva las cosas a click (existen herramientas para terceros).
2. Si quieres ejecutar en un mismo host varios servicios del mismo tipo (ej. dos
   sitios web) tienes que aplicar un poco de creatividad con las interfaces de
   red (**docker-composer** ayuda mucho).
3. Backups, almacenamiento compartido, parámetros de ejecución del contenedor;
   toca hacerlos manualmente (igual que arriba).
4. Es recomentable tener un registro privado. Eso lleva a montarse otro servidor
   o tener un contenedor dedicado, es decir, gastar recursos (depende de la
   cantidad de imágenes que mantengas).

## Resumiendo.
