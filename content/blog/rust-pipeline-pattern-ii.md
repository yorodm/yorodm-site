---
date: "2021-02-22T16:03:13-05:00"
draft: false
series:
- Pipelines en Rust
tags:
- rust
- async
- pipelines
- patrones
title: Pipelines en Rust (II)
comment: true

---

En el [artículo anterior]({{<relref "./rust-pipeline-pattern.md">}})
hablamos sobre la creación de pipelines _extremadamente sencillas_ en
Rust.

Si recuerdan, la implementación se ejecutaba de forma secuencial lo
que en el momento pudo parecer suficiente, pero si lo pensamos mejor
nos damos cuenta que limita mucho la aplicabilidad del modelo. Una
mejor idea sería poder usar nuestros pipelines de forma _concurrente_.


## Async Step

La primera tarea es convertir nuestra implementación de `Step` a algo
que sea usable de forma asíncrona.

```rust
// Todos estos serán necesarios más adelante
use std::collections::VecDeque;
use std::error::Error;
use std::fmt::Display;
use std::future::*;
use std::pin::Pin;
use std::sync::Arc;
use std::sync::Mutex;
use std::task::Poll;

type StepResult<T> = std::result::Result<T, Box<dyn Error>>;
type Output<T> = Pin<Box<dyn Future<Output = StepResult<T>>>>;

pub trait AsyncStep {
    type Item;
    fn run(&self, it: Self::Item) -> Output<Self::Item>;
}

pub struct Multiplier {
    value: u8,
}

impl AsyncStep for Multiplier {
    type Item = u8;
    fn run(&self, it: u8) -> Output<Self::Item> {
        Box::pin(futures::future::ready(Ok(self.value * it)))
    }
}
```

Como **Rust** todavía no permite usar `async` en `traits` vamos a
devolver un `Future`. El alias `Output` lo creamos por un problema de
ergonomía.

```rust
type Output<T> = Pin<Box<dyn Future<Output=StepResult<T>> + 'static>>
```

En resumen, nuestro valor de retorno es un _trait object_ que
representa un `Future` que al resolverse nos da un `StepResult`. El
`Pin` es necesario [por cuestiones que no voy a explicar
aquí](https://rust-lang.github.io/async-book/04_pinning/01_chapter.html).


Para retornar este tipo de valor podemos usar `Box::pin` y bloques
`async`.

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
fn run(&self, it: T) -> StepResult<T> {
    self.v.iter().fold(Ok(it), |acc, x| acc.and_then(|v| x.run(v)))
}
```

Aunque parezca que es posible reutilizar este mecanismo, la solución
sería demasiado problemática. Retornar el valor de una función `async`
en un contexto no `async` no es tarea sencilla en Rust y `fold` no
está diseñado para tratar con `Future`.

Esto nos deja con dos opciones.

1. Crear un `Stream` a partir del `VecDequeue` y aplicar
`StreamExt::fold`, manteniendo la simetría con la solución actual.
2. Implementar nuestro propio `Future` que procese y encadene los
   `AsyncStep`.

Exploremos la variante (1) que a simple vista parece más sencilla.

## Async Pipeline (con Streams).

Un `Stream` es para todos los efectos un `Iterator` que produce
valores de forma *asíncrona*. El módulo `futures:stream` incluye la
función `iter` que nos permite convertir un `Iterator` en un `Stream`.

En el trait `futures::stream::StreamExt` tenemos versiones `async` de
las API de `Iterator`

```rust
use futures::stream::{self, StreamExt};

impl<T> Pipeline<T> {

    async fn run_stream(& self, val: T) -> StepResult<T> {
        let v = &self.v;
        let s = stream::iter(v).fold(Ok(val), |acc, x| async move {
            match acc {
                Err(e) => Err(e),
                Ok(o) => x.run(o).await,
            }
        });
        s.await
    }

}
```

El bloque `async move` es necesario para evitar las protestas del
*borrow checker* y tener `x` como una referencia que viva más allá de
la función.

## The End.

Con todo a mano podemos ejecutar nuestro `Pipeline`. Para *runtime*
prefiero `tokio` pero la implementación es agnóstica por lo que si
eres partidario de `async-std` o `smol` puedes utilizarlos igual.

```rust
use tokio;

fn main() {
    let rt = tokio::runtime::Runtime::new().unwrap();
    let mut p = Pipeline::new();
    p.add(Multiplier { value: 2 });
    p.add(Multiplier { value: 5 });
    rt.block_on(async move {
        println!("{:?}", p.run_stream(10).await);
    })
}
```
