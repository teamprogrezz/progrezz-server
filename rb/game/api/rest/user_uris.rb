# encoding: UTF-8

module Sinatra; module API ;module REST

  class Methods
    
    # Obtener el perfil del jugador
    def self.rest__user_profile( app, response, session)
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      output = user.get_stats()
      
      Game::API::JSONResponse.ok_response!( response, { profile: output } )
    end
    
    # Obtener las acciones permitidas por un jugador
    def self.rest__user_allowed_actions( app, response, session )
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      output = Game::Mechanics::AllowedActionsMechanics.get_allowed_actions( user.level_profile.level )

      Game::API::JSONResponse.ok_response!( response, { allowed_actions: output })
    end
    
    # Obtener usuario actualmente conectado
    def self.rest__user_who_am_i(app, response, session)
      output = Game::AuthManager.current_user(session)
      
      if output != nil
        output = Game::Database::User.search_user( output )
        Game::API::JSONResponse.ok_response!( response, { user: output.to_hash( [] ) })
      else
        Game::API::JSONResponse.error_response!(response, "You are not authenticated.")
      end
    end
    
  end

end; end; end