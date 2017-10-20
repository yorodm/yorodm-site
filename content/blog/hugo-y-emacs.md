+++
categories = ["hugo","emacs"]
date = "2017-10-19T15:26:34-04:00"
description = "Hugo, Emacs y el nuevo blog"
tags = ["emacs","blog","herramientas"]
title = "Hugo y Emacs"

+++

# Hugo, Emacs y el nuevo blog

Como comentaba en el primer post, decidí comenzar desde cero, aprovechando las
bondades de [Github Pages](https://pages.github.com/ ) y
[Hugo](http://gohugo.io) como generador de sitios estático. En lo que a
generador de sitios estáticos se refiere `Hugo` es bastante sencillo de operar,
por lo que inicialmente pensé en hacerme unos scripts para organizar el
*workflow* de trabajo de la siguiente manera:

1. Hacer nuevo post.
2. Previsualizar.
3. Subir a GitHub.

Todo esto organizado, claro está, en una rama *develop* para trabajar y una
*master* tanto para el repositorio donde guardo las fuentes del sitio como para
el que queda publicado.

Estaba muy emocionado escribiendo código en `Python` cuando recordé que `Emacs`
trae **su propio servidor http** en `simple-httpd.el` y unos cuantos paquetes
para interactuar con `Git`. Así surgió `hugo-blog-mode.el`

## Hugo en modo sencillo

Antes de arrancar a escribir `Emacs Lisp` me puse a revisar `MELPA` a ver si
alguien había tenido la misma idea que yo y encontré a `easy-hugo.el`, que está
genial, pero viene pensado para personas super publicadoras que tienen varios
blogs y los actualizan con mucha frecuencia o algo así. En fin, que tiene un
público objetivo en el cual no me incluyo. La idea siempre fue trasladar el
flujo de trabajo que ya tenía en mente a dos o tres comanditos, ponerle dos o
tres atajos de teclado y utilizar `Magit` lo menos posible en el proceso.

El resultado quedo en un archivito de unas 200 líneas de código con tres comandos.

1. `hugo-new-post`, que se explica solito.
2. `hugo-blog-preview`, que mueve todo lo que esté haciendo a la rama *develop*,
   regenera el sitio utilizando una URL local y lanza el navegador para ver como
   va quedando.
3. `hugo-blog-publish`, que regenra el sitio utilizando la URL final, hace
   *commit* en *develop* y me mezcla todo en master.

Como estoy utilizando submódulos de `Git` para mantener los repositorios asi:

```
sitio/ (fuentes del sitio)
   |--- content/
   |--- data/
   |--- static/
   |--- themes/
   |--- public/ (submódulo yorodm.guthub.io)
```

`hugo-blog-publish` se encarga de hacer los *commits* y los *merges* y todo lo que haga falta en los dos repos (de paso, también se encarga de asegurarse de que no haga ningun cambio accidental en master).
