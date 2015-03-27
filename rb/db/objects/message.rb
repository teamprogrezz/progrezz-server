# encoding: UTF-8

require 'thread'
require 'thwait'
require 'rest-client'

require_relative 'user'
require_relative 'message_fragment'
require_relative '../relations/user-completed_message'

module Game
  module Database
    
    # Clase que representa a un mensaje en la base de datos.
    #
    # Se caracteriza por estar enlazado con diversos tipos de nodos, principalmente con
    # un autor y una serie de fragmentos geolocalizados.
    class Message
      include Neo4j::ActiveNode
      
      #-- -------------------------
      #        Constantes
      #   ------------------------- #++
      
      # Nombre de autor desconocido.
      NO_AUTHOR = "?"
      # Nombre de recurso no especificado.
      NO_RESOURCE = ""
      
      # Tamaño mínimo del contenido.
      CONTENT_MIN_LENGTH = 9
      
      # Tamaño máximo del contenido.
      CONTENT_MAX_LENGTH = 255
      
      # Tamaño máximo del recurso.
      RESOURCE_MAX_LENGTH = 128
      
      # Fichero para guardar mensajes borrados.
      REMOVE_DUMP_FILE = "tmp/dump_"
      
      
      #-- -------------------------
      #        Atributos (DB)
      #   ------------------------- #++
      
      # Identificador de mensaje (se usa el uuid de neo4j).
      #property :id_msg, constraint: :unique
      
      # Número total de fragmentos que tiene el mensaje.
      #
      # @return [Integer] Debe ser mayor que cero.
      property :total_fragments, type: Integer
      
      # Cantidad de replicaciones del mensaje.
      #
      # @return [Integer] Se incrementará cada vez que se replique un mensaje.
      property :replications, type: Integer, default: 0

      # Contenido del mensaje.
      #
      # @return [String].
      property :content, type: String
      
      # Recurso adicional (imagen, hipervínculo, ...).
      # Totalmente opcional.
      #
      # @return [String].
      property :resource_link, type: String
      
      # Mensaje replicable o no (crear más fragmentos).
      # @return [Boolean] True si es replicable. False en caso contrario.
      property :replicable, type: Boolean, default: false
      
      # Ajustar fragmentos de mensajes a carreteras cercanas.
      # @return [Boolean] True si es ajustable. False en caso contrario.
      property :snap_to_roads, type: Boolean, default: false
      
      # Timestamp o fecha de creación del mensaje.
      # @return [DateTime] Fecha de creación.
      property :created_at
      
      # Duración (en días) de un mensaje (y todos los fragmentos). Si es 0, durará eternamente.
      # @return [Integer] Días que durará el mensaje.
      property :duration, type: Integer, default: 0

      #-- -------------------------
      #       Relaciones (DB)
      #   ------------------------- #++
      
      # @!method author
      # Relación con un autor (#Game::Database::User). Se puede acceder con el atributo +author+.
      # @return [Game::Database::User]
      has_one :in, :author, model_class: Game::Database::User, origin: :written_messages
      
      # @!method fragments
      #
      # Relación con los fragmentos del mensaje (#Game::Database::MessageFragment).
      # Se puede acceder con el atributo #fragments. El enlace tiene nombre +is_fragmented_in+.
      # Si el mensaje se borra, desaparecerán todos los fragmentos.
      #
      # @return [Game::Database::MessageFragment] Fragmentos.
      has_many :out, :fragments, model_class: Game::Database::MessageFragment, type: "is_fragmented_in", dependent: :destroy

      # @!method owners
      # Relación con los usuarios que han completado este mensaje.
      # Se puede acceder con el atributo #owners.
      #
      # @return [Game::Database::RelationShips::UserCompletedMessage]
      has_many :in, :owners, rel_class: Game::Database::RelationShips::UserCompletedMessage, model_class: Game::Database::User
      
      #-- -------------------------
      #      Métodos de clase
      #   ------------------------- #++

      # Creación de nuevos mensajes.
      #
      # @param cont [String] Contenido del mensaje.
      # @param n_fragments [Integer] Número de fragmentos en el que se romperá el mensaje. Por defecto, 1.
      # @param extra_params [Hash<Symbol, Object>] Parámetros extra. Véase el código para saber los parámetros por defecto.
      #
      # @return [Game::Database::Message] Referencia al objeto creado en la base de datos, de tipo Game::Database::Message.
      def self.create_message(cont, n_fragments, extra_params = {} )
        params = GenericUtils.default_params( {
          resource_link: nil,
          author: nil,
          position: {
            latitude: 0,
            longitude:0
          },
          deltas: {
            latitude: 0,
            longitude:0  
          },
          replicable: true,
          snap_to_roads: true,
          duration: 0
        }, extra_params)
        
        begin
          message = create( {content: cont, total_fragments: n_fragments, resource_link: params[:resource_link], replicable: params[:replicable], snap_to_roads: params[:snap_to_roads], duration: params[:duration]  }) do |msg|
            if params[:author] != nil
              params[:author].add_msg(msg)
            end
            
            # Generar fragmentos iniciales.
            msg.replicate(params[:position], params[:deltas], true)
          end

        rescue Exception => e
          puts e.to_s
          raise "DB ERROR: Cannot create message: \n\t" + e.message + "\n\t\t" + e.backtrace.to_s;
        end
        
        return message
      end
      
      # Creación de nuevos mensajes de sistema.
      #
      # @param content [String] Contenido del mensaje.
      # @param n_fragments [Integer] Número de fragmentos en el que se romperá el mensaje. Por defecto, 1.
      # @param extra_params [Hash<Symbol, Object>] Parámetros extra. Véase el código para saber los parámetros por defecto.
      #
      # @return [Game::Database::Message] Referencia al objeto creado en la base de datos, de tipo Game::Database::Message.
      def self.create_system_message( content, n_fragments, extra_params = {} )
        params = GenericUtils.default_params( {
          resource_link: nil,
          duration: 0
        }, extra_params)
        
        begin
          message = create( {content: content, total_fragments: n_fragments, resource_link: params[:resource_link], replicable: true, snap_to_roads: true, duration: params[:duration]})

        rescue Exception => e
          puts e.to_s
          raise "DB ERROR: Cannot create message: \n\t" + e.message + "\n\t\t" + e.backtrace.to_s;
        end
        
        return message
      end
      
      # Getter de los mensajes sin autor.
      # @return [Object] Retorna un objeto neo4j conteniendo el resultado de la consulta.
      def self.unauthored_messages()
        return self.query_as(:msg).where("NOT ()-[:has_written]->msg").return(:msg).pluck(:msg)
      end
      
      class << self
        alias_method :system_messages, :unauthored_messages
      end
      
      # Getter de los mensajes sin autor que pueden ser replicables.
      # @return [Object] Retorna un objeto neo4j conteniendo el resultado de la consulta.
      def self.unauthored_replicable_messages()
        return self.query_as(:msg).where("msg.replicable = true AND NOT ()-[:has_written]->msg").return(:msg).pluck(:msg)
      end
      
      # Getter de los mensajes de un determinado autor.
      # @param author_id [String] identificador del usuario (correo).
      # @return [Object] Retorna un objeto neo4j conteniendo el resultado de la consulta.
      def self.author_messages(author_id)
        auth = Game::Database::User.search(author_id)
        if auth == nil
          raise "User does not exist."
        end
        
        return auth.written_messages
      end
      
      # Getter de los mensajes con autor.
      # @return [Object] Retorna un objeto neo4j conteniendo el resultado de la consulta.
      def self.authored_messages()
        return self.query_as(:msg).where("()-[:has_written]->msg").return(:msg)
      end
      
      # Limpiar mensajes caducados de la base de datos.
      # @return [Integer] Retorna el número de mensajes que han sido borrados.
      def self.clear_caducated_messages()
        count = 0
        
        Game::Database::DatabaseManager.run_nested_transaction do |t|
          Game::Database::Message.as(:m).where("m.duration <> 0").each do |msg|
            if msg.caducated?
              
              if msg.authored?
                msg.remove()
              else
                msg.remove_keep_msg()
              end
              
              count += 1
            end
          end
        end
        
        return count
      end
    
      #-- -------------------------
      #          Métodos
      #   ------------------------- #++
      
      # Getter del autor.
      #
      # @return [Game::Database::Author] Autor del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_AUTHOR
      def get_author()
        if(self.author == nil); return NO_AUTHOR end
        return self.author
      end
      
      # Getter del alias del autor.
      #
      # @return [String] Alias del autor del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_AUTHOR
      def get_author_alias()
        if(self.author == nil); return NO_AUTHOR end
        return self.author.alias
      end
      
      # Getter del recurso mediático.
      #
      # @return [String] Recurso mediático del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_RESOURCE
      def get_resource()
        if(self.resource_link == nil); return NO_RESOURCE end
        return self.resource_link
      end
      
      # Generar un nuevo fragmento para el mensaje.
      # @param new_location [Hash<Symbol, Float>] Hash de la geolocalización, con la forma { latitude: 0, longitude: 0 }
      # @param deltas [Hash<Symbol, Float>] Offsets para la latitud y longitud (generación aleatoria).
      # @param ignore_replicable_frag [Boolean] Ignorar flag +replicable+ del objeto.
      # @return [Hash<Game::Database::MessageFragment>] Retorna un array con las referencias a los fragmentos añadidos.
      def replicate( new_location = { latitude: 0, longitude: 0 }, deltas = { latitude: 0, longitude: 0 }, ignore_replicable_flag = false )
        # Comprobar replicación
        if ignore_replicable_flag != true && self.replicable == false
          raise "Trying to generate fragments of a irreplicable message."
        end
        
        output = []
        
        # Generar aleatoriamente la posición de cada fragmento
        random = Random.new

        task_threads = []
        locations    = Array.new(self.total_fragments) 
        
        #puts "------- START -------"
        
        locations.each_index do |i|
          task_threads << Thread.new {
            locations[i] = {
              latitude:  new_location[:latitude]  + random.rand( (-deltas[:latitude])..(deltas[:longitude]) ),
              longitude: new_location[:longitude] + random.rand( (-deltas[:longitude])..(deltas[:longitude]) )
            }
            
            # Ajustar a carretera
            if self.snap_to_roads
              Game::Mechanics::GeolocationManagement.snap_geolocation!(locations[i])
            end
          }
        end
        
        task_threads.each(&:join)
        
        #puts "post: " + locations.to_s
        #puts "------- END -------"
        
        # Añadir fragmentos.
        for i in 0...(self.total_fragments)
          output << MessageFragment.create_message_fragment( self, i, locations[i], self.replications )
        end
        
        # Aumentar canitdad de mensajes
        self.update( { replications: self.replications + 1 } )
        
        return output
      end
      
      # Borrar mensaje y fragmentos.
      def remove()
        # Exportar el nodo
        Game::Database::DatabaseManager.export_neo4jnode(self, self.rels)
        
        # Exportar y destruir fragmentos
        self.fragments.each do |f|
          f.remove
        end
        
        # Destruir nodo
        self.destroy()
      end
      
      # Borrar fragmentos y mantener el mensaje como replicable.
      def remove_keep_msg()
        # Exportar y destruir fragmentos
        self.fragments.each do |f|
          f.remove
        end
        
        # Marcar nodo como no replicable (ya que no se podrá copiar más).
        self.update( replicable: false )
      end
      
      # Getter formateado del mensaje conseguido por un usuario.
      #
      # Usado para la API REST.
      #
      # @param user_rel [Game::Database::Relations::UserCompletedMessage] Relación entre un usuario y un mensaje completado.
      #
      # @return [Hash<Symbol, Object>] Hash con los datos referentes al mensaje completado por el usuario.
      def get_user_message(user_rel = nil)
        output = self.to_hash([:fragments])
        
        if(user_rel != nil)
          output[:status] = { }
          output[:status][:status]     = user_rel.status                    if user_rel.respond_to? :status
          output[:status][:created_at] = user_rel.created_at.strftime('%Q') if user_rel.respond_to? :created_at
        end
        
        return output
      end
      
      # Comprobar si un mensaje ha caducado.
      # @return [Boolean] Si ha caducado, retorna True. En caso contrario, False.
      def caducated?
        if self.created_at + duration <= Time.now
          return true
        end
        
        return false
      end
      
      # Comprobar si un mensaje tiene autor.
      # @return [Boolean] Si tiene autor, retorna True. En caso contrario, False.
      def authored?
        return self.author != nil
      end
      
      # Transformar objeto a un hash
      # @param exclusion_list [Array<Symbol>] Elementos a omitir en el hash de resultado (:message, :message_content, :author, :fragments). Por defecto, se ignoran los fragmentos.
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash(exclusion_list = [:fragments] )
        output = {}
        
        if !exclusion_list.include?(:message)
          output[:message] = {
            uuid:            self.uuid,
            total_fragments: self.total_fragments,
            write_date:      self.created_at.strftime('%Q')
          }
        end
        
        if !exclusion_list.include?(:message_content)
          output[:message][:content]  = self.content
          output[:message][:resource] = self.get_resource
        end
        
        if !exclusion_list.include?(:author)
          output[:author] = {
            author_alias:    self.get_author_alias,
            author_id:       self.author != nil ? self.author.user_id : ""
          }
        end
        
        if !exclusion_list.include?(:fragments)
          output[:fragments] = []

          self.fragments.each do |frag|
            output[:fragments] << frag.to_hash([:message])
          end
        end
        
        return output
      end
      
      # Stringificar objeto.
      #
      # @return [String] Objeto como string, con el formato "<Message: +content+,+author+,+total_fragments+,+resource_link+>".
      def to_s()
        return "<Message: " + self.content + ", " + get_author_alias() + ", " + self.total_fragments.to_s + ", " + get_resource() + ">" 
      end
    end
  end
end
