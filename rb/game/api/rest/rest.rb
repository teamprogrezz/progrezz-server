require 'date'

#:nodoc:
module Sinatra
  module API
  module REST
    module Methods
      # Redireccionar a página interactiva
      def test(app)
        app.redirect to("/dev/api/rest/interactive")
      end
      
      # ...
    end
    
    def self.registered(app)
       # Añadir "ayudas".
      app.helpers Methods
    
      app.before '/dev/api/rest' do
        # CORS para JSON
        # ...
      end
      
      # Acceso mediante método GET
      app.get '/dev/api/rest' do
        content_type :json
        
        metadata = { timestamp: DateTime.now.strftime('%Q') }
        request  = params
        response = { }
        
        pre_time = Time.now
         
        begin
          # Tipo de petición
          if request[:type] == nil
            raise "Invalid request type '" + request[:type].to_s + "'"
          else
            #send("Sinatra::")
          end
          
        rescue Exception => e 
          response = { type: "error", message: e.message }
        end
        
        # Calcular tiempo de cómputo
        metadata[:process_time] = (Time.now - pre_time) * 1000.0
        
        # Devolver respuesta como un json
        return {
          metadata: metadata,
          request:  request,
          response: response
        }.to_json
      end
      
      # Método POST no activado
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