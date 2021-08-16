---
categories:
- ""
date: "2018-04-04T20:31:04-04:00"
description: Creando widgets para el backend de Odoo
draft: true
tags:
- odoo
- javascript
title: Creando widgets con Odoo (parte 2)
---

# Creando widgets con Odoo (parte 2)

En el [post anterior]({{<ref "creando-widgets-odoo.md">}}) hablamos de utilizar
**Javascript** para extender el cliente web (también conocido como *backend*) de
**Odoo** y adicionar un nuevo **widget** que mostrara un *slider* de **Bootstrap**.

Los *sliders* tienen su público, pero en general cuando extendemos un framework
lo hacemos para adicionar funcionalidades algo más complejas. Aunque consideré
hacer toda una serie acerca de como crear un nuevo tipo de vista, la realidad es
que suena más a libro **Programando con Odoo y Javascript** por eso en este
capítulo vamos a adicionar un nuevo botón a las vistas.

## ¿Para qué necesitas otro botón?

Por lo general vistas de **Odoo** tienen (al menos las que nos interesan) la
siguiente estructura:

{{< figure src="/images/creando-widgets-odoo/vistas-odoo.png" >}}

1. Un botón de acción principal (90% de las veces crea o salva registros).
2. Una acción secundaria.
3. Una lista con acciones extras (imprimir, duplicar, los *wizards*).
4. El formulario de búsqueda.
5. El contenido de la vista.
6. Paginación y botones para cambiar la vista.

Normalmente . ¿Qué tal si queremos sustituir la acción principal por otra?

## Modificando las plantillas

Como las vistas son *widgets*, modificarlas lleva

```xml
<t t-extend="ListView.buttons">
    <t t-jquery="button.o_list_button_add" t-operation="after">
        <button t-if="widget.model == 'rss.links" type="button"
            class="btn btn-sm btn-default o_button_new_func">
            Open feed
        </button>
        <button t-if="widget.model != 'g_contest.partner.group'"
              class="btn btn-primary btn-sm o_list_button_add"
              type="button">
              Create
              </button>
    </t>
</t>
```
