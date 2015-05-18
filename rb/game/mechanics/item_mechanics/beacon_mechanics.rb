# encoding: UTF-8

require_relative '../mechanic'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente a las balizas.
    class BeaconMechanics < Mechanic
      # Hash que contiene los datos de DATAFILE
      @data = {}

      # Datos referentes a este módulo
      DATAFILE = "data/beacons.json"

      # Inicializar mecánica.
      # Cargará los datos desde el fichero #DATAFILE.
      # @param str_data [String] Datos de entrada (si existiesen).
      def self.setup(str_data = nil)
        self.parse_JSON( str_data || File.read(DATAFILE) )
        GenericUtils.symbolize_keys_deep!(@data)
      end


    end

  end
end