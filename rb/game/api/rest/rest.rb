require 'date'

#:nodoc:
module Sinatra
  module API
  module REST
    class Methods
      # Redireccionar a página interactiva
      def self.test(app, response, session)
        app.redirect to("/dev/api/rest/interactive")
      end
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
        content_type :json  # Tipo de respuesta: JSON.
        
        # Respuesta al usuario
        metadata      = { timestamp: DateTime.now.strftime('%Q'), process_time: 0 }
        request       = params
        response_data = { status: "ok", type: "json", data: { type: "" } }

        response = {
          metadata: metadata,
          request:  request,
          response: response_data
        }

        pre_time = Time.now

        begin
          # Activar gestor de transacciones.
          transaction = Game::Database::DatabaseManager.start_transaction()
          
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
          
          # Limpiar respuesta
          response_data.clear()

          # Y formatear error.
          response_data[:status]  = "error"
          response_data[:data]    = {
            error:      e.message,
            backtrace:  e.backtrace
          }
        ensure
          # Cerrar la transacción
          Game::Database::DatabaseManager.stop_transaction(transaction)
        end

        # Calcular tiempo de cómputo (en ms)
        metadata[:process_time] = (Time.now - pre_time) * 1000.0

        # Quitar la petición del usuario, ya que no es necesario reenviarla (ya está en el cliente).
        response.delete( :request )

        # Devolver respuesta como un json
        return response.to_json
      end

      # Método POST (no activado)
      # post '/dev/api/rest/user' { }

      # Peticiones REST interactivas
      app.get "/dev/api/rest/interactive" do
        erb :"api/rest_interactive"
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