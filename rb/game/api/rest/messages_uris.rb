# encoding: UTF-8

require 'json'
require 'geocoder'
require 'progrezz/geolocation'

module Sinatra; module API ;module REST

  class Methods
  
    # Getter de la información de un mensaje.
    def self.rest__message_get( app, response, session)
      msg_uuid = response[:request][:request][:data][:msg_uuid]
      msg = Game::Database::Message.find_by( uuid: msg_uuid )
      
      if msg == nil
        raise ::GenericException.new( "Message with uuid '" + response[:request][:request][:data][:msg_uuid].to_s + "' not found.", e)
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        info: msg.to_hash( [] )
      })
    end
    
    # Getter de los mensajes sin autor
    def self.rest__message_get_unauthored( app, response, session)
      msg_list = Game::Database::Message.unauthored_messages()
      
      messages = []
      msg_list.each do |msg|
        messages << msg.to_hash( [:author] )
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        messages: messages
      })
    end
    
    # Getter de un mensaje dado un fragmento.
    def self.rest__message_get_from_fragment( app, response, session)
      frag_uuid = response[:request][:request][:data][:frag_uuid]
      fragment = Game::Database::MessageFragment.find_by( uuid: frag_uuid )

      if fragment == nil
        raise ::GenericException.new( "Fragment with uuid '" + response[:request][:request][:data][:frag_uuid].to_s + "' not found.", e)
      end

      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        message: fragment.message.to_hash( )
      })
    end
    
  end
  
end; end; end
