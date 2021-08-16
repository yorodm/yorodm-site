---
categories:
- ""
date: "2020-10-06T17:45:15-04:00"
draft: false
series:
- hugo-mode
tags:
- emacs
- hugo
title: 'Emacs + Hugo: Haciendo `hugo-blog-mode` (II)'
---


En el [artículo anterior]({{< relref "hugo-mode-emacs.md" >}}) (hace
unos cuantos meses ya) estuve hablando sobre como comencé
automatizando el flujo de publicación del blog usando scripts. En este
les mostraré como llevamos esos scripts a un modo de **Emacs**.

## Manos al Emacs.

Una de las ventajas de Emacs es su extensibilidad, con un poco de
código **Elisp** podemos adicionar nuevas funcionalidades al editor.
Aunque sería posible hacer un modo[^1] para crear toda una experiencia
relacionada con el manejo de blogs, es mucho más sencillo crear
comandos[^2].

### Planeando las funcionalidades.

Necesitamos 3 funcionalidades básicas para trabajar en nuestro blog.

- Crear nuevos artículos.
- Publicar el blog en [GitHub Pages](https://github.com).
- Visualizar en el entorno local cualquier cambio que se produzca.

Con esto en mente podemos crear el esqueleto de las funciones

```elisp
(defun hugo-blog-new (path)
	"Create new content in PATH.")
(defun hugo-blog-publish ()
	"Generate the site and commit everything.")
(defun hugo-blog-preview (arg)
	"Launches a preview HTTP server. If ARG is provided also render drafts.")

```


### Opciones de configuración.

Vamos a necesitar algunas opciones configurables:

- El nombre (o camino) del ejecutable de `hugo`.
- La raiz del proyecto del blog.
- El nombre del *buffer* que usaremos para interactuar con el comando.

```elisp
(defgroup hugo-blog nil
  "Hugo blog mode customizations"
  :group 'tools)

(defcustom hugo-blog-command "hugo"
  "Path to hugo's executable."
  :group 'hugo-blog
  :type 'string)

(defcustom hugo-blog-project ""
  "Blog directory project."
  :group 'hugo-blog
  :type 'string)

(defcustom hugo-blog-process-buffer "*hugo-blog-process*"
  "Hugo blog process buffer."
  :group 'hugo-blog
  :type 'string)

```

### Funciones de soporte.

Definidos nuestros puntos de entrada y las opciones configurables
necesitamos englobar algunas funcionalidades comunes en funciones de
soporte.

Emacs nos brinda funciones para ejecutar programas externos o comandos
del shell. La forma simple sería ejecutar los *scripts* de shell que
tenemos definidos, pero es mucho más interesante reproducir la
funcionalidad en Elisp. Veamos por ejemplo como podemos ejecutar
`hugo` y capturar la salida en busca de mensajes de error.


```elisp
(defun hugo-blog-run-command (command parameters)
  "Run COMMAND with PARAMETERS with `hugo-blog-project' as working directory.
Returns the command's output as a string"
  (cd hugo-blog-project)
  (let ((output (shell-command-to-string
                 (concat hugo-blog-command
                         " "
                         command
                         " "
                         parameters))))
    (if (string-match-p "Error" output)
        nil
      output)))
```

La función retorna `nil` en caso de error o el mensaje resultado de la
llamada en otro caso

Así mismo podemos definir el resto de las funciones necesarias.

```elisp
(require 'git) ;; git related functions

(defmacro with-git-repo (repo &rest body)
  "Run BODY using git repository REPO."
  `(let ((git-repo ,repo))
     ,@body))

(defun git-modified-files ()
  "Return list of untracked files."
  (git--lines
   (git-run "ls-files" "-m" "--exclude-standard")))

(defsubst hugo-blog-submodule ()
  "Inline function to get the submodule."
  (concat hugo-blog-project (f-path-separator) "public"))

(defun hugo-blog--commit-all ()
  "Commits the submodule and then the project."
  (with-git-repo  (hugo-blog-submodule)
                 (when (git-modified-files)
                   (git-add)
                   (git-commit (concat "Commit on "
                                       (current-time-string)))))
  (with-git-repo  hugo-blog-project
                 (when (git-modified-files)
                   (git-add)
                   (git-add "public") ;; Let's be really sure
                   (git-commit (concat "Commit on "
                                       (current-time-string))))))
```

### Completando las funcionalidades

Con ayuda de las funciones auxiliares podemos desarrollar los comandos
necesarios.  Es importante notar que todas las funciones están
marcadas como `autoload` e `interactive` así estarán disponibles como
comandos en el editor y sería más fácil distribuirlas en un paquete.

```elisp

;;;###autoload
(defun hugo-blog-new (path)
  "Create new content in PATH."
  (interactive "sNew content path: ")
  (cd hugo-blog-project)
  (let ((output (hugo-blog-run-command "new" path)))
    (if output
        (find-file-existing  (car (split-string output " ")))
      (error "Command hugo returned an error, check your configuration"))))

;;;###autoload
(defun hugo-blog-publish ()
  "Generate the site and commit everything."
  (interactive)
  (save-some-buffers) ;; avoid commiting emacs weird files
  (when (yes-or-no-p "This will commit changes, are you sure? ")
    (hugo-blog-run-command "--noChmod" "--noTimes --ignoreCache")
    (hugo-blog--commit-all)))

;;;###autoload
(defun hugo-blog-preview (arg)
  "Launches a preview HTTP server. If ARG is provided also render drafts."
  (interactive "P")
  (unless (process-status "hugo")
    (cd hugo-blog-project)
  (when arg
    (start-process "hugo" hugo-blog-process-buffer
                   hugo-blog-command "-D" "server"))
  (unless arg
    (start-process "hugo" hugo-blog-process-buffer
                   hugo-blog-command "server")))
  (sleep-for 5)
  (with-current-buffer hugo-blog-process-buffer
    (goto-char (point-max))
    (if (re-search-backward "http://localhost:[0-9]+/" nil t)
        (browse-url (match-string 0))
      (error "Error executing hugo"))))
```

[^1]: Los modos de son conjuntos de funcionalidades que extienden el
    editor en distintas maneras, muchos incluso hacen cambios en la
    forma en que interactuamos con Emacs

[^2]: Los comandos son funcionalidades específicas que no tienen por
    que estar relacionadas con ningún modo en particular.
