+++
title = "Emacs + Hugo: Haciendo `hugo-blog-mode` (I)"
date = 2019-07-07T11:03:33-04:00
tags = ["emacs","hugo"]
categories = [""]
draft = false
description = "Creando un minor mode en Emacs para tu blog con Hugo"
series = ["hugo-mode"]
+++

Este [blog](https://yorodm.github.io) es creado con
[Hugo](https://gohugo.io) y publicado utilizando Github Pages. Cada
artículo es creado utilizando **Markdown** y añadido a un
[repositorio](https://github.com/yorodm/yorodm-site) donde finalmente
pasa a formar parte del sitio estático utilizando submódulos de `Git`.

Todo este proceso implica utilizar 3 herramientas.

1. La **CLI** de `hugo`.
2. Un editor de texto (preferentemente con soporte para Markdown).
3. Git.

Mis primeros intentos implicaron hacer uso de unos cuantos *scripts*

Uno para crear nuevos artículos

```shell
# New article
POST_NAME="$HUGO_BLOG_ROOT/content/blog/$1"
hugo new $POST_NAME
emacsclient $POST_NAME
```

Otro para salvarlos y publicar

```shell
# Save post and publish
cd $HUGO_BLOG_ROOT
# Remember to build the site
hugo --noChmod --noTimes --ignoreCase
git commit -a -m "Update $(date +%Y%M%d)"
cd $HUGO_BLOG_ROOT/publish
git commit -a -m "Update $(date +%Y%M%d)"
git push origin master
cd ..
git push origin master
```

Y finalmente uno para preview

```shell
# Run hugo in watch mode
cd $HUGO_BLOG_ROOT
hugo serve
```
