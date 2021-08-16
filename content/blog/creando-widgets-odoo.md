---
categories:
- ""
date: "2018-01-22"
description: Creando nuevos widgets para el backend de Odoo
draft: false
tags:
- javascript
- odoo
title: Creando widgets para Odoo (Parte 1)
comment: true

---

# Creando widgets para Odoo (Parte 1).

Después de semanas de inactividad regreso con una de [Odoo 10]
(http://www.odoo.com), como ya hay bastantes sitios por ahí dedicados a explicar
causas y razones de lo que se puede hacer con **Python** desde el *backend* voy
a centrarme en el trabajo con **Javascript** y el *frontend*.

En este artículo vamos a crear un nuevo *widget* para manejar campos enteros y
de coma flotante en la vista (la parte V de MV*). Aunque pueda parecer un
ejemplo simple, surgió de la necesidad real de proveer campos numéricos limitados
en un rango de una forma explicita, sencilla y agradable para el usuario.

## Comenzando el proyecto.

Para poder reutilizar el *widget*, vamos a crear un *addon* que contenga las
bibliotecas y el código necesario para hacerlo funcionar. Empecemos creando el
esqueleto del módulo:

```console
$ odoo-bin scaffold widget-slider
```

Añadimos la descripción del *addon*, lo definimos como instalable, ponemos una
categoría válida e incluimos **web* como dependencia. Continuando.

## Bibliotecas externas

Nuestro *widget* tiene una sola dependencia externa: [Bootstrap Slider]
(https://github.com/seiyria/bootstrap-slider/). Normalmente utilizaríamos
**Bower** o **NPM** para manejar las dependencias de proyectos **Javascript**,
pero para algo tan pequeño no es necesario, basta con descargar el *release* de
la biblioteca y los archivos para *static/lib*.

Para hacer estos archivos disponibles en el *backend* extenderemos la plantilla
*web.assets_backend*. Modifiquemos el archivo autogenerado *templates.xml*

```xml
   <template id="assets_backend"
       name="web_widget_slider_assets"
       inherit_id="web.assets_backend">
        <xpath expr="." position="inside">
            <link rel="stylesheet"
                href="/widget-slider/static/lib/css/bootstrap-slider.css"/>
            <script type="text/javascript"
                src="/widget-slider/static/lib/js/bootstrap-slider.js"/>
        </xpath>
    </template>
```

## Javascript dentro de Odoo (para novatos).

Ya tenemos lo necesario para comenzar con nuestro *widget* ahora solo queda
escribir el código necesario para inicializar el plugin.

Lo primero que debes saber para trabajar con **Javascript** en **Odoo** es que a
la versión 10 utiliza un concepto de módulos muy parecido a **requirejs**.
Supongamos que tenemos un módulo *validar* donde incluimos utilitarios para el
resto de nuestros *addons* y ahí exportamos una función *check_int*.

```js
odoo.define('validar.enteros, function(require){
    "use strict";

    var check_int = function(val){
        if(!Number.isInteger(val)){
            throw new TypeError("El valor no es entero");
        }
        else {
            return val;
        }
    };
    return {
        check_int: check_int
    };
});
```

En otro *addon* (o simplemente otro módulo) tendríamos algo parecido a:

```js
odoo.define(otro_addon.otro_servicio', function(require){

    valida_enteros = require('web_validar.enteros').check_int;
    // Resto del código
});
```

Si eres más de *backend* piensa en todo esto como:

1. Una versíon **Javascript** de *self.env["modelo"]*
2. Una forma fiable de declarar dependencias sin importar el orden en que
   carguen los archivos.

La desventaja de este sistema es que es la única forma de acceder a los
componentes que brinda el *framework*, lo que lleva a muchas veces tener que
crear *wrappers* aún alrededor de funcionalidades sencillas.

## Clases, herencia, widgets

Otro punto a tener en cuenta es la programación orientada a objetos. Conceptos
tan familiares como clases, objetos y herencia tienen un enfoque "alternativo"
en **Javascript**. Los desarrolladores de **Odoo** siguieron la idea de
**BackboneJS** de implementar el modelo de [herencia de John Resig]
(http://ejohn.org/)

1. Las clases se definen heredando de *Class* o de alguna de sus hijas.
2. *extend()* se utiliza para heredar de una clase, como parámetro acepta
   objetos (o diccionarios que es lo mismo).
2. *init()* actúa como constructor.
3. *include()* permite modificar clases (a lo *monkey patch*)
4. Cuando utilizamos *extend()* o *include()*, cada método que se redefina puede
   utilizar *this._super()* para acceder a la implementación original.

Tomando un ejemplo del código de Odoo
```js
// Definimos una clase Person
 var Person = Class.extend({
  init: function(isDancing){
     this.dancing = isDancing;
    },
  dance: function(){
     return this.dancing;
    }
 });

// Y ahora una clase Ninja
 var Ninja = Person.extend({
  init: function(){
    this._super(false);
  },
  swingSword: function(){
    return true;
  }
 });
```
Siguiendo este modelo, cada *widget* es una clase que hereda de *web.Widget*
y algún que otro *mixin*.

## Creando un slider para valores enteros.

En vez de crear nuestro *slider* desde el inicio, aprovechemos que existe una
clase encargada de manejar campos numéricos y heredemos de ella. Creemos el
archivo *static/src/js/widget_slider.js* con el siguiente contenido.

```js
odoo.define('web_slider.form', function(require){
    "use strict";

    var core = require('web.core');
    var FieldFloat = require('web.form_widgets').FieldFloat;

    // Heredamos de esta clase para aprovechar toda la
    // maquinaria de inicialización.
    var FieldSlider = FieldFloat.extend({
        // Método que se invoca cuando se va a mostrar
        // el widget
        initialize_content: function(){
            this._super();
            this.wrapped = this.$el.slider(this.options);
            // Desabilitar el slider si está en modo
            // solo lectura
            if (this.get("effective_readonly")){
                this.wrapped.slider("disable");
            }
        },

    });
    // Registramos nuestro widget como disponible para
    // las vistas de formulario
    core.form_widget_registry
        .add('slider', FieldSlider);
    return {
        FieldSlider : FieldSlider
    };
});
```

Ahora modifiquemos nuestra plantilla de *assets* para que cargue este archivo.

```xml
<script type="text/javascript"
                src="/widget-slider/static/src/js/widget-slider.js"/>
```

Instalemos el addon, activemos el modo desarrollador y probemos cambiar
cualquier campo de una vista formulario añadiendo *widget=slider* a la
declaración.

## Resumiendo.

Crear un nuevo *widget* no es un proceso complejo, cada componente del
*framework* está diseñado de modo en que extender, modificar o añadir
funcionalidades sea un proceso sencillo para cualquiera con conocimientos de
**Javascript**.

Dicho esto, a pesar de que existe [una guía oficial]
(http://www.odoo.com/documentation/10.0/index.html), no es para nada completa y
en la mayoría de los casos la única solución a la pregunta "qué es lo que hace
esto" es recurrir al código fuente del hasta dar con lo que buscamos.
