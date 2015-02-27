# encoding: UTF-8

require 'sinatra'
require 'sinatra/base'
require 'neo4j'
require 'cgi'

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
          user_Wikiti = nil
          user_Shylpx = nil
          
          messages = []
          
          tx = Neo4j::Transaction.new
          
          # Usuarios
          puts "Tiempo de creación de usuarios: " + (GenericUtils.timer do
            user_Wikiti = Game::Database::User.sign_up('Wikiti', 'wikiti.doghound@gmail.com' )
            user_Shylpx = Game::Database::User.sign_up('Shylpx', 'cristogr.93@gmail.com' )
          end).to_s
          
          # Mensajes con autor
          puts "Tiempo de creación de mensajes con autor: " + (GenericUtils.timer do
            messages << Game::Database::Message.create_message("Mensaje de prueba de Wikiti.", 1, nil, user_Wikiti)
            messages << Game::Database::Message.create_message("Mensaje de prueba de Shylpx n1.", 1, nil, user_Shylpx)
            messages << Game::Database::Message.create_message("Mensaje de prueba de Shylpx n2 (robado).", 1, nil, user_Wikiti)
          end).to_s
          
          # Mensajes sin autor
          puts "Tiempo de creación de mensajes sin autor: " + (GenericUtils.timer do
            messages << Game::Database::Message.create_message("¡Adelante, campeones de a luz!.", 4)
            messages << Game::Database::Message.create_message("¡Salvar el mundo!.", 3)
            messages << Game::Database::Message.create_message("Mensaje de prueba sin usuario (perdido).", 2)
          end).to_s
          
          # Buscar mensajes de Wikiti
          puts "Tiempo de búsqueda de mensajes escritos por Wikiti : " + (GenericUtils.timer do
            Game::Database::User.all.where( alias: "Wikiti").first.written_messages
          end).to_s
          
          # Añadir fragmentos a Wikiti
          puts "Tiempo de asosiación de fragmentos a Wikiti: " + (GenericUtils.timer do
            fragments = messages[3].fragments
            user_Wikiti.collect_fragment( messages[0].fragments[0] ) # Autor -> No añadido.
            user_Wikiti.collect_fragment( fragments[0] )
            user_Wikiti.collect_fragment( fragments[0] ) # Mensaje repetido -> No añadido.
            user_Wikiti.collect_fragment( fragments[1] )
            
            # Añadir mensaje completo
            fragments = messages[4].fragments
            user_Wikiti.collect_fragment( fragments[0] )
            user_Wikiti.collect_fragment( fragments[1] )
            user_Wikiti.collect_fragment( fragments[2] )
          end).to_s
          
          # Añadir fragmentos a Shylpx
          puts "Tiempo de asosiación de fragmentos a Shylpx: " + (GenericUtils.timer do
            fragments = messages[3].fragments
            user_Shylpx.collect_fragment( fragments[0] )
            user_Shylpx.collect_fragment( fragments[1] )
          end).to_s
          
          result = "<h2>Datos añadidos correctamente.</h2>"

        rescue Exception => e
          tx.failure()
          
          puts e.message
          puts e.backtrace
          result = e.class.name + " -> " + e.message
          
        ensure
          tx.close()
        end
        
        return result
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
        return CGI.escapeHTML( db_add() )
      end

      # Reiniciar prueba
      app.get '/test/reset' do
        msg = db_reset()
        
        if msg != "<h2>Datos añadidos correctamente.</h2>"; return ("<pre>" + CGI.escapeHTML( msg ) + "</pre>") end
        
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
