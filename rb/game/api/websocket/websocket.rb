require 'date'

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
      
      # Configurar websockets
      app.configure do
        app.set :sockets, []
      end

      # Acceso mediante método GET
      app.get '/dev/api/websocket' do
        content_type :json  # Tipo de respuesta: JSON.
        
        output = {
          metadata: { },
          response: {
            status: "ok",
            message: ""
          }
        }
        
        # Si la petición no es de un websocket, rechazar
        if !request.websocket?
          output[:response][:status]  = "error"
          output[:response][:message] = "Invalid request: Not a websocket request."
          
          return output
        else
          request.websocket do |ws|
            ws.onopen do
              ws.send("Hello World!")
              settings.sockets << ws
            end
            ws.onmessage do |msg|
              #EM.next_tick { settings.sockets.each{|s| s.send(msg) } }
            end
            ws.onclose do
              warn("websocket closed")
              settings.sockets.delete(ws)
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