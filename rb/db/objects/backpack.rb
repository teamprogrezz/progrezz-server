# encoding: UTF-8

require_relative './geolocated_object'

module Game
  module Database

    class User < GeolocatedObject; end
    # Forward declaration
    
    # Clase que representa el inventario o mochila de un usuario.
    class Backpack
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # Casillas del inventario.
      # @return [Integer] Tamaño del inventario (slots).
      property :slots, type: Integer, default: 0
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # @!method user
      # Relación con el usuario que posee el inventario (#Game::Database::User). Se puede acceder con el atributo +user+.
      # @return [Game::Database::User] Usuario.
      has_one :in, :user, model_class: Game::Database::User, origin: :backpack
      
      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++
      
      # Crear un inventario para un usuario.
      # @param level [Integer] Nivel del usuario para crear los slots del inventario.
      # @return [Game::Mechanics::Backpack] Objeto creado (no enlazado a un usuario).
      def self.create_backpack( level )
        return self.create( slots: Game::Mechanics::BackpackManagement.slots(level) ) # TODO: Rellenar.
      end
      
      #-- --------------------------------------------------
      #                       Métodos
      #   -------------------------------------------------- #++
      
      # Recalcular espacio de la mochila.
      # @param new_level [Integer] Nuevo nivel. Si es nil, se cogerá el nivel actual del usuario.
      def recalculate_slots( new_level = nil )
        new_level = new_level || user.level_profile.level
        self.update( slots: Game::Mechanics::BackpackManagement.slots( new_level ) )
        return self
      end

    end
    
  end
end