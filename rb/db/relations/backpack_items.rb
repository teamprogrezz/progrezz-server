# encoding: UTF-8

require 'date'

module Game
  module Database
    
    class Backpack; end
    class Item; end
    # Forward declaration

    module RelationShips
      
      # Clase para las relaciones entre inventarios y objetos.
      #
      # Representa una relación neo4j.
      class BackpackItemStacks
        include Neo4j::ActiveRel
        
        #-- -------------------------
        #       Relaciones (DB)
        #   ------------------------- #++
        
        # @!method from_class
        # Relaciona la clase User con la clase ItemDepositInstance, para saber cuando ha minado el depósito.
        from_class Game::Database::Backpack
        
        # @!method to_class
        # Relaciona la clase User con la clase ItemDepositInstance, para saber cuando ha minado el depósito.
        # @return [Game::Database::User]
        to_class   Game::Database::Item
        
        # @!method type
        # Tipo o nombrel del enlace.
        # @return [String] 'owns_completed_message'
        type 'contains_a'
        
        # -------------------------
        #       Atributos (DB)
        # -------------------------
        
        # Timestamp o fecha de recolección del primer elemento.
        # @return [DateTime] Fecha de creación.
        property :created_at
        
        # Índice del objeto o stack en el inventario.
        # @return [Integer] Índice en la mochila. Debe ir desde 0 hasta el número de casillas máximo del inventario (excluido).
        property :backpack_index, type: Integer, default: -1
        
        # Cantidad de objetos en este stack.
        # @return [Integer] No puede superar el límite según el objeto.
        property :amount, type: Integer, default: 0
        
        # TODO: Rellenar.

        # Retornar objeto como hash.
        # @param exclusion_list [Array<Symbol>] Lista de elementos a excluir.
        # @return [Hash<Symbol, Object>] Objeto como hash.
        def to_hash(exclusion_list = [])
          return {
            created_at:      self.created_at.to_i,
            backpack_index:  self.backpack_index,
            amount:          self.amount  
          }
        end
        
      end
      
    end
  end
end
