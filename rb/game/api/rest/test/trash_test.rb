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
        redirect to('/test/list')
      end

      # Listar datos de prueba
      app.get '/test/list' do
        erb :user_list, :views => "views/test/", :locals => {:users => Game::Database::User.all() }
      end

      # Añadir datos de prueba
      app.get '/test/add' do
        begin
          Game::Database::User.sign_in('Wikiti', 'wikiti.doghound@gmail.com' )
          Game::Database::User.sign_in('Shylpx', 'cristogr.93@gmail.com' )

          redirect to('/test/list')

        rescue Exception => e
          return "<pre>" + e.class.name + " -> " + e.message + "</pre>"
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
