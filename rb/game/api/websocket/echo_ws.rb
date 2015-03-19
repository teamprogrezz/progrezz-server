# encoding: UTF-8

module Sinatra
  module API
  module WebSocket
    
    class Methods

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
    end
    
    
  end
  end
end