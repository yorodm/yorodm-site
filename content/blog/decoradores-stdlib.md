+++
title = "Python: Decoradores estándar y su uso"
date = 2019-01-15T22:11:42-05:00
tags = ["python", "decorators", "builtins"]
categories = [""]
draft = true
description = "Decoradores de la biblioteca estándar de Python y cómo utilizarlos"
+++

Entre las *baterías includas* de Python, vienen varios decoradores que nos
facilitan la vida. Aquí una lista de algunos y breve explicación acerca de su
uso.

## Decoradores para OOP

### property

Uno de los más usados. Convierte un conjunto de métodos en un **descriptor** que
hace las funciones de propiedad. Útil cuando queremos adicionar algún tipo de
lógica a propiedades de la clase.

```python
class C:
    def __init__(self):
        self._x = None

    def getx(self):
        return self._x or request.get('http://mydata.com/x')

    def setx(self, value):
        self._x = value
        request.post('http://mydata.com/x', data=x)

    def delx(self):
        del self._x
        request.delete('http://mydata.com/x')

    x = property(getx, setx, delx, "Proxy x como proxy a servicio REST.")
```

### staticmethod

Define métodos estáticos[^1]. Pueden ser llamados tanto desde la clase o una de sus instancias

```python
class C:

    @staticmethod
    def calculo_externo(val, val2):
        return val + val2
```

Nótese la falta del parámetro implicito inicial.

### classmethod

Convierte un método normal a un método de clase. Los métodos de clase reciben la
clase como parámetro implícito en vez de una de las instancias. Uno de los casos
de uso más comunes es crear formas alternativas de instanciar la clase.

```python
class C:

    def __init__(self, x, y ,z):
        self.x = x
        self.y = y
        self.z = z

    @classmethod
    def from_dict(cls, data):
        return cls(data[0], data[1], data[3])
```

### abc.abstractmethod

Métodos que tienen que ser implementados **obligatoriamente** por las subclases.
El equivalente a *interfaces* o *clases abstractas* que tanto encuentras en
otros lenguajes.

```python
import abc

class Animal:

    @abc.abstractmethod
    def sonido(self):
        pass

class Perro(Animal):

    def sonido(self):
        print("Ladrido")

class Vaca(Animal):

    def sonido(self):
        print("Mugido")
```

Se puede utilizar en conjunción con *@property* o *staticmethod* para crear
propiedades o métodos estáticos abstractos.

### functools.total_ordering

Nos permite crear clases que soporten operadores de comparación. Solo tenemos
que proveer el método *__eq__* y uno de los seis métodos predefinidos de orden.
La documentación de la bilioteca estándar advierte que este decorador puede
tener impactos en el rendimiento.

```python
@total_ordering
class Student:
    def _is_valid_operand(self, other):
        return (hasattr(other, "lastname") and
                hasattr(other, "firstname"))
    def __eq__(self, other):
        if not self._is_valid_operand(other):
            return NotImplemented
        return ((self.lastname.lower(), self.firstname.lower()) ==
                (other.lastname.lower(), other.firstname.lower()))
    def __lt__(self, other):
        if not self._is_valid_operand(other):
            return NotImplemented
        return ((self.lastname.lower(), self.firstname.lower()) <
                (other.lastname.lower(), other.firstname.lower()))
```


### dataclasses.dataclass

Nos permite omitir la declaración de *__init__* y *__repr__* en la declaración
de clases en las que solo vamos a manejar datos. El uso puede ser extendido a
subclases

```python
import dataclasses

@dataclasses.dataclass
class Point:
    x: float
    y: float

    def euclidian_distance(self, other: Point) -> float:
        return math.sqrt(
            (other.x - self.y)**2 + (other.y - self.y)**2
        )

@dataclasses.dataclass
class ThreeDPoint(Point):
    z: float

    def euclidian_distance(self,other: Point) -> float:
        dx = (other.x - self.y)**2
        dy = (other.y - self.y)**2
        dz = (other.z - self.z)**2
        return math.sqrt(
            dx+dy+dz
        )
```

## Decoradores para funciones

### functools.lru_cache

Caché de las últimas *n* llamadas a una función. Los parametros tienen que poder
ser utilizados como llaves de un diccionario.

```python
from functools import lru_cache
@lru_cache(20)
def get_exchange(local, foreign):
    exchange_service.convert(local, foreign)
```

### asyncio.coroutine

Convierte corutinas basadas en generadores para que sean compatibles con el
nuevo modelo *async/await*. Usar solamente en código que necesita ser portado

```python
from asyncio import coroutine

@coroutine
def render_view(view_name, context):
    template = Template(view_name, context)
    yield template.render()

async def hanlde_get(route):
    await render_view(route.view, route.params)
```

### contextlib.contextmanager

Convierte una función en un *contextmanager*. Puede ser usado de dos formas:

1. Utilizando una sentencia *with*
2. Como un decorador.

Personalmente para hacer decoradores que sean *contextmanagers* prefiero utilizar
la clase *ContextDecorator*.

```python
from contextlib import contextmanager

@contextmanager
def acquire_lock(key):
    credentials = get_credentials(key)
    lock = acquire_lock_using_credentials(credentials)
    try:
        yield lock
    finally:
        release_lock(lock)

with acquire_lock('my secret api key') as lock:
    use_critical_resource(lock)
```

## Decoradores extra

### functools.wraps

Decorador para crear decoradores. Útil para hacer que las funciones conserven
propiedades como *__name__* y *__doc__*

```python
from functools import wraps
def my_decorator(f):
    @wraps(f)
    def wrapper(*args, **kwds):
        return f(*args, **kwds)
        return wrapper

@my_decorator
def funcion():
    """
    Esta es la doc
    """
    pass
```

### functools.singledispatch

Permite crear funciones sobrecargadas a partir del tipo del primer parámetro.
Hace uso de las anotaciones de tipos.

```python

class Perro:
    pass

clas Vaca:
    pass

@singledispatch
def sonido(animal):
    pass

@sonido.register(Perro)
def _(animal):
    print("Ladra")

@sonido.register(Vaca)
def _(animal):
    print("Muge")
```



[^1]: No soy muy partidario de usar métodos estáticos en Python.
