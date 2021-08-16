---
title: "Desarrollando con Nix y Emacs"
date: 2021-08-15T16:48:07+03:00
draft: true
series: ["Emacs, Nix y todo lo demás"]
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


## Emacs + Nix = (❤)

Instalar **Nix** no es una tarea para principiantes. El sitio
oficicial incluye una [guía rápida](https://nixos.org/learn.html) y
bastante documentación sobre como dar los primeros pasos, pero el
contenido de la misma es bastante denso y no muy amigable para los
recién llegados.

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
