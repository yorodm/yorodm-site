---
date: "2018-07-13T14:44:56-04:00"
description: Como hacer tus plantillas más resistentes a cambios
draft: false
tags:
- serverless
- yaml
title: Buenas prácticas con Serverless
comment: true

---

Aunque llevo poco tiempo utilizando [Serverless](http://serverless.com ) he
intentado ir escribiendo un conjunto de prácticas para escribir plantillas.
Las comparto aquí para los que como yo están empezando.

## Reducir la dependencia de valores externos.

En varios de los ejemplos que he encontrado (incluso en el sitio oficial) es
común utilizar referencias a valores externos por toda la plantilla.

```yaml
functions:
  hello:
    name: ${env:FUNC_PREFIX}-hello
    handler: handler.hello
  world:
    name: ${env:FUNC_PREFIX}-world
    handler: handler.world
```

Aunque esto no es una mala practica en si, hace que nuestras funciones dependan
de un valor que **solo** vamos a obtener desde el entorno. ¿Qué tal si mañana
decidimos que el valor venga [de la salida de otro stack]
(https://serverless.com/framework/docs/providers/aws/guide/variables#reference-cloudformation-outputs)?

Por suerte para nosotros podemos hacer esto:

```yaml
custom:
    func_prefix: # cualquier fuente para el valor
functions:
    hello:
        name: ${self:custom.func_prefix}
```

De esta manera la dependencia al valor externo ocurre en un solo punto y se
propaga hacia el resto de la plantilla.

## Usar plugins.

Las plantillas pueden [utilizar plugins]
(https://serverless.com/framework/docs/providers/aws/guide/plugins/) que
adicionan funcionalidades que van desde nueva sintáxis para algunos aspectos a
acceso a características especiales del proveedor que estemos utilizando. Antes
de lanzarte a crear un script o [lastimar a una cabra]
(https://en.wikipedia.org/wiki/Animal_sacrifice) deberías consultar si alguien a
[creado un plugin](https://www.npmjs.com/search?q=serverless)

## Contenido en la plantilla según condiciones.

Serverless no tiene soporte para evaluación condicional de plantillas así que si
pretendes crear contenido basado por ejemplo en el **stage** del despliegue
puedes hacer algo como esto:

```yml
# stage_properties-qa.yml
functions:
    qa_function:
        handler: MyQaHandler
```

```yml
# stage_properties-prod.yml
functions:
    prod_function:
        handler: MyProdHandler
```

```yml
# serverless.yml
custom:
    stage: ${opt:stage, "qa"}
functions: ${file(stage_properties-${self:custom.stage}.yml):functions}
```

Ahora tienes contenido en `functions` acorde al valor del **stage** si usas
varios entornos de configuración esta estructura te puede ahorrar mucho trabajo
y posibles complicaciones.

## Otras pistas o trucos.

¿Tienes otras pistas o trucos? Por favor compartelas en los comentarios
