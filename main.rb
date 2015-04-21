# encoding: UTF-8

#-- Cargar ruta actual en la ruta de carga de fuentes. #++
$LOAD_PATH << File.dirname(__FILE__) + "\n"

# Mejorar funcionamiento
require 'oj'
require 'oj_mimic_json'

# Cargar cosas genéricas
require 'sinatra'
require 'sinatra/multi_route'
require 'neo4j'
require 'logger'
require 'colorize'
require 'thread'

# Cargar utilidades personalizadas.
require './rb/generic_utils'

if development?
  require 'sinatra/reloader'
  require 'ruby-prof'
  require 'pry'

  puts "--------------------------------------".red.bold
  puts "**   Starting in development mode   **".red.bold
  puts "--------------------------------------".red.bold
  
  # Variable de desarrollo
  ::DEV = true
end

# Módulo Sinatra (predefinido).
module Sinatra
  
  # Aplicación principal (servidor).
  #
  # Funciona como contenedor de una aplicación Ruby Sinatra.
  class ProgrezzServer < Sinatra::Base; end
  
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
      
      # Configuación 
      app.configure do
        # Asignar servidor
        app.set :server, 'thin'
              
        # Activar sesiones del servidor web
        app.set :sessions, true
        
        # Añadir secreto.
        app.set :session_secret, ENV['progrezz_secret']
        
        # Añadir multihilos. 
        app.set :threaded, true # TODO: Probar con Thin y no con rackup.
        
        # Activar loggin
        app.enable :loggin
        app.use Rack::CommonLogger, Logger.new("tmp/app.log")
        
        # Deshabilitar la muestra de excepciones.
        app.set :show_exceptions, false
      end
      
      # Hacer antes de toda petición de ruta
      error_log = ::File.new("tmp/app_errors.log","a+")
      error_log.sync = true
      app.before { env["rack.errors"] = error_log } if ProgrezzServer.production?
      
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
        erb :"dev/home", :locals => { :session => session }, :layout => :"dev/layout"
      end
      
      # Página de información (about).
      app.get '/dev/about' do
        erb :"dev/about", :locals => { :session => session }, :layout => :"dev/layout"
      end
      
      # Página de documentación (doc).
      app.get '/dev/doc' do
        erb :"dev/doc", :locals => { :session => session }, :layout => :"dev/layout"
      end
      
      # Gestión de errores.
      app.error Exception do
        e = env['sinatra.error']

        return "<h1 style='color: red;'>Fatal error</h1>" +
          "<pre><strong>Message: </strong>" + e.message.to_s + "</pre>" +
          "<pre><strong>Backtrace: </strong>\n" + e.backtrace.join("\n") + "</pre>"
      end
    end
  end
  
  register Pages
end

class Sinatra::ProgrezzServer
  register Sinatra::Pages
  register Sinatra::MultiRoute
end

#-- Registrar. #++
#-- ---------------------------------------------------------------- #++

#-- Require especial (con expresiones regulares, para directorios). #++
require './rb/generic_utils'

#-- Cargar Gestores del servidor. #++
GenericUtils.require_dir("./rb/managers/**/*.rb", "----------------------------------\n" + "    Mánager:                ".green, false)
puts "----------------------------------"

# Ejecutar una terminal (si procede)
if development? && ENV['progrezz_interactive_shell'] == "true"

  Thread.new do |t|
    binding.pry
    exit()
  end
end

# Cosas a ejecutar cuando se cierre la app.
at_exit do
  Game::Database::DatabaseManager.force_save()
  puts "Progrezz server ended. Crowd applause."

  Thread.list.each do |thread|
    thread.exit
  end
end

#-- ---------------------------------------------------------------- #++

#Sinatra::ProgrezzServer.run
#-- Ejecutar app #++