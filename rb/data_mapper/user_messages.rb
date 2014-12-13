require 'data_mapper'

module Game
  module Database

    class UserMessages
      include DataMapper::Resource
      
      # -------------------------
      #        Atributos
      # -------------------------
      property :id_user,  Integer,  :key => true   # Identificador de usuario
      property :id_msg,   Integer, :key => true   # Identificador de mensaje
      property :fragment_index, Integer, :key => true # Índice del fragmento
      #property :status, String

      # TODO: Hay que añadir una nueva tabla a la BD: UserCompletedMessages para mostrar los mensajes completados.

      # -------------------------
      #         Métodos
      # -------------------------
      # ...
    end

  end
end
