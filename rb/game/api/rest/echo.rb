# encoding: UTF-8

module Sinatra
  module API
  module REST
    class Methods
      # Redireccionar a página interactiva
      def self.test(app, response)
        app.redirect to("/dev/api/rest/interactive")
      end

      # Método de prueba (saludar al nombre "request.data.name" de la petición realizada).
      def self.echo(app, response, session)
        begin
          if response[:request][:request][:data] == nil || response[:request][:request][:data][:name] == nil
            name = 'world'
          else
            name = response[:request][:request][:data][:name].to_s
          end
          
          Game::API::JSONResponse.ok_response!( response, {
            type: "plain",
            message: "Hello, " + name + "!"
          })
        rescue Exception => e
          raise "Invalid request: " + e.message
        end
      end

      # Método de prueba usando python (saludar al nombre "request.data.name" de la petición realizada).
      def self.echo_py(app, response, session)
        begin
          if response[:request][:request][:data] == nil || response[:request][:request][:data][:name] == nil
            name = 'world'
          else
            name = response[:request][:request][:data][:name].to_s
          end
          
          input_json = '{"name": "' + name + '"}'
          
          Game::API::JSONResponse.ok_response!( response, {
            type: "plain",
            message: GenericUtils.run_py('scripts/python/echo.py', { "INPUT_JSON" => input_json })[:stdout] 
          })

        rescue Exception => e
          raise "Invalid request: " + e.message
        end

      end
      # ...
    end
  end
  end
end