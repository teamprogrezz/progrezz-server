
module Game
  module Database

    # Relación para definir los fragmentos recolectados por un usuario.
    class UserFragmentMessage
      include Neo4j::ActiveRel
      
      #-- -------------------------
      #       Relaciones (DB)
      #   ------------------------- #++
      
      # Relaciona la clase User con la clase MessageFragment, para saber cuando ha recogido el fragmento.
      from_class User
      to_class MessageFragment
      
      type 'owns'
      set_classname
          
      #-- -------------------------
      #        Atributos (DB)
      #   ------------------------- #++
      property :created_at # Fecha de creación del nodo (recolección del mensaje).

    end

  end
end
