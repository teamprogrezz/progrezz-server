# encoding: UTF-8

require 'progrezz/geolocation'

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

        begin
          # Parsear funciones y añadirlas aquí.
          for function in @data[:functions].values
            eval(function)
          end

        rescue Exception => e
          raise ::GenericException.new( "Error occurred while reading json: " + e.message, e)
        end

      end

      # Función auxiliar para ser llamada desde fuera.
      # Define la experiencia necesaria para subir del nivel +next_level-1+ a +next_level+.
      # @param next_level [Integer] Siguiente nivel.
      # @return [Float] Experiencia necesaria para subir de nivel.
      def self.exp_to_next_level(next_level)
        return _next_level_required_exp( next_level )
      end

      # Nivel mínimo (incluido).
      # @return [Integer] Nivel mínimo.
      def self.min_level
        return @data[:levels][:start]
      end

      # Nivel máximo (incluido).
      # @return [Integer] Nivel máximo.
      def self.max_level
        return @data[:levels][:end]
      end

      # Obtener una copia de los datos.
      # @return [Hash] Datos guardados por el gestor.
      def self.data
        return @data.deep_clone
      end

      # Dar energía a la baliza.
      # @param beacon [Game::Database::Beacon] Referencia a la baliza.
      # @param energy [Integer] Energía que se dará a la baliza.
      def self.gain_energy(beacon, energy)
        # Gestión de errores
        if beacon == nil || beacon.level_profile == nil
          raise ::GenericException.new( "Invalid beacon." )
        end

        raise ::GenericException.new( "Invalid energy amount." ) if energy == nil || energy <= 0

        # Ganar experiencia
        level_profile = beacon.level_profile
        current_level = level_profile.level
        current_exp   = level_profile.level_exp

        output = { }

          # -- Subir de nivel --
        # Si tiene el nivel máximo, no ganar experiencia.
        if current_level < self.max_level
          # Añadir a la baliza la experiencia deseada.
          current_exp += energy * @data[:leveling][:exp_per_energy]

          # Calcular cuanta experiencia hace falta para el siguiente nivel (función parseada de DATAFILE)
          exp_for_next_level = _next_level_required_exp( current_level + 1 )

          # Si es mayor que la experiencia actual, añadir un nuevo nivel, además de darle el exceso de experiencia.
          while current_exp >= exp_for_next_level
            current_level += 1
            output[:new_level] = current_level

            # Si no es el nivel máximo, reajustar experiencia y calcular experiencia para el próximo nivel.
            if current_level < self.max_level
              current_exp -= exp_for_next_level
              exp_for_next_level = _next_level_required_exp( current_level + 1 )
            else
              current_exp = 0
            end
          end

          output[:exp_gained] = energy * @data[:leveling][:exp_per_energy]

          # Actualizar datos de la baliza
          level_profile.update( { level: current_level, level_exp: current_exp } )

          # Llamar al callback del usuario de subida de nivel
          beacon.dispatch(:OnLevelUp, output[:new_level]) if output[:new_level] != nil
        end

          # -- Añadir tiempo de vida según su nivel actual --
        output[:duration_added] = beacon.add_life_time( energy * self._duration_per_energy(level_profile.level) )

        # Añadir la energía a la baliza
        beacon.update( energy_gained: beacon.energy_gained + energy )

        # Y retornar estructura
        return output
      end

      # Aumentar el peso o ponderación según las balizas cercanas a ese punto.
      # @param ponderation_hash [Hash] Hash de ponderaciones +Tipo=>Peso+.
      # @param geolocation [Hash] Geolocalización del punto, de tipo {latitude: lat, longitude: lon}
      def self.add_ponderation(ponderation_hash, geolocation)
        max_radius = self._radius_per_level( self.max_level )

        # Buscar balizas cercanas
        beacons = Game::Database::Beacon.search_by_radius(geolocation, max_radius)

        # Para cada baliza, incrementar la ponderación según sea conveniente.
        ponderation_increment = 0
        beacons.each do |b|
          # Si está lo suficientemente cerca, aumentar la ponderación
          ponderation_increment += b.weight_per_deposit if Progrezz::Geolocation.distance( b.geolocation, geolocation, :km ) <= b.action_radius
        end

        # Aumentar la ponderación en el hash
        if ponderation_increment != 0
          ponderation_hash.each { |k, v| ponderation_hash[k] += ponderation_increment }
        end
      end

    end
  end
end