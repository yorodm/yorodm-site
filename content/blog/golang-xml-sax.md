+++
date = "2017-11-02"
description = "SAX XML parser para Golang"
tags = ["go", "golang", "xml"]
title = "Parser SAX en Golang"
+++

# Parser tipo SAX para Golang

## El problema

Tratando de migrar unas cosas del trabajo a **Go** me tropecé con la necesidad de
procesar unos archivos **XML** (cada día doy más gracias por **TOML** y **JSON**) de
tamaño considerable.

Una mirada por encima a `encoding/xml` me dejo bien claro que no existía un
parser tipo `xml.dom.minidom` (el de la biblioteca estándar de **Python**) o algo
como **Expat**. Las principales funciones (ej. las que salen en los ejemplos)
están orientadas más hacia la serialización y deserialización de **XML** que a
andar recorriendo documentos.

Sin otro remedio a mano acudí al [Gran Oráculo](http://google.com) para
investigar mis posibilidades y lo más cercano que encontré fue una biblioteca
llamada [saxlike](https://github.com/kokardy/saxlike ) que no luce nada mal pero
no era exactamente lo que buscaba (hay que implementar toda una interfaz).

## La solución.

El método `Token` de `*xml.Decoder` opera leyendo de un `*io.Reader` y retornando
el próximo token **XML** que encuentra. La función retorna `(Token, error)` donde
**Token** es uno de los siguientes tipos:

1. `xml.StartElement` (comienzo de un elemento)
2. `xml.EndElement` (final de un elemento, funciona incluso para etiquetas  como
   `<esta/>`)
3. `xml.Directive` (directivas especiales)
4. `xml.Comment` (comentarios)
5. `xml.Chardata` (contenido de los elementos)
6. `xml.ProcInst` (instrucciones de procesamiento)

Esto es bastante parecido a **SAX** es decir, podríamos hacer una interfaz
**Handler** con un método por cada tipo y una función (o método de otra clase) que
recibiera algo que implementara a handler y llamara a cada uno de los métodos.

```go
// En este caso hipotético Parser tiene embebido un xml.Decoder
func (self *Parser) Parse(document io.Reader, handler Handler) error {
    for {
        token, err := self.Token()
        if err == io.EOF {
         return nil
        } else if err != nil {
          return err
        }
        switch token.(type){
        case xml.StartElement:
            handler.StartElement(token)
        // mas de lo mismo
        }
    }
    return nil
}
```

Para utilizar este método necesitamos implementar la interfaz **SAX** con 6
métodos para los elemento y otro más para manejo de errores o verificar el valor
de retorno de `Parse`.

Peeeero, la idea de implementar 7 métodos y utilizar callbacks para manejar
eventos..... ya para eso tengo **Java**. Mucho menos cuando voy a tener que
escribir métodos vacíos para `xml.Comment` y `xml.Directive` porque no me
interesa procesarlos pero son necesarios para la interfaz.

Por razones como esta, los eventos en **Go** se manejan mejor utilizando
canales:

```go
type ParserError struct{}

func parse(document io.Reader, elm chan<- xml.Token) {
    defer close(elm)
    decoder := xml.NewDecoder(document)
    for {
        // DefaultDecoder es un *xml.Decoder
        token, err := decoder.Token()
        if err == io.EOF {
            return
        } else if err != nil {
            elm <- ParserError{}
            return
        }
        elm <- token
    }
}
```

Esta versión no solo es mucho más corta sino que además utilizamos una
*gorutina* para procesar el **XML** y un canal para la comunicación entre el
productor y el consumidor de los eventos. El consumidor puede elegir que eventos
le resultan interesantes y descartar el resto

Veamos un ejemplo:

```go
func main() {
    fd, err := os.Open("settings.xml")
    if err != nil {
        panic(err)
    }
    ch := make(chan xml.Token)
    go parse(fd, ch)
    for element := range ch {
        switch element := element.(type) {
        case xml.StartElement:
            fmt.Println(element.Name)
        case xml.EndElement:
            fmt.Println("</" + element.Name.Local)
        case ParserError:
            fmt.Println("Errroooooooooor")
        }
    }
}
```
