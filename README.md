# Servidor proyecto PROGREZZ #

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)  [![Build Status](https://travis-ci.org/teamprogrezz/progrezz-server.svg)](https://travis-ci.org/teamprogrezz/progrezz-server)

## 1. Introducción ##
El servidor de Progrezz permite centralizar y procesar todos los datos referentes a los usuarios o jugadores del mismo.

Para evitar sobrecarga en los dispositivos y erradicar comportamientos no deseados en los jugadores (trampas, lenguaje ofensivo, ...), se ha tomado la decisión de gestionar el mayor número de tareas posible, permitiendo al usuario realizar tareas tan sencillas como dibujar en pantalla el contenido solicitado al servidor.

Para una mayor modularidad, se utilizará Ruby Sinatra sobre el servidor Thin, usando una base de datos neo4j.

## 2. Acceso al servidor ##
Actualmente, el servidor está hosteado en los siguientes servidores o servicios:

- Heroku: http://progrezz-server.herokuapp.com/

## 3. Dependencias ##
#### Ruby  ####
Las dependecias de ruby se pueden encontrar en el Gemfile del repositorio. Pueden ser instaladas cómodamente con ```bundle```, tal como se muestra en el punto **6. Uso**.

#### Base de datos ####
Será necesario un servidor funcional [neo4j](http://neo4j.com), junto son su dirección de acceso en una de las siguientes variables de entorno:

- PROGREZZ_NEO4J_URL
- GRAPHENDB_URL

Deben tener el siguiente formato URI:

``` http://<usuario>:<password>@<dominio-servidor>:<puerto>/db/data/ ```

También se intentará buscar como último remedio en el host *http:localhost:7474* (sin credenciales de acceso).

#### Servicio de rutas ####
Por defecto, el servidor usará un servidor [OSRM](https://github.com/Project-OSRM/osrm-backend) para realizar las peticiones (por ejemplo, a ```http://localhost:5000/nearest?loc=26.08,-16.5```). Para utilizar está función, se debe definir la dirección del servidor en la variable de entorno ```progrezz_matching_osrm``` con la url del servidor (para el caso de anterior, ```http://localhost:5000```).

**Nota:** Se recomienda encarecidamente usar un servidor propio OSRM para resolver este tipo de peticiones.

En caso de no encontrar un servidor OSRM, se utilizará la [API de MapQuest Directions](http://developer.mapquest.com/web/products/dev-services/directions-ws) para ajustar geolocalizaciones a la carretera más próxima. Para ello, se debe definir la variable de entorno ```progrezz_mapquest_key``` con la APPKey de MapQuest.

También se puede deshabilitar el servicio de rutas usando la variable de entorno ```progrezz_disable_routing``` a ```true```.

## 4.  Uso ##
#### Instalación ####
Una vez instalada e iniciada la base de datos, se puede preparar el servidor con el siguiente comando, desde la carpeta raíz del proyecto:

```
$ rake setup
```

#### Ejecución ####

El servidor puede ser iniciado en modo prueba con

```
$ rake development
```

Para iniciar en modo producción, use
```
$ rake production
```

Para subir el proyecto a heroku, teniendo definida el repositorio remoto ```heroku```,  utilice

```
$ rake heroku
```

#### Otros ####

Para generar la documentación, use

```
$ rake doc
```

Para utilizar la consola interactiva de *pry*, se debe definir la variable de entorno ```progrezz_interactive_shell``` a ```true```.

Se activará automáticamente cuando se ejecute el proyecto en modo *development*, y se ejecutará de manera asíncrona con respecto a la aplicación principal, por lo que no bloqueará el acceso a los sitios web.

Un ejemplo de ejecución podría ser el siguiente:

```ruby
Thin web server (v1.6.3 codename Protein Powder)
Maximum connections set to 1024
Listening on localhost:9292, CTRL+C to stop

From: /home/daniel/Dev/Proyectos/Progrezz/progrezz-server/main.rb @ line 131 :

    126: 
    127: # Ejecutar una terminal (si procede)
    128: if development? && ENV['progrezz_interactive_shell'] == "true"
    129: 
    130:   Thread.new do |t|
 => 131:     binding.pry
    132:     exit()
    133:   end
    134: end
    135: 

[1] pry(main)> Game::Database::User.all.each {|u| puts u.alias }
Wikiti
... 
=> [ ... ]
```

Para cerrar la terminar y la aplicación, basta con ejecutar el comando ```exit```:

```ruby
... 
[2] pry(main)> exit()
--------------------------------------
**        Forced saving DB          **
--------------------------------------
Progrezz server ended. Crowd applause.
```

## 5. Contacto ##
Envíe cualquier duda, comentario u opinión a cualquier correo de la siguiente lista:

- Proyecto progrezz: [proyecto.progrezz@gmail.com](mailto:proyecto.progrezz@gmail.com)

## 6. Agradecimientos / Referencias ##
- <p>Directions Courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png"></p>
