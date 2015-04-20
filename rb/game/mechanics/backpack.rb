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
      def self.slots_per_level()
        return @@data[:backpack][:slots_per_level]
      end
      
      # Tamaño de un inventario dado un nivel.
      # @param level [Integer] Nivel de entrada.
      # @return [Integer] Tamaño de un inventario dado un nivel.
      def self.slots(level)
        return (base_slots + level * slots_per_level).round
      end
      
      # Recalcular 
      def self.recaculate_slots_for_players()
        Game::Database::DatabaseManager.run_nested_transaction do |tx|
          begin
            Game::Database::User.all.each { |u| u.backpack.recalculate_slots() }
          rescue Exception => e
            Game::Database::DatabaseManager.rollback_transaction(tx)
            raise e
          end
        end
        
        return nil
      end
      
    end
  end
end

Game::Mechanics::BackpackManagement.setup()
