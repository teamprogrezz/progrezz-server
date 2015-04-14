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
      
      # Róazn por la que ha sido baneado el usuario.
      # @return [String] Razón.
      property :banned_reason, type: String, default: ""
      
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
      
      # Contador de objetos recolectados por el usuario.
      # @return [Integer] Cantidad de objetos recolectados por el usuario.
      property :count_collected_item_deposits, type: Integer, default: 0
      
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
      
      # @!method collected_item_deposit_instances
      # Relación de depósitos recolectados por el usuario.
      # Se puede acceder con el atributo +collected_item_deposit_instances+.
      # @return [Game::Database::RelationShips::UserCompletedMessage] 
      has_many :out, :collected_item_deposit_instances, rel_class: Game::Database::RelationShips::UserCollected_ItemDepositInstance, model_class: Game::Database::ItemDepositInstance
      
      # @!method :level_profile
      # Relación con el nivel del usuario (#Game::Database::LevelProfile). Se puede acceder con el atributo +leel_profile+.
      # @return [Game::Database::LevelProfile] Nivel del usuario.
      has_one :out, :level_profile, model_class: Game::Database::LevelProfile, type: "profiles_in", dependent: :destroy
      
      # @!method backpack
      # Relación con el inventario del usuario (#Game::Database::Backpack). Se puede acceder con el atributo +backpack+.
      # @return [Game::Database::Backpack] Inventario del usuario.
      has_one :out, :backpack, model_class: Game::Database::Backpack, type: "has_a", dependent: :destroy
      
      #-- --------------------------------------------------
      #                    Métodos de clase
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
            usr.level_profile = Game::Database::LevelProfile.create_level_profile( )
            
            # Crear el inventario
            usr.backpack = Game::Database::Backpack.create_backpack( )
          end

        rescue Exception => e
          raise ::GenericException.new( "DB ERROR: Cannot create user '" + al + " with unique id '" + uid + "': " + e.message, e )
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
          raise ::GenericException.new( "User with user_id " + user_id.to_s + " does not exist." )
        end
        
        return user
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
        elsif element == :deposits
          return Game::Mechanics::AllowedActionsManagement.get_allowed_actions(self.level_profile.level)["search_nearby_deposits"]["radius"]
        end
        
        # ...
        raise ::GenericException.new( "Invalid search radius." )
      end
            
      # Marcar mensaje como leído.
      #
      # @param msg_uuid [String] Identificador único del mensaje (uuid).
      def read_message(msg_uuid)
        output = nil
        
        self.collected_completed_messages.where(uuid: msg_uuid).each_with_rel do |msg, rel|
          if rel.status == Game::Database::RelationShips::UserCompletedMessage::STATUS_LOCKED
            raise ::GenericException.new( "Message locked. Must be unlocked first." )
          end
          
          output = rel.change_message_status( Game::Database::RelationShips::UserCompletedMessage::STATUS_READ )
        end
        
        if output == nil
          raise ::GenericException.new( "User does not own message '" + msg_uuid + "' to read." )
        end
        
        return output
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
