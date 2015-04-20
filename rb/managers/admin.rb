# encoding: UTF-8

require 'date'

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
      password = ENV['progrezz_admin_password'] || "admin"
    end
    
    # Credenciales del administrador
    # @return [Array<String, String>] Array con la forma [usuario, contraseña].
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
      
      app.get '/admin/items' do
        admin_protected!
        erb :"admin/items", :layout => :"admin/layout"
      end
      
      app.get '/admin/game_parameters' do
        admin_protected!
        erb :"admin/game_parameters", :layout => :"admin/layout"
      end
      
      # -- Parámetros de juego (parametrizado). # ++
      app.post '/admin/game_parameters/:action' do   
        content_type :json
        admin_protected!
        
        @@action_list ||= {
          "allowed_actions" => Game::Mechanics::AllowedActionsMechanics,
          "backpack" => Game::Mechanics::BackpackMechanics,
          "items" => Game::Mechanics::ItemsMechanics,
          "leveling" => Game::Mechanics::LevelingMechanics
        }
        
        begin
          data    = params["data"]
          action  = params['action']
          manager = @@action_list[ action ]
          
          # Reiniciar objetos
          manager.update(data)
          
          # Guardar una copia del anterior
          FileUtils.cp(manager::DATAFILE, "tmp/data/" + action + "_" + DateTime.now.to_time.to_i.to_s + ".sav")
          
          # Y sobrescribir
          File.open(manager::DATAFILE, 'w') { |file| file.write( data ) }
          
        rescue Exception => e
          halt 400, {'Content-Type' => 'text/plain'}, e.message + "\n" + e.backtrace.to_s
        end
        
        return {status: "ok"}.to_json
      end
      
      
      # -- Mensajes --
      app.post '/admin/messages/add' do
        content_type :json
        admin_protected!
        
        Game::Database::Message.create_system_message( params["add_content"], params["add_nfragments"].to_i, { resource_link: params["add_resource"], duration: params["add_duration"]} )
        
        return {status: "ok"}.to_json
      end
      
      app.post '/admin/messages/remove' do
        content_type :json
        admin_protected!
        
        Game::Database::Message.find_by( uuid: params["rem_uuid"] ).remove()
        return {status: "error"}.to_json
      end
      
      # -- Usuarios --
      app.post '/admin/users/search_by_alias' do
        content_type :json
        admin_protected!
        
        output = nil
        if params["regexp"] == nil
          output = Game::Database::User.where( alias: params["alias"] ).to_a
        else
          output = Game::Database::User.as(:u).where( "u.alias =~ {al}" ).params(al: params["alias"]).to_a
        end
        
        output.each_index do |i|
          user = output[i]
          output[i] = {
            uuid: user.uuid,
            user_id: user.user_id,
            alias: user.alias,
            banned_until: user.banned_until,
            banned_reason: user.banned_reason
          }
        end
        
        return output.to_json
      end
      
      app.post '/admin/users/search_by_email' do
        content_type :json
        admin_protected!
        
        output = nil
        if params["regexp"] == nil
          output = Game::Database::User.where( user_id: params["email"] ).to_a
        else
          output = Game::Database::User.as(:u).where( "u.user_id =~ {u}" ).params(u: params["email"]).to_a
        end
        
        output.each_index do |i|
          user = output[i]
          output[i] = {
            uuid: user.uuid,
            user_id: user.user_id,
            alias: user.alias,
            banned_until: user.banned_until,
            banned_reason: user.banned_reason
          }
        end
        
        return output.to_json
      end
      
      app.post '/admin/users/ban' do
        content_type :json
        admin_protected!
        
        user_id = params["ban_id"]
        ban_duration = params["ban_duration"].to_i
        ban_reason = params["ban_reason"]
        
        Game::AuthManager.ban_user(user_id, ban_duration, ban_reason)

        return {status: "ok"}.to_json
      end
      
      app.post '/admin/users/unban' do
        content_type :json
        admin_protected!
        
        user_id = params["unban_id"]
        
        Game::AuthManager.unban_user(user_id)
        
        return {status: "ok"}.to_json
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