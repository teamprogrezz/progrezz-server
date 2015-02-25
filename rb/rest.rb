# encoding: UTF-8

module Game
  # Módulo que contiene estructuras de datos referentes a la API de acceso.
  module API
    # Módulo que contiene estructuras de datos referentes a la API REST de acceso.
    module REST
      # Clase gestora de la API REST.
      #
      # Se encarga de realizar tareas sencillas, como inicializar el acceso a los métodos
      # REST HTML (Sinatra).
      class RESTManager

        # Inicializa la API REST.
        #
        # Principalmente, carga todos los ficheros fuente (.rb) contenidos
        # en el directorio *game/api/rest*.
        def self.setup()
          #-- Metodos HTTP (GET y POST) de la API REST #++
          GenericUtils.require_dir("./rb/game/**/*.rb", "Leyendo URIs: ")
        end

      end

      #-- Lanzar el método setup #++
      RESTManager.setup()

    end

  end
end


