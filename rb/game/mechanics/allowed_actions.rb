# encoding: UTF-8

require 'rest-client'
require 'progrezz/geolocation'

require_relative './mechanic'
require_relative './leveling'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente a
    # las acciones permitidas por los usuario según el nivel.
    class AllowedActionsMechanics < Mechanic
      # Hash que contiene los datos de DATAFILE
      @data = {}
      
      # Acciones por nivel ya preparadas (no es necesario computarlas cada vez que se piden).
      @precomputed_allowed_actions = []
      
      # Datos referentes a este módulo
      DATAFILE = "data/allowed_actions.json"
      
      # Inicializar mecánica.
      # Cargará los datos desde el fichero #DATAFILE.
      # @param str_data [String] Datos de entrada (si existiesen).
      def self.setup(str_data = nil)
        super(str_data)
        self.parse_JSON( str_data || File.read(DATAFILE) )
        
        # Calcular acciones de cada usuario
        @precomputed_allowed_actions = []
        @precomputed_allowed_actions << @data[LevelingMechanics.min_level.to_s]
        for i in (LevelingMechanics.min_level)..(LevelingMechanics.max_level)
          # Crear de anera apilada (con los datos del anterior).
          @precomputed_allowed_actions[i] = (@precomputed_allowed_actions[i - 1].deep_merge(@data[i.to_s])  )
          
          # Previsualizar
          # puts i.to_s, JSON.pretty_generate(@precomputed_allowed_actions[i])
        end
        
      end
      
      # Comprobar que el nivel sea válido
      # @param level [Integer] Nivel dado.
      # @raise [Exception] Si no es válido, genera una excepción.
      def self.check_level(level)
        if !level.is_a? Fixnum || level < LevelingMechanics.min_level || level > LevelingMechanics.max_level
          raise ::GenericException.new( "Invalid level '" + level.to_s + "'.")
        end
      end
      
      # Listar acciones permitidas a un cierto nivel.
      # @param level [Integer] Nivel actual del jugador.
      # @return [Hash] Lista de acciones permitidas, con los correspondientes parámetros.
      def self.get_allowed_actions(level)
        check_level(level)
        
        return @precomputed_allowed_actions[level].deep_clone
      end
      
      # Comprobar si una acción se permite.
      # @param level [Integer] Nivel actual.
      # @param action_name [String] Acción a realizar.
      # @raise [Exception] Si la acción no está permitida, genera una excepción.
      def self.action_allowed?(level, action_name)
        check_level(level)
        
        if !@precomputed_allowed_actions[level].keys.include? action_name
          raise ::GenericException.new( "Action '" + action_name + "' not allowed at level '" + level.to_s + "'.")
        end
        
        return nil
      end
      
      # Retornar parámetros de una acción por nivel.
      # @param level [Integer] Nivel actual.
      # @param action_name [String] Nombre de la acción.
      def self.action_params_by_level(level, action_name)
        check_level(level)
        
        return @precomputed_allowed_actions[level][action_name]
      end
      
    end
    
  end
end