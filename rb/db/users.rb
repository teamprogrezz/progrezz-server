require 'neo4j'

module Game
  module Database

    class User
      include Neo4j::ActiveNode
      
      # -------------------------
      #      Atributos (DB)
      # -------------------------
      property :user_id, constraint: :unique  # Identificador de usuario (correo, único en la BD)
      property :alias                         # Alias o nick del usuario.
      property :created_at                    # Timestamp o fecha de creación del usuario.

      # -------------------------
      #     Relaciones (DB)
      # -------------------------
      has_one :out, :geolocation, model_class: Geolocation, type: "is_located_at"

      # -------------------------
      #    Métodos de clase
      # -------------------------

      # Creación de nuevos usuarios
      # al  -> alias
      # uid -> identificador de usuario (correo)
      def self.sign_in(al, uid)
        begin
          user = create( {alias: al, user_id: uid } );
          user.geolocation = Geolocation.create_geolocation();

        rescue Neo4j::Server::CypherResponse::ResponseError => e
          raise "DB ERROR: Cannot create user '" + al + " with unique id '" + uid + "': \n\t" + e.message;
        end
        
        return user
      end

      # -------------------------
      #        Métodos
      # -------------------------
      # ...
    end
  end
end
