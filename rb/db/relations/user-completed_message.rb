
module Game
  module Database
    
    # Forward declaration
    class User < GeolocatedObject; end
    class Message; end
    class MessageFragment < GeolocatedObject; end

    module RelationShips
      # Clase para mensajes ya completados
      class UserCompletedMessage
        include Neo4j::ActiveRel
        
        #-- -------------------------
        #       Constantes
        #   ------------------------- #++
        STATUS_LOCKED = "locked" # Estado de mensaje "bloqueado".
        STATUS_UNREAD = "unread" # Estado de mensaje "sin leer".
        STATUS_READ   = "unread" # Estado de mensaje "leído".
        
        #-- -------------------------
        #       Relaciones (DB)
        #   ------------------------- #++
        
        # Relaciona la clase User con la clase Message, para saber cuando ha completado o adquirido el mensaje.
        from_class Game::Database::User
        to_class   Game::Database::Message
        
        type 'owns_completed_message'
        set_classname

        
        # -------------------------
        #       Atributos (DB)
        # -------------------------
        # Fecha de creación del nodo (recolección del mensaje).
        property :created_at
        
        # Estado del mensaje para el jugador (leído, no leído, etc).
        property :status, type: String, default: STATUS_LOCKED

      end
      
    end
  end
end
