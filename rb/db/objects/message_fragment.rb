require_relative '../relations/user-message_fragment'

module Game
  module Database

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
      
      # Relación con fragmentos recolectados por el usuario. Se puede acceder con el atributo +:collected_fragmented_messages+.
      has_many :in, :owners, rel_class: Game::Database::RelationShips::UserFragmentMessage
      
      
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
          fmsg = create( {message: msg, fragment_index: f_index, geolocated_pos: GeolocatedObject.clamp(position.dup()) });

        rescue Exception => e
          puts e.to_s
          raise "DB ERROR: Cannot create fragment " + f_index.to_s + " for the message " + message.to_s + ": \n\t" + e.message;
        end
        
        return fmsg
      end

      #-- -------------------------
      #           Métodos
      #   ------------------------- #++
      # ...
    end

  end
end