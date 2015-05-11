# Servidor del proyecto PROGREZZ #

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE.txt)  [![Build Status](https://travis-ci.org/teamprogrezz/progrezz-server.svg)](https://travis-ci.org/teamprogrezz/progrezz-server)

## 1. Introducción ##
El servidor de Progrezz permite centralizar y procesar todos los datos referentes a los usuarios o jugadores del mismo.

Para evitar sobrecarga en los dispositivos y erradicar comportamientos no deseados en los jugadores (trampas, lenguaje ofensivo, ...), se ha tomado la decisión de gestionar el mayor número de tareas posible, permitiendo al usuario realizar tareas tan sencillas como dibujar en pantalla el contenido solicitado al servidor.

Para una mayor modularidad, se utilizará Ruby Sinatra sobre el servidor Thin, usando una base de datos neo4j.

## 2. Acceso al servidor ##
Actualmente, el servidor está hosteado en los siguientes servidores o servicios:

- Heroku: http://progrezz-server.herokuapp.com/

## 3. Dependencias ##
### 3.1. Ruby  ###
Las dependecias de ruby se pueden encontrar en el Gemfile del repositorio. Pueden ser instaladas cómodamente con ```bundle```, tal como se muestra en los apartados de **Uso**.

### 3.2. Base de datos ###
Será necesario un servidor funcional [neo4j](http://neo4j.com), junto son su dirección de acceso en una de las siguientes variables de entorno:

- PROGREZZ_NEO4J_URL
- GRAPHENDB_URL

Deben tener el siguiente formato URI:

``` http://<usuario>:<password>@<dominio-servidor>:<puerto>/db/data/ ```

También se intentará buscar como último remedio en el host *http:localhost:7474* (sin credenciales de acceso).

### 3.3. Servicio de rutas ###
Por defecto, el servidor usará un servidor [OSRM](https://github.com/Project-OSRM/osrm-backend) para realizar las peticiones (por ejemplo, a ```http://localhost:5000/nearest?loc=26.08,-16.5```). Para utilizar está función, se debe definir la dirección del servidor en la variable de entorno ```progrezz_matching_osrm``` con la url del servidor (para el caso de anterior, ```http://localhost:5000```).

**Nota:** Se recomienda encarecidamente usar un servidor propio OSRM para resolver este tipo de peticiones.

En caso de no encontrar un servidor OSRM, se utilizará la [API de MapQuest Directions](http://developer.mapquest.com/web/products/dev-services/directions-ws) para ajustar geolocalizaciones a la carretera más próxima. Para ello, se debe definir la variable de entorno ```progrezz_mapquest_key``` con la APPKey de MapQuest.

También se puede deshabilitar el servicio de rutas usando la variable de entorno ```progrezz_disable_routing``` a ```true```.

## 4. Instalación ##

Descargue el código fuente de este repositorio:

```sh
$ git clone https://github.com/teamprogrezz/progrezz-server
```

E inicie todos los submódulos del repositorio:

```sh
$ cd progrezz-server
$ git submodule update --init --recursive
```

Véase el apartado **5. Uso (vía docker)** o **6. Uso (sin docker)** para saber como ejecutar el servidor

## 5. Uso (vía [docker](https://www.docker.com/ "https://www.docker.com/")) ##
Con la finalidad de hacer facilmente *portable* el servidor, se ha decidido hacer que éste sea compatible con docker, siendo completamente opcional su uso. Para ello, hace falta recalcar algunos puntos:

### 5.1. Variables de entorno ###
Las variables de entorno pueden ser cargadas también desde el fichero *data/envs.json*. Está estructurado en un *.json* de manera clara:

```json
{
  "env_key":         "env_key_value",
  "progrezz_secret": "my_super_secret",
  "...":             "..."
}
```

Nótese que el contenido de estas sobrescribirá a las variables de entorno del sistema.

### 5.2. Docker ###
Para usar *docker*, el usuario deberá tener instalado la herramienta, y deberá ser accesible por el usuario actual sin necesidad de usar el prefijo ```sudo```.

**IMPORTANTE:** No modifique  el fichero *Dockerfile* a menos que sepa lo que está haciendo.

#### A. Contenedor neo4j ####
Si utiliza docker, es conveniente usar un contenedor para encapsular la base de datos neo4j requerida por el back-end de progrezz.

Para ello, use el comando siguiente:
```sh
$ rake docker:neo4j:setup # Call this only once!!
...
$ rake docker:neo4j:start
...
$ rake docker:neo4j:stop
...
```

El servidor deberá ser accesible desde el host (linux) por medio de la dirección ````http://localhost:7474````. En caso de usar otro sistema operativo que utilice la herramienta *boot2docker*, deberá acceder a la *ip* de la máquina virtual. Dicha *ip* puede obtenerse con el comando siguiente:

````sh
$ boot2docker ip
````

Una vez tenga la dirección *ip*, tal vez deba modificar la redirección de puertos de la máquina virtual (desde *VirtualBox*) para poder acceder al servicio de neo4j desde su explorador.

Si desea usar otro puerto, modifique el fichero *rakefile* de manera oportuna, o ejecute el comando:

```sh
$ docker run -i -t -d --name neo4j --cap-add=SYS_RESOURCE -p 7474:<PUERTO_AQUÍ> tpires/neo4j
```

Asegúrese de configurar correctamente la variable ````PROGREZZ_NEO4J_URL```` (a un valor parecido a ````http://<usuario neo4j>:<password neo4j>@neo4j:7474/db/data/````) para que el contenedor de progrezz pueda acceder a la base de datos.

**Nota:** Si prefiere ejecutar un servidor de neo4j externo (que no sea un contenedor) y un servidor docker de progrezz, deberá inicializar progrezz sin linkear al contenedor de neo4j, de la siguiente manera:

```sh
$ rake docker:progrezz:setup["osrm"] # Sin neo4j
```

ó

```sh
$ rake docker:progrezz:setup[] # Si ningún contenedor
```

#### B. OSRM (opcional) ####
Tal como se especifica en el apartado *3.3. Servicio de rutas*, el servicio de rutas es meramente opcional. Si se desea, se puede instalar un contenedor con el servidor de rutas dentro.

Para ello, se recomienda leer el siguiente enlace sobre la instalación del contenedor:

- https://registry.hub.docker.com/u/xcgd/osrm-backend/

Una vez instalado, se puede acceder a su ejecución mediante el comando rake siguiente:

**Nota:** Si prefiere ejecutar un servidor de osrm externo (o no ejecutarlo) y un servidor docker de progrezz, deberá inicializar progrezz sin linkear al contenedor de osrm, de la siguiente manera:

```sh
$ rake docker:progrezz:setup["neo4j"] # Sin osrm
```

ó

```sh
$ rake docker:progrezz:setup[] # Si ningún contenedor
```

#### C. Progrezz back-end ####

Con el fin de facilitar su instalación y uso, se han creado una serie de tareas *rake* para realizar tanto la instalación de la imagen como la ejecución del mismo.

Instalar la imagen:
```sh
$ rake docker:progrezz:setup["neo4j osrm_server"]
```

Hay que ajustar la configuración inicial para ejecutar un comando personalizo:

```sh
$ rake docker:progrezz:setup["neo4j osrm_server","rake development:start"]
```

Ejecutar un comando rake de la imagen:
```sh
$ rake docker:progrezz:start
```

Puede terminar el proceso (si se está ejecutando de fondo) con el comando:
```sh
$ rake docker:progrezz:stop
```

Si cambia un fichero, deberá reconstruirse el contenedor de docker con el comando

```sh
$ rake docker:progrezz:build
```

En caso de no disponer de *rake*, use los comandos correspondientes:

```sh
$ docker build -t progrezz/server .
$ docker run -i -t --net host progrezz/server
...
```

Use el comando ```$ rake -T docker``` para ver todos los comandos disponibles.


## 6.  Uso (sin docker) ##
### 6.1. Instalación ###
Una vez instalada e iniciada la base de datos, se puede preparar el servidor con el siguiente comando, desde la carpeta raíz del proyecto:

```sh
$ rake setup
```

### 6.2. Ejecución ###

El servidor puede ser iniciado en modo prueba con

```sh
$ rake development
```

Para iniciar en modo producción, use
```sh
$ rake production
```

Para subir el proyecto a heroku, teniendo definida el repositorio remoto ```heroku```,  utilice

```sh
$ rake heroku
```

### 6.3. Otros ###

Para generar la documentación, use

```sh
$ rake doc
```

Para utilizar la consola interactiva de *pry*, se debe definir la variable de entorno ```progrezz_interactive_shell``` a ```true```.

Se activará automáticamente cuando se ejecute el proyecto en modo *development*, y se ejecutará de manera asíncrona con respecto a la aplicación principal, por lo que no bloqueará el acceso a los sitios web.

Un ejemplo de ejecución podría ser el siguiente:

```sh
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
[2] pry(main)> exit()
--------------------------------------
**        Forced saving DB          **
--------------------------------------
Progrezz server ended. Crowd applause.
```

## 7. Contacto ##
Envíe cualquier duda, comentario u opinión a cualquier correo de la siguiente lista:

- Proyecto progrezz: [proyecto.progrezz@gmail.com](mailto:proyecto.progrezz@gmail.com)

## 8. Agradecimientos / Referencias ##
- <p>Directions Courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png"></p>
