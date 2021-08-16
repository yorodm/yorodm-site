---
date: "2020-12-24T13:27:39-05:00"
draft: false
series:
- Pipelines en Rust
tags:
- rust
- patrones
title: Pipelines en Rust (I)
comment: true

---

**Pipeline** es un patrón de diseño muy útil cuando tienes datos que
deben ser procesados en una secuencia de etapas donde cada etapa toma
como entrada la salida de la anterior. En cierta manera un
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
    pub run(&self, it: Self::Item) -> Self::Item
}
```

Hecho, hasta la próxima. O... mejor aún, miremos más de cerca la
definición de `Step`.

Es un `trait` bastante sencillo. Tiene un tipo asociado `Item` y una
función `run` que acepta y retorna `Item`. La forma en que la función
está especificada no permite que `Item` sea una referencia. Y
finalmente `it` no es mutable, por lo que el parámetro de entrada es
*consumido* por la función y el valor de retorno es generado por ella.


`Step` es muy simple de implementar, veamos un ejemplo:

```rust
pub struct Multiplier {
    value: u8,
}

impl Step for Multiplier {
    type Item = u8;
    fn run(&self, it: u8) -> u8 {
        return self.value * it;
    }
}
```

Podemos usar `Multiplier` para crear pasos que... bueno, multipliquen
su valor de entrada por un número dado.


```rust
let by2 = Multiplier{value:2};
println!("Multiplicado por 2 {0}", by2.run(5)) // 10
```

## Paso 2: Pipeline

Ahora solo tenemos que encadenar los pasos para formar un pipeline.
Ya que tenemos un número variable de pasos y todos implementan el
mismo `trait`, podemos guardarlos en un vector de *trait objects*

```rust
pub struct Pipeline<T> {
    v: Vec<Box<dyn Step<Item = T>>>,
}
```

La implementación de `Pipeline` es extremadamente corta.

```rust
impl<T> Pipeline<T> {
    fn new() -> Pipeline<T> {
        Pipeline { v: Vec::new() }
    }

    fn add(&mut self, x: impl Step<Item = T> + 'static) {
        self.v.push(Box::new(x));
    }
}
```

Un detalle en `add`: para adicionar un `Step`, debemos asegurarnos que
*viva* lo suficiente[^1], por lo que indicamos con `'static`. Por
cuestiones de estilo (y pensando en el futuro) podemos hacer que `Pipeline`
se comporte como cualquier otro `Step`.

```rust
impl<T> Step for Pipeline<T> {
    type Item = T;
    fn run(&self, it: T) -> T {
        todo!()
    }
}
```

Listo, tenemos la capacidad de hacer *subpipelines* y sólo nos ha
costado unas líneas. La operación dentro de `run` es tan simple como
hacer un `fold`.

```rust
fn run(&self, it: T) -> T {
    self.v.iter().fold(it, |acc, x| x.run(acc))
}
```

Hagamos un pequeña prueba[^2]:

```rust
#[test]
fn test_pipeline() {
    let mut p = Pipeline::<u8>::new();
    p.add(Multiplier { value: 2 });
    p.add(Multiplier { value: 5 });
    assert_eq!(p.run(10),100);
}
```

## Paso 3: Pipelines en el mundo real.

Nuestras pipelines funcionan bastante bien en el mundo de las
multiplicaciones de números pequeños, pero en el resto de los mundos
existe algo llamado "errores" y con la definición actual (por muy
elegante que sea) no tenemos modo de detectar si uno de los pasos
falla. Es hora de sacar `Result`

```rust
use std::error::Error;

type StepResult<T> = Result<T,Box<dyn Error>>;

trait Step {
    type Item;
    fn run(&self, it: Self::Item) -> StepResult<Self::Item>;
}

impl Step for Multiplier {
    type Item = u8;
    fn run(&self, it: u8) -> StepResult<u8> {
       Ok(self.value * it)
    }
}

```

Tener `Box<dyn Error>` nos da la garantía de poder manejar errores de
cualquier tipo. La implementación de `Pipeline` debe tener esto en
cuenta y *propagar* el estado de error hasta el resultado final.

```rust
impl<T> Step for Pipeline<T> {
    type Item = T;
    fn run(&self, it: T) -> StepResult<T> {
        self.v.iter().fold(Ok(it), |acc, x| acc.and_then(|v| x.run(v)))
    }
}
```

Hora de ajustar nuestra prueba.

```rust
#[test]
fn test_pipeline_ok() {
    let mut p = Pipeline::<u8>::new();
    p.add(Multiplier { value: 2 });
    p.add(Multiplier { value: 5 });
    assert_eq!(p.run(10),Ok(100));
}
```

Y crear una nueva para cuando algún `Step` falla.

```rust
struct ErrStep;

impl Step for ErrStep {
    type Item = u8;

    fn run(&self, it:u8) -> StepResult<u8> {
       Err("This will fail")?
    }
}

fn test_pipeline_ok() {
    let mut p = Pipeline::<u8>::new();
    p.add(Multiplier { value: 2 });
    p.add(ErrStep{});
    assert!(p.run(10).is_err());
}
```

## Pensando en paralelismo y concurrencia.

Recuento:

1. Tenemos la posibilidad de hacer un `Pipeline` compuesto de
   distintas implementaciones de `Step`.
2. Tenemos la forma de propagar errores en el `Pipeline`

El próximo paso natural sería intentar usar nuestro diseño actual para
ejecutar tareas *en paralelo*. Por desgracia, aún no hemos llegado a
ese punto.

Una de las ventajas de **Rust** es la garantía de que el compilador va
a detectar problemas comunes de seguridad de hilos (ejemplo, acceder
desde dos hilo distintos a la misma zona de memoria), para esto el la
biblioteca estándard incluye marcadores como `Send` y `Sync`, o tipos
especiales como `Arc`.

Adicionalmente, en el espíritu de [compartir
comunicando](https://blog.golang.org/codelab-share), los datos entre
implementaciones de `Step` deberían pasar usando canales o colas
concurrentes, esto ayudaría también con otros aspectos que mencionamos
al inicio del artículo (como *backpressure*) pero que no tratamos por
no ser necesarios para una implementación secuencial.

## The end.

Con todos los puntos del plan cumplidos, me retiro hasta la próxima
aventura. Mientras tanto si estás interesado en el tema de *pipelines*
en **Rust** recomiendo mirar
[pipelines](https://crates.io/crates/pipelines) o
[rayon](https://crates.io/crates/rayon), ambas con implementaciones
muy interesantes.


[^1]: Aunque implementar `Step` para una referencia o un tipo con
    restricciones de tiempo de vida no es trivial, tampoco es
    imposible.

[^2]: Las autoridades advierten que hacer pruebas unitarias
    **después** de escribir funcionalidades es malo para la salud.
