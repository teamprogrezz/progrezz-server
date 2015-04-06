# encoding: UTF-8

module Game
  module Database
    
    class ItemDeposit; end
    # Forward declaration.
    
    # Clase que representa un objeto de usuario en la base de datos.
    # 
    # Será usado para representar objetos de un usuario, de
    # una veta o depósitov¡, ... mediante relaciones neo4j.
    #
    # Principalmente, son recursos que el usuario puede craftear.
    class Item
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                       Constantes
      #   -------------------------------------------------- #++
      
      # Cantidad máxima de objetos por defecto en un stack de un usuario.
      DEFAULT_MAX_ITEM = 500
      
      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++
      
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
      property :description, type: String, default: ""
      
      
      # Cantidad máxima en el stack del jugador.
      # @return [Integer] 
      property :max_ammount, type: Integer, default: DEFAULT_MAX_ITEM
      
      # @!method :deposit
      # Relación con el depósito del objeto. Puede no existir.
      # @return [Game::Database::ItemDeposit] Depósito que encapsula a este objeto..
      has_one :out, :deposit, model_class: Game::Database::ItemDeposit, type: "deposited_in", dependent: :destroy 
      
      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++
      
      # Crear un objeto parametrizado (json).
      # @param extra_params [Hash] Parámetros a cargar. Véase el código para ver los parámetros.
      # @return [Game::Database::Item] Objeto creado en la base de datos.
      def self.create_item(extra_params)
        params = GenericUtils.default_params( {
          name: "",
          description: "",
          max_ammount: DEFAULT_MAX_ITEM
        }, extra_params, [:item_id])
        
        return self.create( item_id: params[:item_id], name: params[:name], description: params[:description], max_ammount: params[:max_ammount] )
      end
      
      #-- --------------------------------------------------
      #                        Métodos
      #   -------------------------------------------------- #++
      
      # Actualizar los parámetros de un objeto.
      # @param extra_params [Hash] Parámetros a cargar. Véase el código para ver los parámetros.
      def update_item(extra_params)
        params = GenericUtils.default_params( {
          name: self.name,
          description: self.description,
          max_ammount: self.max_ammount
        }, extra_params, [:item_id])
        
        self.update( name: params[:name], description: params[:description], max_ammount: params[:max_ammount] )
      end
      
      # Crear un depósito del objeto.
      # @param extra_params [Hash] Parámetros a cargar. Véase la función #Game::Database::ItemDeposit.create_deposit() .
      # @return [Game::Database::ItemDeposit] Depósito creado en la base de datos.
      def create_deposit(extra_params)
        return Game::Database::ItemDeposit.create_item_deposit(self, extra_params)
      end
      
    end
  end
end