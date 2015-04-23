# encoding: UTF-8

require 'rest-client'
require 'progrezz/geolocation'

require_relative './mechanic'
require_relative './leveling'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente al
    # sistema de crafteo del juego.
    class CraftingMechanics < Mechanic
      # Hash que contiene los datos de DATAFILE
      @data = {}

      # Datos referentes a este módulo
      DATAFILE = "data/crafting.json"

      # Inicializar mecánica.
      # Cargará los datos desde el fichero #DATAFILE.
      # @param str_data [String] Datos de entrada (si existiesen).
      def self.setup(str_data = nil)
        super(str_data)
        self.parse_JSON( str_data || File.read(DATAFILE)

        # ...
      end

      # Recetas relacionadas con un objeto.
      # @param item_id [String] Identificador del objeto.
      # @return [Hash] Recetas relacionadas con el objeto, sea como entrada o salida de la receta.
      def self.related_recipes(item_id)
        # ...
      end

      # Dado un rango, obtener todas sus recetas.
      # @param rank [String] Identificador del rango.
      # @return [Hash] Recetas de dicho rango.
      def self.recipes_by_rank(rank)
        # ...
      end

      # Getter de todas las recetas.
      # @return [Hash] Lista de recetas.
      def self.recipes()
        # ...
      end

    end
  end
end