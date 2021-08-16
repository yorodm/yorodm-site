---
date: "2018-10-04T13:42:12-04:00"
description: Como implementar estructuras persistentes en Rust
draft: true
title: Estructuras persistentes en Rust
comment: true

---

# Estructuras persistentes en Rust

[Rust](https://www.rust-lang.org/) es uno de esos lenguajes que como
[Go](https://golang.org) vienen llenos de nuevas características que una vez que
aprendemos a utilizarlas nos preguntamos como habíamos vivido sin ellas.

Una de mis cosas favoritas del lenguaje es el [borrow checker]
(https://doc.rust-lang.org/1.8.0/book/references-and-borrowing.html) y las
facilidades que brinda una vez que "conoces" como funciona (aunque no voy a
negar que es un gusto adquirido). Si recordamos ante todo que Rust es no es 100%
[funcional](http://xion.io/post/programming/rust-into-haskell.html) pero que
lentamente nos impulsa a adoptar buenas prácticas de ese estilo, entonces podemos
sacar mejor partido


## ¿Qué tiene que ver esto con estructuras persistentes?

Bastante, el /borrow checker/ de Rust nos garantiza todo un conjunto de cosas en
tiempo de compilación. La que nos ocupa es:

 > El mismo valor no puede ser accesible desde dos nombres.

 O llevado a un ejemplo:

 ```rust
    let v = vec![1, 2, 3];

    let v2 = v;

    println!("v[0] is: {}", v[0]);
 ```

En el código anterior, la llamada a `println` no compila porque el valor de la variable
`v` se **movió** hacia `v2`, lo cual deja a `v` en un estado inusable.

Lo anterior es
