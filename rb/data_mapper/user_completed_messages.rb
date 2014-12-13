require 'data_mapper'

module Game
  module Database

    # Clase para mensajes ya completados
    class UserCompletedMessages
      include DataMapper::Resource
      
      # -------------------------
      #        Atributos
      # -------------------------
      property :id_user,  Integer, :key => true   # Identificador de usuario
      property :id_msg,   Integer, :key => true   # Identificador de mensaje
      property :status, String

      # -------------------------
      #         Métodos
      # -------------------------
      # ...
    end

  end
end
