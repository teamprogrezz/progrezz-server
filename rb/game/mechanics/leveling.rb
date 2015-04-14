# encoding: UTF-8

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente al leveo.
    class LevelingManagement
      
      # Fichero que contiene la información relativa al leveo.
      LEVELING_FILE = "data/leveling.json"
      
      # Datos de leveo (hash)
      @@leveling_data = {}
      
      # Inicializar mecánica.
      # Cargará los datos de leveo desde el fichero #LEVELING_FILE.
      def self.setup()
        begin
          @@leveling_data = JSON.parse( File.read(LEVELING_FILE) )
          
          # Parsear funciones y añadirlas aquí.
          for function in @@leveling_data["functions"].values
            eval(function)
          end
          
        rescue Exception => e
          raise ::GenericException.new( "Error reading '" + LEVELING_FILE + "': " + e.message, e)
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
        return @@leveling_data["levels"]["start"]
      end
      
      # Nivel máximo (incluido).
      # @return [Integer] Nivel máximo.
      def self.max_level
        return @@leveling_data["levels"]["end"]
      end
      
      # Dar experiencia a un usuario.
      # @param user [Game::Database::User] Referencia al usuario.
      # @param action_str [String] Acción realizada por el usuario.
      # @return [Hash<Symbol, Object>] Hash con información de la experiencia obtenida, o si se ha alcanzado un nuevo nivel.
      def self.gain_exp(user, action_str)
        # Gestión de errores
        if user == nil || user.level_profile == nil
          raise ::GenericException.new( "Invalid user." )
        end
        
        # Ganar experiencia
        level_profile = user.level_profile
        current_level = level_profile.level
        current_exp   = level_profile.level_exp
        
        output = { }
        
        # Si tiene el nivel máximo, no ganar experiencia.
        if current_level >= @@leveling_data["levels"]["end"]
          return output
        end
        
        # Recoger cantidad de experiencia por la acción.
        action_exp = @@leveling_data["exp"]["exp_per_action"][action_str]
        if action_exp == nil
          raise ::GenericException.new( "Invalid action: there is no exp related to '" + action_str + "'" )
        end
        
        # Añadir al usuario la experiencia actual.
        current_exp += action_exp
        
        # Calcular cuanta experiencia hace falta para el siguiente nivel (función parseada de LEVELING_FILE)
        exp_for_next_level = _next_level_required_exp( current_level + 1 )
        
        # Si es mayor que la experiencia actual, añadir un nuevo nivel, además de darle el exceso de experiencia.
        while current_exp >= exp_for_next_level
          current_level += 1
          output[:new_level] = current_level
          
          # Si no es el nivel máximo, reajustar experiencia y calcular experiencia para el próximo nivel.
          if current_level < @@leveling_data["levels"]["end"]
            current_exp -= exp_for_next_level
            exp_for_next_level = _next_level_required_exp( current_level + 1 )
          else
            current_exp = 0
          end
        end
        
        output[:exp_gained] = action_exp
        
        # Actualizar datos del usuario
        level_profile.update( { level: current_level, level_exp: current_exp } )
        
        # Llamar al callback del usuario de subida de nivel
        user.on_level_up( output[:new_level] ) if output[:new_level] != nil
        
        # Y retornar estructura
        return output
      end
      
    end
    
    LevelingManagement.setup()
  end
end