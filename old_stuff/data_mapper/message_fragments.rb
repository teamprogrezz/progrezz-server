require 'data_mapper'
require 'dm-core'
require 'dm-timestamps'

require_relative 'geolocation'

module Game
  module Database

    class MessageFragments
      include DataMapper::Resource
      
      # -------------------------
      #        Atributos
      # -------------------------
      property :id_msg, Integer, :key => true          # Identificador de mensaje
      property :fragment_index, Integer, :key => true  # Índice de fragmento
      
      property :latitude,  Float  # Coordenada X
      property :longitude, Float  # Coordenada Y
      #property :geolocation, Geolocation

      property :created_on, Date
      #property :expire_date, Date


      # -------------------------
      #         Métodos
      # -------------------------
      # ...
    end

  end
end
