+++
categories = []
date = "2017-10-26T15:04:13-04:00"
description = ""
tags = ["emacs","go","golang"]
title = "Desarrollando con Emacs y Go"

+++

# Desarrollando con Emacs y Go.

Tengo la muy sana costumbre de utilizar Emacs para todo lo que pueda (incluso
revisar el correo) así que cuando me decidí a iniciar algunos proyectos en
[Go](https://golang.org ) me alegró mucho que no existiera un IDE "oficial" para
el lenguaje y si muchas herramientas, utilidades y plugins para que cada cual se
arme la casa a su manera.


## Haciendo un IDE en tres pasos.

Convertir `Emacs` en un entorno de desarrollo para `Go` es una tarea bastante
sencilla. Vamos a separarla en tres pasos.

### Instalar las herramientas necesarias.

Despúes de tener `Go` y `Git` instalado, necesitamos un conjunto de herramientas
(oficiales y de terceros) que nos hacen la vida mucho más sencilla.

1. [errcheck](http://github.com/kisielk/errcheck ): verificar errores de compilación.
2. [Guru](http://golang.com/x/tools/cmd/guru ): obtener información acerca del código.
3. [Gocode](http://github.com/nsf/gocode ): completamiento
4. [Gorename](http://golang.org/x/tools/cmd/gorename ): refactorizacíon a cierto
   nivel.
4. [Goimports](http://golang.org/x/tools/cmd/goimports ): ayuda a adicionar o
    eliminar paquetes importados (también formatea código).

Estas herramientas por si solas no nos son de mucha utilidad, están diseñadas
para que cualquier editor de texto que soporte extensiones pueda integrarlas de
un modo sencillo.


### El lado de Emacs

En mi lista de paquetes (uso nada más que [Melpa
estable](http://melpa.org/packages/ )) hay cerca de 15 paquetes que tienen que
ver con desarrollo en `Go`. En lo personal no necesito mucho para trabajar en un
lenguaje. Las funcionalidades que adiciono son:

1. Lenguaje y completaminto con `go-mode` y `company-go`.
2. Verificacíon de errores con `go-errcheck`.
3. Ayuda interactiva con `go-eldoc`.
4. Refactorización con `go-rename`.
5. Inspección de código con `go-guru`.
6. Integración con `projectile` vía `go-projectile`

Todos los paquetes es recomendable instalarlos vía `package-install` con la
excepción de `company-go` que está incluido en los fuentes de la herramienta
`gocode` y lo cargo desde ahí para evitar conflictos de versiones.

### Paso final.

Con todos los ingredientes estamos a solo 2 minutos de programar en `Go` como
campiones, solo queda:

1. Añadir `$GOPATH/bin` al `$PATH`
2. Modificar el `init.el` para personalizar los paquetes de `Emacs`.

Lo primero depende del sistema operativo donde estés, pero de todas formas es
una tarea trivial. Si eres relativamente nuevo en `Emacs` hay grandes
posibilidades de que no sepas como hacer lo segundo, no importa, aquí va mi
configuración (sin atajos de teclado, que ya eso es cosa muy personal).

```
;; Si estás utilizando correctamente tu gestor de paquetes en Emacs
;; no tienes que adicionar las lineas de los  `require'
;; Adicionar el backend de Go a company
(require 'company)
(add-to-list 'company-backends 'company-go)
;; Activamos go-mode
(require 'go-mode)
;; y toda la familia
(require 'go-guru)
(require 'go-errcheck)
(require 'go-projectile)
;; Añadimos un hook para que cuando se active el modo se configuren todas
;; estas cosas
(add-hook 'go-mode-hook (lambda ()
                         (company-mode)
                         (projectile-mode)
                         (go-eldoc-setup)
                         (add-hook 'before-save-hook 'gofmt-before-save)
                         (setq gofmt-command "goimports")))

```

Y...ya está. Hemos creado un `IDE` para trabajar en `Go` sin salir de la
comodidad de nuestro editor favorito.
