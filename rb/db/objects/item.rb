# encoding: UTF-8

module Game
  module Database
    
    # Clase que representa un objeto de usuario en la base de datos.
    # 
    # Será usado para representar objetos de un usuario, de
    # una veta o depósitov¡, ... mediante relaciones neo4j.
    class User < GeolocatedObject
      include Neo4j::ActiveNode
      
      # Cantidad máxima de objetos por defecto en un stack de un usuario.
      DEFAULT_MAX_ITEM = 500
      
      # Identificador del objeto.
      # 
      # El formato puede ser el deseado por el programador.
      # Se recomienda usar un id coherente para todos los objetos.
      #
      # @return [String] Debe ser único.
      property :item_id, constraint: :unique, type: String
      
      # Nombre legible del objeto.
      #
      # Puede ser o no similar a la propiedad #item_id
      # @return [String] 
      property :name, type: String, default: ""
      
      # Descripción del objeto (narrativa).
      #
      # Se usará principalmente para el lore del juego.
      # @return [String] 
      property :name, type: String, default: ""
      
      
      # Cantidad máxima en el stack del jugador.
      # @return [Integer] 
      property :name, type: Integer, default: DEFAULT_MAX_ITEM
      
    end
  end
end