require_relative '../relations/user-message_fragment'

module Game
  module Database
    
    # Forward declaration
    class Message; end

    # Clase que representa a un fragmento geolocalizado de un juego.
    #
    # Los atributos se guardan en el objeto (incluida geolocalización) como un nodo del grafo neo4j.
    # Las relaciones se harán mediante relaciones directas o codificadas.
    class MessageFragment < GeolocatedObject
      include Neo4j::ActiveNode
      
      #-- -------------------------
      #         Atributos DB)
      #   ------------------------- #++
      property :fragment_index, type: Integer #, constraint: :unique  # Índice de fragmento
      property :created_at                                            # Timestamp o fecha de creación del fragmento.
      
      #-- -------------------------
      #     Relaciones (DB)
      #   ------------------------- #++
      
      # Relación con el mensaje padre. Se puede acceder con el atributo +message+.
      has_one :in, :message, model_class: Game::Database::Message, origin: :fragments
      
      # Relación con fragmentos recolectados por el usuario. Se puede acceder con el atributo +owners+.
      has_many :in, :owners, rel_class: Game::Database::RelationShips::UserFragmentMessage, model_class: Game::Database::User
      
      
      #-- -------------------------
      #      Métodos de clase
      #   ------------------------- #++

      # Creación de nuevos usuarios.
      #
      # En caso de error, lanzará una excepción como una String (Exception).
      #
      # * *Argumentos* :
      #   - +msg+: Referencia al mensaje.
      #   - +f_index+: Índice del fragmento.
      #   - +position+: Posición geolocalizada del fragmento.
      def self.create_message_fragment(msg, f_index, position)
        begin
          fmsg = create( {message: msg, fragment_index: f_index, geolocated_pos: [ position[:latitude], position[:longitude] ] });

        rescue Exception => e
          puts e.to_s
          raise "DB ERROR: Cannot create fragment " + f_index.to_s + " for the message " + message.to_s + ": \n\t" + e.message;
        end
        
        return fmsg
      end

      #-- -------------------------
      #           Métodos
      #   ------------------------- #++
      # Stringificar objeto.
      #
      # * *Retorna* :
      #   - Objeto como string, con el formato "<MessageFragment: +uuid+,+message.uuid+,+fragment_index+,+geolocation+>".
      def to_s()
        return "<MessageFragment: " + self.uuid.to_s + ", " + self.message.uuid + ", " + fragment_index.to_s + ", " + super.to_s() + ">" 
      end
    end

  end
end