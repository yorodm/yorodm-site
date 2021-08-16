---
date: "2021-03-14T20:38:14+02:00"
description: Implementando patrones de diseño OOP en Rust
draft: false
tags:
- rust
- patrones
- oop
title: Mediator en Rust
comment: true

---

>  **UPDATE 2021-03-15T22:46:50+02:00**. Un lector (pues si, tengo
> lectores) me comentó sobre un error en `Mediator::send`. Cosas que
> pasan cuando transcribes y experimentas desde el playground.

## Un Rustacean en tierras de Dotnet.

Un amigo me hace una pregunta mientras conversábamos sobre las
ventajas de [MediatR](https://github.com/jbogard/MediatR). ¿Qué te
haces en Rust si quieres un *mediator*? Y de ahí salió la excusa para
este artículo.


## MediatR para Rustaceans.

**MediatR** es (en sus propias palabras) una implementación sencilla
del patrón *mediator* para .NET. Entre sus características más
utilizadas está la posibilidad de comunicación entre componentes (in
process) de forma sencilla.

```c#
/// Mensaje a enviar
public class Ping : IRequest<string> {
}

/// Handler para el mensaje
public class PingHandler : IRequestHandler<Ping, string>
{
    public Task<string> Handle(Ping request, CancellationToken cancellationToken)
    {
        return Task.FromResult("Pong");
    }
}

/// Componente que se comunica con PingHandler
var response = await mediator.Send(new Ping());
Debug.WriteLine(response); // "Pong"
```

El enlace entre la solicitud de tipo `Ping` y el `PingHandler` ocurre
automáticamente gracias a *reflection* y otros procesos malignos de
.NET que a nosotros como Rustaceans no nos interesan[^1].

## Implementando en Rust.

Veamos primero qué queremos lograr.

1. Definir tipos como *Requests* o *Handlers*.
2. Registrar estos tipos en un *Mediator*.
3. Enviar mensajes entre componentes usando el *Mediator*.

Traduciendo el ejemplo anterior quedaría algo como esto:

```rust
/// Esto es un marker trait
pub trait Request: 'static {}
pub struct Ping;
/// Marcamos Ping como Request
impl Request for Ping {}

pub trait Handler<I, O>
where
    I: Request,
    O: Sized
{
    fn handle(&self, r: I) -> O;
}

pub struct PingHandler {}

impl Handler<Ping, String> for PingHandler {
    fn handle(&self, _: Ping) -> String {
        return "Pong".to_owned()
    }
}
```

Para simplificar la implementación evitaremos trabajar con tipos de
referencias.

### Creando un registro de tipos.

El siguiente paso es crear un registro que mantenga la relación entre
los `Request` y los `RequestHandler`. Will Crichton tiene un artículo
bastante interesante acerca de [arquitecturas extensibles en
Rust](https://willcrichton.net/notes/types-over-strings/) en el que
nos muestra como usar `std::any::TypeId` y `std::any::Any`

```rust
use std::collections::HashMap;
use std::any::{TypeId, Any};

impl TypeMap {

  pub fn new() -> TypeMap {
      TypeMap(HashMap::<TypeId,Box<dyn Any>>::new())
  }

  pub fn set<R: 'static, H: Any + 'static>(&mut self, t: H){
    self.0.insert(TypeId::of::<R>(), Box::new(t));
  }

  pub fn get_mut<R:'static, H: 'static+Any>(&mut self) -> Option<&mut H> {
    self.0.get_mut(&TypeId::of::<R>()).and_then(|t| {
      t.downcast_mut::<H>()
    })
  }
}
```

`TypeId` nos permite crear un identificador único para cada tipo en
nuestro código mientras que `Any` es un trait que nos permite emular
tipado dinámico en **Rust**. Mediante una combinacíon de los 2 podemos
utilizar un `HashMap` que relacione un tipo (`Request`) con un `trait
object` (`RequestHandler`)

## Implementando el Mediator

`Mediator` es una simple estructra que contiene un `TypeMap` y dos
funciones.

1. Adicionar un `Handler` para un `Request`.
2. Enviar un mensaje y esperar que el `Handler` correspondiente lo
   procese.

```rust
pub struct Mediator(TypeMap);

type Wrapper<R,T> = Box<dyn RequestHandler<R,T>>;

impl Mediator {

  pub fn new () -> Mediator {
      Mediator(TypeMap::new())
  }

  pub fn add_handler<R, H, T>(&mut self, f: H)
  where
    R: Request,
    H: RequestHandler<R,T> + 'static,
    T: 'static
  {
    self.0.set::<R,Wrapper<R,T>>(Box::new(f));
  }

  pub fn send<R: Request, T: 'static>(&mut self, r: R) -> Option<T> {
    self.0.get_mut::<R,Wrapper<R,T>>().map(|h| h.handle(r))
  }
}
```

De nuevo, los `'static` están ahí para evitar tener que lidear con
complicaciones de *lifetimes*.

## The end.

A diferencia de **MediaTr** tenemos que registrar los pares
*Request/Handler* manualmente, aunque podemos hacer uso de la
inferencia de tipos de **Rust** (para escribir menos).

```rust
fn main() {
    let mut m = Mediator::new();
    m.add_handler::<Ping,_,_>(PingHandler{});
    let x: Option<String> = m.send::<Ping,_>(Ping{});
    println!("{:?}",x)
}
```

Y finalmente tenemos una versión *extremadamente simple* del patrón
mediator en Rust. Si estás interesado en aprender un poco más
recomiendo:

1. Modificar `Mediator::send` para que retorne un `Result` con una
   implementación de `Error` propia (dificultad simple).
2. Modificar el código para que `Handler::handle` pueda retornar referencias (dificultad intermedia).
3. Permitir que los tipos que implementen `Request` puedan contener referencias (dificultad alta).

[^1]: Dejo constancia de que IRL mi sustento se obtiene vía muchas
    líneas de código C#.
