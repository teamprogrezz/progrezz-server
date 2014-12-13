require 'data_mapper'

module Game
  module Database

    class Users
      include DataMapper::Resource
      
      # -------------------------
      #        Atributos
      # -------------------------
      property :id_user, Serial, :key => true # Identificador de mensaje
      
      property :alias, String    # Sin usar.

      # -------------------------
      #         Métodos
      # -------------------------
      # ...
    end

  end
end
