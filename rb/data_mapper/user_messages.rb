require 'data_mapper'

module Game
  module Database

    # Mensajes de un usuario (fragmentados)
    class UserMessages
      include DataMapper::Resource
      
      # -------------------------
      #        Atributos
      # -------------------------
      property :id_user,  Integer,  :key => true   # Identificador de usuario
      property :id_msg,   Integer, :key => true   # Identificador de mensaje
      property :fragment_index, Integer, :key => true # �ndice del fragmento

      # -------------------------
      #         M�todos
      # -------------------------
      # ...
    end

  end
end
