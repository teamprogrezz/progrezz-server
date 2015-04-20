# encoding: UTF-8

require 'progrezz/geolocation'

require_relative 'geolocated_object'

module Game
  module Database
    
    class User < GeolocatedObject
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                    Callbacks (juego)
      #   -------------------------------------------------- #++
            
      # Callback de subida de nivel.
      add_event_listener :OnLevelUp, lambda { |user, new_level|
        raise ::GenericException.new("Invalid user.") if (user == nil)
        
        new_level ||= user.level_profile.level
        user.backpack.recalculate_slots(new_level)
      }
      
      #-- --------------------------------------------------
      #                  Métodos
      #   -------------------------------------------------- #++
            
      # Lanzar un evento desde el usuario actual.
      #
      # Lista de eventos registrados:
      # - +:onLevelUp (user, new_level)+: Al subir de nivel. 
      #
      # @param event_name [Object] Nombre del evento a lanzar.
      # @param args [Object] Argumentos a pasar a los callbacks (además de +self+).
      def dispatch(event_name, *args)
        self.class.dispatch_event(event_name, self, *args)
      end
      
      # Añadir eventos existentes
      
      
    end
    
  end
end