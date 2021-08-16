---
date: "2020-12-31T00:54:30-05:00"
draft: false
tags:
- rust
- linux
- copyq
title: Cola de Copia para Linux (I)
---

¡Ultimo artículo del 2020! Este ha sido un año muy turbulento en el
casi no he podido atender el blog, por lo que se me ocurrió dejar algo
interesante a modo de cierre.

Hace ya unos cuantos meses ya surgió la idea en el [Canal
SWL-X](https://t.me/blogswlx) de hacer una pequeña utilidad en Linux
para permitir colas de copia de ficheros. Estas utilidades son muy
populares en otros sistemas operativos y algunos de los usuarios
buscan migrar hacia tecnologías libres se sentían frustrados al no
tener una alternativa.

Después de varios experimentos (resultados variados) decidí volver a
empezar desde 0 y ya de paso documentar el proceso de creación en el
blog.

En esta entrega hablaremos de:

1. Copiar archivos en **Linux** usando **libc**.
2. *Buffers*.
3. Alternativas a `read` y `write` de **POSIX**

## El problema.

Para los que llevamos tiempo utilizando cualquier variante **\*nix**
`cp` es uno de esos comandos que no hay por que mejorar, pero las
alternativas que proponen los entornos de escritorio dejan mucho que
desear a aquellos que llegan de entornos _más agradables_ (en lo
personal estoy encantado con el gestor de ficheros de GNOME 3, pero
cada cual con lo suyo)

Otro problema radica en la velocidad de copia, muchas de estas
herramientas en sistemas privativos anuncian incrementos
significativos en la velocidad de transferencia de datos y sus
usuarios juran que es así (nadie me ha mostrado un _benchmark_, pero
la experiencia de los usuarios vale).

Como buenos usuarios de Linux que somos nos lanzamos a buscar
alternativas posibles (desde scripts hasta herramientas GUI para
Rsync) hasta que alguien recomendó utilizar la versión Linux de
[Ultracopier](https://github.com/alphaonex86/Ultracopier) e intentar
crear plugins para integrarla a los entornos de escritorio más populares.

Aún así los usuarios de **Ultracopier** hablan de bajo rendimiento de
la herramienta con respecto a su versión en Windows, por lo que varios
miembros del canal nos lanzamos a la aventura de hacer (o investigar
cómo se hace) una herramienta para colas de copia de ficheros que
saque partido de todo lo que Linux tiene para ofrecer.


## Como copiar archivos en Linux.

Bueno, después de esta larga introducción vamos al problema que nos toca:
¿Cómo programamos la copia de archivos en Linux?.

En su forma más simple, copiar un archivo lleva unas pocas líneas de código **C**.

```c
inputFd = open("foo.txt", O_RDONLY);
outputFd = open("bar.txt", O_CREAT | O_WRONLY | O_TRUNC, S_IRUSR | S_IWUSR);
// Ignoremos por el momento el valor de BUF_SIZE y el tamaño de buf
while ((numRead = read(inputFd, buf, BUF_SIZE)) > 0)
	if (write(outputFd, buf, numRead) != numRead)
		fatal("write() returned error or partial write occurred");
```

O como decimos los usuarios de **Rust**

```rust
std::fs::copy("foo.txt", "bar.txt")?; // :)
```

Pero teniendo en cuenta que queremos optimizar el funcionamiento de la copia
lo más probable es que utilicemos el _crate_ `libc` y hagamos nuestra versión
del ciclo de copia:

```rust
use libc::*;

let input_fd = std::fs::File::open("foo.txt")
let output_fd = std::fs::File::create("bar.txt")
let mut read: isize = 0;
let mut written: isize = 0;
loop {
	 read = unsafe {
		read(input_fd.as_raw_fd(),buf.as_mut_ptr() as *mut c_void, BUF_SIZE as usize) as isize
	}
	if read < 0 {
		break;
	}
	let written = unsafe {
		libc::write(fd.as_raw_fd(), buf.as_mut_ptr() as *mut libc::c_void, BUF_SIZE as usize) as isize
	};
	if written < read {
		break
	}

}
```

Si hacemos un diagrama sencillo de como fluyen los datos en esta
variante sería algo como esto

```
          read      +------+    write
      +------------>+buffer+------------+
      |             +------+            |
      |                                 V
  +---+---+                         +---+--+
  |entrada|                         |salida|
  +-------+                         +------+
```

## Qué hay de importante en un buffer.

Nuestro sencillo (pero genial) diagrama nos muestra algo interesante:
el tamaño del *buffer* afecta la velocidad de todo el proceso.

Si tenemos un archivo de 50mb y nuestro *buffer* es de 1mb
necesitaremos ejecutar el ciclo de copia 50 veces. Si subimos el
tamaño a 50mb tendremos una iteración. Podemos concluir entonces
que 50mb es el tamaño especial para nuestro *buffer*.

Para probar nuestra teoría veamos que tal funciona `cp`


```shell
$ strace -s 8 -xx cp /dev/urandom /dev/null | grep read
...
read(3, "\x61\xca\xf8\xff\x1a\xd6\x83\x8b"..., 131072) = 131072
read(3, "\xd7\x47\x8f\x09\xb2\x3d\x47\x9f"..., 131072) = 131072
read(3, "\x12\x67\x90\x66\xb7\xed\x0a\xf5"..., 131072) = 131072
read(3, "\x9e\x35\x34\x4f\x9d\x71\x19\x6d"..., 131072) = 131072
```

Pues... 131072 bytes, básicamente 128kb, un aproximado de 400
iteraciones para nuestro ciclo de copia. ¡Imagina copiar un archivo de
5GB, o varios archivos igual de grandes!

Antes de que reine el pánico tengo una confesión que hacer: el
diagrama genial no cuenta toda la verdad. El proceso de lectura y
escritura de archivos no ocurre en las funciones `read` y `write`,
ocurre en el **kernel**.


```
          read      +------+    write
      +------------>+buffer+------------+
      |             +------+            |
      |                                 V
  +---+---+                         +---+--+
  |entrada|                         |salida|
  +-------+                         +------+
      ^                                |
      |                                V
  +---+--------------------------------+---+
  |             magia del kernel           |
  +----------------------------------------+

```

El trabajo real de lectura/escritura ocurre en el **kernel** del
sistema operativo, esto implica que existe una transferencia de datos
entre nuestra aplicación (ejecutándose en *user space*) y el núcleo
(*kernel space*), con la corresponiente latencia en cada operación.

Una vez que entramos en terrenos del **kernel** podemos pasar horas
discutiendo sobre el *cache* de paginado, tamaño de bloques del
sistema de archivos, sectores de disco y así sucesivamente [hasta
encontrar la primera
tortuga](https://en.wikipedia.org/wiki/Turtles_all_the_way_down), pero
no tenemos tiempo para eso así que usaremos la sabiduría de los
antiguos para establecer el tamaño del buffer en 4096 bytes. Aunque
pueda parecer aleatorio este número está [respaldado por la
ciencia](https://stackoverflow.com) y por el momento, parece una
apuesta segura[^1].


## Más allá del read y el write.

Ahora que tenemos una idea de lo básico, podemos buscar alternativas
más eficientes al ciclo `read/write`. Las opciones que nos brinda
**Linux** son:

1. Utilizar acceso directo mediante el flag `O_DIRECT` para acceder a
   los archivos para evitar el *cache* del sistema operativo.
2. Usar `posix_fadvise` para que el sistema optimice el modo en que
   accedemos al archivo.
3. Utilizar la **API** asíncrona para acceso a datos.
4. La función `copy_file_range` que nos permite copiar datos desde un
   archivo a otro *sin* tener que intercambiar datos con el proceso en
   espacio usuario.

Cada una de estas técnicas tiene sus pro y sus contra (incluso se
pueden usar combinaciones entre ellas), pero como bien pueden imaginar
no son un tema a tratar a la ligera así que explorar su factibilidad
queda para otra aventura (con suerte en el Enero de este año nuevo).

## The end.

Nada más que decir que desearles un año nuevo en el que puedan crecer
como desarrolladores y como personas. Nuevo año, nuevas metas y ¡salud!.

[^1]: En el libro *The Linux Programming Interface*, capítulo 13 se
pueden ver *benchmarks* con distintos tamaños de buffer así como una
discusión más profunda sobre el tema.
