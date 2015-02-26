# encoding: UTF-8

require 'sinatra'
require 'sinatra/base'
require 'neo4j'

module Sinatra #:nodoc: all

module API
module REST

  # Módulo de la api REST para hacer pruebas.
  module Trash
    module Helpers
      def db_drop()
        Game::Database::DatabaseManager.drop()
        
        return "<h2>Database droped.</h2>"
      end
      
      def db_add()
        begin

          pre_time = Time.now
            # Usuarios
            user_Wikiti = Game::Database::User.sign_up('Wikiti', 'wikiti.doghound@gmail.com' )
            user_Shylpx = Game::Database::User.sign_up('Shylpx', 'cristogr.93@gmail.com' )
          puts "Tiempo de creación de usuarios: " + (Time.now - pre_time).to_s
          
          pre_time = Time.now
            # Mensajes con autor
            Game::Database::Message.create_message("Mensaje de prueba de Wikiti.", 1, nil, user_Wikiti)
            Game::Database::Message.create_message("Mensaje de prueba de Shylpx n1.", 1, nil, user_Shylpx)
            Game::Database::Message.create_message("Mensaje de prueba de Shylpx n2 (robado).", 1, nil, user_Wikiti)
          puts "Tiempo de creación de mensajes con autor: " + (Time.now - pre_time).to_s
          
          pre_time = Time.now
            # Mensajes sin autor
            Game::Database::Message.create_message("¡Adelante, campeones de a luz!.", 4)
            Game::Database::Message.create_message("¡Salvar el mundo!.", 3)
            Game::Database::Message.create_message("Mensaje de prueba sin usuario (perdido).", 2)
          puts "Tiempo de creación de mensajes sin autor: " + (Time.now - pre_time).to_s

          return "<h2>Datos añadidos correctamente.</h2>"

        rescue Exception => e
          return "<pre>" + e.class.name + " -> " + e.message + "</pre>"
        end
      end
      
      def db_reset()
        db_drop()
        return db_add()
      end
       
    end
    
    def self.registered(app)
       # Añadir "ayudas".
      app.helpers Helpers
      
      # Tirar base de datos
      app.get '/test/drop' do
        return db_drop()
      end

      # Listar datos de prueba
      app.get '/test/list' do
        erb :list, :views => "views/test/", :locals => {:users => Game::Database::User.all(), :messages => Game::Database::Message.all() }
      end

      # Añadir datos de prueba
      app.get '/test/add' do
        return db_add()
      end

      # Reiniciar prueba
      app.get '/test/reset' do
        msg = db_reset()
        
        if msg != "<h2>Datos añadidos correctamente.</h2>"; return msg end
        
        erb :list, :views => "views/test/", :locals => {:users => Game::Database::User.all(), :messages => Game::Database::Message.all() }
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
