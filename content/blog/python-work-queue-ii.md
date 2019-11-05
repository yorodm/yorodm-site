+++
title = "Cola de tareas en Python (II)"
date = 2019-11-05T13:05:06-05:00
tags = ["python", "asyncio"]
categories = [""]
draft = true
description = "Productores, consumidores, límites y AsyncIO"
+++

En el [post anterior]({{< relref "python-work-queue.md" >}}) hablé
sobre como hacer una cola de tareas sencilla (léase extremandamente
simple) utilizando **AsyncIO**. La cola de tareas cuenta con un solo
consumidor (puedeb haber varios productores) y las tareas no se
ejecutan concurrentemente.

## Mejorando nuestra cola de tareas.

Aunque como ejemplo no está del todo mal, en la vida real casi nunca
quieres ejecutar código síncrono dentro de una función asíncrona, por
lo que de una forma más generica nuestro antiguo `worker` quedaría
mucho mejor de la siguiente forma

```python3
# Para tareas que bloquean o usan mucho CPU
async def dispatcher(queue):
	loop = asyncio.get_running_loop()
	while True:
		data = await queue.get()
		loop.run_in_executor(None, process, data)

# Para tareas que pueden usar asyncio
async def dispatcher(queue):
	while True:
		data = await queue.get()
		asyncio.create_task(process(data))
```

Ahora tenemos varias tareas ejecutándose de modo concurrente.

## Trabajando con recursos limitados.

Tareas ilimitadas suena maravilloso, pero en la vida real hay cosas
como ancho de banda, velocidad de discos y disponibilidad de RAM.
Tomen por ejemplo un scraper, hacer conexiones ilimitadas a un sitio
puede ser considerado un ataque de **DoS** y conseguir que (en el
mejor de los casos) nos bloqueen el acceso. Lo recomendado para estos
casos es utilizar `asyncio.Semaphore`:

```python3

```

Lo mismo es aplicable si utilizas productores concurrentes.
