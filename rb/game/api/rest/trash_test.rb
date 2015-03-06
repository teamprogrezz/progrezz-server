# encoding: UTF-8

require 'sinatra'
require 'sinatra/base'
require 'neo4j'
require 'cgi'

module Sinatra
module API
module REST

  # Módulo de la api REST para hacer pruebas.
  module Trash
    
    # Métodos de ayuda del módulo de pruebas.
    module Helpers
      
      # Eliminar contenido de la base de datos.
      def db_drop()
        Game::Database::DatabaseManager.drop()
        
        return "<h2>Database droped.</h2>"
      end
      
      # Añadir contenido de prueba de la base de datos.
      def db_add()
        begin
          user_Wikiti = nil
          user_Shylpx = nil
          
          messages = []
          
          #tx = Neo4j::Transaction.new
          
          # Usuarios
          puts "Tiempo de creación de usuarios: " + (GenericUtils.timer do
            user_Wikiti = Game::Database::User.sign_up('Wikiti', 'wikiti.doghound@gmail.com', {latitude: 2.0, longitude: 0.81})
            user_Shylpx = Game::Database::User.sign_up('Shylpx', 'cristogr.93@gmail.com' )
          end).to_s
          
          # Mensajes con autor
          puts "Tiempo de creación de mensajes con autor: " + (GenericUtils.timer do
            messages << user_Wikiti.write_msg( "Mensaje de prueba de Wikiti." )
            messages << user_Wikiti.write_msg( "Mensaje de prueba de Shylpx n2 (robado)." )
            messages << user_Shylpx.write_msg( "Mensaje de prueba de Shylpx n1." )
          end).to_s
          
          # Mensajes sin autor
          puts "Tiempo de creación de mensajes sin autor: " + (GenericUtils.timer do
            messages << Game::Database::Message.create_message("¡Adelante, campeones de a luz!.", 4, nil, nil, {latitude: 1.995, longitude: 0.809})
            messages << Game::Database::Message.create_message("¡Salvar el mundo!.", 3, nil, nil, {latitude: 1.995, longitude: 0.809} )
            messages << Game::Database::Message.create_message("Mensaje de prueba sin usuario (perdido).", 2)
          end).to_s
          
          # Buscar mensajes de Wikiti
          puts "Tiempo de búsqueda de mensajes escritos por Wikiti : " + (GenericUtils.timer do
            Game::Database::User.all.where( alias: "Wikiti").first.written_messages
          end).to_s
          
          # Añadir fragmentos a Wikiti
          puts "Tiempo de asosiación de fragmentos a Wikiti: " + (GenericUtils.timer do
            user_Wikiti.collect_fragment( messages[0].fragments[0] ) # Autor -> No añadido.
            
            # Añadir fragmentos
            fragments = messages[4].fragments
            user_Wikiti.collect_fragment( fragments[0] )
            user_Wikiti.collect_fragment( fragments[0] ) # Mensaje repetido -> No añadido.
            user_Wikiti.collect_fragment( fragments[2] )
            
            # Añadir mensaje completo
            fragments = messages[3].fragments
            user_Wikiti.collect_fragment( fragments[0] )
            user_Wikiti.collect_fragment( fragments[1] )
            user_Wikiti.collect_fragment( fragments[2] )
            user_Wikiti.collect_fragment( fragments[3] )
            
          end).to_s
          
          # Añadir fragmentos a Shylpx
          puts "Tiempo de asosiación de fragmentos a Shylpx: " + (GenericUtils.timer do
            fragments = messages[3].fragments
            user_Shylpx.collect_fragment( fragments[0] )
            user_Shylpx.collect_fragment( fragments[1] )
            
            fragments = messages[0].fragments
            user_Shylpx.collect_fragment( fragments[0] )
          end).to_s
          
          # Borrar usuario
          puts "Tiempo de borrado de Wikiti: " + (GenericUtils.timer do
            #user_Wikiti.destroy
          end).to_s
          
          # Tiempos de geocoder
          puts "Progrezz time: " + (GenericUtils.timer do
            for i in 0...9999 do
              distance = Progrezz::Geolocation.distance({latitude: i - 1, longitude: i + 1}, {latitude: i - 2, longitude: i + 2}, :km)
            end
          end).to_s
          
          puts "Geocoder time: " + (GenericUtils.timer do
            for i in 0...9999 do
              Geocoder::Calculations.distance_between([i-1,i+1], [i-2,i+2], {:units => :km})
            end
          end).to_s
          
          result = "<h2>Datos añadidos correctamente.</h2>"

        rescue Exception => e
          #tx.failure()
          
          puts e.message
          puts e.backtrace
          result = e.class.name + " -> " + e.message
          
        ensure
          Game::Database::DatabaseManager.force_save() 
        end
        
        return result
      end
      
      # Reiniciar contenido de la base de datos.
      def db_reset()
        db_drop()
        return db_add()
      end
       
    end
    
    # Registrar métodos de prueba.
    #
    # @param app [Sinatra::Application] Aplicación sinatra.
    def self.registered(app)
       # Añadir "ayudas".
      app.helpers Helpers
      
      # Tirar base de datos
      app.get '/test/drop' do
        return db_drop()
      end

      # Listar datos de prueba
      app.get '/test/list' do
        erb :"test/list", :locals => {:users => Game::Database::User.all(), :messages => Game::Database::Message.all() }
      end

      # Añadir datos de prueba
      app.get '/test/add' do
        return CGI.escapeHTML( db_add() )
      end

      # Reiniciar prueba
      app.get '/test/reset' do
        msg = db_reset()
        
        if msg != "<h2>Datos añadidos correctamente.</h2>"; return ("<pre>" + CGI.escapeHTML( msg ) + "</pre>") end
        
        erb :"test/list", :locals => {:users => Game::Database::User.all(), :messages => Game::Database::Message.all() }
      end

    end
  end

end; end

#-- Registrar rutas sinatra #++
register API::REST::Trash
end

class Sinatra::ProgrezzServer
  register Sinatra::API::REST::Trash
end
#-- Cargar en el servidor #++
