# encoding: UTF-8

require './rb/game/api/json_response'

module Game
  module API
    # Módulo que contiene estructuras de datos referentes a la API de web sockets.
    module WebSocket
      # Clase gestora de los websockets.
      #
      # Se encarga de realizar tareas sencillas, como inicializar el acceso a los métodos
      # Web Sockets (Sinatra-websocket).
      class WebSocketManager
        
        # Añadir un socket a la lista.
        # @param ws [Object] Socket a añadir.
        def self.add_socket( ws )
          @@sockets << ws
          return nil
        end
        
        # Eliminar un socket a la lista.
        # @param ws [Object] Socket a eliminar.
        def self.remove_socket( ws )
          @@sockets.delete(ws)
          return nil
        end
        
        # Enviar un mensaje global.
        # Se enviará a los usuarios conectados vía websocket.
        # @param response [Hash] Respuesta o mensaje a enviar a los usuarios.
        def self.global_response( response )
          @@sockets.each do |ws|
            ws.send( response.to_json )
          end
          
          return nil
        end
        
        # Enviar mensaje a un socket.
        # @param ws [Object] Socket objetivo.
        # @param response [Hash] Mensaje a enviar al usuario.
        def self.send(ws, response)
          if @@sockets.include?(ws)
            ws.send( response.to_json )
          end
        end

        # Inicializa los websockets.
        #
        # Principalmente, carga todos los ficheros fuente (.rb) contenidos
        # en el directorio *game/api/websocket*.
        def self.setup()
          @@sockets = []
          GenericUtils.require_dir("./rb/game/api/websocket/**/*.rb", "Leyendo URIs de WebSocket: ")
        end
        
        # Comprobar si un usuario está autenticado para usar la API WebSocket.
        #
        # @return [Boolean] true si es posible, false en caso contrario.
        def self.auth?(session)
          return (Game::AuthManager.auth?(session) == true)
        end

      end

      #-- Lanzar el método setup #++
      WebSocketManager.setup()

    end

  end
end


