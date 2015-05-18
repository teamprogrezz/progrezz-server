# encoding: UTF-8

require 'date'

require_relative './geolocated_object'

module Game
  module Database
    
    # Clase que representa una baliza (beacon) geolocalizado.
    class Beacon < GeolocatedObject
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                      Constantes
      #   -------------------------------------------------- #++
      
      # Duración por defecto de un depósito, especificado en días.
      DEFAULT_DURATION = 7
      
      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++

      
      # Timestamp o fecha de creación de la baliza..
      # @return [DateTime] Fecha de creación.
      property :created_at
      
      # Duración (en días) de una baliza. Si es 0, durará eternamente.
      # @return [Integer] Días que durará la baliza.
      property :duration, type: Integer, default: DEFAULT_DURATION
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++

      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++
      
      #-- --------------------------------------------------
      #                      Métodos
      #   -------------------------------------------------- #++
      
    end
  end
end