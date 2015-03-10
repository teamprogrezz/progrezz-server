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
        
        ws_manager    = Game::API::WebSocket::WebSocketManager

        # Si la petición no es de un websocket, rechazar
        if !request.websocket?
          output = Game::API::JSONResponse.get_template()
          Game::API::JSONResponse.error_response!(output, "Invalid request: Not a websocket request.")
          
          return output
        else
          request.websocket do |ws|
            # Petición de apertura.
            ws.onopen do
              output = Game::API::JSONResponse.get_template()
              
              # Si no está autenticado, rechazar.
              if ws_manager.auth?(session) == true
                Game::API::JSONResponse.ok_response!( output, {type: "plain", message: "Connection established."} )
                
                ws_manager.add_socket(ws)
                ws_manager.send(ws, output)
              else
                Game::API::JSONResponse.error_response!(output, "Invalid request: You are not authenticated.")
                
                ws_manager.send(ws, output)
                ws.close_websocket()
              end
            end
            
            # Petición de mensaje.
            ws.onmessage do |msg|
              # Generar plantilla de respuesta
              output = Game::API::JSONResponse.get_template()
              
              # Si deja de estar autenticado, cerrar socket.
              # ...
              
              # Procesar respuesta
              # ...
              
              # Y Enviar mensaje
              ws_manager.send(ws, output)
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