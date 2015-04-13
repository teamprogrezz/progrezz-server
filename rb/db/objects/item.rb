# encoding: UTF-8

module Game
  module Database
    
    class ItemDeposit; end
    class ItemDepositInstance < GeolocatedObject; end
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
      
      # Imagen por defecto para el objeto.
      DEFAULT_IMAGE = "/img/game/null.png"
      
      # Calidad por defecto.
      NULL_QUALITY = "Null"
      
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
      # @return [String] Nombre.
      property :name, type: String, default: ""
      
      # Calidad del objeto.
      #
      # @return [String] Calidad.
      property :quality, type: String, default: NULL_QUALITY
      
      # Descripción del objeto (narrativa).
      #
      # Se usará principalmente para el lore del juego.
      # @return [String] Descripción.
      property :description, type: String, default: ""
      
      # Imagen del objeto.
      #
      # Se usará principalmente para el lore del juego.
      # @return [String] Imagen.
      property :image, type: String, default: DEFAULT_IMAGE
      
      # Cantidad máxima en el stack del jugador.
      # @return [Integer] Cantidad numérica.
      property :max_amount, type: Integer, default: DEFAULT_MAX_ITEM
      
      #-- --------------------------------------------------
      #                      Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # @!method deposit
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
          max_amount: DEFAULT_MAX_ITEM,
          quality: NULL_QUALITY,
          image: DEFAULT_IMAGE
        }, extra_params, [:item_id])
        
        return self.create( item_id: params[:item_id], name: params[:name], description: params[:description], max_amount: params[:max_amount], quality: params[:quality], image: params[:image] )
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
          image: self.image,
          quality: self.quality,
          max_amount: self.max_amount
        }, extra_params, [:item_id])
        
        self.update( name: params[:name], description: params[:description], max_amount: params[:max_amount], quality: params[:quality], image: params[:image] )
      end
      
      # Crear un depósito del objeto.
      # @param extra_params [Hash] Parámetros a cargar. Véase la función #Game::Database::ItemDeposit.create_deposit() .
      # @return [Game::Database::ItemDeposit] Depósito creado en la base de datos.
      def create_deposit(extra_params)
        return Game::Database::ItemDeposit.create_item_deposit(self, extra_params)
      end
      
      # Borrar el objeto y sus relacionados (depósito, etc).
      def remove()
        # Exportar el nodo
        Game::Database::DatabaseManager.export_neo4jnode(self, self.rels)
        
        # Destruir el depósito del objeto
        self.deposit.remove()  if self.deposit != nil
        
        # Destruir nodo
        self.destroy()
      end
      
      # Transformar objeto a un hash
      # @param exclusion_list [Array<Symbol>] Elementos a omitir en el hash de resultado (...).
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash(exclusion_list = [:description, :max_ammount])
        output = {}
        
        output[:item_id]     = self.item_id      if !exclusion_list.include? :item_id
        output[:name]        = self.name         if !exclusion_list.include? :name
        output[:description] = self.description  if !exclusion_list.include? :description
        output[:image]       = self.image        if !exclusion_list.include? :image
        output[:max_amount]  = self.max_amount   if !exclusion_list.include? :max_amount
        
        return output
      end
    end
  end
end