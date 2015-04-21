# encoding: UTF-8

require_relative './geolocated_object'
require_relative '../relations/backpack_items'

module Game
  module Database

    class User < GeolocatedObject; end
    class Item; end
    # Forward declaration
    
    # Clase que representa el inventario o mochila de un usuario.
    class Backpack
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # Casillas del inventario.
      # @return [Integer] Tamaño del inventario (slots).
      property :slots, type: Integer, default: 0
      
      # Contador de stacks.
      # @return [Integer] Contador de stacks.
      property :last_stack_id, type: Integer, default: 0
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # @!method user
      # Relación con el usuario que posee el inventario (#Game::Database::User). Se puede acceder con el atributo +user+.
      # @return [Game::Database::User] Usuario.
      has_one :in, :user, model_class: Game::Database::User, origin: :backpack
      
      # @!method stacks
      # Relación de la mochila de cada uno de los usuarios con los objetos, formando stacks. Se puede acceder con el atributo +backpack_owners+.
      # @return [Game::Database::Item] Objeto del stack.
      has_many :out, :stacks, rel_class: Game::Database::RelationShips::BackpackItemStacks, model_class: Game::Database::Item
      
      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++
      
      # Crear un inventario para un usuario.
      # @param level [Integer] Nivel del usuario para crear los slots del inventario.
      # @return [Game::Mechanics::Backpack] Objeto creado (no enlazado a un usuario).
      def self.create_backpack( level )
        return self.create( slots: Game::Mechanics::BackpackMechanics.slots(level) ) # TODO: Rellenar. (?)
      end
      
      #-- --------------------------------------------------
      #                       Métodos
      #   -------------------------------------------------- #++
      
      # Recalcular espacio de la mochila.
      # @param new_level [Integer] Nuevo nivel. Si es nil, se cogerá el nivel actual del usuario.
      def recalculate_slots( new_level = nil )
        new_level = new_level || user.level_profile.level
        self.update( slots: Game::Mechanics::BackpackMechanics.slots( new_level ) )

        raise ::GenericException.new("Invalid slots recalculation: too small.") if self.stacks.count > self.slots
        
        return self
      end

      # Añadir un nuevo stack (de manera forzada).
      # @param item [Game::Database::Item] Tipo de objeto a añadir.
      # @param amount [Integer] Cantidad a añadir.
      private def force_add_item(item, amount)
        stack = Game::Database::RelationShips::BackpackItemStacks.create({
          from_node: self,
          to_node:   item,
          amount:    amount,
          stack_id:  self.last_stack_id
        })

        self.update(last_stack_id: self.last_stack_id + 1)

        return stack
      end
      
      # Añadir objetos de un tipo al inventario.
      # @param item [Game::Database::Item] Tipo de objeto a añadir.
      # @param amount [Integer] Cantidad a añadir.
      # @return [Hash] Propiedades de la adición.
      # @raise [GenericException] Si algo falla estrepitosamente, genera una excepción.
      def add_item(item, amount)
        
        raise ::GenericException.new "Invalid item." if item == nil
        raise ::GenericException.new "Invalid amount." if amount == nil || amount <= 0
        raise ::GenericException.new "Amount is too big for one stack." if amount > item.max_amount
        
        output = {
          added_amount: 0,
          desired_add_amout: amount,
          info: ""
        }

        # Operación atómica.
        Game::Database::DatabaseManager.run_nested_transaction do |tx|
          # Comprobar si se puede añadir a un stack existente, y añadir la cantidad que se pueda a cada uno
          self.stacks.match_to(item).each_with_rel do |it, rel|
            if (empty_space = rel.empty_space()) >= 0
              add_amount = [empty_space, amount].min

              rel.force_add_item( add_amount )
              amount -= add_amount
              output[:added_amount] += add_amount
            end

            break if ( amount <= 0 )
          end

          # Si aún queda cantidad, se añade otro stack
          if amount > 0
            # En otro caso, se añadirña otro stack. Se comprueba si queda espacio para añadir un nuevo stack.
            if self.stacks.count == self.slots
              output[:info] = "Could not add all items: backpack is full."
            else
              # Finalmente, se añade el/los nuevo/s stack/s.
              output[:added_amount] += amount

              self.force_add_item( item, amount )
            end
          end
        end

        return output
      end

      # Getter de un stack dado su identificador.
      # @param stack_id [Integer] Identificador del stack (numérico).
      # @return [Game::Database::RelationShips::BackpackItemStacks] Stack o relación del nodo.
      def get_stack(stack_id)
        stack = self.stacks(:s, :r).where("r.stack_id = " + stack_id.to_s).pluck(:r).first
        raise ::GenericException.new( "Stack not found." ) if stack == nil

        return stack
      end
      
      # Borra una cantidad de un stack de objetos.
      # @param stack_id [Integer] Identificador del stack.
      # @return [Hash] Información del proceso de borrado.
      def exchange_stack_amount(stack_id, amount)
        raise ::GenericException.new( "Invalid stack id." ) if stack_id == nil || amount.to_i < 0
        raise ::GenericException.new( "Invalid amount (null)." ) if amount == nil || amount.to_i <= 0

        count = nil
        Game::Database::DatabaseManager.run_nested_transaction do |tx|
          # item = stack.to_node
          count = get_stack(stack_id).remove_amount( amount.to_i )
        end
        
        # TODO: Cambiar el contenido borrado por energía, o algo así.
        # ...
        
        return {
          removed: count
        }
      end
      
      # Particionar una pila de objetos.
      # @param stack_id [Integer] Identificador del stack.
      # @param restack_amount [Integer] Cantidad a añadir al nuevo stack, eliminándolo del viejo.
      # @return [Hash] Información de la partición.
      def split_stack(stack_id, restack_amount)
        # Comprobar si queda espacio para partir un stack.
        raise ::GenericException.new("There is no free space to split a stack.") if self.stacks.count >= self.slots

        stack = nil
        new_stack = nil

        # Operación atómica.
        Game::Database::DatabaseManager.run_nested_transaction do |tx|
          # Buscar el stack a partir del identificador
          stack = get_stack(stack_id)

          # Comprobar que hay cantidad suficiente para particionar
          raise ::GenericException.new("Invalid restack amount") if (restack_amount <= 0) || (restack_amount >= stack.amount)

          # Realizar la partición
          stack.update( amount: stack.amount - restack_amount )
          new_stack = self.force_add( stack.item, restack_amount )
        end

        # Retornar lo que sea.
        return {
          old_stack: stack.to_hash,
          new_stack: new_stack.to_hash
        }
      end
      
      # Transformar objeto a un hash
      # @param exclusion_list [Array<Symbol>] Elementos a omitir en el hash de resultado (...).
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash(exclusion_list = [])
        output = []
        index = 0
        
        self.stacks.each_with_rel do |item, rel|
          output << {
            item_id: item.item_id,
            stack: rel.to_hash
          }
          
          index += 1
        end
        
        return output
      end

    end
    
  end
end