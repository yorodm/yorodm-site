---
categories:
- ""
date: "2017-12-04"
description: Algunos microframeworks en Java que deberías seguir
draft: false
tags:
- java
- microframeworks
title: Microframeworks en Java
comment: true

---

¡Hola! Después de unas semanas de inactivdad continúo con el tema de los
frameworks para microservicios, ahora con **Java** que es otro de mis lengajes
favoritos. Ya que todo el mundo conoce a los jugadores fuertes como
[Dropwizard](http://www.dropwizard.io ),
[Spring](https://projects.spring.io/spring-boot/) y [Swarm](wildfly-swarm.io/)
voy a hablar de los llamados "microframeworks".

## [Ratpack](http://www.ratpack.io )

En primer lugar tenemos [Ratpack](http://www.ratpack.io ), que nos brinda
basicamente un servidor Web basado en **Netty** y un *DSL* para manejar rutas
(muy a lo [Rack](http://rack.github.io )+ [Sinatra](http://sinatrarb.com/ )) y
una fuerte integración con [Groovy](http://groovy-lang.org/ ) . Como un plus
podemos utilizar [Lazybones](https://github.com/pledbrook/lazybones ) para
generar esqueletos de aplicaciones.

Aparte del *core* del framework, existen componentes para:

- Utilizar **Guice** como contenedor de inyección de dependencias.
- Métricas de uso.
- **Thymleaf** y **Handlebars** como motores de plantillas.
- [Consul](http://www.consul.io )
- **Spring Boot**
- Pruebas unitarias utilizando [Spock](http://spockframework.org/ )


## [Bootique](http://bootique.io )

**Bootique** nos invita a crear aplicaciones modulares utilizando **Guice**. A
diferencia de **Ratpack**, su estilo de programación es mas de utilizar
anotaciones aunque también hace uso de interfaces fluidas y clausuras. El uso de
**Guice** le da también un sabor particular a la forma en que creamos
aplicaciones o extendemos el framework. En fin, esta es la lista de
características fuertes de **Bootique**

- Soporte para migraciones con [Flyway](http://flyway.orge ) o
  [LiquidBase](http://www.liquibase.org/ ).
- Integración con otros frameworks vía **Guice**
- Métricas.
- **Swagger**
- Componentes para **Rabbitmq**
- Posibilidad de desarrollar utilizando [Kotlin](http://kotlinlang.org/ )

## [Rapidoid](http://www.rapidoid.org/ )

Como su nombre lo indica, **Rapidoid** se centra en la velocidad. Podemos crear
no solo microservicios sino aplicaciones completas en muy poco tiempo. De los
frameworks presentados acá es el único que incluye un componente para **UI** y
su propio motor de plantillas a lo **Mustache**. Cosas que me impresionaron:

- Interfaz de automática administración para las entidades a lo **Django** o
  **JHipster**.
- Motor de plantillas integrado.
- Soporte para **Guice**
- Rapidez + Funcionalidad

Como es el que más me gusta voy a poner un ejemplo de como crear una **Web API**
simple que nos permita adicionar, consultar y eliminar solicitudes de servicio
(lo que toda la vida hemos llamado tickets)

### Paso 1. Configurar Maven.

Como soy usuario de **Maven** y **Eclipse** me voy a crear un nuevo proyecto y
adicionar la siguiente dependencia

```xml
<dependency>
    <groupId>org.rapidoid</groupId>
    <artifactId>rapidoid-quick</artifactId>
    <version>5.4.6</version>
</dependency>
```

### Paso 2. Crear mis entidades.

**Rapidoid Quick** incluye **Hibernate**, **JPA** preconfigurados, así que no
necesitamos mucho para crear entidades

```java
package com.github.yorodm.rapidoid_example.models;

import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.Id;
import javax.validation.constraints.NotNull;

@Entity
public class Ticket {

    @Id
    @GeneratedValue
    public long id;

    @NotNull
    public String title;

    @NotNull
    public String description;
}
```

### Paso 3. Creando mi aplicación y rutas

```java
public class Main {

    public static void main(String[] args) {
        App.bootstrap(args).auth()
        .jpa()
        .adminCenter();

        On.get("/tickets").json(()
            -> JPA.of(Ticket.class).all());

        On.post("/tickets")
            .json((@Valid Ticket t)
                -> JPA.save(t));
        On.put("/tickets/{id}")
            .json((Long id, @Valid Ticket t)
                -> JPA.update(t));

        On.delete("/tickets/{id}")
            .json((Long id) -> {
                JPA.delete(Ticket.class, id);
                return true;
        });
    }

}
```

### Paso 4. Configurando.

Para la configuracion utilizamos **YAML** en `src/resources/config.yml`.

```yaml
users:
  root:
    roles:
      - administrator
      - owner
    password: root
```

### Paso 5. Creando un jar para despliegue.

Vamos a configurar el plugin `shade` de **Maven** para crear un *uberjar* y
hacernos la vida más fácil.

```xml

<build>
  <plugins>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-shade-plugin</artifactId>
      <version>3.1.0</version>
      <configuration>
        <transformers>
          <transformer
              implementation=
              "org.apache.maven.plugins.shade.resource.ManifestResourceTransformer">
            <mainClass>
                com.github.yorodm.rapidoid_example.Main
            </mainClass>
          </transformer>
        </transformers>
      </configuration>
      <executions>
        <execution>
          <phase>package</phase>
          <goals>
            <goal>shade</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
```

### Paso 6. Ejecutando la aplicación

Empaquetamos y ejecutamos:

```console
$ mvn package
$ cd target
$ java -jar rapidoid-example-0.0.1-SNAPSHOT.jar profiles=dev,default
```

Después de unos cuantos logs tenemos el servicio disponible en [nuestro
host](http://localhost:8080/tickets ) junto con el [dashboard de administración](http://localhost:8080/_).
