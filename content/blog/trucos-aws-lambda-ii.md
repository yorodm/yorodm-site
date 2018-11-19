+++
title = "Trucos Aws Lambda (parte 2)"
date = 2018-11-18T12:39:59-05:00
tags = ["aws","lambda"]
categories = [""]
draft = false
description = "Más formas creativas de usar tus lambdas"
+++

# Trucos con AWS Lambda (II).


## Truco 1. Utiliza las tags.

Los tags en AWS nos permiten:

1. Tener asociados un máximo de 50 a cada recurso.
2. Llaves de hasta 128 caracteres Unicode.
3. Valores de hasta 256 caracteres Unicode.
4. Distinción entre mayúsculas y minúsculas para llaves y valores.

Basicamente todo lo que necesitamos para hacernos un caché:

```python
lambda_cient = boto3.client('lambda')
def save_cache(tags): # tags is a dict of string:string
    lambda_client.tag_resource(
        Resource=self_arn, # get it from handler context
        Tags=json.dumps(tags)
    )

def get_cache():
    return lambda_client.list_tags(
        Resource=self_arn # get it from handler context
    )

def invalidate_cache(keys):
    return lambda_client.untag_resource(
        Resource=self_arn,
        Tags=json.dumps(keys)
    )
```

## Truco 2. Desarrolla tus Lambdas en otros lenguajes.

Los lenguajes soportados oficialmente por AWS Lambda son (en el momento en que escribo este artículo):

1. Javascript (Node.js).
2. Python (2 y 3).
3. Java.
4. C#.
5. Go.

¿No está el lenguaje de tu preferencia? Pues no te preocupes, esa lista se puede extender a:

1. Kotlin, Groovy, Ruby Clojure y todo lo que soporte la JVM.
2. Cualquier lenguaje soportado por la plataforma .NET, incluido [PHP](https://www.peachpie.io).
3. Rust sobre [lando](https://github.com/softprops/lando) o [crowbar](https://github.com/ilianaw/rust-crowbar) incluso con integración con [serverless](https://github.com/softprops/serverless-rust).
5. [Cualquier cosa que genere WASM](https://blog.scottlogic.com/2018/10/18/serverless-rust.html)

## Más trucos

¿Tienes algún otro que compartir? Deja tu comentario aquí o en [DEV](https://dev.to/yorodm).
