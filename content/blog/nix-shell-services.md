---
title: "Usando servicios con Nix Shell"
date: 2022-04-13T12:52:28+03:00
draft: false
comments: true
tags:
    - nix
    - bash
---

En el [post anterior]({{<ref "nix-development-emacs.md">}}) tocaba el
tema de crear entornos de desarrollo reproducibles con `Nix` e incluso
dejé algunos casos de uso para lenguajes en específico.

Justo cuando pensaba que todo iba de maravilla se me ocurrió la idea
de probar
[Easypodcasts](https://github.com/easypodcasts/easy_podcasts) en modo
desarollador y de paso refrescar un poco de `Elixir`. `Easypodcasts`
es un proyecto basado en [Phoenix
LiveView](https://github.com/phoenixframework/phoenix_live_view) y
entre otras cosas necesita `PostgreSQL` como fuente de datos. En el
pasado (léase antes de usar `Nix`) esto lo habría resuelto usando un
`Dockerfile` para configurar y lanzar el servicio, pero ahora tenemos
otra alternativa.

## Creando `shellHooks` para nuestro entorno.

Buscando en la documentación de `Nix` podemos ver lo siguiente:

> Si una derivación `mkShell` define la variable especial `shellHooks`
> el contenido de esta será ejecutado despúes de `$stdenv/setup`

Traduciendo: es posible inyectar un script arbitrario que se ejcuta
con cada instancia de la derivación

Esto nos abre la puerta a otro conjunto de posibilidades.


## Manos a la obra

Ahora que sabemos que es posible alterar el funcionamiento del
`shell.nix` pongamos manos a la obra. Los objetivos son:

1. Configurar el servidor el arranque del servidor `PostgreSQL`.
2. Crear un usuario y contraseña para el entorno de desarrollo.
3. Exportar la configuración utilizando variables de entorno que sean
   visibles desde nuestro proyecto `Elixir`.

Primero las variables de entorno.


```sh
echo 'Setting database'
export PGDATA=$PWD/postgres_data
export PGHOST=$PWD/postgres
export LOG_PATH=$PWD/postgres/LOG
export PGDATABASE=postgres
export PGSOCKET=$PWD/sockets
```

Listo, `PostgresSQL` usará un directorio local para guardar el estado
del servicio y exportamos el directorio donde vivirá el _socket_
necesario para la comunicación.

Este último paso es en extremo importante, utilizar sockets en vez de
comunicación TCP nos posibilita ejecutar varias instancias de nuestra
base de datos sin tener que preocuparnos por cosas molestas como
puertos o permisos.

Continuando con nuestro script ahora necesitamos arrancar el servicio
de base de datos

```sh
mkdir $PGSOCKET
if [ ! -d $PGHOST ]; then
    mkdir -p $PGHOST
fi
if [ ! -d $PGDATA ]; then
    echo 'Initializing postgresql database...'
    initdb $PGDATA --auth=trust >/dev/null
fi
pg_ctl start -l $LOG_PATH -o "-c listen_addresses= -c unix_socket_directories=$PGSOCKET"
createuser -d -h $PGSOCKET postgres
psql -h $PGSOCKET -c "ALTER USER postgres PASSWORD 'postgres';"
```

¡Perfecto! Al ejecutar `nix-shell` tenemos todo listo para utilizar
 nuestra instancia local de la base de datos, solo queda un pequeño
 detalle. ¿Cómo detenemos el servidor una vez hayamos terminado con
 el?

La forma más sencilla es definir una rutina de limpieza para cuando
salgamos del `nix-shell`

```sh
function cleanup {
    echo "Shutting down the database..."
    pg_ctl stop
    echo "Removing directories..."
    rm -rf $PGDATA $PGHOST $PGSOCKET
}
trap end EXIT
```

Usando el comando `trap` de `Bash` podemos capturar la señal `EXIT`
(que no es una verdadera señal de POSIX) para ejecutar la función
`cleanup` y detener nuestra instancia de `PostgreSQL`. En este caso
además elimino todos los datos temporales creados en la sesíon de
desarrollo, de ese modo arrancamos desde 0 cada vez (lo mismo si haces
un `docker run` y no defines algún modo para que tu contenedor
persista su estado).

## The end?

Hay pocas tareas que no se pueden ejecuta con `shellHooks` En el caso de
`Easypodcasts` además de lanzar la base de datos, el script se asegura
de que el entorno de Elixir esté correctamente configurado y que tanto
`hex` como `rebar` se encuentren en el entorno.

Como nota de advertencia: Recuerden que los archivos `shell.nix`
pueden ejecutar código shell arbitrario. Verifiquen que el contenido
es seguro antes de de crear un entorno nuevo.
