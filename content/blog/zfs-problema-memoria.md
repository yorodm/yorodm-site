+++
categories = []
date = "2017-10-24T10:55:56-04:00"
description = ""
tags = ["zfs","linux","proxmox"]
title = "ZFS y el problema de la memoria"

+++

# ZFS y el problema de la memoria

`ZFS` lleva ya unos años en tierras de [Linux](http://www.open-zfs.org/) y cada
vez que tengo un chance lo recomiendo a alguno de mis amigos *sysadmins* junto
con un grupito de notas que he tomado acerca de como trabajar con el
*filesystem*, optimizar alguna que otra *feature* y algunos casos de estudio.

Después de notar que en la mayoría de los casos, los aconsejados regresaban al
castigo de `LVM` me dediqué a investigar las causas del rechazo y como
enmendarlas.

# Pero ¿cuál es el problema?

Descartado el factor "resistencia al cambio" (los linuxeros solo temen a cambiar
de distribución) la mayoría de los problemas relacionados con `ZFS` (entre las
personas a las que le pregunté) están relacionados con uso y/o configuracíon
incorrecta (también conocido como: "No leiste las notas"). Los 4 más comúnes
fueron:

1. Poner `/boot` o la `swap` en un volumen `ZFS`.
2. No entender la diferencia entre `clone` y `snapshot`.
3. El consumo de memoria.
4. Problemas con `RAID` (tanto el de hardware como `RAIDZ`).

Comparando mis problemas locales con los globales (gracias a [Google
Trends](http://trends.google.com ) ) veo que los puntos 3 y 4 tienen buen
ranking y me dije: "Esto va al blog".


# Como hacer que ZFS se porte bien.

Lo primero que le recomiendo a todo el mundo es que se lea un buen tutorial. Si
vienes de el mundo `ext4` + `LVM`, la filosofía de `ZFS` te puede parecer
extraña y deberías tener una idea de las semejanzas y diferencias en el modo de
operar con cada uno. En dependencia del nivel de inglés de cada cual
[aquí](http://www.open-zfs.org/wiki/Performance_tuning ) hay una buena
referencia sobre todos los parámetros de optimización e incluso casos de
estudio.

El "problema" del uso de memoria no es nada más que el método de caché utilizado
en `ZFS`. La mayoría de los *filesystems* utilizan alguna variante de `LRU`, que
en este caso fue sustituido por el *Adaptive Replacement Cache* o `ARC`. El
`ARC` mejora mucho el rendimiento, pero consume *cantidades masivas* de `RAM`. A
pesar de esto raras veces es **necesario** configurar algo de aquí, aunque la
memoria se muestra como ocupada (por ejemplo al utilizar `free`) es un caché y
si existiera la necesidad sería liberada por el kernel. En caso de que no sepas
como está configurado tu `ARC` puedes simplemente:

```
cat /sys/module/zfs/parameters/zfs_arc_max
```

Un valor de 0 indica que la mitad de la `RAM` disponible se utilizará para
caché. Para cambiar este valor puedes hacer lo siguiente:

```
# Configura la cantidad de memoria máxima disponible para ARC
echo <numero en bytes> >> /sys/module/zfs/parameters/zfs_arc_max
# fuerza al kernel a vaciar la información de caché
echo 3 > /proc/sys/vm/drop_caches
```

Por último y no por ello menos importante, `RAID`. `RAIDZ` es una implementación
de `RAID` basada en software. Si estás utilizando `ZFS` es recomendable que
utilices `RAIDZ` en vez de una solución por hardware. Si tu servidor require que
tengas `RAID` por hardware crea X unidades `RAID0` y añádelas a un `zpool`
configurado con `RAIDZ`. Recuerda: **nunca** pongas `RAIDZ` sobre discos que
tienen `RAID` mayor que 0. Repito: **NUNCA**.


# Para ir empezando con ZFS.

Estos tres links me sirven cada vez que tengo que refrescar algo del tema.

1. [ZFS en 12 pasos](http://jjmora.es/zfs_aprendiendo_zfs_en_12_pasos/ )
2. [Open-ZFS Wiki](http://www.open-zfs.org/wiki/Main_Page )
3. [Wiki de Gentoo sobre ZFS](https://wiki.gentoo.org/wiki/ZFS )
