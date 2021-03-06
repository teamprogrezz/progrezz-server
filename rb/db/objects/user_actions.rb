# encoding: UTF-8

require 'progrezz/geolocation'

require_relative 'geolocated_object'
require_relative '../relations/user-message_fragment'
require_relative '../relations/user-completed_message'

module Game
  module Database
    
    class LevelProfile; end
    class Message; end
    # Forward declaration
    
    # Clase que representa a un jugador cualquiera en la base de datos.
    #
    # Se caracteriza por estar enlazado con diversos tipos de nodos, 
    # además de tener una serie de propiedades o atributos.
    #
    # Se considera un objeto geolocalizado.
    class User < GeolocatedObject
      include Neo4j::ActiveNode
      
      
      #-- --------------------------------------------------
      #                     Acciones (juego)
      #   -------------------------------------------------- #++
      
      # Escribir nuevo mensaje.
      #
      # @param content [String] Contenido del nuevo mensaje a escribir.
      # @param extra_params [Hash<Symbol, Object>] Parámetros extra. Véase el código para saber los parámetros por defecto.
      #
      # @return [Game::Database::Message] Referencia al nuevo mensaje escrito.
      def write_message(content, extra_params = {})
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        # Parámetros extra
        params = GenericUtils.default_params(default_params = {
          resource_link: nil
        }, extra_params)
        
        level_params = Game::Mechanics::AllowedActionsMechanics.action_params_by_level( self.level_profile.level, __callee__.to_s )
        
        min_lenght = level_params["min_length"]
        max_lenght = level_params["max_length"]
        
        if level_params["allow_resources"] == false
          params[:resource_link] = nil
        end
        
        if content.length    < min_lenght
          raise ::GenericException.new( "Message too short (" + content.length.to_s + " < " + min_lenght.to_s + ")." )
        elsif content.length > max_lenght
          raise ::GenericException.new( "Message too long (" + content.length.to_s + " > " + max_lenght.to_s + ")." )
        end
        
        if params[:resource_link].to_s.length > Game::Database::Message::RESOURCE_MAX_LENGTH
          raise ::GenericException.new( "Resource too long (" + resource.length.to_s + " > " + Game::Database::Message::RESOURCE_MAX_LENGTH.to_s + ")." )
        end
        
        # Aumentar mensajes escritos
        self.update( { count_written_messages: count_written_messages + 1 } )
        
        # Duración
        duration = level_params["duration"]
        
        return Game::Database::Message.create_message(content, USER_MESSAGE_FRAGMENTS, { resource_link: params[:resource_link], author: self, position: geolocation(), duration: duration, deltas: { latitude: 0, longitude: 0 }, snap_to_roads: false, replicable: false } )
      end
      
      
      # Recoger fragmento.
      #
      # No se recogerán fragmentos repetidos ni del propio usuario.
      # En caso de recoger todos los fragmentos, se añadirá el mensaje
      # a la lista de mensajes completados por el usuario. 
      #
      # @param fragment_message [Game::Database::FragmentMessage] Nuevo fragmento a añadir.
      # @param out [Hash] Salida personalizada (exp, etc).
      #
      # @return [Game::Database::RelationShips::UserFragmentMessage, Game::Database::RelationShips::UserCompletedMessage, nil] Si añade el fragmento, devuelve la referencia al enlace del fragmento añadido. Si se ha completado el mensaje, devuelve la referencia al enlace de dicho mensaje. En cualquier otro caso, generará excepciones.
      def collect_fragment(fragment_message, out = {})
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        if fragment_message != nil

          # TODO: Comprobar que el mensaje esté lo suficientemente cerca.
          # ...
          
          # Si el fragmento es suyo, no recogerlo
          if (fragment_message.message.author != nil && fragment_message.message.author == self)
            raise ::GenericException.new( "User fragment." )
          end
          
          # Si ya tiene el mensaje completado, no añadir el fragmento
          #if ( self.collected_completed_messages.where(uuid: fragment_message.message.uuid).first != nil ) 
          if ( self.collected_completed_messages.include?(fragment_message.message) ) 
             raise ::GenericException.new( "Already completed." )
          end
          
          # Si ya tiene el fragmento, no volver a añadirlo
          #if ( self.collected_fragment_messages.where(uuid: fragment_message.uuid).first != nil )
          query = self.collected_fragment_messages.where(fragment_index: fragment_message.fragment_index).message.where( uuid: fragment_message.message.uuid )
          if ( query.first != nil )
            raise ::GenericException.new( "Already collected." )
          end
                    
          # Añadir experiencia al usuario
          method_name = (__callee__).to_s
          out[:exp] = Game::Mechanics::LevelingMechanics.gain_exp(self, method_name)
          
          # Añadir al contador
          self.update( { count_collected_fragments: count_collected_fragments + 1 } )
          
          # Comprobar si es necesario quitarla, ya que ha completado el mensaje.
          # En este punto, se han descartado fragmentos repetidos. Si la cantidad de
          # fragmentos del mensaje del fragmento actual es el número total de fragmentos
          # menos uno (el que falta), se borrarán dichas relaciones y se añadirá un nuevo mensaje
          # marcado como completo.
          total_fragments_count         = fragment_message.message.total_fragments
          collected_fragments_rel       = self.collected_fragment_messages(:f, :rel).message.where(neo_id: fragment_message.message.neo_id).pluck(:rel)
          
          collected_fragments_rel_count = collected_fragments_rel.count

          if collected_fragments_rel_count == total_fragments_count - 1
            # Borrar los fragmentos
            
            collected_fragments_rel.each do |fragment_relation|
              fragment_relation.destroy
            end
            
            # Y Añadir el mensaje como completado
            message_status = Game::Database::RelationShips::UserCompletedMessage::STATUS_LOCKED
            if total_fragments_count == 1
              message_status = Game::Database::RelationShips::UserCompletedMessage::STATUS_UNREAD
            end
            
            # Añadir al contador
            self.update( { count_completed_messages: count_completed_messages + 1 } )
            
            return Game::Database::RelationShips::UserCompletedMessage.create(from_node: self, to_node: fragment_message.message, status: message_status )
          else
            return Game::Database::RelationShips::UserFragmentMessage.create(from_node: self, to_node: fragment_message )
          end
        else     
          raise ::GenericException.new( "Nul fragment." )
        end
      end
    
      # Desbloquear un mensaje.
      #
      # Desloquear un mensaje otorga, además del contenido del mismo, experiencia.
      #
      # @param msg_uuid [String] Identificador del mensaje completado.
      # @param out [Hash] Salida personalizada (experiencia, etc.)
      # @return [Game::Database::Relations::UserCompletedMessage] Referencia al *enlace* del mensaje completado. Si no, se retornará nil o se generará una excepción.
      def unlock_message(msg_uuid, out = {} )
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        output = nil
        
        self.collected_completed_messages.where(uuid: msg_uuid).each_with_rel do |msg, rel|
          if rel.status != Game::Database::RelationShips::UserCompletedMessage::STATUS_LOCKED
            raise ::GenericException.new( "Already unlocked." )
          end
          
          output = rel.change_message_status( Game::Database::RelationShips::UserCompletedMessage::STATUS_UNREAD )
        end
        
        if output == nil
          raise ::GenericException.new( "User does not own message '" + msg_uuid + "' to unlock." )
        end
        
        # Añadir al contador
        self.update( { count_unlocked_messages: count_unlocked_messages + 1 } )
        
        # Añadir experiencia al usuario
        method_name = (__callee__).to_s
        out[:exp] = Game::Mechanics::LevelingMechanics.gain_exp(self, method_name)
        
        return output
      end

      # Buscar mensajes cercanos a un usuario.
      # Ignorar los fragmentos escritos por el usuario.
      # @param ignore_user_written_messages [Boolean] Flag para ignorar los mensajes escritor por el usuario.
      # @return [Hash] Resultado de la búsqueda (fragmentos cercanos).
      def search_nearby_fragments( ignore_user_written_messages = true )
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        # El radio dependerá del nivel del usuario.
        radius = self.get_current_search_radius(:fragments)
        user_geo = geolocation

        # Resultado
        output = {
          user_fragments:   {},
          system_fragments: {}
        }
        
        user_geo = user_geo.values
        
        lat = Progrezz::Geolocation.distance_to_latitude(radius, :km)
        lon = Progrezz::Geolocation.distance_to_longitude(radius, :km)
        
        fragments = Game::Database::MessageFragment.query_as(:mf)
          .where("mf.latitude  > {l1} and mf.latitude  < {l2} and mf.longitude > {l3} and mf.longitude < {l4}")
          .params(l1: (user_geo[0] - lat), l2: (user_geo[0] + lat), l3: (user_geo[1] - lon), l4: (user_geo[1] + lon)).pluck(:mf)
           
        fragments.each do |fragment|
          sym = :system_fragments
          sym = :user_fragments if fragment.message.author != nil
            
          output[sym][ fragment.uuid ] = fragment.to_hash
        end
      
        # Eliminar mensajes cuyo autor sea el que realizó la petición
        if ignore_user_written_messages == true
          output[:system_fragments].delete_if { |key, fragment| fragment[:message][:author][:author_id] == self.user_id }
          output[:user_fragments].delete_if { |key, fragment| fragment[:message][:author][:author_id] == self.user_id }
        end
        
        return output
      end
      
      # Buscar depósitos cercanos a un usuario.
      # @return [Hash] Resultado de la búsqueda (depósitos cercanos).
      def search_nearby_deposits()
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        # El radio dependerá del nivel del usuario.
        radius = self.get_current_search_radius(:deposits)

        # Resultado
        output = { }
        
        user_geo = geolocation.values
        
        lat = Progrezz::Geolocation.distance_to_latitude(radius, :km)
        lon = Progrezz::Geolocation.distance_to_longitude(radius, :km)
        
        deposits = Game::Database::ItemDepositInstance.query_as(:id)
          .where("id.latitude  > {l1} and id.latitude  < {l2} and id.longitude > {l3} and id.longitude < {l4}")
          .params(l1: (user_geo[0] - lat), l2: (user_geo[0] + lat), l3: (user_geo[1] - lon), l4: (user_geo[1] + lon)).pluck(:id)
        
        deposits.each do |d|
          output[d.uuid] = d
        end
        
        return output
      end
      
      
      # Recolectar o minar depósito (genérico).
      #
      # No se recogerán depósitos ya recolectados.
      #
      # @param deposit_instance [Game::Database::ItemDepositInstance] Nuevo depósito a recolectar.
      # @param out [Hash] Salida personalizada (exp, etc).
      #
      # @return [Game::Database::RelationShips::UserCollected_ItemDepositInstance] Si es posible recolectar el depósito, se añade a la lista de depósitos recolectados por el usuario. En cualquier otro caso, generará excepciones.
      def collect_item_from_deposit(deposit_instance, out = {})
        raise ::GenericException.new("Null deposit.") if deposit_instance == nil
        
        # Nótese que se añade la calidad del objeto como parte de la acción. Esto se hace para
        # diferenciar claramente unas acciones de otras.
        action_name = (__callee__).to_s + "_" + deposit_instance.deposit.item.quality
        
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, action_name)

        # Si ya lo ha recolectado y está en cooldown, lanzar un error
        current_rel = self.collected_item_deposit_instances(:d, :rel).where(uuid: deposit_instance.uuid).pluck(:rel).first
        raise ::GenericException.new( "Deposit in cooldown." ) if current_rel != nil and current_rel.cooldown?
        
        # TODO: Comprobar si está lo suficientemente cerca
        # ...
        
        # Añadir al inventario del usuario (o intentarlo).
        out[:mining] = deposit_instance.gather( self )
                  
        # Si realmente ha recolectado algo, hacer lo que sigue
        if out[:mining][:added_amount] > 0
          # Añadir experiencia al usuario en función de lo recolectado (calidad).
          out[:exp] = Game::Mechanics::LevelingMechanics.gain_exp(self, action_name)
          
          # Añadir al contador
          self.update( { count_collected_item_deposits: count_collected_item_deposits + 1 } )
          
          # TODO: Cooldown en función del nivel del usuario
          cooldown = deposit_instance.deposit.user_cooldown
          
          # Marcar depósito como recolectado.
          if current_rel != nil
            current_rel.update_cooldown( cooldown )
            return current_rel
          else
            return Game::Database::RelationShips::UserCollected_ItemDepositInstance.create(from_node: self, to_node: deposit_instance, cooldown: cooldown )
          end
        end
        
      end

      # Craftear un objeto.
      # @param craft_recipe_id [String] Identificador de la receta.
      # @param out [Hash] Salida personalizada (exp, etc).
      def craft_item(craft_recipe_id, out = {})

        craft_recipe = Game::Mechanics::CraftingMechanics.get_recipe(craft_recipe_id)
        raise ::GenericException.new("Invalid craft recipe (null).") if craft_recipe == nil

        # Nótese que se añade la calidad del objeto como parte de la acción. Esto se hace para
        # diferenciar claramente unas acciones de otras.
        action_name = (__callee__).to_s + "_" + craft_recipe[:rank].to_s

        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, action_name)

        # Empezar transacción (atómica)
        # IMPORTANTE: Si algo falla, se deshará cualquier cambio.
        Game::Database::DatabaseManager.run_nested_transaction do |tx|
          # Comprobar que tiene los objetos, y quitarlos
          craft_recipe[:recipe][:input].each do |obj|

            raise ::GenericException.new("Invalid item id '" + obj[:item_id] + "'.") unless input_item = Game::Database::Item.find_by(item_id: obj[:item_id])
            raise ::GenericException.new("Invalid amount " + obj[:quantity].to_s + " of " + obj[:item_id] + ".") unless input_item_quantity = obj[:quantity]

            self.backpack.remove_item_amount input_item, input_item_quantity
          end

          # Comprobar que cabe la cantidad de objetos de salida
          output_item        = Game::Database::Item.find_by(item_id: craft_recipe[:recipe][:output][:item_id])
          output_item_amount = craft_recipe[:recipe][:output][:quantity]
          raise ::GenericException.new("User does not own a free slot to add " + output_item_amount.to_s + " of " + output_item.name) unless self.backpack.fits? output_item, output_item_amount

          # Añadir el objeto al inventario
          self.backpack.add_item output_item, output_item_amount
        end

        # Añadir experiencia al usuario en función de lo crafteado
        out[:exp] = Game::Mechanics::LevelingMechanics.gain_exp(self, action_name)

        # Añadir al contador
        self.update( { count_crafted_items: count_crafted_items + 1 } )
      end

      # Desplegar una baliza en la posición actual.
      # En caso de error, se generará la correspondiente excepción.
      # @param message [String] Mensaje de la baliza.
      # @param out [Hash] Salida personalizada (exp, etc).
      # @return [Game::Database::Beacon] Retorna una referencia a la baliza generada.
      def deploy_beacon(message, out = {})

        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, __callee__.to_s)

        # Comprobar que el usuario tenga al menos una baliza, y quitarsela
        beacon_item = Game::Database::Beacon.get_item()
        self.backpack.remove_item_amount(beacon_item, 1)
        # raise ::GenericException.new("User does not own 1x " + beacon_item.name.to_s + ".") unless self.backpack.has?( beacon_item, 1 )

        # Crear y desplegar la baliza
        beacon = Game::Database::Beacon.create_item(self, {message: message})

        # Añadir al contador
        self.update( { count_deployed_beacons: count_deployed_beacons + 1 } )

        # Retornar referencia
        return beacon
      end


      # Buscar balizas cercanas a un usuario.
      # @param out [Hash] Salida personalizada (exp, etc).
      # @return [Hash] Resultado de la búsqueda (balizas cercanos).
      def search_nearby_beacons(out = {})
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, __callee__.to_s)

        # El radio dependerá del nivel del usuario.
        radius = self.get_current_search_radius(:beacons)

        # Resultado
        beacons = Game::Database::Beacon.search_by_radius(self.geolocation, radius)
        output = {}

        beacons.each do |b|
          output[b.uuid] = b.to_hash
        end

        return output
      end

      # Ceder energía a una baliza.
      # @param beacon [Game::Database::Beacon] Referencia a la baliza.
      # @param energy_amount [Integer] Cantidad de energía a ceder.
      # @param out [Hash] Salida personalizada (exp, etc).
      def yield_energy(beacon, energy_amount, out = {})
        Game::Mechanics::AllowedActionsMechanics.action_allowed?(self.level_profile.level, __callee__.to_s)

        # Comprobar entrada
        raise ::GenericException.new( "Invalid beacon." ) if beacon == nil

        # Comprobar que el usuario tiene suficiente energía, y quitársela
        self.remove_energy(energy_amount)

        # Y cederla al objeto
        Game::Mechanics::BeaconMechanics.gain_energy(beacon, energy_amount)

      end

    end
  end
end