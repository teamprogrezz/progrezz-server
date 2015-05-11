# encoding: UTF-8

module Game
  
  # Módulo de mecánicas de juego
  module Mechanics
    
    # Clase gestora de las mecánicas de juego (simplona).
    class MechanicsManager
      
      # Inicializar (carga de ficheros).
      def self.setup()
        # Requerir ficheros de mecánicas de juego
        GenericUtils.require_dir("./rb/game/mechanics/**/*.rb", "Leyendo mecánicas:          ")
        
        # Inicializar
        Game::Mechanics.constants.each do |c|
          c = Game::Mechanics.const_get(c)
          if Class === c && c != self && c != Game::Mechanics::Mechanic
            puts "Inicializando mecánica:     ".cyan + c.name.gsub(/^.*::/, '')
            c.setup()
          end
        end
      end
      
    end
    
  end
end

Game::Mechanics::MechanicsManager.setup()
