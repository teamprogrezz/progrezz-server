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
      #                      Constantes
      #   -------------------------------------------------- #++
      
      # Fragmentos en los que se partirán los mensajes de un usuario.
      USER_MESSAGE_FRAGMENTS = 1 
      
      # Método de búsqueda de mensajes por defecto.
      DEFAULT_SEARCH_METHOD = "neo4j"
      
      # TODO: Añadir límite de mensajes (según el nivel, o algo así).
      
      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++
      
      # Identificador del usuario.
      #
      # @return [String] Debe ser único, como el correo electrónico.
      property :user_id, constraint: :unique
      
      # Alias o nick del usuario.
      # No tiene por qué ser único.
      # @return [String] 
      property :alias, type: String, default: ""
      
      # Timestamp o fecha de creación del mensaje.
      # @return [DateTime] Fecha de creación.
      property :created_at
      
      # Fecha hasta la que ha sido baneado el usuario.
      # @return [Date] Segundos desde el 1/1/1970
      property :banned_until, type: DateTime, default: 0
      
      # Flag para saber si un usuario está conectado o no (mediante websockets).
      # @return [Boolean] True si está conectado (mediante websockets). False en caso contrario.
      property :is_online, type: Boolean, default: false
      
        # Datos auxiliares para no tener que buscar en la base de datos.
      
      # Contador de mensajes escritos por el usuario.
      # @return [Integer] Cantidad de mensajes escritos por el usuario.
      property :count_written_messages, type: Integer, default: 0
      
      # Contador de fragmentos recolectados por el usuario.
      # @return [Integer] Cantidad de fragmentos recolectados por el usuario.
      property :count_collected_fragments, type: Integer, default: 0
      
      # Contador de mensajes completados por el usuario.
      # @return [Integer] Cantidad de mensajes completados por el usuario.
      property :count_completed_messages, type: Integer, default: 0
      
      # Contador de mensajes desbloqueados por el usuario.
      # @return [Integer] Cantidad de mensajes desbloqueados por el usuario.
      property :count_unlocked_messages, type: Integer, default: 0
      
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # @!method written_messages
      #
      # Relación de mensajes creados por el usuario.
      #
      # Si se borra el usuario, se borrarán todos sus mensajes.
      # Se puede acceder con el atributo #written_messages. Tiene como tipo +has_written+.
      #
      # @return [Game::Database::Message]
      has_many :out, :written_messages, model_class: Game::Database::Message, type: "has_written", dependent: :destroy
      
      # @!method collected_fragment_messages
      # Relación de fragmentos recolectados por el usuario. Se puede acceder con el atributo #collected_fragment_messages.
      # @return [Game::Database::RelationShips::UserFragmentMessage] 
      has_many :out, :collected_fragment_messages, rel_class: Game::Database::RelationShips::UserFragmentMessage, model_class: Game::Database::MessageFragment
      
      # @!method collected_completed_messages
      # Relación de mensajes completados por el usuario.
      # Se puede acceder con el atributo +collected_completed_messages+.
      # @return [Game::Database::RelationShips::UserCompletedMessage] 
      has_many :out, :collected_completed_messages, rel_class: Game::Database::RelationShips::UserCompletedMessage, model_class: Game::Database::Message
      
      # @!method :level_profile
      # Relación con el nivel del usuario (#Game::Database::User). Se puede acceder con el atributo +user+.
      # @return [Game::Database::User] Usuario que posee este nivel.
      has_one :out, :level_profile, model_class: Game::Database::LevelProfile, type: "profiles_in", dependent: :destroy
      
      #-- --------------------------------------------------
      #      Métodos de clase
      #   -------------------------------------------------- #++

      # Creación de nuevos usuarios.
      #
      # En caso de error, lanzará una excepción como una String (Exception).
      #
      # @param al [String] Alias o nick del usuario.
      # @param uid [String] Identificador de usuario (correo electrónico).
      def self.sign_up(al, uid, position = {latitude: 0.0, longitude: 0.0} )
        begin          
          user = create( { alias: al, user_id: uid } ) do |usr|
            usr.set_geolocation( position[:latitude], position[:longitude] )
            # Crear perfil
            usr.level_profile = Game::Database::LevelProfile.create( )
          end

        rescue Exception => e
          raise "DB ERROR: Cannot create user '" + al + " with unique id '" + uid + "': \n\t" + e.message + "\n\t\t" + e.backtrace.to_s + "\n";
        end

        return user
      end
      
      # Retornar lista de usuarios online.
      # @return [Object] Query de neo4j.
      def self.online_users()
        return Game::Database::User.where( is_online: true )
      end
      
      # Buscar un usuario
      #
      # @param user_id [String] Identificador de usuario (correo electrónico).
      #
      # @return [Game::Database::User] Si el usuario existe, devuelve una referencia al mismo. Si no, genera una excepción.
      def self.search_user(user_id)
        # Identificar que el usuario exista, etc.
        user = Game::Database::User.find_by( user_id: user_id )
        
        # Si no existe, error.
        if user == nil
          raise "User with user_id " + user_id.to_s + " does not exist."
        end
        
        return user
      end
      
      #-- --------------------------------------------------
      #                     Acciones (juego)
      #   -------------------------------------------------- #++
      
      # Escribir nuevo mensaje.
      #
      # @param content [String] Contenido del nuevo mensaje a escribir.
      # @param resource [String, nil] Recurso del mensaje (por defecto es nil).
      #
      # @return [Game::Database::Message] Referencia al nuevo mensaje escrito.
      def write_message(content, resource = nil)
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsManagement.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        if content.length    < Game::Database::Message::CONTENT_MIN_LENGTH
          raise "Message too short (" + content.length.to_s + " < " + Game::Database::Message::CONTENT_MIN_LENGTH.to_s + ")."
        elsif content.length > Game::Database::Message::CONTENT_MAX_LENGTH
          raise "Message too long (" + content.length.to_s + " > " + Game::Database::Message::CONTENT_MAX_LENGTH.to_s + ")."
        end
        
        if resource.to_s.length > Game::Database::Message::RESOURCE_MAX_LENGTH
          raise "Resource too long (" + resource.length.to_s + " > " + Game::Database::Message::RESOURCE_MAX_LENGTH.to_s + ")."
        end
        
        # Aumentar mensajes escritos
        self.update( { count_written_messages: count_written_messages + 1 } )
        
        return Game::Database::Message.create_message(content, USER_MESSAGE_FRAGMENTS, resource, self, geolocation(), { latitude: 0, longitude: 0 }, false, false )
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
        Game::Mechanics::AllowedActionsManagement.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        if fragment_message != nil
          
          # Si el fragmento es suyo, no recogerlo
          if (fragment_message.message.author != nil && fragment_message.message.author == self)
            raise "User fragment."
          end
          
          # Si ya tiene el mensaje completado, no añadir el fragmento
          #if ( self.collected_completed_messages.where(uuid: fragment_message.message.uuid).first != nil ) 
          if ( self.collected_completed_messages.include?(fragment_message.message) ) 
             raise "Message already completed."
          end
          
          # Si ya tiene el fragmento, no volver a añadirlo
          #if ( self.collected_fragment_messages.where(uuid: fragment_message.uuid).first != nil )
          query = self.collected_fragment_messages.where(fragment_index: fragment_message.fragment_index).message.where( uuid: fragment_message.message.uuid )
          if ( query.first != nil )
            raise "Fragment already collected."
          end
                    
          # Añadir experiencia al usuario
          method_name = (__callee__).to_s
          out[:exp] = Game::Mechanics::LevelingManagement.gain_exp(self, method_name)
          
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
          raise "Nul fragment."
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
        Game::Mechanics::AllowedActionsManagement.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        output = nil
        
        self.collected_completed_messages.where(uuid: msg_uuid).each_with_rel do |msg, rel|
          if rel.status != Game::Database::RelationShips::UserCompletedMessage::STATUS_LOCKED
            raise "Message already unlocked."
          end
          
          output = rel.change_message_status( Game::Database::RelationShips::UserCompletedMessage::STATUS_UNREAD )
        end
        
        if output == nil
          raise "User does not own message '" + msg_uuid + "' to unlock."
        end
        
        # Añadir al contador
        self.update( { count_unlocked_messages: count_unlocked_messages + 1 } )
        
        # Añadir experiencia al usuario
        method_name = (__callee__).to_s
        out[:exp] = Game::Mechanics::LevelingManagement.gain_exp(self, method_name)
        
        return output
      end

      # Buscar mensajes cercanos a un usuario.
      # Ignorar los fragmentos escritos por el usuario.
      # @param ignore_user_written_messages [Boolean] Flag para ignorar los mensajes escritor por el usuario.
      # @return [Hash] Resultado de la búsqueda (fragmentos cercanos).
      def search_nearby_fragments( ignore_user_written_messages = true )
        # Lanzará una excepción si no se permite al usuario realizar la acción.
        Game::Mechanics::AllowedActionsManagement.action_allowed?(self.level_profile.level, __callee__.to_s)
        
        # El radio dependerá del nivel del usuario.
        radius = self.get_current_search_radius(:fragments)
        method = DEFAULT_SEARCH_METHOD
        
        user_geo = geolocation

        # Resultado
        output = {
          user_fragments:   {},
          system_fragments: {}
        }
        
        # Ejecutar de una manera o de otra en función del método.
        case method
        when "progrezz"
          Game::Database::MessageFragment.each do |fragment|
            frag_geo = fragment.geolocation
            
            if Progrezz::Geolocation.distance(user_geo, frag_geo, :km) <= radius
              sym = :system_fragments
              sym = :user_fragments if fragment.message.author != nil
              
              output[sym][ fragment.uuid ] = fragment.to_hash
            end
          end
          
        when "geocoder"
          user_geo = user_geo.values
          
          Game::Database::MessageFragment.each do |fragment|
            frag_geo = fragment.geolocation.values

            if Geocoder::Calculations.distance_between(user_geo, frag_geo, {:units => :km}) <= radius
              sym = :system_fragments
              sym = :user_fragments if fragment.message.author != nil
              
              output[sym][ fragment.uuid ] = fragment.to_hash
            end
          end
          
        when "neo4j"
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
          
        end
      
        # Eliminar mensajes cuyo autor sea el que realizó la petición
        if ignore_user_written_messages == true
          output[:system_fragments].delete_if { |key, fragment| fragment[:message][:author][:author_id] == self.user_id }
          output[:user_fragments].delete_if { |key, fragment| fragment[:message][:author][:author_id] == self.user_id }
        end
        
        return output
      end
      
      
      #-- --------------------------------------------------
      #                        Métodos
      #   -------------------------------------------------- #++
      
      # Actualizar perfil del usuario.
      #
      # Cambiarán los atributos de un usuario (alias, de momento). Se 
      # guardará en la base de datos siempre y cuando se haya cambiado 
      # al menos un atributo.
      #
      # @param attributes [Hash<Symbol, Object>] Lista de atributos a actualizar, con sus respectivos valores (ej: { alias: => "pepio" }).
      def update_profile( attributes = {} )
        changed = false
        
        attributes.delete( :user_id )
        self.update( attributes )
      end
      
      # Actualizar estado "online" del jugador.
      # @param new_status [Boolean] Nuevo estado. True si es online, False si es offline.
      def online(new_status = true) 
        self.update( {is_online: new_status} )
      end
      
      # Añadir nuevo mensaje.
      #
      # @param message [Game::Database::Message] Nuevo mensaje a añadir.
      def add_msg(message)
        self.written_messages << message
        
        return message
      end
      
      # Obtener mensajes completados por el usuario como un hash (usado para la API REST).
      #
      # @return [Hash<String, Object>] Se retornará una lista con las características de los mensajes completados por el usuario.
      def get_completed_messages()
        output = {}
        
        self.collected_completed_messages.each_with_rel do |msg, rel|
          output[msg.uuid] = msg.get_user_message(rel)
        end
        
        return output
      end
      
      # Listar fragmentos recolectados de un mensaje.
      # @param message [Game::Database::Message] Mensaje cuyos fragmentos serán buscados.
      # @return [Hash] Lista de fragmentos recolectados por un usuario.
      def get_collected_message_fragments(message)
        output = {}
        msg_uuid = message.uuid
        
        self.collected_fragment_messages.each do |fragment|
          if fragment.message.neo_id == message.neo_id
            if output[msg_uuid] == nil
              output[msg_uuid] = []
            end
            
            output[msg_uuid] << fragment.to_hash( [:message] )
          end
        end
        
        return output
      end
      
      # Cambiar el estado de un mensaje completado por el usuario
      #
      # @deprecated No debe ser usado, ya que puede comprometer la jugabilidad.
      #
      # @param msg_uuid [String] Identificador del mensaje completado.
      # @param new_status [String] Nuevo estado del mensaje a cambiar de estado (véase Game::Database::Message).
      #
      # @return [Game::Database::Relations::UserCompletedMessage] Referencia al *enlace* del mensaje completado. Si no, se retornará nil.
      def change_message_status(msg_uuid, new_status)
        output = nil
        
        self.collected_completed_messages.where(uuid: msg_uuid).each_with_rel do |msg, rel|
          output = rel.change_message_status(new_status)
        end
        
        return output
      end
      
      # Getter del radio de búsqueda de un determinado objeto
      # @param element [Symbol] Radio del tipo de elemento deseado (:fragments, ...).
      # @return [Float] Radio de búsqueda, en km.
      def get_current_search_radius( element = :fragments)
        if element == :fragments
          return Game::Mechanics::AllowedActionsManagement.get_allowed_actions(self.level_profile.level)["search_nearby_fragments"]["radius"]
        end
        
        # ...

        return nil
      end
      
      # Obtener mensajes fragmentados de un usuario como un hash.
      #
      # Se usará principalmente para la API REST.
      #
      # El formato de respuesta es el siguiente:
      #
      #   { type: "json", completed_messages = { uuid1: { content: "...", author: "...", ... }, uuid2: {...}, ... }, fragmented_messages = { uuid1: { content: "...", author: "...", fragments: n, ... }, ... }  }
      #
      # @return [Hash<Symbol, Object>] Se retornará una lista con las características de los mensajes fragmentados de un usuario.
      def get_fragmented_messages()
        output = {}
        
        collected_fragment_messages.each_with_rel do |fragment, rel|
          msg = fragment.message
          
          # Añadir mensaje por primeravez
          if output[msg.uuid] == nil
            output[msg.uuid] = msg.get_user_message(rel)
            output[msg.uuid][:fragments] = []
          end
        
          # Fragmentos
          output[msg.uuid][:fragments] << fragment.fragment_index
        end
        
        return output
      end
      
      # Buscar usuarios cercanos.
      # @param radius [Float] Radio de búsqueda (km).
      # @return [Array<Game::Database::User>] Usuarios cercanos.
      def get_online_nearby_users(radius)
        user_geo = geolocation.values
        lat = Progrezz::Geolocation.distance_to_latitude(radius, :km)
        lon = Progrezz::Geolocation.distance_to_longitude(radius, :km)
        
        users = User.query_as(:u)
          .where("u.user_id <> {user_id} and u.is_online = true and u.latitude > {l1} and u.latitude < {l2} and u.longitude > {l3} and u.longitude < {l4}")
          .params(user_id: self.user_id, l1: (user_geo[0] - lat), l2: (user_geo[0] + lat), l3: (user_geo[1] - lon), l4: (user_geo[1] + lon)).pluck(:u)
        
        output = []
        
        users.each do |u|
          output << u.to_hash
        end
        
        return output
      end
      
      # Devuelve las estadísticas del jugador.
      # @return [Hash<Symbol, Object>] Hash con todas las estadísticas y datos del usuario.
      def get_stats()
        return {
          # Datos del usuario
          info: {
            user_id:    self.user_id,
            alias:      self.alias,
            created_at: self.created_at.strftime('%Q').to_i
          },
          
          # Nivel y experiencia
          level: {
            current_level:  self.level_profile.level,
            current_exp:    self.level_profile.level_exp,
            next_level_exp: Game::Mechanics::LevelingManagement.exp_to_next_level(self.level_profile.level + 1)
          },
          
          # Estadísticas de mensajes
          messages: {
            completed_messages:  self.count_completed_messages,
            collected_fragments: self.count_collected_fragments,
            unlocked_messages:   self.count_unlocked_messages,
            written_messages:    self.count_written_messages
          }

          
          # Otras estadísticas
          # ...
        }
      end

      # Stringificar objeto.
      #
      # @return [String] Objeto como string, con el formato "<User: +user_id+,+alias+,+geolocation+>".
      def to_s
        return "<User: " + self.user_id + ", " + self.alias + ", " + self.is_online.to_s + ", " + super.to_s + ", " + self.level_profile.to_s + ">" 
      end
      
      # Retornar objeto como hash.
      # @param exclusion_list [Array<Symbol>] Lista de elementos a excluir.
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash(exclusion_list = [:user_id])
        output = {}
        
        if !exclusion_list.include? :user_id;     output[:user_id]     = self.user_id end
        if !exclusion_list.include? :alias;       output[:alias]       = self.alias end
        if !exclusion_list.include? :geolocation; output[:geolocation] = self.geolocation end
        
        return output
      end
      
    end
  end
end
