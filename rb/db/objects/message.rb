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
      
      
      #-- -------------------------
      #        Atributos (DB)
      #   ------------------------- #++
      
      # Identificador de mensaje (se usa el uuid de neo4j).
      #property :id_msg, constraint: :unique
      
      # Número total de fragmentos que tiene el mensaje.
      property :total_fragments, type: Integer

      # Contenido del mensaje.
      property :content, type: String
      
      # Recurso adicional (imagen, hipervínculo, ...). Totalmente opcional.
      property :resource_link, type: String
      
      # Timestamp o fecha de creación del mensaje.
      property :created_at

      #-- -------------------------
      #       Relaciones (DB)
      #   ------------------------- #++
      
      # Relación con un autor. Se puede acceder con el atributo +author+.
      has_one :in, :author, model_class: Game::Database::User, origin: :written_messages
      
      # Relación con los fragmentos del mensaje. Se puede acceder con el atributo +fragments+.
      # Si el mensaje se borra, desaparecerán todos los fragmentos.
      has_many :out, :fragments, model_class: Game::Database::MessageFragment, type: "is_fragmented_in", dependent: :destroy

      # Relación con los usuarios que han completado este mensaje. Se puede acceder con el atributo +owners+.
      has_many :in, :owners, rel_class: Game::Database::RelationShips::UserCompletedMessage, model_class: Game::Database::User
      
      #-- -------------------------
      #      Métodos de clase
      #   ------------------------- #++

      # Creación de nuevos mensajes.
      #
      # * *Argumentos*:
      #   - +cont+: Contenido del mensaje.
      #   - +n_fragments+: Número de fragmentos en el que se romperá el mensaje. Por defecto, 1.
      #   - +resource+: Recurso mediático (opcional).
      #   - +custom_author+: Autor del mensaje (opcional).
      #
      # * *Retorna* :
      #   - Referencia al objeto creado en la base de datos, de tipo Game::Database::Message.
      def self.create_message(cont, n_fragments = 1, resource = nil, custom_author = nil, position = {latitude: 0, longitude:0 })
        begin
          message = create( {content: cont, total_fragments: n_fragments, resource_link: resource }) do |msg|
            if custom_author != nil
              custom_author.add_msg(msg)
            end
            
            # Para cada fragmento, se crea un nuevo nodo en la bd
            for fragment_index in 0...(msg.total_fragments) do
              Game::Database::MessageFragment.create_message_fragment(msg, fragment_index, position)
            end
          end

        rescue Exception => e
          puts e.to_s
          raise "DB ERROR: Cannot create message: \n\t" + e.message;
        end
        
        return message
      end
    
      #-- -------------------------
      #          Métodos
      #   ------------------------- #++
      
      # Getter del autor.
      #
      # * *Retorna* :
      #   - Autor del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_AUTHOR
      def get_author()
        if(self.author == nil); return NO_AUTHOR end
        return self.author
      end
      
      # Getter del alias del autor.
      #
      # * *Retorna* :
      #   - Alias del autor del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_AUTHOR
      def get_author_alias()
        if(self.author == nil); return NO_AUTHOR end
        return self.author.alias
      end
      
      # Getter del recurso mediático.
      #
      # * *Retorna* :
      #   - Recurso mediático del mensaje. En caso de que no exista devolverá Game::Database::Message.NO_RESOURCE
      def get_resource()
        if(self.resource_link == nil); return NO_RESOURCE end
        return self.resource_link
      end
      
      # Getter formateado del mensaje conseguido por un usuario.
      #
      # Usado para la API REST.
      #
      # * *Retorna*:
      #   - Hash con los datos referentes al mensaje completado por el usuario.
      def get_user_message(user_rel = nil)
        output = {
          author:          self.get_author_alias,
          content:         self.content,
          resource:        self.get_resource,
          total_fragments: self.total_fragments,
          write_date:      self.created_at.strftime('%Q'),
        }
        
        if(user_rel != nil)
          output[:status]     = user_rel.status                    if user_rel.respond_to? :status
          output[:created_at] = user_rel.created_at.strftime('%Q') if user_rel.respond_to? :created_at
        end
        
        return output
      end
      
      # Transformar objeto a un hash
      #
      # * *Retorna* :
      #   - Objeto como hash.
      def to_hash()
        return {
          uuid:            self.uuid,
          author:          self.get_author_alias,
          content:         self.content,
          resource:        self.get_resource,
          total_fragments: self.total_fragments,
          write_date:      self.created_at.strftime('%Q')
        }
      end
      
      # Stringificar objeto.
      #
      # * *Retorna* :
      #   - Objeto como string, con el formato "<Message: +content+,+author+,+total_fragments+,+resource_link+>".
      def to_s()
        return "<Message: " + self.content + ", " + get_author() + ", " + self.total_fragments.to_s + ", " + get_resource() + ">" 
      end
    end
  end
end
