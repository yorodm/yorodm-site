---
author: Yoandy Rodríguez Martínez
categories:
- ""
date: "2017-11-03T16:18:39-04:00"
description: Accediendo a Odoo desde Go
draft: true
tags:
- golang
- go
- odoo
title: Godoo
comment: true

---


# Godoo, accediendo a Odoo desde Go.

**Godoo** es mi nuevo y flamante proyecto disponible en
[Github](http://github.com ). Consiste una biblioteca (y pronto herramienta de
línea de comandos) para acceder a la interfaz **XMLRPC** de
[Odoo](http://www.odoo.com ). La idea principal del es permitir el desarrollo de
aplicaciones en **Go** que accedan a los modelos de **Odoo** como servicio. Las
funcionalidades desarrolladas en esta versión son:

1. **CRUD** para los modelos.
2. Ejecutar `search_count` y `search_read` sobre un modelo (sujeto a cambios).
3. Llamar métodos arbitrarios (soporte parcial).

Aún falta por implementar:

1. Acceso a reportes.
2. Workflows.
3. Interfaz más cómoda para crear expresiones de dominio.

Para versiones futuras pienso crear además una herramienta para ejecutar
consultas desde la línea de comandos y mejorar el acceso a métodos definidos por
el usuario en los modelos.

## Instalación y uso.

Como toda biblioteca de **Go** la instalación no podría ser más fácil

```bash
$ go get http://github.com/yorodm/godoo
```

Una vez terminada la descarga podemos comenzar la diversión

```go
package main
import (
    "fmt"
    "github.com/yorodm/godoo"
)

func main() {
    client, err := godoo.NewClient("http://localhost:8069")
    if err != nil {
        panic("No se pudo establecer comunicación")
    }
    client.Authenticate("mydb","myuser","mypassword")
    newRecord := struct {
        Name string
    }{Name: "Brand new record"}
    id, err:= client.Create(newRecord)
    if err != nil {
        panic("No se pudo crear el registro")
    }
    fmt.Printf("Creado nuevo registro con id %d", id)
}
```

Para más ejemplos y documentación visita el
[repo](http://github.com/yorodm/godoo ) y de paso puedes mirar otro de mis
[proyectos personales](http://github.com/yorodm)
