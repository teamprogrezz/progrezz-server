# encoding: UTF-8

require 'json'

module Sinatra; module API ;module REST

  class Methods
    
    # Colocar una baliza en la posición actual del usuario.
    def self.rest__user_deploy_beacon( app, response, session )
      user_id = response[:request][:request][:data][:user_id]
      message = response[:request][:request][:data][:message]

      user     = Game::AuthManager.search_auth_user( user_id, session )
      
      begin
        user.deploy_beacon(message)
      rescue Exception => e
        raise ::GenericException.new( "Could not deploy beacon: " + e.message, e)
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        message: "Beacon deployed."
      })
    end

    # Obtener lista de balizas colocadas por un usuario.
    def self.rest__user_get_deployed_beacons( app, response, session )
      user_id = response[:request][:request][:data][:user_id]
      user     = Game::AuthManager.search_auth_user( user_id, session )

      beacons = Hash[user.get_beacons().map { |b| [b.uuid, b.to_hash] }]
      #beacons = user.get_beacons().map { |b| b.to_hash }

      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        beacons: beacons
       })
    end

    # Obtener lista de balizas cercanas a un usuario.
    def self.rest__user_get_nearby_beacons( app, response, session )
      user_id = response[:request][:request][:data][:user_id]
      user     = Game::AuthManager.search_auth_user( user_id, session )

      beacons = user.search_nearby_beacons()

      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        beacons: beacons
       })
    end
    
  end
  
end; end; end
