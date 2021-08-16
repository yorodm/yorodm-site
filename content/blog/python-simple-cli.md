---
categories:
- ""
date: "2018-10-29T09:45:07-04:00"
description: Creando tus propias herramientas de interfaces de comandos con Python
draft: false
tags:
- python
title: Interfaces de comandos con Python
---

# Interfaces de comandos sencillas con Python.

Entre las muchas cosas para las que uso [Python](https://python.org) está
escribir pequeñas herramientas de líneas de comandos que me ayudan en el día a
día (especialmente cuando toca trabajar de **devops**). Aunque en la biblioteca
estándar existe `argparse` y muchos están contentos con eso, personalmente me
gustan alternativas que me hagan la vida más fácil.

## Docopt.

[Docopt](http://docopt.org/ "Docopt") Es (en mi opinión) uno de los mejores
frameworks para crear herramientas de líneas de comandos que existe y tiene
además la ventaja de no ser exclusiva de **Python**, para utilizarla solo tienes
que documentar el módulo o función que va a obtener los argumentos de la línea
de comandos. Veamos un ejemplo de una herramienta que utilizo para subscribir
ahorrarme tener que subscribir a un conjunto de usuarios cuando creo un
repositorio.

```python
"""Subscriber.

Usage:
  subscriber.py repo <reponame> group <groupname>

"""

def main(arguments):
    repo_name = arguments.get('<reponame>')
    group_name = arguments.get('<groupname>')
    # El resto va aqui

if __name__ == '__main__':
    arguments = docopt(__doc__)
    main(arguments)
```

Al invocar la herramienta sin parámetros obtenemos el siguiente mensaje de ayuda:

```console
$ python subscriber.py
Usage:
  subscriber.py repo <reponame> group <groupname>

```

Para utilizarla simplemente podemos

```console
$ python subscriber.py repo https://my.repo.cu group developers
```

Ventajas:

1. El código extra es mínimo (casi todo es documentación).
2. Ganas la documentación de gratis.
3. El minilenguaje de las cli es extremadamente poderoso.

Desventajas:

1. Tienes que aprender el minilenguaje.


## Lazycli.

[Lazycli](https://github.com/ninjaaron/lazycli "Lazycli") es un framework **muy
nuevo** pero de una simpleza y claridad que dan ganas de usarlo. En lugar de
documentación utilizamos decoradores para declarar nuestra **CLI**. El autor nos
muestra como ejemplo un clon de `cp`

```python
#!/usr/bin/env python3
import lazycli
import shutil
import sys


@lazycli.script
def cp(*src, dst, recursive=False):
    """copy around files"""
    for path in src:
        try:
            shutil.copy2(path, dst)
        except IsADirectoryError as err:
            if recursive:
                shutil.copytree(path, dst)
            else:
                print(err, file=sys.stderr)


if __name__ == '__main__':
    cp.run()
```

Si invocamos la herramienta obtenemos lo siguiente:

```console
$ python cp.py -h
usage: cp.py [-h] [-r] [src [src ...]] dst

copy around files

positional arguments:
  src
  dst

optional arguments:
  -h, --help       show this help message and exit
  -r, --recursive
```

Ventajas:

1. Casi 0 código extra (ejecutar el objeto que devuelve el decorador).
2. Convención sobre configuración.

Desventajas:

1. No es tán versátil como `docopt`.
