# encoding: UTF-8

require 'date'

module Game
  module Database
    
    class User < GeolocatedObject; end
    class ItemGeolocatedObject < GeolocatedObject; end
    # Forward declaration

    module RelationShips
      
      # Clase para mensajes ya completados por un usuario.
      #
      # Representa una relación neo4j.
      class UserPlaced_ItemsGeo
        include Neo4j::ActiveRel
        
        #-- -------------------------
        #       Relaciones (DB)
        #   ------------------------- #++
        
        # @!method from_class
        # Relaciona la clase User con la clase ItemGeolocatedObject, para saber cuando ha colocado el objeto.
        # @return [Game::Database::User]
        from_class Game::Database::User
        
        # @!method to_class
        # Relaciona la clase User con la clase ItemGeolocatedObject, para saber cuando ha colocado el objeto.
        # @return [Game::Database::ItemGeolocatedObject]
        to_class   Game::Database::ItemGeolocatedObject
        
        # @!method type
        # Tipo o nombrel del enlace.
        # @return [String] 'has_placed'
        type 'has_placed'
        
        # -------------------------
        #       Atributos (DB)
        # -------------------------

        # Tipo de objeto (id) colocado por el usuario (ej: "geo_beacon").
        # @return [String] Identificador del objeto geolocalizado.
        property :item_type, type: String
        
        # Retornar objeto como hash.
        # @param exclusion_list [Array<Symbol>] Lista de elementos a excluir.
        # @return [Hash<Symbol, Object>] Objeto como hash.
        def to_hash(exclusion_list = [])
          return {
            item_type: self.item_type
          }
        end
        
      end
      
    end
  end
end
