+++
title = "Scrapper para DEV desde Emacs"
date = 2018-11-20T17:28:59-05:00
tags = ["emacs","scrapper"]
categories = [""]
draft = false
description = "Construyendo un web scrapper en Emacs Lisp"
+++

# Scrapper para DEV desde Emacs.

Recién publiqué en
[DEV](https://dev.to/yorodm/scrapping-dev-with-common-lisp-6j0) un artículo
acerca de como hacer un [scrapper](https://es.wikipedia.org/wiki/Web_scraping)
para obtener los títulos del [feed principal](https://dev.to). El artículo
surgió de una discusión amistosa acerca de la relevancia de Common Lisp como
tecnología en la actualidad y quedé muy satisfecho con el resultado.

Me llamó tanto la atención la simpleza detrás de las bibliotecas utilizadas que
decidí ver si había una para Emacs Lisp y... TL;DR, aquí está el scrapper 😍.


```elisp
;;; Eval this in the scratch buffer, first make sure to get
;;; `elquery' from MELPA.
;;; Eval this in a buffer and get the headlines in *another* buffer
;;; named *dev*
(require 'elquery)
(let ((dev-buffer (generate-new-buffer "*dev*")))
  (with-current-buffer (url-retrieve-synchronously "https://dev.to")
    ;; Feel free to hate this
    (dolist (elt (mapcar 'elquery-text (elquery-$ "div.single-article h3"
                                                  (elquery-read-string (buffer-string)))))
      (with-current-buffer dev-buffer (insert (concat elt "\n"))))))
```
