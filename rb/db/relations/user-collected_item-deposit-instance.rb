# encoding: UTF-8

require 'date'

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
        # @return [String] 'has_mined'
        type 'has_mined'
        
        # -------------------------
        #       Atributos (DB)
        # -------------------------
        
        # Timestamp o fecha de recolección del depósito.
        # @return [DateTime] Fecha de creación.
        property :created_at
        
        # Tiempo de reutilización para el usuario para reusar la mina, especificado en segundos.
        # @return [Integer] Tiempo especificado en segundos.
        property :cooldown, type: Integer, default: 0
        
        # Comprobador del cooldown.
        # @return [Boolean] Si está en cooldown, devuelve True. En caso contrario, devuelve false.
        def cooldown?
          return DateTime.strptime((created_at.to_time.to_i + cooldown).to_s,'%s') > DateTime.now
        end
        
        # Actualizar cooldown (reusar relación).
        # @param new_cooldown [Integer] Nuevo cooldown, especificado en segundos. Si es nil, no se actualiza.
        def update_cooldown(new_cooldown = nil)
          properties = {}
          properties[:created_at] = DateTime.now
          properties[:cooldown]   = new_cooldown if new_cooldown != nil
          
          self.update( properties )
        end
        
        # Retornar objeto como hash.
        # @param exclusion_list [Array<Symbol>] Lista de elementos a excluir.
        # @return [Hash<Symbol, Object>] Objeto como hash.
        def to_hash(exclusion_list = [])
          return {
            in_cooldown:       (self.cooldown?) ? true : false,
            start:             self.created_at.to_i,
            cooldown:          self.cooldown,
            remaining_seconds: self.cooldown - (DateTime.now.to_time.to_i - self.created_at.to_time.to_i)
          }
        end
        
      end
      
    end
  end
end
