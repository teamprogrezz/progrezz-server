# encoding: UTF-8

require 'neo4j'

require_relative './geolocated_object'

module Game
  module Database

    # Clase abstracta que representa un objeto geolocalizado.
    class ItemGeolocatedObject < GeolocatedObject
      include Neo4j::ActiveNode
      extend  Evented # Eventos.

      # Duración por defecto de una baliza, especificado en minutos.
      DEFAULT_DURATION = 0

      # Timestamp o fecha de creación del objeto.
      # @return [DateTime] Fecha de creación.
      property :created_at

      # Duración (en días) de un objeto. Si es 0, durará eternamente.
      # @return [Integer] Días que durará la baliza.
      property :duration, type: Float, default: DEFAULT_DURATION

      def self.create_item(*args)
        raise ::GenericException.new("Method 'create_item' is not defined.")
      end

      # ...
    end
  end
end
