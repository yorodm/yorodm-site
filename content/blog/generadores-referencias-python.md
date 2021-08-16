---
categories:
- ""
date: "2017-12-15"
description: Peligros del uso de referencias en los generadores
draft: false
tags:
- python
title: Generadores y referencias
comment: true

---

# Generadores y referencias

Las referencias en **Python** son un tema que a menudo se pasa por alto, incluso
por los que ya no somos [tan novatos](https://stackoverflow.com/questions/47552529/obscure-iterator-behavior-in-python).
Hagamos un experimento, toma a diez desarrolladores que conozcas y
pregúntales qué hay de malo en esta función.

```python
def funcionx(*args):
    ctx = dict()
    for x in args:
        ctx['run'] = x
        yield ctx
```

Vale, es una pregunta con truco y la respuesta es **todo** o **nada** en
dependencia de como utilices la función generadora. Si no sabes que es una
función generadora porque no has llegado a ese capítulo en el libro o no te has
leído la [PEP 255](https://www.python.org/dev/peps/pep-0255 ) no importa. Aquí
tienes la versión **TL;DR**

> Los funciones generadoras son aquellas que usan **yield** en vez de **return**
> para devolver valores.

Cuando llamas una función generadora obtienes un *generador*, el cual puedes
utilizar para seguir obteniendo valores de la función, haciendo llamadas que
retornarán nuevos valores mientras encuentren **yield** (como dije antes
**TL;DR** o mejor **TL;DW**). Los generadores son iterables así que generalmente
se utilizan en ciclos **for .. in**.

```python
>>> funcionx(1,2,3,4)
<generator object funcionx at 0x00000000061D98B8>
>>> for x in funcionx(1,2,3,4):
....    print(x)
{'run': 1}
{'run': 2}
{'run': 3}
{'run': 4}
```

Hasta aquí parece todo bien, **funcionx** retorna un objeto de tipo generador y
podemos iterar sobre los resultados. Pero por alguna razón no pasa esta sencilla
prueba unitaria.

```python
class TestFuncionx(unittest.TestCase):

    def test_returns_generator(self):
        self.assertTrue(isinstance(funcionx(1,2,3,4),collections.Iterable))

    def test_yields_context(self):
        l = list(funcionx(1,2))
        self.assertEqual(len(l),2)
        # ¡¡Fatal!!
        self.assertEqual(l,[{'run': 1}, {'run': 2}])
```
¿Cómo es posible?. Obviamente algo está fallando en la prueba unitaria, verifiquemos manualmente.

```python
>>> len(list(funcionx(1,2,))) == 2
True
>>> list(funcionx(1,2,))
[{'run': 2}, {'run': 2}]
```
Mmmmm...¿qúe?...mmmm. Calma, miremos de cerca la función, especialmente la parte en que hace:

 ```python
    yield ctx
```
¿Recuerdas que **ctx** es un diccionario? ¿Recuerdas que los diccionarios en **Python** son referencias?

En cada ejecución del generador estamos devolviendo la **misma** referencia con
valores modificados. Cuando utilizas la función en el ciclo **for...in**
utilizamos el valor de **ctx** y lo descartamos enseguida, como no guardamos el
resultado no notamos que el próximo valor que obtenemos es la misma referencia
modificada.

{{< figure src="/images/generadores-referencias-python/yield-con-ciclo-for.png" >}}

La prueba unitaria falla porque, cada invocación del generador modifica las
referencias que tenemos guardadas.

{{< figure src="/images/generadores-referencias-python/yield-con-list.png" >}}

En este caso obtendremos una lista de *n* elementos que tienen el último valor
de **ctx**.

Por suerte el problema tiene soluciones sencillas, podemos retornar una nueva
instancia en cada invocación o simplemente crear una copia:

```python
def funcionx(*args):
    ctx = dict()
    for x in args:
        ctx['run'] = x
        yield dict(ctx)
```

Y listo, no más valores extraños ni pruebas que fallan.
