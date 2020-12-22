---
title: "Pipelines en Rust (I)"
date: 2020-12-13T22:16:43-05:00
draft: true
tags: ["rust","patrones"]
---

**Pipeline** es un patrón de diseño muy útil cuando tienes datos que
deben ser procesados en una secuencia de etapas, donde cada etapa toma
como entrada la salida de la etapa anterior. En cierta manera un
pipeline es similar a *componer funciones* pero el nivel de
complejidad es mucho más elevado debido a factores como *backpressure*,
*deadlocks* o cancelación.

**Go** es un lenguaje especialmente capacitado para programar
pipelines debido a sus características especiales para el manejo de
errores y concurrencia. Pero ¿cómo sería usar pipelines en **Rust**?
En este post vamos a:

1. Definir las estructuras necesarias para crear pipelines.
2. Hacer uso del sistema de tipos del lenguaje para nuestras ventajas.
3. Hablar un poco de concurrencia usando hilos.


## Paso 1: El `trait Step`

En el mejor espíritu de **Rust** hagamos un trait que represente la
capacidad de formar parte de un pipeline. Vamos a llamarle `Step`

```rust
pub trait Step {
	type Item;
	pub run(&self, it: Item) -> Self::Item
}
```

Hecho, continuamos.

O mejor aún, vamos a mirar `Step` un segundo, notemos que tiene un
tipo asociado `Item` y una función asociada `run`. Un aspecto que
resalta es que `run` no toma una referencia a `Item` sino un `Item` en
si. La razón de esto puede parecer arbitraria, pero en mi dado el
modelo de memoria de **Rust**
