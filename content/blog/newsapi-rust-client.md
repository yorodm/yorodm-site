---
date: "2020-09-30T20:58:07-04:00"
draft: true
tags:
- rust
- hyper
- async
- newsapi
title: 'Rust: Haciendo un cliente para NewsAPI (1)'
---

Después de bastante tiempo sin escribir regreso con uno sobre desarrollo utilizando **Rust**.

Para los que (como yo) llegan a **Rust** viniendo de **Python** o
**Go** una de las cosas más chocantes es la falta en la biblioteca
estándar de un cliente **HTTP**. Aunque es cierto que `urllib` o
`net/http` muchas veces se usan de conjunto con bibliotecas externas
es reconfortante saber que forman parte de las *baterías incluidas*
del lenguaje.

Otro aspecto que a veces choca es la carencia de clases en la
biblioteca estándar de funcionalidades para trabajar con **JSON**. En
el mundo actual **JSON** es practicamente *lingua franca* de
comunicación entre servicios no solo para la Web sino en
microservicios

Pero: aunque para los recién llegados `std` parezca un poco desolada,
existen `crates` que aportan todo lo necesario. En lo particular para consumir servicios Web me inclino por:

- `hyper` para hacer llamadas a servicios REST.
- `serde` como framework de serialización de datos
- `serde_json` para procesar datos en formato JSON.

En esta serie de artículos veremos como hacer un cliente REST para el
servicio [NewsAPI](https://newsapi.org) haciendo uso de los `crates`
mencionados

## Haciendo un cliente REST en Rust

Comencemos creando una nueva biblioteca y adicionando las dependencias necesarias

```toml
[dependencies]
hyper = "0.13.8"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = {version = "0.4", features = ["serde"]}

[dev-dependencies]
tokio = { version = "0.2", features = ["full"] }
```

Por el momento ignoremos el uso de `chrono` y la declaración de
`dev-dependencies`.


### Paso 1: Peticiones al endpoint Everything

> La documentacíon de los endpoints está en https://newsapi.org/docs


```rust
```
