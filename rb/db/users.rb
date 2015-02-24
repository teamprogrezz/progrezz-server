require 'neo4j'

module Game
  module Database

    # Clase que representa a un jugador cualquiera en la base de datos.
    class User < GeolocatedObject
      include Neo4j::ActiveNode
      
      # -------------------------
      #      Atributos (DB)
      # -------------------------
      property :user_id, constraint: :unique  # Identificador de usuario (correo, único en la BD)
      property :alias                         # Alias o nick del usuario.
      property :created_at                    # Timestamp o fecha de creación del usuario.

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

        rescue Exception => e
          raise "DB ERROR: Cannot create user '" + al + " with unique id '" + uid + "': \n\t" + e.message;
        end
        
        return user
      end

      # -------------------------
      #        Métodos
      # -------------------------

      # Stringificar objeto
      def to_s
        return "<User: " + self.user_id + ", " + self.alias + ", " + super.to_s + ">" 
      end
    end
  end
end
