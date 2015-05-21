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
    
  end
  
end; end; end
