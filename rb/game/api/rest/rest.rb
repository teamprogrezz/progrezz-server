require 'date'

module Sinatra
  
  # Módulo de la API para acceder al servidor.
  module API
    
  # Módulo de la API REST para hacer peticiones http al servidor.
  module REST
    
    # Clase contenedora de los métodos diversos de la API REST.
    #
    # Las peticiones REST se caracterizan por enviar como petición un objeto
    # JSON, y recibir una respuesta de tipo JSON también.
    #
    # Las peticiones a la API REST se harán por medio de la ruta +/dev/api/rest+.
    #
    # Cada método debe tener un nombre *único*. Todos los métodos REST tendrán
    # los mismos parámetros:
    # - app: Referencia a la aplicación sinatra.
    # - response: Referencia a la respuesta JSON proporcionada por el servidor.
    # - session: Objeto de la sesión sinatra actual.
    #
    # @see http://progrezz-server.heroku.com/dev/rest
    class Methods
      
      # Redireccionar a página interactiva.
      def self.test(app, response, session)
        app.redirect to("/dev/rest")
      end
    end

    # Registrar métodos de la API REST.
    #
    # Se registrarán todos los métodos incluídos
    # en el módulo Sinatra::API::REST::Methods.
    #
    # @param app [Sinatra::Application] Aplicación sinatra.
    def self.registered(app)
      # Clase contenedora de métodos
      methods = Methods.new()
      
      # Habilitar CORS para realizar peticiones desde cualquier dominio.
      app.before '/dev/api/rest' do
        # CORS para habilitar peticiones JSON entre dominios.
        headers['Access-Control-Allow-Methods']     = 'GET' # , POST'
        headers['Access-Control-Allow-Origin']      = '*'
        headers['Access-Control-Allow-Headers']     = 'accept, authorization, origin, content-type'
        headers['Access-Control-Allow-Credentials'] = 'true'
      end

      # Acceso mediante método GET
      app.get '/dev/api/rest' do
        content_type :json  # Tipo de respuesta: JSON.
        
        # Simbolizar claves de los parámetros
        GenericUtils.symbolize_keys_deep!(params)
        
        # Respuesta al usuario
        response = Game::API::JSONResponse.get_template()
        request = params
        response[:request] = request

        # Activar gestor de transacciones.
        transaction = Game::Database::DatabaseManager.start_transaction()
        begin  
          # Tipo de petición
          method = request[:request][:type].to_s

          if method == ""
            raise "Invalid request type '" + method + "'"
          else
            Methods.send( method, app, response, session )
          end

        rescue Exception => e  
          # Deshacer transacción.
          Game::Database::DatabaseManager.rollback_transaction(transaction)
          
          # Generar error
          Game::API::JSONResponse.error_response!( response, e.message )
          
          # Añadir parámetros adicionales
          response[:response][:backtrace] = e.backtrace

        ensure
          # Cerrar la transacción
          Game::Database::DatabaseManager.stop_transaction(transaction)
        end

        # Calcular tiempo de cómputo (en ms)
        Game::API::JSONResponse.stop_timer!(response)

        # Quitar la petición del usuario, ya que no es necesario reenviarla (ya está en el cliente).
        response.delete( :request )

        # Devolver respuesta como un json
        return response.to_json
      end

      # Método POST (no activado)
      # post '/dev/api/rest/user' { }

      # Peticiones REST interactivas
      app.get "/dev/rest" do
        # Parsear métodos REST
        class << app
          attr_accessor :rest_methods
        end
        
        if app.rest_methods == nil
          app.rest_methods = JSON.parse( File.read('data/rest_methods.json') )
        end
        
        erb :"dev/rest", :locals => {
          :session => session,
          :rest_methods => app.rest_methods
        }, :layout => :"dev/layout"
      end
    end
  end
  end

  #-- Registrar rutas sinatra #++
  register API::REST
end

class Sinatra::ProgrezzServer
  register Sinatra::API::REST
end
#-- Cargar en el servidor #++