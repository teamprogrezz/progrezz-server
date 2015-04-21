# encoding: UTF-8

module Sinatra
  module API
  module REST
    class Methods
      # Redireccionar a página interactiva
      def self.test(app, response, session)
        app.redirect to("/dev/api/rest/interactive")
      end

      # Método de prueba (saludar al nombre "request.data.name" de la petición realizada).
      def self.echo(app, response, session)
        begin
          name = (response[:request][:request][:data][:name] || 'world').to_s
          
          Game::API::JSONResponse.ok_response!( response, {
            type: "plain",
            message: "Hello, " + name + "!"
          })
        rescue Exception => e
          raise ::GenericException.new( "Invalid request: " + e.message, e )
        end
      end

      # Método de prueba usando python (saludar al nombre "request.data.name" de la petición realizada).
      def self.echo_py(app, response, session)
        begin
          name = (response[:request][:request][:data][:name] || 'world').to_s
          
          input_json = '{"name": "' + name + '"}'
          
          Game::API::JSONResponse.ok_response!( response, {
            type: "plain",
            message: GenericUtils.run_py('scripts/python/echo.py', { "INPUT_JSON" => input_json })[:stdout] 
          })

        rescue Exception => e
          raise ::GenericException.new( "Invalid request: " + e.message, e)
        end

      end
      # ...
    end
  end
  end
end