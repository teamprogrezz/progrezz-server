# encoding: UTF-8

#-- Cargar ruta actual en la ruta de carga de fuentes. #++
$LOAD_PATH << File.dirname(__FILE__) + "\n"

require 'sinatra'
require 'neo4j'

if development?
  require 'sinatra/reloader'

  puts "--------------------------------------"
  puts "**   Starting in development mode   **"
  puts "--------------------------------------"
  
  # Variable de desarrollo.
  DEV = true
end

# Módulo Sinatra (predefinido).
module Sinatra
  
  # Aplicación principal (servidor).
  #
  # Funciona como contenedor de una aplicación Ruby Sinatra.
  class ProgrezzServer < Sinatra::Base
  
    # Activar sesiones del servidor web
    set :sessions, true
    
    # Añadir secreto.
    set :session_secret, ENV['progrezz_secret']
    
    # Añadir multihilos. 
    set :threaded, true # TODO: Probar con Thin y no con rackup.
    
    # Getter de la sesión de la aplicación.
    #
    # @return Sesión actual (objeto session).
    def self.get_session()
      return self.session
    end
  end
  
  # Módulo de páginas webs. Usado para definir los métodos get y post
  # de las distintas páginas webs del servidor.
  module Pages
    
    # Helpers o métodos de ayuda para las peticiones http.
    module WebHelpers
      
      # Comprobar si la página dada es la actual.
      # @param path [String] Ruta dada para saber si se corresponde con la actual
      # @return [String, nil] Si es la misma, retorna "current". En otro caso, retorna nil. 
      def current?(path='/')
        (request.path==path || request.path==path+'/') ? "current" : nil
      end
    end
    
    # Registrar páginas web elementales.
    # @param app [Sinatra::Application] Aplicación sinatra.
    def self.registered(app)
      app.helpers Pages::WebHelpers
      
      # Ruta principal del servidor.
      app.get '/' do
        redirect to("/dev")
      end
      
      # Página no encontrada (error 404).
      # 
      # Redirecciona a "/".
      app.not_found do
        redirect to("/")
      end
      
      # Página dev principal (home).
      app.get '/dev' do
        erb :"dev/home", :locals => { :session => session }, :layout => :layout_dev
      end
      
      # Página de información (about).
      app.get '/dev/about' do
        erb :"dev/about", :locals => { :session => session }, :layout => :layout_dev
      end
      
      # Página de documentación (doc).
      app.get '/dev/doc' do
        erb :"dev/doc", :locals => { :session => session }, :layout => :layout_dev
      end
    end
  end
  
  register Pages
end

class Sinatra::ProgrezzServer; register Sinatra::Pages; end
#-- Registrar. #++

# Cosas a ejecutar cuando se cierre la app.
at_exit do
  Game::Database::DatabaseManager.force_save()
  puts "Progrezz server ended. Crowd applause."
end

#-- ---------------------------------------------------------------- #++

#-- Require especial (con expresiones regulares, para directorios). #++
require './rb/generic_utils'

#-- Cargar datos referente a la base de datos. #++
require './rb/db'

#-- Cargar datos referentes a la api REST. #++
require './rb/rest'

#-- Cargar autenticación de usuarios. #++
require './rb/auth'

#-- ---------------------------------------------------------------- #++

Sinatra::ProgrezzServer.run
#-- Ejecutar app #++