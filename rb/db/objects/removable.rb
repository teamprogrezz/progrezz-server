# encoding: UTF-8

module Game
  module Database
    
    # Clase auxiliar que representa un objeto que puede ser parcialmente eliminado de la base de datos. 
    class RemovableObject
      include Neo4j::ActiveNode
      
      # Propiedad de borrado.
      # @return [Boolean] Si está "borrado", retorna True. Si no, retorna False.
      property :removed, type: Boolean, default: false
      
      # Scope neo4j para acceder rápidamente a objetos sin borrar.
      # @return [Object] Consulta neo4j.
      
      # Eliminar un objeto.
      # @overload
      def remove()
        self.update( removed: true )
      end
    end
    
  end
end

module Neo4j
  module Core
    class Query
      
      def unremoved(id = nil)
        if(id == nil)
          where(removed: false)
        else
          where("#{id}.removed = false")
        end
      end
      
    end
  end
end