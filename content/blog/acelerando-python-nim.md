---
categories:
- ""
date: "2019-01-22T15:46:33-05:00"
draft: true
tags:
- nim
- python
- rendimiento
title: Acelerando Python con Nim
---

¿Has escuchado sobre [Nim](https://nim-lang.org)? Es un lenguaje de propósito
general con sintáxis parecida a Python lo cuál lo hace muy cómodo para los que
venimos de ese lenguaje. Tomemos por ejemplo una implementación sencilla de la
función factorial.

```nim
# Nim
proc factorial(x): int =
  if x > 0: x * factorial(x - 1)
  else: 1
```

y ahora en Python

```python
# Python
def factorial(n):
    if x > 0:
        return x * factorial(x -1)
    else:
        return 1
```

¿Bastante parecido no? La diferencia radica en que el código Python se ejecuta
en el intérprete mientras Nim *transpila* a C para después generar binarios
dependientes de la plataforma. En otras palabras: con Nim ganas en
**velocidad**[^1].

[^1]: Suponiendo que la calidad del código sea aceptable
