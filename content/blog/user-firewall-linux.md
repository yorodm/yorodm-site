+++
title = "Firewall de usuarios para Linux"
date = 2020-09-07T12:39:46-04:00
tags = ["rust"]
categories = [""]
draft = true
+++

Hace unos meses entre varios amigos comentamos la idea de hacer un
firewall de usuario para Linux.

## ¿Qué es eso de "firewall de usuario"?

Si usas Linux como estacíon de trabajo, generalmente no te proecupan
cosas como "restringir acceso desde el ip 192.16.20.2" o "sólo
permitir conexiones al puerto 22 desde la interfaz de red X". En la
mayor parte de los casos un firewall para usuario se basa en
permitir/denegar que ciertas aplicaciones hagan uso de la red, o
"denegar que el navegador se conecte en este momento". Esto puede
parecer trivial a simple vista, pero la mayoría de las herramientas
carecen de este tipo de dinamismo y están centradas en hacer reglas de
tipo más permanente

## Filtrado de paquetes en Linux.

El filtrado de paquetes en GNU/Linux es parte del "subsistema"
[Netfilter](ponerme.org).
