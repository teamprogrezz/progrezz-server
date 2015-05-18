# encoding: UTF-8

require 'date'

require_relative './item_geo'

module Game
  module Database

    class LevelProfile; end
    # Forward declaration
    
    # Clase que representa una baliza (beacon) geolocalizado.
    class Beacon < ItemGeolocatedObject
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                      Constantes
      #   -------------------------------------------------- #++
      

      
      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++


      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++

      # @!method :level_profile
      # Relación con el nivel de la baliza (#Game::Database::LevelProfile). Se puede acceder con el atributo +level_profile+.
      # @return [Game::Database::LevelProfile] Nivel de la baliza.
      has_one :out, :level_profile, model_class: Game::Database::LevelProfile, type: "profiles_in", dependent: :destroy

      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++
      
      #-- --------------------------------------------------
      #                      Métodos
      #   -------------------------------------------------- #++
      
    end
  end
end