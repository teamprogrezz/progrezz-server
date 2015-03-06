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
      
      response[:response][:data][:type]    = "plain"
      response[:response][:data][:message] = "Message status changed to '" + response[:request][:request][:data][:new_status] + "'."
    end
    
    # Recoger un fragmento de mensaje cercano.
    def self.user_collect_message_fragment( app, response, session )
      user     = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      fragment = Game::Database::MessageFragment.find_by( uuid: response[:request][:request][:data][:frag_uuid] )
      
      # TODO: Comprobar que el mensaje esté lo suficientemente cerca.
      # ...
      
      if user.collect_fragment( fragment ) == nil
        raise "The fragment could not be collected."
      end
      
      response[:response][:data][:type]    = "plain"
      response[:response][:data][:message] = "Fragment collected."
    end
    
    # Escribir mensaje de un usuario.
    def self.user_write_message( app, response, session )
      user = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      msg_content  = response[:request][:request][:data][:content].to_s
      msg_resource = response[:request][:request][:data][:resource].to_s
      
      msg = user.write_msg( msg_content, msg_resource )
      
      response[:response][:data][:type]    = "json"
      response[:response][:data][:message] = msg.get_user_message()
    end
    
    # Recibir fragmentos de mensajes cercanos al usuario.
    def self.user_get_nearby_message_fragments( app, response, session )
      default_radius = 0.600      # in km
      default_method = "progrezz" # progrezz, geocoder o neo4j
      
      user    = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      radius  = response[:request][:request][:data][:radius]  || default_radius
      method  = response[:request][:request][:data][:method]  || default_method
      output  = {}
      
      # Geolocalizaciones (como arrays).
      user_geo = user.geolocation
      frag_geo = nil
      
      case method
      when "progrezz"
        Game::Database::MessageFragment.all.each do |fragment|
          #if fragment.message.author == nil || fragment.message.author.user_id != user.user_id
          frag_geo = fragment.geolocation
          
          distance = Progrezz::Geolocation.distance(user_geo, frag_geo, :km)
          if distance <= radius
            output[ fragment.uuid ] = fragment.to_hash 
          end
          #end
        end
        
      when "geocoder"
        user_geo = user_geo.values
        Game::Database::MessageFragment.all.each do |fragment|
          #if fragment.message.author == nil || fragment.message.author.user_id != user.user_id
          frag_geo = fragment.geolocation.values
          
          distance = Geocoder::Calculations.distance_between(user_geo, frag_geo, {:units => :km})
          if distance <= radius
            output[ fragment.uuid ] = fragment.to_hash
          end
          #end
        end
        
      when "neo4j"
        # ...
        puts "neo4j"
        user_geo = user_geo.values
        
        lat =  Progrezz::Geolocation.distance_to_latitude(radius, :km)
        lon = Progrezz::Geolocation.distance_to_longitude(radius, :km)
        
        Game::Database::MessageFragment.query_as(:mf).where(
           "mf.latitude  > " + (user_geo[0] - lat).to_s + " and " +
           "mf.latitude  < " + (user_geo[0] + lat).to_s + " and " +
           "mf.longitude > " + (user_geo[1] - lon).to_s + " and " +
           "mf.longitude < " + (user_geo[1] + lon).to_s).pluck(:mf).each do |fragment|
            output[ fragment.uuid ] = fragment.to_hash
        end
        
      end
    
      # formatear output
      response[:response][:data][:type]      = "json"
      response[:response][:data][:fragments] = output
    end
    
    # Listar mensajes de un usuario.
    # Entrada: Usuario, ... .
    # Salida:  Array de mensajes completados y sin completar del usuario.
    def self.user_get_messages( app, response, session )
      user = Game::Database::User.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      response[:response][:data][:type]                = "json"
      response[:response][:data][:completed_messages]  = user.get_completed_messages()  # Añadir mensajescompletados.
      response[:response][:data][:fragmented_messages] = user.get_fragmented_messages() # Y mensajes fragmentados.
    end
  end
  
end; end; end