---
categories:
- ""
date: "2019-03-25T15:34:27-04:00"
description: Preparando Emacs para Go 1.13
draft: false
tags:
- emacs
- golang
title: Emacs + Golang. Edición 2019
comment: true

---

[Go 1.12](https://blog.golang.org/go1.12) fue lanzado hace un
mes y entre los cambios más significativos se encuentran varias mejoras
en el soporte para módulos (que va a ser el método por defecto en la
versión 1.13).

Si eres usuario de [Emacs](https://www.gnu.org/software/emacs) y te
interesa desarrollar utilizando Go, aquí tienes una guía sencilla de
como habilitar el soporte para el lenguaje.


## Paso 1. Language server protocol

Si tienes una versión actualizada de
[lsp-mode](https://github.com/emacs-lsp/lsp-mode) ya tienes soporte
para [bingo](https://github.com/saibing/bingo), una herramienta que
provee un servidor de lenguajes para Go y que tiene soporte integrado
para trabajar con módulos


```elisp
(use-package lsp-mode
  :commands (lsp)
  :config
  (use-package company-lsp
    :config
    (add-to-list 'company-backends 'company-lsp)))

(use-package lsp-ui
  :hook (lsp-mode . lsp-ui-mode)
  :config
  (define-key lsp-ui-mode-map
	[remap xref-find-definitions] #'lsp-ui-peek-find-definitions)
  (define-key lsp-ui-mode-map
	[remap xref-find-references] #'lsp-ui-peek-find-references)
  (setq lsp-ui-sideline-enable nil
        lsp-ui-doc-enable t
        lsp-ui-flycheck-enable nil
        lsp-ui-imenu-enable t
		lsp-ui-sideline-ignore-duplicate t))
```

## Paso 2. Go mode y utilidades

Como [lsp-mode](https://github.com/emacs-lsp/lsp-mode) es un *minor mode* necesitamos
el soporte para el lenguaje (font-lock entre otras cosas). Los pasos necesarios son:

 1. Instalar [goimports](golang.org/x/tools/cmd/goimports)
 2. Instalar [golint](https://github.com/golang/lint) o
    [gofmt](https://golang.org/cmd/gofmt/).


```elisp
(use-package flycheck)
(use-package go-mode
  :config
  ; Use goimports instead of go-fmt
  (setq gofmt-command "goimports")
  (flycheck-mode)
  (add-hook 'go-mode-hook 'company-mode)
  ;; Call Gofmt before saving
  (add-hook 'before-save-hook 'gofmt-before-save)
  (add-hook 'go-mode-hook #'lsp)
  (add-hook 'go-mode-hook #'flycheck-mode)
  (add-hook 'go-mode-hook '(lambda ()
			     (local-set-key (kbd "C-c C-r") 'go-remove-unused-imports)))
  (add-hook 'go-mode-hook '(lambda ()
			     (local-set-key (kbd "C-c C-g") 'go-goto-imports)))
  (add-hook 'go-mode-hook (lambda ()
			    (set (make-local-variable 'company-backends) '(company-go))
			    (company-mode))))
```

## Paso 3. Comenzar a programar en Go.

Con la configuración anterior puedes empezar a programar en Go

1. Completamiento y referencias cruzadas
2. Revisión de código mientras escribes.
3. Formato automático al salvar.
4. Un efecto aprecido al *hover* de [ese editor taaan popular](https://code.visualstudio.com/)


## Paso 4. Compilar y debug.

Puedes configurar el comando de compilación por defecto que utilizas
cuando editas archivos Go.

```elisp
;; Adicionar en la sección :config de `go-mode`
(add-hook 'go-mode-hook #'setup-go-mode-compile)

;; adicionar en el mismo archivo

(defun setup-go-mode-compile ()
  ; Customize compile command to run go build
  (if (not (string-match "go" compile-command))
      (set (make-local-variable 'compile-command)
           "go build -v && go test -v && go vet")))
```

Si prefieres los *debuggers* interactivos debes instalar
[delve](https://github.com/go-delve/delve) y añadir la siguiente línea
en tu archivo de inicio de Emacs.

```elisp
(use-package go-dlv)
```

Los comandos `dlv` y `dlv-current-func` son los puntos de entrada al debugger.
