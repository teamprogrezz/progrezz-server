# encoding: UTF-8

module Game
  module API
    # Módulo que contiene estructuras de datos referentes a la API de web sockets.
    module WebSocket
      # Clase gestora de los websockets.
      #
      # Se encarga de realizar tareas sencillas, como inicializar el acceso a los métodos
      # Web Sockets (Sinatra-websocket).
      class WebSocketManager

        # Inicializa los websockets.
        #
        # Principalmente, carga todos los ficheros fuente (.rb) contenidos
        # en el directorio *game/api/websocket*.
        def self.setup()
          GenericUtils.require_dir("./rb/game/api/websocket/**/*.rb", "Leyendo URIs de WebSocket: ")
        end

      end

      #-- Lanzar el método setup #++
      WebSocketManager.setup()

    end

  end
end


