---
date: "2020-12-11T12:18:10-05:00"
draft: true
tags:
- rust
- patrones
title: Storage Combinators en Rust
comment: true

---

**Storage combinators** es el nombre de un patrón de diseño para
abstraer el acceso a fuentes de datos. La propuesta es sencilla,
abstraer los procesos de *localización*, *resolución*, y *operaciones*
de manera que

## Referencias.

Las referencias están compuestas por un camino, esquema, y los
elementos que componen la referencia.

``` rust
pub trait Reference<'a> {
	path:&'a str,
	scheme:&'a str,
	components:Vec<&'a str>
}
```

## Protocolo


```rust
pub trait Protocol<T>{

	fn get(&self, r: &Reference) -> Result<T>;
	fn post(&self, r: &Reference,data: T) -> Result<()>;
	fn put(&self,r: &Reference, data: T) -> Result<()>
	fn delete(&self, r: &Reference) -> Result<()>
}
```
