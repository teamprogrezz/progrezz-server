# encoding: UTF-8

require 'sinatra'
require 'sinatra/base'
require 'neo4j'

module Sinatra #:nodoc: all

module API
module REST

  # Módulo de la api REST para hacer pruebas.
  module Trash
    def self.registered(app)
      # Tirar base de datos
      app.get '/test/drop' do
        Game::Database::DatabaseManager.drop()
        return "<h1>Database droped.</h1>"
      end

      # Listar datos de prueba
      app.get '/test/list' do
        erb :list, :views => "views/test/", :locals => {:users => Game::Database::User.all(), :messages => Game::Database::Message.all() }
      end

      # Añadir datos de prueba
      app.get '/test/add' do
        begin
          # Usuarios
          user_Wikiti = Game::Database::User.sign_up('Wikiti', 'wikiti.doghound@gmail.com' )
          user_Shylpx = Game::Database::User.sign_up('Shylpx', 'cristogr.93@gmail.com' )
          
          # Mensajes
          t = Game::Database::Message.create_message("Mensaje de prueba de Wikiti.", 1, nil, user_Wikiti)
          Game::Database::Message.create_message("Mensaje de prueba de Shylpx n1.", 1, nil, user_Shylpx)
          Game::Database::Message.create_message("Mensaje de prueba de Shylpx n2 (robado).", 1, nil, user_Wikiti)
          
          Game::Database::Message.create_message("Mensaje de prueba sin usuario (perdido).", 2)
          
          puts t.author
          
          redirect to('/test/list')

        #rescue Exception => e
        #  return "<pre>" + e.class.name + " -> " + e.message + "</pre>"
        end
      end

    end
  end

end; end

#-- Registrar rutas sinatra #++
register API::REST::Trash
end

#-- Cargar en el servidor #++
class ProgrezzServer
  register Sinatra::API::REST::Trash
end
