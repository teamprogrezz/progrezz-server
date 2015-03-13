# encoding: UTF-8

require 'progrezz/geolocation'

module Game
  
  # Módulo de mecánicas de juego
  module Mechanics

    # Clase gestora de las mecánicas de juego referente a los mensajes y sus fragmentos.
    class MessageManagemet
      # Cantidad de fragmentos a generar por kilómetro
      FRAGMENT_REPLICATION_PER_RADIUS_KM = 6

      # Espacio para generar fragmentos
      FRAGMENT_REPLICATION_RADIUS = 4

      # Número mínimo de fragmentos en la zona para empezar a generar más fragmentos.
      FRAGMENT_MIN_COUNT = 2

      # Generar fragmentos cercanos al usuario.
      # @param user [Game::Database::User] Referencia a un usuario.
      # @param fragments [Hash<Symbol, Object>] Fragmentos cercanos a +user+.
      # @param radius [Float] Radio de generación (depende del usuario).
      # @return [Integer] Número de mensajes cercanos actuales.
      def self.generate_nearby_fragments(user, fragments) 
        # El radio se obtiene directamente del usuario
        radius = user.get_current_search_radius(:fragments)
        
        # Fragmentos cercanos al usuario
        fragment_count = fragments.length
        
        # Fragmentos a generar
        max_fragments = (radius * FRAGMENT_REPLICATION_PER_RADIUS_KM).round
        
        puts "" + fragment_count.to_s + "/" + FRAGMENT_MIN_COUNT.to_s + "? -> " + max_fragments.to_s
        
        # Salir si ya hay suficientes fragmentos generados.
        if fragment_count >= FRAGMENT_MIN_COUNT
          return
        end
        
        random_generator = Random.new
        random_list = Game::Database::Message.unauthored_replicable_messages()
        num_of_msg = random_list.count
        
        if num_of_msg == 0
          raise "There are no replicable messages to generate."
        end
        
        offsets = {latitude: 0, longitude: 0}
        
        while fragment_count <= max_fragments do     
          random_msg = random_list.sample
          
          # Generar offsets a partir del radio
          offsets[:latitude]  = Progrezz::Geolocation.distance_to_latitude(  radius, :km )
          offsets[:longitude] = Progrezz::Geolocation.distance_to_longitude( radius, :km )
          
          # Replicar mensaje
          new_fragments = random_msg.replicate( user.geolocation, offsets )
          new_fragments.each do |fragment|
            fragments[fragment.uuid] = fragment.to_hash
          end
          
          # Incrementar número de fragmentos
          fragment_count += random_msg.total_fragments
        end
        
        return fragment_count
      end
      
      
    end
    

  end
end

