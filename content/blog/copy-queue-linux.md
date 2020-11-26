---
title: "Cola de Copia para Linux (I)"
date: 2020-11-09T20:23:40-05:00
tags: ["rust","linux","copyq"]
draft: true
---

Hace ya unos cuantos meses ya surgió la idea en el [Canal
SWL-X](https://t.me/blogswlx) de hacer una pequeña utilidad en Linux
para permitir colas de copia de ficheros. Estas utilidades son muy
populares en otros sistemas operativos y algunos de los usuarios
buscan migrar hacia tecnologías libres se sentían frustrados al no
tener una alternativa.

Después de varios experimentos (resultados variados) decidí volver a
empezar desde 0 y ya de paso documentar el proceso de creación en el
blog.


## El problema.

Para los que llevamos tiempo utilizando cualquier variante **\*nix**
`cp` es uno de esos comandos que no hay por que mejorar, pero las
alternativas que proponen los entornos de escritorio dejan mucho que
desear a aquellos que llegan de entornos _más agradables_ (el lo
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
let mut num_read = unsafe {
	read(input_fd.as_raw_fd(),buf.as_mut_ptr() as *mut c_void, BUF_SIZE as usize) as usize
}
while num_read > 0 {

}
```

Si hacemos un diagrama sencillo de como fluyen los datos en esta
variante sería algo como esto

```
          read      +------+   	write
      +------------>+buffer+------------+
      |             +------+            |
      |                                 V
  +---+---+                         +---+--+
  |entrada|                         |salida|
  +-------+                         +------+
```

## Qué hay de importante en un buffer.
