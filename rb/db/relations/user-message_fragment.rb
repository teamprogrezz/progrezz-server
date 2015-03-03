
module Game
  module Database
    
    # Forward declaration
    class GeolocatedObject; end
    class User < GeolocatedObject; end
    class MessageFragment < GeolocatedObject; end
    
    # Contenedor de relaciones especiales de la base de datos.
    module RelationShips
      # Relación para definir los fragmentos recolectados por un usuario.
      class UserFragmentMessage
        include Neo4j::ActiveRel
        
        #-- -------------------------
        #       Relaciones (DB)
        #   ------------------------- #++
        
        # Relaciona la clase User con la clase MessageFragment, para saber cuando ha recogido el fragmento.
        from_class Game::Database::User
        to_class   Game::Database::MessageFragment
        
        type 'owns_fragmented_message'
            
        #-- -------------------------
        #        Atributos (DB)
        #   ------------------------- #++
        property :created_at # Fecha de creación del nodo (recolección del mensaje).
  
      end
     

    end
  end
end

