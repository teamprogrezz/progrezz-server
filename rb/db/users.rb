require 'neo4j'


module Game
  module Database

    class User
      include Neo4j::ActiveNode
      
      # -------------------------
      #        Atributos
      # -------------------------
      property :user_id # Identificador de usuario
      property :alias   # Sin usar.

      # -------------------------
      #         Métodos
      # -------------------------
      # ...
    end

  end
end
