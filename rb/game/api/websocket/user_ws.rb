
module Sinatra
  module API
  module WebSocket
    class Methods

      # Actualizar la posición geolocalizada del servidor.
      def self.ws__user_update_geolocation(app, response, session)
        user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
        
        # Actualizar en la BD.
        lat = response[:request][:request][:data][:latitude].to_f
        lon = response[:request][:request][:data][:longitude].to_f
        user.set_geolocation(lat, lon )
      
        # Generar respuesta
        Game::API::JSONResponse.ok_response!( response, {type: "plain", message: "User geolocation changed to " + lat.to_s + ", " + lon.to_s} )
      end
      
      # Buscar jugadores cercanos.
      def self.ws__user_get_nearby_users(app, response, session)
        default_radius = 2 # km
        
        user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
        
        # Buscar jugadores
        output = user.get_online_nearby_users(default_radius)
      
        # Generar respuesta
        Game::API::JSONResponse.ok_response!( response, {type: "json", users: output} )
      end

      # ...
    end
  end
  end
end