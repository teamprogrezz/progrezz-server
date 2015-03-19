
require_relative 'user'

module Game
  module Database
    
    # Clase que representa el nivel y la experiencia de un
    # jugador determinado.
    #
    # Funcionará como cualquier RPG, de tal manera que se suba de
    # nivel obteniendo un determinado CAP de experiencia.
    class LevelProfile
      include Neo4j::ActiveNode
      
      #-- -------------------------
      #         Atributos DB)
      #   ------------------------- #++
      
      # Nivel actual del jugador.
      # @return [Integer] Irá desde el 1 hasta lvl_max
      property :level, type: Integer, default: 1
      
      # Experiencia del nivel actual.
      # @return [Integer] Irá desde el 0 hasta el máximo del nivel actual (:level).
      property :level_exp, type: Integer, default: 0
      
      # @!method :user
      # Relación con usuario padre (#Game::Database::User). Se puede acceder con el atributo +user+.
      # @return [Game::Database::User] Usuario que posee este nivel.
      has_one :in, :user, model_class: Game::Database::User, origin: :level_profile
      
      
      # ...
    end
    
  end
end