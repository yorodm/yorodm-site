+++
title = "Plumber: ETL simple para Python"
date = 2019-03-12T10:14:20-04:00
tags = ["python","etl"]
categories = [""]
description = "Hacer tuberías ETL nunca fue menos complicado"
+++

Implementando una feature para uno de los proyectos en los que trabajo terminé
necesitando hacer el típico proceso ETL que tomara las cosas de una fuente X,
las pasara por 1 o varios filtros y las cargara en nuestra base de datos documental.

Ahora, si bien existen frameworks de excelente calidad como
[petl](https://petl.readthedocs.io) y [Bonobo](https://www.bonobo-project.org)
que cubren este campo, me encontré con los siguientes problemas:

1. Existe mucho código *legacy* en  el proyecto.
2. Exceptuando la parte de ETL, la complejidad de proceso es bastante alta,
   incrementarla no sería lo más adecuado.
3. El componente ETL no se ejecutaría por si mismo sino como parte de una solución.
4. La mayoría de los datos que agregamos usan formatos no convencionales.

Aunque en apariencia sencillos, estos cuatro puntos me llevaron a crear mi
propio *miniframework* para componentes ETL que es fácil de integrar con código
existente y no hace ningún tipo de suposiciones con respecto a la forma de los
datos, [plumber](https://github.com/yorodm/plumber).


## Características de plumber.

Para el desarrollo del framework me basé mucho en mi experiencia anterior con
[kiba](https://www.kiba-etl.org), una de esas joyas que siempre vienen desde la
comunidad de Ruby. Kiba hace uso de las bondades de Ruby para crear DSL's
dejando al desarrollador que se centre en los datos de la manera que considere
correcta. En [plumber](https://github.com/yorodm/plumber) esta idea está
reflejada en cuatro conceptos:

1. Extractors (que acceden al origen de datos).
2. Transformers (que manipulan los datos obtenidos).
3. Writers (que persisten los datos).
4. Pipes (que controlan todo el proceso).

### Extractors.

Un **Extractor** es una clase o función que emite datos para una tubería (pipe),
los datos pueden tener cualquier origen y cualquier forma, los extractors son
independientes del resto del proceso.

Aunque es posible utilizar una función como extractor, lo recomendado en la
mayoría de los casos es heredar de la clase `plumber.pipe.Extractor` e
implementar los métodos `read`, `setup` y `cleanup`. Varios extractors se pueden
unir para formar uno solo que emita una secuencia (tupla) con los valores de
cada uno.

### Transformers.

Un **Transformer** es cualquier función marcada con `@transformer` o una clase
derivada de `plumber.pipe.Transformer`. Es posible unir varios transformers en
una cadena de procesamiento

### Writer.

Finalmente los **Writers** heredan de `plumber.pipe.Writer`. Como generalmente
acceden a recursos externos, es requerido que implementen los métodos `setup` y
`cleanup` además de `write`.

Todos los elementos usan anotaciones [PEP 484](https://www.python.org/dev/peps/pep-0484/).


## Un ejemplo sencillo:

Uno de los casos de uso que motivaron la creación del framework fue obtener una
lista de registros de un archivo con formato propietario. El contenido del
archivo es más o menos el siguiente:

1. Campo identificador de cliente. Comienza en la posición 0, tiene longitud
   entre 1 y 20.
2. Campo identificador de transacción. Comienza en la posición 22. Es numérico y tiene longitud 8.
3. Campo identificador de transacción relacionada. Comienza en la posición 32.
   Tiene longitud 8, es opcional y de no estar se ponen espacios en blanco.
4. Campo motivo de la transacción. Comienza en la posición 42 y longitud entre
   10 y 50. Es de tipo alfanumérico, incluye espacios, no tiene delimitaciones.

Veamos un ejemplo de como procesar estos archivos:

```python
from plumber import pipe # API síncrona.

@pipe.extractor
def read_file():
    file_name = os.environ['FILENAME']
    with open(file_name) as f:
        for x in f.readlines():
            yield process_line(x)

@pipe.transformer
def csvfy(element):
    yield ','.join(map(str,element))


class SaveData(pipe.Writer):

    def __init__(self, filename):
        self.filename = filename

    def setup(self):
        self._file = open(f,'w')

    def cleanup(self):
        self._file.close()

    def write(x):
        self._file.write(x)

tuberia = pipe.Pipe(
    read_file,
    csvfy,
    SaveData("prueba.csv")
)
tuberia.run()
```

## ¿Qúe queda por hacer?

Ahora que [plumber](https://github.com/yorodm/plumber) salió a la luz es hora de
convertirlo en un framework ETL medianamente decente. Los próximos pasos son:

1. Adicionar la posibilidad de hacer **Writers** como funciones con
   administración de contexto integrada.
2. Poder inicializar los **Extractors** de manera sencilla.
3. Mejorar el tratamiento de errores.
4. Concurrencia y/o paralelismo.
