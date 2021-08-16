---
date: "2020-10-07T08:28:24-04:00"
draft: true
tags:
- rust
- cnproc
title: Iteradores en Rust
---

[cnproc](https://github.com/yorodm/cnproc-rs) es un *crate* para
acceder al conector de eventos de procesos del kernel de **Linux** y
recibir notificaciones acerca del estado de los procesos del sistema.

Veamos un ejemplo de como usarlo:

```rust
use cnproc::PidMonitor;

fn main() {
    let mut monitor = PidMonitor::new().unwrap();

    loop {
        match monitor.recv() {
            None => {}
            Some(x) => println!("{:?}", x),
        }
    }
}
```

Eso es todo, un ciclo, un `match` para determinar si llegan eventos
nuevos y eso es todo. Hasta la próxima.

### ¿Por qué iteradores?

El único problema con el código anterior es que no es idiomático. En
**Rust** y otros lenguajes funcionales, la forma adecuada de leer una
cadena de elementos es utilizando iteraradores.


```rust
// Ejemplo de uso para un posible iterador sobre `monitor`
for x in monitor.iter() {
	match x {
		None => {}
		Some(x) => println!("{:?}", x),
	}
}
```

La conveniencia de los iteradores no está solo en la sintáxis, el uso
de *adaptadores* aumenta la legibilidad y coherencia del código.

```rust
// iterador para obtener solo los eventos relacionados con la creacíon
// de nuevos procesos.
use std::mem::discriminant;

let new_process_iter = monitor.iter().filter(|x| discriminant(x) == discriminant(PidEvents::Fork(-1)))
```

`new_proces_iter` es ahora un iterador que podemos consumir para
obtener solo los eventos de tipo **fork** que nos envíe el kernel

### Como crear un iterador (o un iterable)

Podemos usar iteradores de dos formas en **Rust**, una es implementar
[IntoIterator](https://doc.rust-lang.org/std/iter/trait.IntoIterator.html),
un trait que indica que nuestro tipo (en este caso `PidMonitor`) se
puede convertir en un **iterable**, la otra es usar el trait
[Iterator](https://doc.rust-lang.org/std/iter/trait.Iterator.html) que
indica que nuestro tipo **es** un iterador.


```rust
struct PidMonitorIterator {
	monitor: PidMonitor
}

impl Iterator for PidMonitorIterator {
 type Item = PidEvent

	fn next(&mut self) -> Option<Self::Item> {

	}
}
```


```rust
impl IntoIterator for PidMonitor {
  type Itep = PidEvent;
  type IntoIter = PidMonitorIterator

  fn into_iter(self) -> Self::IntoIter{
	todo!()
  }

}
```
