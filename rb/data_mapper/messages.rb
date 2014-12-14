require 'data_mapper'

module Game
  module Database

    class Messages
      include DataMapper::Resource
      
      # -------------------------
      #        Atributos
      # -------------------------
      property :id_msg, Serial, :key => true        # Identificador de mensaje
      
      property :total_fragments, Integer

      #property :header,  String
      property :content, String
      property :resource_link, String

      property :id_user, Integer # ¿?

      # -------------------------
      #         Métodos
      # -------------------------
      # ...
    end

  end
end
