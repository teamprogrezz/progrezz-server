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
        property :stack_id, type: Integer, default: 0
        
        # Cantidad de objetos en este stack.
        # @return [Integer] No puede superar el límite según el objeto.
        property :amount, type: Integer, default: 0

        # -------------------------
        #      Alias de métodos
        # -------------------------


        alias_method :item, :to_node
        alias_method :backpack, :from_node

        # -------------------------
        #       Métodos
        # -------------------------

        # Retornar objeto como hash.
        # @param exclusion_list [Array<Symbol>] Lista de elementos a excluir.
        # @return [Hash<Symbol, Object>] Objeto como hash.
        def to_hash(exclusion_list = [])
          return {
            stack_id:        self.stack_id,
            created_at:      self.created_at.to_i,
            amount:          self.amount,
            max_amount:      self.item.max_amount
          }
        end
        
        # Comprobar si una cantidad de objetos caben en el stack.
        # @param add_amount [Integer] Cantidad supuesta a añadir.
        # @return [Boolean] True si cabe. False en caso contrario.
        def fits?(add_amount)
          return (self.amount + add_amount) <= item.max_amount
        end

        # Comprobar si el stack tiene al menos una cantidad.
        # @param amount [Integer] Cantidad de objetos a comprobar.
        # @return [Boolean] True si existen los recursos. False en caso contrario.
        def has?(amount)
          return self.amount >= amount
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
        # Si es lo suficientemente grande, se borrará el stack completo.
        # Si es demasiado grande, lanzará una excepción.
        #
        # @param am [Integer] Cantidad de objetos a borrar del stack.
        # @return [Integer] Cantidad de objetos borrados.
        def remove_amount(am)
          if am < self.amount      
            self.update( amount: self.amount - am )
            am = self.amount
          elsif am == self.amount
            am = self.amount
            self.remove()
          else
            raise "Invalid amount (too big)."
          end
          
          return am
        end

        # Saber si el stack vacío
        # @return [Boolean] Si está vacío (0 recursos), retorna true. En otro caso, retorna false.
        def empty?
          return amount == 0
        end

        # Borra el objeto de la base de datos si está vacío.
        def remove_if_empty()
          self.remove if empty?
        end
        
        # Cantidad de objetos que caben en el 
        def empty_space()
          return item.max_amount - self.amount
        end
        
        # Borrar enlace.
        def remove()
          Game::Database::DatabaseManager.export_neo4jnode(nil, [self])
          self.destroy()
        end
        
      end
      
    end
  end
end
