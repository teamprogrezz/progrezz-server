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
        
        # Forzar el cierre de un websocket si el usuario ya no está autenticado.
        # @param session [Hash] Sesión Ruby-sinatra actual.
        # @param ws [Object] Socket a cerrar.
        # @return [Boolean] True si la sesión sigue activa. False si se ha cerrado.
        def self.force_close_if_no_auth(session, ws)
          if auth?(session) == false
            force_close(session, ws, "Invalid request: You are no longer authenticated.")
            return false
          else
            return true
          end
        end
        
        # Forzar el cierre de un websocket.
        # @param session [Object] Sessión sinatra.
        # @param ws [Object] Socket a cerrar.
        # @param reason [String] Razón del cierre.
        def self.force_close(session, ws, reason)
          output = Game::API::JSONResponse.get_template()
          Game::API::JSONResponse.error_response!(output, reason)
          
          send(ws, output)
          ws.close_websocket()
          close(session, ws)
        end
        
        # Cerrar socket.
        # @param session [Object] Sessión sinatra.
        # @param ws [Object] Websocket.
        def self.close(session, ws)
          begin
            Game::Database::User.search_user(session['user_id']).online(false)
          rescue
          end
          self.remove_socket(ws)
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
          GenericUtils.require_dir("./rb/game/api/websocket/**/*.rb", "Leyendo URIs de WebSocket:  ")
        end
        
        # Comprobar si un usuario está autenticado para usar la API WebSocket.
        #
        # @return [Boolean] true si es posible, false en caso contrario.
        def self.auth?(session)
          return (Game::AuthManager.auth?(session) == true)
        end
        
        # Autorizar al usuario el acceso.
        #
        # Si está autenticado, se permitirá el acceso, y se añadirá a la lista de sockets actuales.
        # Si no, se enviará un mensaje de error.
        #
        # @param session [Hash] Sesión Ruby-sinatra actual.
        # @param ws [Object] Socket del usuario.
        def self.auth_user(session, ws)
          output = Game::API::JSONResponse.get_template()
          
          if auth?(session) == true
            Game::API::JSONResponse.ok_response!( output, {type: "plain", message: "Connection established."} )
            output[:metadata][:type] = "system"
            
            if !(ENV['users_auth_disabled'] == "true")
              puts "Warning! User auth disabled."
              Game::Database::User.search_user(session['user_id']).online(true)
            end
            
            add_socket(ws)
            send(ws, output)
          else
            Game::API::JSONResponse.error_response!(output, "Invalid request: You are not authenticated.")
            output[:metadata][:type] = "system"
            
            add_socket(ws)
            send(ws, output)
            remove_socket(ws)
            ws.close_websocket()
          end
          
        end

      end

      #-- Lanzar el método setup #++
      WebSocketManager.setup()

    end

  end
end


