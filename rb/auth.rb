require 'omniauth-oauth2'
require 'omniauth-google-oauth2'
#require 'omniauth-facebook'

module Game
  class AuthManager
    
    # Servicios disponibles.
    SERVICES = [:google_oauth2]
    
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
      for service in SERVICES
        if !service_exceptions.include? service
          @@loaded_services << service
        end
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

#:nodoc: all
module Sinatra
  module AuthMethods
    def self.registered(app)
      
      # Métodos OmnitAuth: configuración.
      app.configure do
        app.enable :sessions
        app.set :session_secret, ENV['progrezz_secret']
        
        app.use OmniAuth::Builder do
          # Configurar Google Auth.
          if Game::AuthManager.get_loaded_services.include? :google_oauth2
            provider :google_oauth2, ENV['progrezz_google_id'], ENV['progrezz_google_secret'], 
              :scope => "userinfo.email,userinfo.profile", :provider_ignores_state => true
          end
          
          # ...
        end
      end
      
      # Acceso a cualquier servicio con la URI "/auth/<servicio>" (ej: /auth/twitter).
      app.get '/auth/:provider/callback' do
        session[:auth]    = @auth = request.env['omniauth.auth']
        session[:user_id] = @auth['info'].email              # ID -> correo
        session[:name]    = @auth['info'].name               # Nombre completo
        session[:alias]   = @auth['info'].name.split(' ')[0] # Coger como Alias la primera palabra.
        session[:url]     = @auth['info'].urls.values[0]     # Url del usuario (opcional).
         
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
        oparams = request.env["omniauth.params"]
        origin  = request.env['omniauth.origin']

        if (oparams["redirect"] != nil)
          redirect to(oparams["redirect"])
        elsif origin != nil
          redirect to(request.env['omniauth.origin'])
        else
          redirect to("/")
        end
        
      end
             
      app.get '/auth/failure' do
        # TODO: Cambiar callback de función failure.
        oparams = request.env["omniauth.params"]
        
        if (oparams["error_redirect"] != nil)
          redirect to(oparams["error_redirect"])
        else
          return params["error_message"]
        end
      end
      
    end
  end

  # Registrar en sinatra.
  register AuthMethods
end

#-- Cargar en el servidor #++
class ProgrezzServer
  register Sinatra::AuthMethods
end