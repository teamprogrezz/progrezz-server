
module Game
  module Database
    
    class GeolocatedObject < RemovableObject; end
    class User < GeolocatedObject; end
    class MessageFragment < GeolocatedObject; end
    # Forward declaration
    
    # Contenedor de relaciones especiales de la base de datos.
    module RelationShips
      
      # Relación para definir los fragmentos recolectados por un usuario.
      # 
      # Contendrá la fecha de recolección del fragmento.
      class UserFragmentMessage
        include Neo4j::ActiveRel
        
        #-- -------------------------
        #       Relaciones (DB)
        #   ------------------------- #++
        
        # @!method from_class
        # Relaciona la clase User con la clase MessageFragment, para saber cuando ha recogido el fragmento.
        # @return [Game::Database::User]
        from_class Game::Database::User
        
        # @!method to_class
        # Relaciona la clase User con la clase MessageFragment, para saber cuando ha recogido el fragmento.
        # @return [Game::Database::MessageFragment]
        to_class   Game::Database::MessageFragment
        
        # @!method type
        # Tipo o nombrel del enlace.
        # @return [String] 'owns_fragmented_message'
        type 'owns_fragmented_message'
            
        #-- -------------------------
        #        Atributos (DB)
        #   ------------------------- #++
        
        # Timestamp o fecha de completación del mensaje.
        # @return [DateTime] Fecha de creación.
        property :created_at
        
      end
    end
  end
end

