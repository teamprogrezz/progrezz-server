
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
        
         # Estado de mensaje "bloqueado".
        STATUS_LOCKED = "locked"
        
        # Estado de mensaje "sin leer".
        STATUS_UNREAD = "unread"
        
        # Estado de mensaje "leído".
        STATUS_READ   = "read"
        
        #-- -------------------------
        #       Relaciones (DB)
        #   ------------------------- #++
        
        # Relaciona la clase User con la clase Message, para saber cuando ha completado o adquirido el mensaje.
        from_class Game::Database::User
        to_class   Game::Database::Message
        
        type 'owns_completed_message'
        
        # -------------------------
        #       Atributos (DB)
        # -------------------------
        # Fecha de creación del nodo (recolección del mensaje).
        property :created_at
        
        # Estado del mensaje para el jugador (leído, no leído, etc).
        property :status, type: String, default: STATUS_LOCKED
        
        # Cambiar el estado del mensaje completado.
        #
        # * *Argumentos*: 
        #   - +new_status+: Nuevo estado (STATUS_LOCKED, STATUS_UNREAD, STATUS_READ)
        #
        # * *Retorna* :
        #   - Referencia al *enlace* del mensaje completado. Si no, se retornará nil.
        def change_message_status(new_status) 
          self.status = new_status
          self.save # ¿?
        end

      end
      
    end
  end
end
