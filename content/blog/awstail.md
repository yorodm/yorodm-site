+++
title = "awstail: AWS Logs a la vieja usanza"
date = 2020-01-20T11:50:59-05:00
tags = ["aws","rust","cloudwatch logs"]
categories = [""]
draft = false
description = "Herramienta sencilla para DevOps y desarrolladores"
+++

[awstail](https://github.com/yorodm/awstail) es una herramienta muy simple que cumple dos funciones:

1. Darme la excusa para aprender **Rust**.
2. Monitorear un grupo de logs en `AWS Cloudwatch` desde la terminal.

Por el momento, estas son las opciones que permite la herramienta:

```console
awstail 0.3.0
Yoandy Rodriguez <yoandy.rmartinez@gmail.com>
like tail -f for AWS Cloudwatch

USAGE:
    awstail.exe [OPTIONS] <LOG_GROUP>

FLAGS:
    -h, --help       Prints help information
    -V, --version    Prints version information

OPTIONS:
    -p <PROFILE>        Profile if using other than 'default'
    -r <REGION>         AWS region (defaults to us-east-1)
    -s <SINCE>          Take logs since a given time (defaults to 5 minutes)
    -w <WATCH>          Keep watching for new logs every n seconds (defaults to 10)

ARGS:
    <LOG_GROUP>    Log group name
```

Posibles opciones futuras:

1. Agregar logs de más de un grupo.
2. Color diferenciado para mensajes de error.
3. Listar grupos de logs existentes.
