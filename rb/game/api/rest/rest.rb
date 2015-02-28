require 'date'

#:nodoc:
module Sinatra
  module API
  module REST
    class Methods
      # Redireccionar a página interactiva
      def self.test(app)
        app.redirect to("/dev/api/rest/interactive")
      end
      
      # ...
    end
    
    def self.registered(app)
       # Añadir "ayudas".
      #app.helpers Methods
      
      # Clase contenedora de métodos
      methods = Methods.new()
    
      app.before '/dev/api/rest' do
        # CORS para habilitar peticiones JSON entre dominios.
        headers['Access-Control-Allow-Methods']     = 'GET' # , POST'
        headers['Access-Control-Allow-Origin']      = '*'
        headers['Access-Control-Allow-Headers']     = 'accept, authorization, origin, content-type'
        headers['Access-Control-Allow-Credentials'] = 'true'
      end
      
      # Acceso mediante método GET
      app.get '/dev/api/rest' do
        content_type :json
        
        metadata      = { timestamp: DateTime.now.strftime('%Q') }
        request       = params
        response_data = { }
        
        response = {
          metadata: metadata,
          request:  request,
          response: response_data
        }
        
        pre_time = Time.now
         
        begin
          # Tipo de petición
          method = request[:type].to_s
          
          if method == ""
            raise "Invalid request type '" + method + "'"
          else
            Methods.send( method, app, response )
          end
          
        rescue Exception => e 
          response_data[:type]   = "error"
          response_data[:messag] = e.message
        end
        
        # Calcular tiempo de cómputo
        metadata[:process_time] = (Time.now - pre_time) * 1000.0
        
        # Devolver respuesta como un json
        return response.to_json
      end
      
      # Método POST (no activado)
      # post '/dev/api/rest/user' { }
      
      # Peticiones REST interactivas
      app.get "/dev/api/rest/interactive" do
        erb :rest_interactive, :views => "views/api/"
      end
    end
  end
  end
  
  #-- Registrar rutas sinatra #++
  register API::REST
end

#-- Cargar en el servidor #++
class ProgrezzServer
  register Sinatra::API::REST
end