---
categories:
- ""
date: "2019-01-28T23:55:02-05:00"
draft: true
tags:
- python
- tdd
title: Pytest vs Unittest
comment: true

---

Recientemente comencé un nuevo [proyecto personal](https://github.com/yorodm/kenobi) en Python
y me surgió la disyuntiva sobre que framework utilizar para mis pruebas unitarias.

Llevo lo que parecen siglos utilizando TDD con frameworks xUnit así que mi
elección por defecto siempre ha sido utilizar `unittest`[^1]. Pero como una de
las bibliotecas de las que dependo (y a la que he hecho pequeñas contribuciones)
utiliza `pytest` decidí que era un buen momento para dar el paso y ver por qué
es tan popular entre la comunidad.[^2]

## Recapitulando unittest

Por si hace rato que no usas `unittest` o de casualidad este es tu primer post
sobre TDD en Python, aquí van algunas de sus característucas más importantes:

1. Es orientado a objetos. Los casos de prueba se agrupan en clases donde creas
   métodos para cada una de las unidades.
2. Permite varios modelos para la carga de datos iniciales (*fixtures*).
3. Los métodos `assert*` dedicados dan más legibilidad al código

## Mirada a pytests

[^1]: En aquel entonces todavía se llamaba PyUnit

[^2]: Y no, "es por los plugins" no es una razón válida.
