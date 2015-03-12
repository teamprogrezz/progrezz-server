# encoding: UTF-8

require 'json'
require 'geocoder'
require 'progrezz/geolocation'

module Sinatra; module API ;module REST

  class Methods
  
    # Getter de la información de un mensaje.
    def self.message_get( app, response, session)
      msg = Game::Database::Message.find_by( response[:request][:request][:data][:msg_uuid] )
      
      if msg == nil
        raise "Message with uuid '" + response[:request][:request][:data][:msg_uuid].to_s + "' not found."
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        info: msg.to_hash( [] )
      })
    end
    
    # Getter de los mensajes sin autor
    def self.message_get_unauthored( app, response, session)
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
    def self.message_get_from_fragment( app, response, session)
      fragment = Game::Database::Message.find_by( response[:request][:request][:data][:frag_uuid] )

      if fragment == nil
        raise "Fragment with uuid '" + response[:request][:request][:data][:frag_uuid].to_s + "' not found."
      end

      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        message: fragment.message.to_hash( )
      })
    end
    
  end
  
end; end; end
