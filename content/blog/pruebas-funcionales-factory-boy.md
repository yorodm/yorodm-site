---
categories:
- ""
date: "2017-12-13"
description: Mejorando el modo en que escribimos pruebas funcionales
draft: false
tags:
- testing
- python
title: Pruebas funcionales con factory_boy y faker
comment: true

---
# Pruebas funcionales con factory_boy.

Una de las primeras cosas que aprendí cuando comencé a hacer pruebas funcionales
(allá en los lejanos tiempos de la [universidad](http://www.uci.cu )) fue la
necesidad de crear juegos de datos con el mayor nivel de realidad posible. En
ese entonces era práctica común entre compañeros de equipo guardar un archivo
**CSV** con nuestra información personal (nombre, número de identidad, etc) e
incluso hubo alguna que otra base de datos llena de información ficticia creada
por los más minuciosos.

No era una solución perfecta, estábamos solo a un paso por encima de utilizar
nombres como **"Persona 1"** con número telefónico **11-111-111** y cosas
parecidas. Por desgracia en aquel momento (en el lejano 2004) no teníamos acceso
a herramientas que nos facilitaran el proceso. Por eso hoy les voy a hablar de
**factory_boy**.


## Python, factory_boy y faker.

[Factory boy](https://github.com/FactoryBoy/factory_boy ) es una biblioteca
inspirada en [Factory Girl](https://github.com/thoughtbot/factory_girl ) (punto
para **Ruby**) que nos permite crear juegos de datos (o *fixtures* que hay que
hablar idiomas) de manera sencilla. Desde hace unas cuantas versiones se integra
con otra biblioteca llamada [faker](https://github.com/joke2k/faker ) que provee
datos aleatorios (de nuevo, basada en algo del mundo **Ruby**). Veamos un
ejemplo:

```python
class Person(object):
    """
    Modelo persona de toda la vida
    """
    def __init__(self, firstname, lastname):
        self.firstname = firstname
        self.lastname = lastname

    @property
    def fullname(self):
        return self.firstname + " " self.lastname

class PersonFactory(factory.Factory):
    """
    ¡¡¡La fábrica de personas!!!
    """
    class Meta:
        model = Person
    firstname = factory.Faker('first_name')
    lastname = factory.Faker('last_name')
```

Pues tenemos una clase **Person** y una clase **PersonFactory**
(¿**PeopleFactory**?), vamos a utilizarlas para crear 9 nombres.

```python
>>> [x.fullname for x in factory.build_batch(PersonFactory,9)]
['Keith Best', 'Michelle Wilson', 'David Stewart',
'Robert Garza', 'Sharon Brandt', 'Erica Joseph',
'Katelyn Washington', 'Stacy Byrd', 'Jeanne Harrison']
```
Vale, funciona. Vamos a extender la idea y hacer un catálogo de frases famosas que incluya
el nombre del autor

```python
class Quote(object):
    def __init__(text, author):
        self.text = text
        self.author = author

class QuoteFactory(factory.Factory):
    class Meta:
        model = Quote
    text = factory.Faker("sentence")
    author = factory.SubFactory(Person)
```

Y de nuevo hacemos una prueba de concepto: tres citas famosas con sus autores.

```python
>>> [(x.text, x.author.fullname)
    for x in factory.build_batch(QuoteFactory,3)]
[('Voluptas fugit culpa libero.', 'Terri Clements'),
('Molestiae perspiciatis eius odit.', 'Betty Clark'),
('Exercitationem voluptates corrupti nihil.', 'Eric Hernandez')]
```

## Soporte para ORMs.

Si las *factories* te recuerdan a algo, con su clase **Meta** incluida y sus
descriptores para los campos, no es casualidad. Esta biblioteca fue pensada
originalmente para ser utilizada con **Django**. Con el tiempo los
desarrolladores decidieron extender el soporte a otros de los **ORM** más
populares y separar las funcionalidades en clases específicas.

- **factory.django.DjangoModelFactory** para [Django](http://www.djangoproject.com )
- **factory.mongo.MongoFactory** para [Mongo](https://github.com/joshmarshall/mogo )
- **factory.mongoengine.MongoEngineFactory** para [MongoEngine](http://mongoengine.org )
- **factory.alchemy.SQLAlchemyFactory** para [SQLAlchemy](http://sqlalchemy.org )

Cada clase incluye además facilidades para interactuar con el **ORM**. Vean una
versión de **Person** llevada a **SQLAlchemy**

```python
from sqlalchemy import Column, Integer, Unicode, create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchmey.orm import scoped_seesion, sessionmaker
import factory
from factory.alchemy import SQLAlchemyFactory as Factory

engine = create_engine("sqlite://")
session = scoped_session(sessionmaker(bind=engine))
Base = declarative_base()

class Person(Base):
    # Para el ejemplo
    id = Column(Integer(), primary_key=True)
    firstname = Column(Unicode(30))
    lastname = Column(Unicode(30))

class PersonFactory(Factory):
    class Meta:
        model = Person
        # El objeto session que vamos a utilizar
        sqlalchemy_session = session
    id = factory.Sequence(lambda n: n)
    firstname = factory.Faker('first_name')
    lastname = factory.Faker('last_name')
```

## Puntos finales.

Un solo artículo no alcanza para describir todas las funcionalidades de esta
biblioteca. Si les ha picado la curiosidad les recomiendo que vean la
[documentación oficial](https://factoryboy.readthedocs.io ) y exploren los casos
de uso comunes expuestos por el equipo de desarrollo.

Características que no exploré en este artículo:

- Atributos definidos por secuencias numéricas.
- Atributos *lazy*.
- Atributos específicos para **ORMs** (ej. campos **FileField** de **Django**)
- Logs (muy útiles para el *debugging*).
- Estrategias de creación de modelos.
