---
comments: true
date: "2021-08-15T16:48:07+03:00"
draft: true
series:
- Emacs, Nix y todo lo demás
title: Desarrollando con Nix y Emacs
comment: true
---

Si eres usuario de [Visual Studio
Code](https://code.visualstudio.com/) es muy probable que hayas
utilizado Remote Containers y [Docker](https://docker.com) para
desarrollar o simplemente probar algún nuevo lenguaje/tecnología sin
tener que modificar nuestro sistema. Aunque la idea de usar de usar
entornos aislados para desarrollar no es nueva (los desarrolladores de
Python conocen [varias](https://virtualenv.pypa.io/en/latest/)
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

¿Pero no es esto lo mismo que nos promete **Docker?. En teoría si, en
la práctica es una de esas cuestiones de *filosofía a* vs *filosofía
b* que se escapa un poco del alcance de este artículo por lo que no
voy a ponerme a debatir sobre ella. Solo basta decir que hay más
diferencias que similitudes entre una *derivación* de **Nix** y un
*Dockerfile**.

## Instalando Nix.

Instalar **Nix** es bastante sencillo . El sitio oficicial incluye una
[guía rápida](https://nixos.org/learn.html) y bastante documentación
sobre como dar los primeros pasos. Aunque el esto de la guía es densa
y plagada de términos técnicos que no son muy amigables para los
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

 Ahora sólo nos queda instalar [direnv](https://direnv.net/) y empezar
 la diversión.

## Emacs + Nix = (❤)

**Direnv** nos permite cargar el entorno necesario para usar **Nix**
desde la terminal, *casualmente* hay un modo que lo hace funcionar en
**Emacs**.

```elisp
(use-package direnv
  :pin melpa
  :ensure t)
```



## Referencias


* Nix Pills: https://nixos.org/nixos/nix-pills/
* Nix Shorts: https://github.com/justinwoo/nix-shorts
* NixOS: For Developers: https://myme.no/posts/2020-01-26-nixos-for-development.html
* Nix Pills: https://nixos.org/guides/nix-pills/
