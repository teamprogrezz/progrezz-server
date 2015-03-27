# encoding: UTF-8

#if development?

require 'sinatra'
require 'sinatra/base'
require 'neo4j'
require 'cgi'

# Prueba de ajuste geolocalizado
#location = {latitude: 28.26807, longitude: -16.43555}
#puts location
#puts "Tiempo de geolocalización: " + (GenericUtils.timer { Game::Mechanics::GeolocationManagement.snap_geolocation!(location) }).to_s
#puts location

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
        result = nil
        
        user_Wikiti = nil
        user_Shylpx = nil
        
        messages = []
        
        begin
          Game::Database::DatabaseManager.run_nested_transaction do |tx|
            
            # Usuarios
            puts "Tiempo de creación de usuarios: " + (GenericUtils.timer do
              user_Wikiti = Game::Database::User.sign_up('Wikiti', 'wikiti.doghound@gmail.com', {latitude: 28.4748, longitude: -16.2679})
              user_Shylpx = Game::Database::User.sign_up('Shylpx', 'cristogr.93@gmail.com' )
            end).to_s
            
            # Levear a wikiti
            puts "Tiempo de leveo de usuarios: " + (GenericUtils.timer do
              Game::Database::DatabaseManager.run_nested_transaction do
                for i in 0...80
                  Game::Mechanics::LevelingManagement.gain_exp( user_Wikiti, "collect_fragment" )
                  Game::Mechanics::LevelingManagement.gain_exp( user_Shylpx, "collect_fragment" )
                end
              end
            end).to_s

            # Mensajes con autor
            puts "Tiempo de creación de mensajes con autor: " + (GenericUtils.timer do
              messages << user_Wikiti.write_message( "Mensaje de prueba de Wikiti." )
              messages << user_Wikiti.write_message( "Mensaje de prueba de Shylpx n2 (robado)." )
              messages << user_Shylpx.write_message( "Mensaje de prueba de Shylpx n1." )
            end).to_s
            
            # Mensajes sin autor
            puts "Tiempo de creación de mensajes sin autor: " + (GenericUtils.timer do
              messages << Game::Database::Message.create_system_message("¡Adelante, campeones de a luz!.", 4)
              messages << Game::Database::Message.create_system_message("¡Salvar el mundo!.", 3)
              messages << Game::Database::Message.create_system_message("Mensaje de prueba sin usuario (perdido).", 2)
              
              messages[3].replicate( {latitude: 41, longitude: 0.92}, { latitude: 0.05, longitude: 0.05 } )
              messages[4].replicate( {latitude: 1.995, longitude: 0.809}, { latitude: 0.05, longitude: 0.05 } )
              messages[5].replicate()
              
              # Crear copia de un mensaje replicable
              # messages[3].replicate( {latitude: 0.0, longitude: 0.0}, {latitude: 0.5, longitude: 0.6} )
              
            end).to_s
            
            # Buscar mensajes de Wikiti
            puts "Tiempo de búsqueda de mensajes sin autor: " + (GenericUtils.timer do
              Game::Database::Message.unauthored_messages()
            end).to_s
            
            # Buscar mensajes de Wikiti
            puts "Tiempo de búsqueda de mensajes escritos por Wikiti : " + (GenericUtils.timer do
              Game::Database::User.find_by( alias: "Wikiti").written_messages
            end).to_s

            # Añadir fragmentos a Wikiti
            puts "Tiempo de asociación de fragmentos a Wikiti: " + (GenericUtils.timer do
              # Añadir fragmentos
              fragments = messages[4].fragments
              user_Wikiti.collect_fragment( fragments.where(fragment_index: 0).first )
              user_Wikiti.collect_fragment( fragments.where(fragment_index: 2).first )
              
              # Añadir mensaje completo
              fragments = messages[3].fragments
              user_Wikiti.collect_fragment( fragments.where(fragment_index: 0).first )
              user_Wikiti.collect_fragment( fragments.where(fragment_index: 1).first )
              user_Wikiti.collect_fragment( fragments.where(fragment_index: 2).first )
              user_Wikiti.collect_fragment( fragments.where(fragment_index: 3).first )
              
            end).to_s
            
            fragments = messages[3].fragments
            
            # Añadir fragmentos a Shylpx
            puts "Tiempo de asociación de fragmentos a Shylpx: " + (GenericUtils.timer do

              user_Shylpx.collect_fragment( fragments.where(fragment_index: 0).first )
              user_Shylpx.collect_fragment( fragments.where(fragment_index: 1).first )
              user_Shylpx.collect_fragment( fragments.where(fragment_index: 2).first )
              
              fragments = messages[0].fragments
              user_Shylpx.collect_fragment( fragments.where(fragment_index: 0).first )
              user_Shylpx.change_message_status( messages[0].uuid, "locked" )
              
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
          end
          
        # Banearme 5 minutos ( D': ).
        # Game::AuthManager.ban_user(user_Wikiti.user_id, 300 )
        
        # Borrar mensaje (prueba).
        messages[3].remove

        rescue Exception => e
          #puts e.message
          #puts e.backtrace
          result = e.class.name + " -> " + e.message + " \n\n" + e.backtrace.to_s
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

#end