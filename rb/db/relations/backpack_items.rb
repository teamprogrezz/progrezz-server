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
      #
      # @note Los atributos de esta clase NO deben alterarse de manera manual.
      # Use los métodos de la clase #Game::Database::Backpack.
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
        # @return [Integer] Índice en la mochila. Debe ser mayor que cero, y no tiene porque estar contenido en el número de slots de la mochila.
        property :stack_id, type: Integer, default: -1
        
        # Cantidad de objetos en este stack.
        # @return [Integer] No puede superar el límite según el objeto.
        property :amount, type: Integer, default: 0
        
        # TODO: Rellenar.

        # Retornar objeto como hash.
        # @param exclusion_list [Array<Symbol>] Lista de elementos a excluir.
        # @return [Hash<Symbol, Object>] Objeto como hash.
        def to_hash(exclusion_list = [])
          return {
            id:              neo_id,
            created_at:      self.created_at.to_i,
            #backpack_index:  self.backpack_index,
            amount:          self.amount,
            max_amount:      self.to_node.max_amount
          }
        end
        
        # Comprobar si una cantidad de objetos caben en el stack.
        # @param add_amount [Integer] Cantidad supuesta a añadir.
        # @return [Boolean] True si cabe. False en caso contrario.
        def fits?(add_amount)
          return (self.amount + add_amount) <= to_node.max_amount
        end
        
        
        # Añadir una cantidad al stack (forzado).
        # @note No use esta función a la ligera.
        # @param add_amount [Integer] Cantidad a añadir.
        # @return [Integer, nil] Devuelve la cantidad actual del stack una vez añadido.
        def force_add_item(add_amount)
          current_amount = self.amount + add_amount
          self.update( amount: self.amount + add_amount )
          return current_amount
        end
        
        # Intenta añadir una cantidad al stack.
        # @param add_amount [Integer] Cantidad a añadir.
        # @return [Integer, nil] Devuelve la cantidad actual del stack una vez añadido. Si no puede añadirse, retorna nil.
        def add_item(add_amount)
          return force_add_item(add_amount) if fits?(add_amount)          
          return nil
        end
        
        # Borrar una cantidad de objetos del stack.
        #
        # Si es demasiado grande, se borrará el stack completo.
        #
        # @param am [Integer] Cantidad de objetos a borrar del stack.
        # @return [Integer] Cantidad de objetos borrados.
        def remove_amount(am)
          if am < self.amount      
            self.update( amount: self.amount - am )
            am = self.amount
          else
            am = self.amount
            self.remove()
          end
          
          return am
        end
        
        # Cantidad de objetos que caben en el 
        def empty_space()
          return to_node.max_amount - self.amount
        end
        
        # Borrar enlace.
        def remove()
          Game::Database::DatabaseManager.export_neo4jnode(nil, [stack])
          stack.destroy()
        end
        
      end
      
    end
  end
end
