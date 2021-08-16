---
date: "2021-02-17T19:21:46-05:00"
description: Sacando ventaja de la concurrencia en Go
draft: false
tags:
- go
- concurrencia
- patrones
title: 'Desarrollo en Golang: Futures/Promises'
---

Entre las cosas que pienso adicionar al [workshop de
Go](https://yorodm.github.io/golang-workshop) está un capítulo sobre
patrones y técnicas para programación concurrente.

_Future_ es un objeto que representa el resultado de un cálculo que se
ejecuta de forma concurrente. Las _futures_ se utilizan cuando tenemos
un valor que es costoso de obtener pero sabemos de antemano como
calcularlo.

Las facilidades de **Go** para manejar concurrencia hacen la
implementación de _futures_ en el lenguaje bastante sencilla.

## Interfaz

Nuestro primer paso es crear una interfaz.

```go
type Value interface{}

type Future interface {
	Get(c context.Context) (Value, error)
}
```

Como **Go** todavia no tiene soporte para genericidad (mientras
escribo esto estamos en la versión _1.16_) utilizamos un alias para
representar cualquier valor de retorno.

## Implementación

Para la implementación crearemos estructura que contenga el resultado
de la operación y otra con un canal para transmitir el valor.

```go
type result struct {
	value Value
	err   error
}

type futureImpl struct {
	result chan *result
}
```

Necesitamos una función para crear nuevas _Futures_, el algoritmo es sencillo:

1. Creamos un canal para comunicar el completamiento de la subrutina.
2. Lanzamos una _gorutine_ anónima que englobe la ejecución de la
   subrutina.
3. La _gorutine_ es encargada de notificar el completamientoa los
   interesados.

```go
func NewFuture(f func() (Value, error)) Future {
	fut := &futureImpl {
		result: make(chan *result)
	}
	go func(){
		defer close(fut.result)
		value, err := f()
		f.result <- &result{value, err}
	}()
	return fut
}
```

Ahora solo necesitamos implementar `Get`, en este caso tenemos que
tener en cuenta la posible cancelación del _future_ o casos de
_timeout_.

```go
func (f *futureImpl) Get(c context.Context) (Value, error) {
	select {
		case <-ctx.Done():
			return nil, ctx.Err()
		case result := <-f.result:
			return result.value, result.err
	}
}
```

## The End.

Veamos un ejemplo ficticio:

```go

func takeFinalSteps(f Future) error{
	prepareTheSteps()
	value, err := f.Get(context.TODO())
	if err != nil {
		return nil, err
	}
	sendValue(value)
}

func main() {
	data := getProcessableData()
	fut := NewFuture(func() {
		cleaned := doSomeDataCleaning(data)
		return doSomeDataProcessing(cleaned)
	})
	createAuxiliaryResources();
	_ := takeFinalSteps(fut)
}
```

Aunque parezca sencillo, un `Future` es una abstracción poderosa que
nos permite diferir la obtención de un valor para el momento en el que
realmente lo necesitemos. Como toda herramienta hay que tener en
cuenta que su uso no aplica a todos los casos, pero nunca está de más
tenerla a mano.
