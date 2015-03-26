# encoding: UTF-8

module Game
  module Database
    
    # Clase auxiliar que representa un objeto que puede ser parcialmente eliminado de la base de datos. 
    class RemovableObject
      include Neo4j::ActiveNode
      
      # Scope neo4j para acceder rápidamente a objetos sin borrar.
      # @return [Object] Consulta neo4j.
      
      # Eliminar un objeto.
      # @overload
      def remove()
        # Guardar en ficheros destruidos
        # TODO ...
      end
    end
    
  end
end