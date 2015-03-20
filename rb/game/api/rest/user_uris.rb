

module Sinatra; module API ;module REST

  class Methods
    
    # Obtener el perfil del jugador
    def self.user_get_profile( app, response, session)
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      output = user.get_stats()
      
      Game::API::JSONResponse.ok_response!( response, { profile: output } )
    end
  end

end; end; end