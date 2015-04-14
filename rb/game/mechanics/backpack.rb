# encoding: UTF-8

require 'pickup'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente al
    # inventario o mochila de los diferentes usuarios.
    class BackpackManagement
      
      # Datos referentes a este gestor.
      DATAFILE = "data/backpack.json"
      
      # Datos cargados
      @@data = nil
      
      # Inicializar gestor de mecánicas de objetos.
      def self.setup()
        begin
          @@data = JSON.parse( File.read(DATAFILE) )
          
        rescue Exception => e
          raise ::GenericException.new( "Error reading '" + DATAFILE + "': " + e.message, e)
        end
        
        GenericUtils.symbolize_keys_deep!(@@data)
      end
      
      # Tamaño del inventario base.
      # @return [Integer] Tamaño del inventario base.
      def self.base_slots()
        return @@data[:backpack][:base_slots]
      end
      
      # Incremento del inventario por nivel.
      # @return [Integer, Float] Incremento del inventario por nivel.
      def self.per_level_slots()
        return @@data[:backpack][:base_slots]
      end
      
      # Tamaño de un inventario dado un nivel.
      # @param level [Integer] Nivel de entrada.
      # @return [Integer] Tamaño de un inventario dado un nivel.
      def self.slots(level)
        return (base_slots + level * per_level_slots).to_i
      end
      
    end
  end
end

Game::Mechanics::BackpackManagement.setup()
