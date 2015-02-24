require 'neo4j'


module Game
  module Database

    class User
      include Neo4j::ActiveNode
      
      # -------------------------
      #      Atributos (DB)
      # -------------------------
      property :user_id, constraint: :unique  # Identificador de usuario (correo, único en la BD)
      property :alias                         # Sin usar.

      # -------------------------
      #    Métodos de clase
      # -------------------------
      def self.sign_in(al, uid)
        begin
          return create( {alias: al, user_id: uid, test_attr: ["what", "1"] } );
        rescue Neo4j::Server::CypherResponse::ResponseError => e
          raise "DB ERROR: Cannot create user '" + al + " with unique id '" + uid + "': \n\t" + e.message;
        end

      end

      # -------------------------
      #        Métodos
      # -------------------------
      # ...
    end
  end
end
