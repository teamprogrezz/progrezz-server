require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
#require 'omniauth-facebook'

module Game
  class AuthManager
    
    # Servicios disponibles.
    SERVICES = [:google]
    
    # Servicios cargados con OmniAuth.
    @@loaded_services
    
    # Iniciar módulos OmniAuth.
    #
    # Los datos referentes a los servicios se cargarán desde las variables de entorno siguientes:
    # - *google*: id: progrezz_google_id, secret: progrezz_google_secret
    # - ...
    # 
    # * *Argumentos*: 
    #   - +service_exceptions+: Servicios (símbolos ruby) que no serán cargados. Por defecto, se cargarán todos los posibles. La lista de servicios se encuentra en SERVICES.
    def self.setup(service_exceptions = [] )
      @@loaded_services = []
      
      # Incluir o excluir google.
      if !service_exceptions.include? :google
        @@loaded_services << :google
      end
      
    end
    
    # Getter de los servicios cargados.
    #
    # * *Retorna*: 
    #   - Lista o Array de símbolos de los servicios cargados (ej: [:google, :twitter, ...]).
    def self.get_loaded_services()
      return @@loaded_services
    end
  end
end

# Inicializar.
Game::AuthManager.setup()

# Cargar URI de la autenticación.
class ProgrezzServer < Sinatra::Base
  
  # Métodos OmnitAuth: configuración.
  use OmniAuth::Builder do
    
    # Configurar Google Auth.
    if AuthManager.get_loaded_services.include? :google
      provider :google_oauth2, ENV['progrezz_google_id'], ENV['progrezz_google_secret'], 
        :scope => "userinfo.email,userinfo.profile", :provider_ignores_state => true
    end
    
    # ...
  end
  
  # Acceso a cualquier servicio con la URI "/auth/<servicio>" (ej: /auth/twitter).
  get '/auth/:name/callback' do
    session[:auth] = @auth = request.env['omniauth.auth']
    session[:name] = @auth['info'].name
    session[:url] = @auth['info'].urls.values[0]
    session[:email] = @auth['info'].email
     
    puts "params = #{params}"
    puts "@auth.class = #{@auth.class}"
    puts "@auth info = #{@auth['info']}"
    puts "@auth info class = #{@auth['info'].class}"
    puts "@auth info name = #{@auth['info'].name}"
    puts "@auth info email = #{@auth['info'].email}"
    puts "-------------@auth----------------------------------"
    puts "*************@auth.methods*****************"
         
    # TODO: Si el usuario no está en la base de datos, añadirlo.
    # ...
    
    # Redireccionar al usuario.
    if (params[:redirect] != nil)
      redirect params[:redirect]
    else
      redirect '/'
    end
    
  end
   
  get '/auth/failure' do
    # TODO: Cambiar callback de función failure.
    
    puts params
    redirect '/'
  end
end