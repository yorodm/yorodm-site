---
title: "Pipelines en Rust (II)"
date: 2021-02-14T14:21:04-05:00
draft: true
tags: ["rust","async","pipelines","patrones"]
---

En el [artículo anterior]({{<relref "./rust-pipeline-pattern.md">}})
hablamos sobre la creación de pipelines _extremadamente sencillas_ en
Rust.

Si recuerdan, la implementación se ejecutaba de forma secuencial lo
que en el momento pudo parecer suficiente, pero si lo pensamos mejor
nos damos cuanta que limita mucho la aplicabilidad del modelo. Una
mejor idea sería poder usar nuestros pipelines de forma _concurrente_.


## Async Step

La primera tarea es convertir nuestra implementación de `Step` a algo
que sea usable de forma asíncrona.

```rust
use std::future::*;
use std::pin::Pin;
use std::error::Error;

type StepResult<T> = Result<T,Box<dyn Error>>;

type Output<T> = Pin<Box<dyn Future<Output=StepResult<T>> + 'static>>

pub trait AsyncStep {
	type Item;
	fn run(&self, it: Self::Item) -> Output<Self::Item>;
}

pub struct Multiplier {
    value: u8
}

impl AsyncStep for Multiplier {
    type Item = u8;
    fn run(&self, it: u8) -> Output<Self::Item> {
       let x = Ok(self.value * it);
       Box::pin(async move {
           x
       })
    }
}
```

Si has leido algo de Rust, lo primero que te llamará la atención en el
código anterios es la falta de `async` en la función `run`. No hay
problema, Rust todavía no permite usar el modificador `async` en un
`trait`. En vez de eso vamos a devolver un `Future`, incluso le
definimos un alias.

```rust
type Output<T> = Pin<Box<dyn Future<Output=StepResult<T>> + 'static>>
```

En resumen, nuestro valor de retorno es un _trait object_ que
representa un `Future` que al resolverse nos da un `StepResult`. El
`Pin` es necesario [por cuestiones que no voy a explicar
aquí](https://rust-lang.github.io/async-book/04_pinning/01_chapter.html).


Para retornar este tipo de valor usamos `Box::pin` y bloques `async`.

```rust
fn run(&self, it: u8) -> Output<Self::Item> {
	let x = Ok(self.value * it);
	Box::pin(async move {
		x
	})
}
```

## Async Pipeline

Nuestra implementación de `Step` para `Pipeline` utilizaba un simple
`fold`

```rust
fn run(&self, it: T) -> T {
    self.v.iter().fold(it, |acc, x| x.run(acc))
}
```

Aunque parezca que es posible reutilizar este mecanismo, la solución
sería demasiado problemática. Retornar el valor de una función `async`
en un contexto no `async` no es tarea sencilla en Rust y `fold` no
está diseñado para tratar con `Future`.

Si queremos algo parecido a `Iterator` pero que funcione con `asyc`
tenemos que hacernos de un `Stream`.

## Streams

Un `Stream` es un `Future` que retorna más de un valor antes de
completar. Para todos los efectos (o al menos los que nos interesa)
podemos considerarlo un `Iterator` asíncrono.

```rust
pub struct PipeStream<T>{
    v: Arc<Vec<Box<dyn AsyncStep<Item = T>>>>,
    current: Box<dyn AsyncStep<Item = T>>,
    chunk: Option<Pin<Box<dyn Future<Output=StepResult<T>> + Send>>>
}
```

## Async Pipeline (de nuevo)

## The End.
