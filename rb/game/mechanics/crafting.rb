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
        self.parse_JSON( str_data || File.read(DATAFILE) )
        GenericUtils.symbolize_keys_deep! @data

        # ...
      end

      # Recetas relacionadas con un objeto.
      # @param item_id [String] Identificador del objeto.
      # @return [Hash] Recetas relacionadas con el objeto, sea como entrada o salida de la receta.
      def self.related_recipes(item_id)
        output = {}

        @data.each do |rank, value|
          value[:recipes].each do |recipe_id, recipe|
            # Relacionar si está en la salida o en la entrada.
            if recipe[:output][:item_id] == item_id or recipe[:input].any? { |input| input[:item_id] == item_id }
              output[rank] ||= { }
              output[rank][recipe_id] = recipe
            end
          end
        end

        return output.deep_clone()
      end

      # Dado un rango, obtener todas sus recetas.
      # @param rank [String] Identificador del rango.
      # @return [Hash] Recetas de dicho rango.
      def self.recipes_by_rank(rank)
        return @data[rank]
      end

      # Getter de todas las recetas.
      # @return [Hash] Lista de recetas.
      def self.recipes()
        return @data
      end

      # Getter de una receta dada su id.
      # @param recipe_id [String] Identificador de la receta.
      # @return [Hash] Información sobre la receta.
      def self.get_recipe(recipe_id)
        recipe_id = recipe_id.to_sym

        output = nil
        @data.each do |rank, value|
          if value[:recipes][recipe_id] != nil
            output = {
              recipe: value[:recipes][recipe_id],
              rank: rank
            }
            break
          end
        end

        return output
      end

    end
  end
end