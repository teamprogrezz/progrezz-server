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
      
      # @!method user
      # Relación con el usuario que posee el inventario (#Game::Database::User). Se puede acceder con el atributo +user+.
      # @return [Game::Database::User] Usuario.
      has_one :in, :user, model_class: Game::Database::User, origin: :backpack
      
      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++
      
      # Crear un inventario para un usuario.
      # @return [Game::Mechanics::Backpack] Objeto creado (no enlazado a un usuario).
      def self.create_backpack()
        return self.create( ) # TODO: Rellenar
      end
    end
    
  end
end