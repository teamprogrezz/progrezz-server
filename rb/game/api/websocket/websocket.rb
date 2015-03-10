require 'date'
require 'sinatra-websocket'

module Sinatra

  module API
    
  # Módulo de la API WebSocket para hacer peticiones al servidor.
  module WebSocket
    
    # Clase contenedora de los métodos diversos de la API WebSocket.
    #
    # Los websockets se abrirán accediendo a la URI /dev/api/websocket
    # TODO: ...
    #
    # @see http://progrezz-server.heroku.com/dev/websocket
    class Methods
    end
    
    # Generar un error de respuesta.
    #
    # @param response [Hash] Hash de respuesta al usuario.
    # @param reason [String] Razón del error en sí (e.j. 'Me caes mal').
    def self.error_request(response, reason)
      response[:response][:status]  = "error"
      response[:response][:message] = reason
    end
    
    # Generar una respuesta.
    #
    # @param response [Hash] Hash de respuesta al usuario.
    # @param data [Hash] Estructura de datos a enviar al usuario.
    def self.ok_request(response, data)
      response[:response][:status]  = "ok"
      response[:response][:data]    = data
    end

    # Registrar yconfigurar la API WebSocket.
    #
    # Se registrarán todos los métodos incluídos
    # en el módulo Sinatra::API::WebSocket::Methods.
    #
    # @param app [Sinatra::Application] Aplicación sinatra.
    def self.registered(app)
      # Clase contenedora de métodos
      methods = Sinatra::API::WebSocket::Methods.new()
      
      # Acceso mediante método GET
      app.get '/dev/api/websocket' do
        content_type :json  # Tipo de respuesta: JSON.
        
        output = {
          metadata: { },
          response: {
            status: "ok"
            # 'message: ""' o 'data: {}'
          }
        }
        
        ws_manager = Game::API::WebSocket::WebSocketManager
        
        # Si la petición no es de un websocket, rechazar
        if !request.websocket?
          error_request(output, "Invalid request: Not a websocket request.")
          
          return output
        else
          request.websocket do |ws|
            # Petición de apertura.
            ws.onopen do
              # Si no está autenticado, rechazar.
              if ws_manager.auth?(session) == true
                ok_request( output, {type: "plain", message: "Connection established."} )
                
                ws_manager.add_socket(ws)
                ws_manager.send(ws, output)
              else
                error_request(output, "Invalid request: Not a websocket request.")
                
                ws.send("You are not authenticated.")
                ws.close_websocket()
              end
            end
            
            # Petición de mensaje.
            ws.onmessage do |msg|
              # Procesar respuesta
              # ...
              
              ws_manager.send(ws, response)
            end
            
            # Petición de cierre.
            ws.onclose do
              ws_manager.remove_socket(ws)
            end
          end
        end
      end

      # Método POST (no activado)
      # post '/dev/api/rest/user' { }

      # Peticiones REST interactivas
      app.get "/dev/websocket" do
        # Parsear métodos REST
        class << app
          attr_accessor :websocket_methods
        end
        
        if app.websocket_methods == nil
          # TODO: ...
          app.websocket_methods = JSON.parse( File.read('data/websocket_methods.json') )
        end
        
        erb :"dev/websocket", :locals => {
          :session => session,
          :websocket_methods => app.websocket_methods
        }, :layout => :"dev/layout"
      end
    end
  end
  end

  #-- Registrar rutas sinatra #++
  register API::WebSocket
end

class Sinatra::ProgrezzServer
  register Sinatra::API::WebSocket
end
#-- Cargar en el servidor #++