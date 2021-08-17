---
comments: true
date: "2021-08-17T13:48:16+03:00"
draft: false
tags:
- emacs
- nix
- direnv
series:
- Emacs, Nix y todo lo demás
title: Desarrollando con Nix y Emacs
comment: true
---

Si eres usuario de [Visual Studio
Code](https://code.visualstudio.com/) es muy probable que hayas
utilizado Remote Containers y [Docker](https://docker.com) para
desarrollar o simplemente probar algún nuevo lenguaje/tecnología sin
tener que modificar nuestro sistema. Aunque la idea de entornos
aislados para desarrollar no es nueva (los desarrolladores de Python
conocen [varias](https://virtualenv.pypa.io/en/latest/)
[alternativas](https://docs.python.org/3/library/venv.html))


## Nix en pocas palabras

Tanto [Nix como NixOS](https://nixos.org) vienen dando que hablar
desde hace un tiempo en el mundo de Linux. Su filosofía se basa en
crear un sistema que cumpla las siguientes características.

1. Reproducible: Si un paquete funciona en la máquina X, debe
   funcionar en la máquina Y.
2. Declarativo: El entorno se describe usando el lenguaje **Nix**.
3. Fiable: instalar o actualizar un paquete no puede hacer fallar la
   configuración existente.

¿Pero no es esto lo mismo que nos promete **Docker**?. En teoría si, en
la práctica es una de esas cuestiones de *filosofía a* vs *filosofía
b* que se escapa un poco del alcance de este artículo por lo que no
voy a ponerme a debatir sobre ella. Solo basta decir que hay más
diferencias que similitudes entre una *derivación* de **Nix** y un
*Dockerfile*.

## Instalando Nix.

Instalar **Nix** es bastante sencillo . El sitio oficicial incluye una
[guía rápida](https://nixos.org/learn.html) y bastante documentación
sobre como dar los primeros pasos. Aunque el resto del sitio es denso
y plagado de términos técnicos que no son muy amigables para los
recién llegados, existen otros recursos más accesibles (Dejo una lista
en la sección de referencias)

Por suerte, si usas [Archlinux](https://archlinux.org/) puedes seguir
la guía en la [wiki](https://wiki.archlinux.org/title/Nix) y tener
**Nix** disponible en pocos pasos.

```sh
$ sudo pacman -S archlinux-nix
$ sudo archlinux-nix setup-build-group
$ sudo archlinux-nix bootstrap
$ nix-channel --add https://nixos.org/channels/nixpkgs-unstable
$ nix-channel --update
$ nix-env -u

```

Podemos iniciar un *shell* de **Nix** nuevo utilizando el comando
`nix-shell`. Probemos arrancar un entorno con
[Deno](https://deno.land/)


```shell
$ nix-shell -p deno --pure
```

Con el comando anterior creamos un entorno temporal *puro* donde solo
tenemos lo necesario para operar (las **coreutils**) y **Deno** con
sus dependencias. Todo esto totalmente aislado del sistema (por eso la
parte de *puro*).

Ahora veamos cómo utilizar esto para hacer entornos de desarrollo.

## Nix + Direnv + Emacs = (❤)

Lo primero que necesitamos es una forma de indicarle al `nix-shell`
que queremos tener en nuestro entorno. Para eso creamos el archivo
`shell.nix` con el siguiente contenido

```nix
let
  pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  name ="deno-env";
  buildInputs = with pkgs; [
	deno
	python38
  ];
}
```

Ahora solo necesitamos entrar al directorio donde se encuentra el
archivo y ejecutar `nix-shell --pure` y tenemos **Deno** y **Python
3.8** a nuestra disposición. ¿Qué tal si soy un fan de
[Golang](https://golang.org)?

```nix
let
 pkgs = import <nixpkgs> {};
in
pkgs.mkShell {
  name = "go-env";
  buildInputs = with pkgs; [
    go
    gosec
    golangci-lint
    gopls
    delve
  ];

  shellHook = ''
    unset GOPATH GOROOT
    export GO111MODULE=on
  '';
}
```

Bueno, se entiende la idea. Podemos buscar cualquier paquete necesario
en [el repo oficial de Nixos](https://search.nixos.org/packages) o en
[NUR](https://nur.nix-community.org/) e incluirlo en la lista de los
*inputs* necesarios para la derivación. Incluso podemos declarar o
sobrescribir variables de entorno.

Nuestro segundo objetivo es evitar escribir `nix-shell` cada vez que
queremos activar la configuración. [Direnv](https://direnv.net/) es
una herramienta que nos permite cargar variables de entorno cada vez
que entramos a un directorio o sus hijos.

**Direnv** funciona mediante uso de *hooks* en el shell y requiere un
archivo `.envrc` donde el usuario define las variables usando la
sintaxis `VAR=VALUE`, aunque en nuestro caso haremos uso de la función
estándar `use_nix`. Es tan sencillo como ejecutar los siguientes pasos

```shell
$  echo "use_nix" >> .envrc
$  direnv allow .
```

La función `use_nix` ejecuta y obtiene el entorno de `nix-shell` y lo
inyecta en el *shell* regular.

> Si has prestado atención hasta ahora o simplemente experimentaste
> con los *snippets* debes haber notado que al usar este método no
> creas un entorno *puro*. Aunque parezca contraproducente, esto no
> afecta el modo en que la versión final del entorno de desarrollo
> va a funcionar.

Último paso es integrar todo con **Emacs**.


```elisp
(use-package direnv
  :pin melpa
  :ensure t)
```

El paquete **direnv** nos brinda un conjunto de funciones para
utilizar **direnv** desde el editor. Utilizarlo es tan sencillo como
navegar hasta el directorio usando *dired* y ejecutar *direnv-allow* o
activar el modo menor *direnv-mode*.

## The end?

Con estos simples pasos podemos replicar (parcialmente) la
funcionalidad de *Remote Containers*, creando entornos de desarrollo
*ad-hoc* o incluso manteniendo versiones incompatibles de un
compilador o SDK sin que esto afecte el resto del sistema.

En próximas entregas veremos como expandir este *setup* y utilizar
**Nix** para:

1. Compilar y empaquetar nuestro proyecto.
2. Crear imágenes de **Docker**.
3. *Cross-compiling*.
4. Otros trucos que todavía no se me han ocurrido.

## Referencias

* Nix Pills: https://nixos.org/nixos/nix-pills/
* Nix Shorts: https://github.com/justinwoo/nix-shorts
* NixOS: For Developers: https://myme.no/posts/2020-01-26-nixos-for-development.html
* Nix Pills: https://nixos.org/guides/nix-pills/
