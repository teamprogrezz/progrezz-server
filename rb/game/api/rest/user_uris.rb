# encoding: UTF-8

module Sinatra; module API ;module REST

  class Methods
    
    # Obtener el perfil del jugador
    def self.user_profile( app, response, session)
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      output = user.get_stats()
      
      Game::API::JSONResponse.ok_response!( response, { profile: output } )
    end
    
    # Obtener las acciones permitidas por un jugador
    def self.user_allowed_actions( app, response, session )
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      output = Game::Mechanics::AllowedActionsManagement.get_allowed_actions( user.level_profile.level )

      Game::API::JSONResponse.ok_response!( response, { allowed_actions: output })
    end
    
  end

end; end; end