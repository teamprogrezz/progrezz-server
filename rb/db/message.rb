require_relative 'user'

module Game
  module Database
    
    class Message
      include Neo4j::ActiveNode
      
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

      #-- -------------------------
      #       Relaciones (DB)
      #   ------------------------- #++
      
      # Relación con un autor. Se puede acceder con el atributo +author+.
      has_one :in, :author, model_class: Game::Database::User, origin: :written_messages #type: "is_written_by"

      #-- -------------------------
      #      Métodos de clase
      #   ------------------------- #++

      # Creación de nuevos mensajes.
      #
      # * *Argumentos* :
      #   - +cont+: Contenido del mensaje.
      #   - +n_fragments+: Número de fragmentos en el que se romperá el mensaje. Por defecto, 1.
      #   - +resource+: Recurso mediático (opcional).
      #   - +custom_author+: Autor del mensaje (opcional).
      def self.create_message(cont, n_fragments = 1, resource = nil, custom_author = nil)
        begin
          message = create( {content: cont, total_fragments: n_fragments, resource_link: resource });
          if custom_author != nil
            custom_author.add_msg(message)
            message.author = custom_author
          end

        rescue Exception => e
          raise "DB ERROR: Cannot create message '" + self.to_s() + "': \n\t" + e.message;
        end
        
        return message
      end
    end
    
    #-- -------------------------
    #          Métodos
    #   ------------------------- #++
    
    # Stringificar objeto.
    #
    # * *Retorna* :
    #   - Objeto como string, con el formato "<User +user_id+,+alias+,+geolocation+>".
    def to_s
      return "<Message: " + self.content + ", " + self.author + ", " + self.total_fragments + ", " + self.resource_link + ">" 
    end
  end
end
