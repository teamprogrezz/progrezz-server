# encoding: UTF-8

require 'json'
require 'geocoder'
require 'progrezz/geolocation'

module Sinatra; module API ;module REST

  class Methods
    
    # Desbloquear un mensaje completado por el usuario.
    def self.user_unlock_message( app, response, session)
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      extra = {}
      user.unlock_message( response[:request][:request][:data][:msg_uuid], extra ) 
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        message: "Message unlocked.",
        exp_gained: extra[:exp]
      })
    end
    
    # Marcar un mensaje como leído.
    def self.user_read_message( app, response, session)
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      user.read_message( response[:request][:request][:data][:msg_uuid] ) 
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "plain",
        message: "Message read."
      })
    end
    
    # Cambiar el estatus o estado de un mensaje completado.
    def self.user_change_message_status( app, response, session)
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      if user.change_message_status( response[:request][:request][:data][:msg_uuid], response[:request][:request][:data][:new_status] ) == nil
        raise ::GenericException.new( "Could not change message status." )
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "plain",
        message: "Message status changed to '" + response[:request][:request][:data][:new_status] + "'."
      })
      
      response[:metadata][:warning] = "Deprecated method."
    end
    
    # Recoger un fragmento de mensaje cercano.
    def self.user_collect_message_fragment( app, response, session )
      user     = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      fragment = Game::Database::MessageFragment.find_by( uuid: response[:request][:request][:data][:frag_uuid] )
      
      # TODO: Comprobar que el mensaje esté lo suficientemente cerca.
      # ...
      
      extra = {}
      
      relation = nil
      begin
        relation = user.collect_fragment( fragment, extra )
      rescue Exception => e
        raise ::GenericException.new( "The fragment could not be collected: " + e.message, e)
      end
      
      msg = "Fragment collected."
      if relation.is_a? Game::Database::RelationShips::UserCompletedMessage
        msg = "Message completed."
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        message: msg,
        exp_gained: extra[:exp]
      })
    end
    
    # Escribir mensaje de un usuario.
    def self.user_write_message( app, response, session )
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      msg_content  = response[:request][:request][:data][:content].to_s
      msg_resource = response[:request][:request][:data][:resource].to_s
      
      msg = user.write_message( msg_content, :resource_link => msg_resource )
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        written_message: msg.get_user_message()
      })
    end
    
    # Recibir fragmentos de mensajes cercanos al usuario.
    def self.user_get_nearby_message_fragments( app, response, session )
      default_ignore = "true"
      
      ignore  = (response[:request][:request][:data][:ignore_user_written_messages] || default_ignore) == "true"
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )

      # Geolocalizaciones (como arrays).
      output = user.search_nearby_fragments(ignore)

      # Comprobar si es necesario añadir nuevos fragmentos
      if ignore == true
        Game::Mechanics::MessageMechanics.generate_nearby_fragments(user, output[:system_fragments])
      end
      
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
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        completed_messages:  user.get_completed_messages(),  # Añadir mensajescompletados.
        fragmented_messages: user.get_fragmented_messages()  # Y mensajes fragmentados.
      })
    end
    
    # Listar fragmentos recolectados de un mensaje determinado.
    def self.user_get_collected_message_fragments( app, response, session )
      user     = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      message  = Game::Database::Message.find_by( uuid: response[:request][:request][:data][:msg_uuid] )
      
      if message == nil
        raise ::GenericException.new( "Unkown message." )
      end

      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        fragments: user.get_collected_message_fragments(message)
      })
    end
  end
  
end; end; end
