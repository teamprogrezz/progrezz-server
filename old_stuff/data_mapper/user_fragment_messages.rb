require 'data_mapper'

module Game
  module Database

    # Mensajes de un usuario (fragmentados)
    class UserFragmentMessages
      include DataMapper::Resource
      
      # -------------------------
      #        Atributos
      # -------------------------
      property :id_user,  Integer,  :key => true   # Identificador de usuario
      property :id_msg,   Integer, :key => true   # Identificador de mensaje
      property :fragment_index, Integer, :key => true # Índice del fragmento

      # -------------------------
      #         Métodos
      # -------------------------
      # ...
    end

  end
end
