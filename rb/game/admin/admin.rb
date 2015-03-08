module Game
  
  # Clase gestora de la administración del juego.
  #
  class AdminManager
    
    # Getter del usuario del admin.
    # @return [String] Nombre de usuario del administrador.
    def self.admin_user()
      admin = ENV['progrezz_admin_user'] || "admin"
    end
    
    # Getter de la contraseña del admin.
    # @return [String] Contraseña del administrador
    def self.admin_password()
      password = ENV['progrezz_admin_user'] || "admin"
    end
    
    def self.credentials()
      return [ admin_user, admin_password ]
    end
    
    # @return [Rack::Auth::Basic::Request] Autenticación http sencilla.
    attr_accessor :admin_auth
    
    # Iniciar módulos de administrador.
    #
    def self.setup(service_exceptions = [] )
      # ...
    end

  end
end

# Inicializar.
Game::AdminManager.setup( )

module Sinatra
  
  # Métodos o ayudas para la administración.
  module AdminHelpers
    
    # Helper para proteger una página.
    # 
    # Si la autenticación es orrecta, redirecciona a la página deseada.
    # En caso contrario, devuelve al usuario a una página con el error 401, "No autorizado".
    def admin_protected!
      @admin_auth ||=  Rack::Auth::Basic::Request.new(request.env)
      if @admin_auth.provided? and @admin_auth.basic? and @admin_auth.credentials and @admin_auth.credentials == Game::AdminManager.credentials
        return
      end

      headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
      halt 401, "Not authorized\n"
    end
  end
  
  
  # Métodos http de autenticación de administradores.
  module AdminMethods
    
    # Registrar páginas web necesarias.
    # @param app [Sinatra::Application] Aplicación sinatra.
    def self.registered(app)
      app.helpers Sinatra::AdminHelpers
      
      app.get '/admin' do
        redirect to("/admin/home")
      end
      
      app.get '/admin/home' do
        admin_protected!
        erb :"admin/home", :layout => :"admin/layout"
      end
      
      app.get '/admin/messages' do
        admin_protected!
        erb :"admin/messages", :layout => :"admin/layout"
      end
      
      app.get '/admin/users' do
        admin_protected!
        erb :"admin/users", :layout => :"admin/layout"
      end
    end
  end

  # Registrar en sinatra.
  register Sinatra::AdminMethods
end

class Sinatra::ProgrezzServer
  register Sinatra::AdminMethods
end
#-- Cargar en el servidor #++