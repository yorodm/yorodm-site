---
categories:
- ""
date: "2019-11-04T13:01:46-05:00"
description: Utilizando la API de AsyncIO
draft: false
tags:
- python
- asyncio
title: Cola de tareas en Python (I)
comment: true

---

Después de unos meses trabajando en **Go** se llegan a extrañar las
abstracciones del lenguaje para concurrencia. Hoy por ejemplo
necesitaba hacer una cola de tareas en **Python** utilizando
**AsyncIO**.  En **Go** esto sigue una estructura sencilla:

```go
// Este es la gorutina que procesa los trabajos
func worker(jobChan <-chan Job) {
    for job := range jobChan {
        process(job)
    }
}
// Creamos un canal a donde enviar los datos
jobChan := make(chan Job, 10)
// Arrancamos la gorutina
go worker(jobChan)
// Enviamos datos para un trabajo, esto puede ser desde cualquier
// gorutina
jobChan <- job
//Indicamos que ya no vamos a procesar más datos
close(jobChan)
```

Veamos si podemos lograr un equivalente en Python:


```python
# Primer intento
import asyncio
async def worker(queue):
    while True:
		process(await queue.get())
		# Indicamos que se procesó el trabajo
		queue.task_done()

# Creamos la cola de mensajes
queue = asyncio.Queue(10)
# arrancamos el worker
worker_task = asyncio.create_task(worker(queue))
# Enviamos mensajes a la cola
await queue.put(x)
```

Hasta acá todo parece bien, pero: ¿Cómo indicamos que no se van a
procesar más datos?

En **Go** la operación `close` sobre un canal hace que el ciclo
termine **después de procesar cualquier elemento pendiente**. En
**Python** a primera vista podemos cancelar la tarea creada en
`worker_task` pero eso nos deja con la posibilidad de que varias
tareas se queden en la cola. Por otro lado, la corutina `join()` de
`asyncio.Queue` nos permite esperar a que ya no existan elementos en
la cola, aunque no garantiza que `worker` se detenga.

La solución es utilizar una mezcla de los dos:

```python
await queue.join() # Esperar a que se procesen los pendientes
worker_task.cancel() # Cancelar la tarea
```
