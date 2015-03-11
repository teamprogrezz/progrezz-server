# encoding: UTF-8

require 'json'
require 'geocoder'
require 'progrezz/geolocation'

module Sinatra; module API ;module REST
  # Añadir métodos a la clase de métodos de la API REST. Se añadirá automáticamente en el fichero rest.rb
  class Methods
    
    # Cambiar el estatus o estado de un mensaje completado.
    def self.user_change_message_status( app, response, session)
      user = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      if user.change_message_status( response[:request][:request][:data][:msg_uuid], response[:request][:request][:data][:new_status] ) == nil
        raise "Could not change message status."
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "plain",
        message: "Message status changed to '" + response[:request][:request][:data][:new_status] + "'."
      })
    end
    
    # Recoger un fragmento de mensaje cercano.
    def self.user_collect_message_fragment( app, response, session )
      user     = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      fragment = Game::Database::MessageFragment.find_by( uuid: response[:request][:request][:data][:frag_uuid] )
      
      # TODO: Comprobar que el mensaje esté lo suficientemente cerca.
      # ...
      
      begin
        user.collect_fragment( fragment )
      rescue Exception => e
        raise "The fragment could not be collected: " + e.message
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "plain",
        message: "Fragment collected."
      })
    end
    
    # Escribir mensaje de un usuario.
    def self.user_write_message( app, response, session )
      user = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      msg_content  = response[:request][:request][:data][:content].to_s
      msg_resource = response[:request][:request][:data][:resource].to_s
      
      msg = user.write_msg( msg_content, msg_resource )
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        written_message: msg.get_user_message()
      })
    end
    
    # Recibir fragmentos de mensajes cercanos al usuario.
    def self.user_get_nearby_message_fragments( app, response, session )
      default_radius = 0.600      # in km
      default_method = "progrezz" # progrezz, geocoder o neo4j
      default_ignore = true
      
      user    = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      radius  = (response[:request][:request][:data][:radius] || default_radius).to_f
      method  = (response[:request][:request][:data][:method] || default_method).to_s
      ignore  = (response[:request][:request][:data][:ignore_user_written_messages] || default_ignore) == "true"

      # Geolocalizaciones (como arrays).
      output = user.get_nearby_fragments(method, radius, ignore)
      
      # formatear output
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        fragments: output
      })
      
    end
    
    # Listar mensajes de un usuario.
    # Entrada: Usuario, ... .
    # Salida:  Array de mensajes completados y sin completar del usuario.
    def self.user_get_messages( app, response, session )
      user = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        completed_messages:  user.get_completed_messages(),  # Añadir mensajescompletados.
        fragmented_messages: user.get_fragmented_messages()  # Y mensajes fragmentados.
      })
    end
    
    # Listar fragmentos recolectados de un mensaje determinado.
    def self.user_get_collected_message_fragments( app, response, session )
      user     = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      message  = Game::Database::Message.find_by( uuid: response[:request][:request][:data][:msg_uuid] )
      
      if message == nil
        raise "Unkown message."
      end

      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        fragments: user.get_collected_message_fragments(message)
      })
    end
  end
  
end; end; end
