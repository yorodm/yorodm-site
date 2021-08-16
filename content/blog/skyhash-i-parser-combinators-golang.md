---
title: "Skyhash (I) Introduccíon a Parser Combinators en Golang"
date: 2021-08-08T14:19:59+03:00
draft: true
tags: ["golang", "skyhash", "cs"]
series: ["Skytable para Golang"]
---

Hace unos días en mi *feed* de Reddit me apareció un anuncio sobre
[Skytable](https://github.com/skytable/skytable) y descubrí que (por
desgracia) no tienen un cliente para Golang. Como hace tiempo que no
escribo nada en Go (ni publico en el blog) decidí que era buen momento
para empezar una nueva serie.


## Skytable y Skyhash.

**Skytable** es una base de datos NoSQL escrita en **Rust** que, a
pesar de no haber alcanzado la versión **1.0** [los
benchmarks](https://github.com/ohsayan/sky-benches) indican que será
un serio competidor para muchas de las soluciones existentes.

Aunque actualmente existe un [cliente oficial en
Rust](https://github.com/skytable/client-rust), no hay muchas
alternativas si quieres utilizar otros lenguajes. Pero, los
desarrolladores del proyecto han previsto esta situación y proveen una
especie de guía para los que quieran implementar sus propios clientes,
comenzando por el [protocolo de
comunicación Skyhash](https://docs.skytable.io/protocol/skyhash/)

Skyhash es un protocolo de texto basado en TCP que permite a los
clientes intercambiar información con el servidor; para esto, asigna
significado a distintas secuencias de caracteres que deben ser
generadas e interpretadas por el cliente. Aquí es donde entran los
*parser combinators*

## Parser Combinators en 1 minuto.

La teoría detrás de los parser combinators puede ser algo densa, por
lo que siempre es mejor usar ejemplos para explicar.

Un parser es una función que recibe como parámetro una cadena de
caracteres (dado el caso de que el protocolo es de texto)

```go
/// ParserFunc es una función que toma un arreglo de caracteres (runes)
/// y returna un tipo Result con el resultado de la operación.
type ParserFunc func(input []rune) Result
```

El resultado de una `ParserFunc` debe contener.

1. El valor/dato encontrado.
2. El estado de error (o nil en caso de no error).
3. El resto de la entrada

```go
type Result struct {
    Data      interface{}
    Err       error
    Remaining []rune
}
```

El uso de `interface {}` es necesario dado que **Go** no tiene
genericidad *todavía*, como veremos más adelante esto trae sus propias
complicaciones pero no nos queda otro remedio.

Como llevo mucho tiempo programando en Rust también voy a adicionar
estas dos funciones para retornar los dos casos de `Result`.

```go
func Ok(data interface{}, remaining []rune) Result {
    return Result{
        Data:      data,
        Remaining: remaining,
    }
}

func Err(err error, input []rune) Result {
    return Result{
        Err:       err,
        Remaining: input,
    }
}
```

Con todas estas definiciones a mano, veamos como luce nuestro primer
*parser*.

```go
/// Char: Retorna un parser que verifica si el próximo paracter en la entrada es
/// el esperado y lo retorna. En caso contrario retorna un estado de error.
func Char(c rune) ParserFunc {
    return func(input []rune) Result {
        if len(input) == 0 || input[0] != c {
            err := errors.New(fmt.Sprintf("Expected %v got %v", c, input[0]))
            return Err(err, input)
        }
        return Ok(string(c), input[1:])
    }
}
```

Esta función sencilla nos da una pauta sobre cómo vamos a desarrollar
el resto de nuestros *parsers*. Cada uno será una función que toma
algún argumento (o no) y retorna un `ParserFunc` que hace el verdadero
trabajo de detectar y convertir los datos en la entrada en algo que
necesitamos. En caso de resultado positivo, el valor `Remaining` del
resultado incluye lo que resta de la entrada.

Verifiquemos que funciona utilizando la siguiente prueba unitaria

```go
func sameResult(a Result, b Result) bool {
    return a.Data == b.Data && reflect.DeepEqual(a.Remaining, b.Remaining)
}
func TestChar(t *testing.T) {
    chartest := []struct {
        in  []rune
        arg rune
        out Result
    }{
        { []rune{'a'}, 'a', Result{Data: "a", Err: nil, Remaining: make([]rune, 0)} },
        { []rune{'a', 'b'}, 'a', Result{Data: "a", Err: nil, Remaining: []rune{'b'}} },
    }
    for _, tt := range chartest {
        t.Run(string(tt.in), func(t *testing.T) {
            s := Char(tt.arg)(tt.in)
            if s.Err != nil || !sameResult(s, tt.out) {
                t.Errorf("%v no es %v", s, tt.out)
            }

        })
    }
}
```

Hagamos ahora una función obtener todos los caracteres en la entrada
hasta que encontremos un caracter de "parada".

```go
func Until(c rune) ParserFunc {
    return func(input []rune) Result {
        accum := make([]rune, 0, 10)
        for i, r := range input {
            if c != r {
                accum = append(accum, r)
            } else {
                return Ok(string(accum), input[i:])
            }
        }
        err := fmt.Sprintf("Consumed input without finding terminator %v", c)
        return Err(errors.New(err), input)
    }
}
```

Este parser en si no es muy util, pero podemos utilzarlo para crear otros

```go
/// Line obtiene todas las rune de la entrada hasta que encuenta un line feed
func Line() ParserFunc {
    return Until('\n')
}
```

Y finalmente hagamos uno para obtener números

```go
func isASCIIDigit(c rune) bool {
    ascii := int(c)
    return ascii >= 48 && ascii <= 57
}

func Numeric() ParserFunc {
    return func(input []rune) Result {
        accum := make([]rune, 0, 10)
        for _, r := range input {
            if isASCIIDigit(r) {
                accum = append(accum, r)
            } else {
                if len(accum) == 0 {
                    return Err(errors.New("Could not find a number on input"), input)
                }
                return Ok(string(accum), input[len(accum):])
            }
        }
        return Ok(string(accum), input[len(accum):])
    }
}
```

Ahora que tenemos varias funciones para parsear datos, hagamos algunos
combinadores (por si alguien se preguntaba lo de parsers combinators).

```go
///Or toma dos parser y
func Or(one ParserFunc, other ParserFunc) ParserFunc {
    return func(input []rune) Result {
        res := one(input)
        if res.Err != nil {
            return res
        } else {
            return other(input)
        }
    }
}
/// Any retorna el resuldado del primer ParserFunc que procese
/// datos de entrada o Err en caso de que todos fallen.
func Any(parsers ...ParserFunc) ParserFunc {
    return func(input []rune) Result {
        for _, p := range parsers {
            res := p(input)
            if res.Err == nil {
                return res
            }
        }
        return Err(errors.New("All cases failed"), input)
    }
}

/// All trata de ejecutar los parsers secuencialmente y retornar
/// una lista con la salida de cada uno. En caso de fallo retorna
/// el error.
func All(parsers ...ParserFunc) ParserFunc {
    return func(input []rune) Result {
        accum := list.New()
        data := input
        for _, p := range parsers {
            res := p(data)
            if res.Err != nil {
                accum.PushBack(res.Data)
                data = res.Remaining
            } else {
                return Err(res.Err, data)
            }
        }
        return Ok(accum, data)
    }
}

/// Check
func Check(p ParserFunc) ParserFunc {
    return func(input []rune) Result {
        res := p(input)
        if res.Err == nil {
            return res
        } else {
            return Result{nil, nil, input}
        }
    }
}
```

Esto nos permite hacer las siguientes expresiones:

```go

```
