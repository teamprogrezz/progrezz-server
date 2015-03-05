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
  
  DEV = true
end

# Aplicación principal (servidor).
#
# Funciona como contenedor de una aplicación Ruby Sinatra.
class ProgrezzServer < Sinatra::Base

  # Activar sesiones del servidor web
  set :sessions, true # TODO: Añadir secreto.
  
  # Añadir multihilos. 
  set :threaded, true # TODO: Probar con Thin y no con rackup.
  
  # Getter de la sesión de la aplicación.
  #
  # * *Retorna:
  #   - Sesión actual (objeto session).
  def self.get_session()
    return self.session
  end
end

#-- Require especial (con expresiones regulares, para directorios). #++
require './rb/generic_utils'

#-- Cargar datos referente a la base de datos. #++
require './rb/db'

#-- Cargar datos referentes a la api REST. #++
require './rb/rest'


#-- Cosas a ejecutar cuando se cierre la app. #++
at_exit do
  Game::Database::DatabaseManager.force_save()
  puts "Progrezz server ended. Crowd applause."
end

