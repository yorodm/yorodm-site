---
categories:
- ""
date: "2018-05-09T11:45:31-04:00"
description: Implementando un cliente JSON RPC para Odoo en Golang
draft: false
tags:
- golang
- jsonrpc
- snippets
- desafío
title: Implementando JSON-RPC en Go
---

# Implementando JSON-RPC en Go

**JSON-RPC** es mi método favorito para comunicarme con
[Odoo](http://www.odoo.com ) desde el "exterior", en estos días estaba
experimentando para enviar información desde un servicio desarrollado en
[Go](http://golang.org ) hacia el **ERP** y utilizar **Odoo** como *dashboard* y
me di cuenta que hacerlo con el paquete **net/rpc/jsonrpc** era todo un dolor de
cabeza por lo que me pregunté cuánto tiempo me tomaría hacerme mi propia
implementación. La respuesta es 32 minutos (tuve que leer mucha documentación).

```go
import (
    "errors"
    "fmt"
    "io/ioutil"
    "net/http"
    "net/rpc"
    "net/url"
    "reflect"
)

type JsonCodec struct {
    url        *url.URL
    httpClient *http.Client
    responses  map[uint64]*http.Response
    response   *Response
    ready      chan uint64
}

func (self *JsonCodec) WriteRequest(req *rpc.Request, args interface{}) error {
    request, err := NewRequest(self.url.String(), req.ServiceMethod, req.Seq, args)
    if err != nil {
        return err
    }

    response, err := self.httpClient.Do(request)
    if err != nil {
        return err
    }
    self.responses[req.Seq] = response
    self.ready <- req.Seq
    return nil
}

func (self *JsonCodec) ReadResponseHeader(resp *rpc.Response) error {
    seq := <-self.ready
    response := self.responses[seq]
    if response.StatusCode < 200 || response.StatusCode >= 300 {
        return fmt.Errorf("request error: %d", response.StatusCode)
    }
    data, err := ioutil.ReadAll(response.Body)
    if err != nil {
        return err
    }
    _ = response.Body.Close()
    r, err := NewResponse(data)
    if err != nil {
        return err
    }
    if r.Failed() {
        resp.Error = fmt.Sprintf("%v", r.Err())
    }
    self.response = r
    resp.Seq = seq
    delete(self.responses, seq)
    return nil
}

func (self *JsonCodec) ReadResponseBody(v interface{}) error {
    if v == nil {
        return nil
    }
    value := reflect.ValueOf(v)
    if value.Kind() != reflect.Ptr || value.IsNil() {
        return errors.New("Called with non ptr or nil")
    }
    value = value.Elem()
    value.Set(reflect.ValueOf(*self.response))
    return nil
}

func (self *JsonCodec) Close() error {
    transport := self.httpClient.Transport.(*http.Transport)
    transport.CloseIdleConnections()
    return nil
}
```

Como pueden ver utilizo la biblioteca estándar para crear un nuevo *codec* que
pueda utilizarse con **net/rpc**.

```go
codec := &JsonCodec{
        url:        u, /net.url.Url
        httpClient: httpClient, // net.http.Client
        ready:      make(chan uint64),
        responses:  make(map[uint64]*http.Response),
    }
client := rpc.NewClientWithCodec(codec)
```

Gran parte de la simpleza de la implementación responde al trato que reciben las
interfaces en [Go](http://golang.org ). Si no estás familiarizado con el tema te
recomiendo que leas.

1. [Go by Example: Interfaces](https://gobyexample.com/interfaces)
2. [The Problem with Interfaces, and how Go Fixed it](https://dev.to/deanveloper/the-problem-with-interfaces-and-how-go-fixed-it)
3. [Haking go interfaces](https://dev.to/loderunner/hacking-go-interfaces)
