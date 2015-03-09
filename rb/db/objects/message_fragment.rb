require_relative '../relations/user-message_fragment'

module Game
  module Database
    
    class Message; end
    # Forward declaration

    # Clase que representa a un fragmento geolocalizado de un juego.
    #
    # Los atributos se guardan en el objeto (incluida geolocalización) como un nodo del grafo neo4j.
    # Las relaciones se harán mediante relaciones directas o codificadas.
    class MessageFragment < GeolocatedObject
      include Neo4j::ActiveNode
      
      #-- -------------------------
      #         Atributos DB)
      #   ------------------------- #++
      
      # Índice del fragmento.
      # @return [Integer] Debe ser mayor o igual que 0, o menor que el total de fragmentos del mensaje.
      property :fragment_index, type: Integer #, constraint: :unique
      
      # Timestamp o fecha de creación del fragmento.
      # return [Integer] Milisegundos desde el 1/1/1970.
      property :created_at
      
      #-- -------------------------
      #     Relaciones (DB)
      #   ------------------------- #++
      
      # @!method message
      # Relación con el mensaje padre (#Game::Database::Message). Se puede acceder con el atributo +message+.
      # @return [Game::Database::Message] Mensaje que está compuesto por este fragmento.
      has_one :in, :message, model_class: Game::Database::Message, origin: :fragments
      
      # @!method owners
      # Relación con fragmentos recolectados por el usuario (#Game::Database::RelationShips::UserFragmentMessage). Se puede acceder con el atributo +owners+.
      # @return [Game::Database::User] Propietarios de este fragmento.
      has_many :in, :owners, rel_class: Game::Database::RelationShips::UserFragmentMessage, model_class: Game::Database::User
      
      
      #-- -------------------------
      #      Métodos de clase
      #   ------------------------- #++

      # Creación de nuevos usuarios.
      #
      # En caso de error, lanzará una excepción como una String (Exception).
      #
      # @param msg [String] Referencia al mensaje.
      # @param f_index [Integer] Índice del fragmento.
      # @param position [Hash<Symbol, Float>] Posición geolocalizada del fragmento.
      def self.create_message_fragment(msg, f_index, position)
        begin
          fmsg = create( {message: msg, fragment_index: f_index }) do |fragment|
            fragment.set_geolocation( position[:latitude], position[:longitude], false )
          end

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
      # @return [String] Objeto como string, con el formato "<MessageFragment: +uuid+,+message.uuid+,+fragment_index+,+geolocation+>".
      def to_s()
        return "<MessageFragment: " + self.uuid.to_s + ", " + self.message.uuid + ", " + fragment_index.to_s + ", " + super.to_s() + ">" 
      end
      
      # Transformar objeto a un hash.
      # @param exclusion_list [Array<Symbol>] Lista de propiedades a ignorar.
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash(exclusion_list = [])
        output = {}

        if !exclusion_list.include? :uuid;           output[:uuid]           = self.uuid end
        if !exclusion_list.include? :geolocation;    output[:geolocation]    = self.geolocation end
        if !exclusion_list.include? :fragment_index; output[:fragment_index] = self.fragment_index end
        if !exclusion_list.include? :message;        output[:message]        = self.message.to_hash() end
        
        return output
      end
    end

  end
end