---
categories:
- ""
date: "2019-11-05T13:05:06-05:00"
description: Productores, consumidores, límites y AsyncIO
draft: true
tags:
- python
- asyncio
title: Cola de tareas en Python (II)
comment: true

---

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
def process(data, queue):
	# trabajar con data
	do_something_cpu_expensive(data)
	# Indicar que terminamos
	queue.task_done()

async def dispatcher(queue):
	loop = asyncio.get_running_loop()
	while True:
		loop.run_in_executor(None, process,data, queue)

# Para tareas que pueden usar asyncio
async def process(queue)
	data = await queue.get()
	await do_something_async(data)
	queue.task_done()

async def dispatcher(queue):
	while True:
		asyncio.create_task(process(queue))
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
