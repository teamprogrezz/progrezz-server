
module Game
  module Database
    
    class User < GeolocatedObject; end
    class ItemDepositInstance < GeolocatedObject; end
    # Forward declaration

    module RelationShips
      
      # Clase para mensajes ya completados por un usuario.
      #
      # Representa una relación neo4j.
      class UserCollected_ItemDepositInstance
        include Neo4j::ActiveRel
        
        #-- -------------------------
        #       Relaciones (DB)
        #   ------------------------- #++
        
        # @!method from_class
        # Relaciona la clase User con la clase ItemDepositInstance, para saber cuando ha minado el depósito.
        from_class Game::Database::User
        
        # @!method to_class
        # Relaciona la clase User con la clase ItemDepositInstance, para saber cuando ha minado el depósito.
        # @return [Game::Database::User]
        to_class   Game::Database::ItemDepositInstance
        
        # @!method type
        # Tipo o nombrel del enlace.
        # @return [String] 'owns_completed_message'
        type 'has_mined'
        
        # -------------------------
        #       Atributos (DB)
        # -------------------------
        
        # Timestamp o fecha de recolección del depósito.
        # @return [DateTime] Fecha de creación.
        property :created_at

      end
      
    end
  end
end
