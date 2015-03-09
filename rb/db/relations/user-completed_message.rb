
module Game
  module Database
    
    class User < GeolocatedObject; end
    class Message; end
    class MessageFragment < GeolocatedObject; end
    # Forward declaration

    module RelationShips
      
      # Clase para mensajes ya completados por un usuario.
      #
      # Representa una relación neo4j.
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
        
        # @!method from_class
        # Relaciona la clase User con la clase Message, para saber cuando ha completado o adquirido el mensaje.
        # @return [Game::Database::User]
        from_class Game::Database::User
        
        # @!method to_class
        # Relaciona la clase User con la clase Message, para saber cuando ha completado o adquirido el mensaje.
        # @return [Game::Database::User]
        to_class   Game::Database::Message
        
        # @!method type
        # Tipo o nombrel del enlace.
        # @return [String] 'owns_completed_message'
        type 'owns_completed_message'
        
        # -------------------------
        #       Atributos (DB)
        # -------------------------
        
        # Timestamp o fecha de completación del mensaje.
        # @return [Integer] Milisegundos desde el 1/1/1970.
        property :created_at
        
        # Estado del mensaje para el jugador (leído, no leído, etc).
        # @return [String] Por defecto vale STATUS_LOCKED.
        property :status, type: String, default: STATUS_LOCKED
        
        #-- -------------------------
        #          Métodos
        #   ------------------------- #++
        
        # Cambiar el estado del mensaje completado.
        #
        # @param new_status [String] Nuevo estado (STATUS_LOCKED, STATUS_UNREAD, STATUS_READ)
        #
        # @return [Game::Database::RelationShips::UserCompletedMessage] Referencia al *enlace* del mensaje completado. Si no, se retornará nil.
        def change_message_status(new_status) 
          self.status = new_status
          self.save # ¿?
        end

      end
      
    end
  end
end
