# encoding: UTF-8

module Game
  module Database
    
    # Clase que representa un depósito o veta de objetos.
    # 
    # A diferencia de los fragmentos de un mensaje, esta clase no está geolocalizada.
    # Por el contrario, se geolocaliza en los nodos de tipo #Game::Database::ItemDepositInstance.
    class ItemDeposit
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++
      
      
      # Peso del depósito.
      #
      # Se usa para, cuando se genere aleatoriamente un nuevo depósito, se pueda elegir
      # el peso o probabilidad de cada uno de los depósitos, para que exista así un sistema sencillo de
      # "rareza".
      #
      # @return [Integer] Peso del depósito.
      property :weight, type: Integer, default: 1
      
      # Cantidad máxima de usos o recursos de un depósito.
      #
      # La cantidad de objetos se genera aleatoriamente entre #max_ammount y #min_ammount.
      #
      # @return [Integer] Cantidad máxima de usos o recursos en un depósito.
      property :max_ammount, type: Integer
      
      # Cantidad mínima de usos o recursos de un depósito.
      #
      # La cantidad de objetos se genera aleatoriamente entre #max_ammount y #min_ammount.
      #
      # @return [Integer] Cantidad mínima de usos o recursos en un depósito.
      property :min_ammount, type: Integer
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # @!method item
      # Relación con el objeto (#Game::Database::Item). Se puede acceder con el atributo +item+.
      # @return [Game::Database::Item] Objeto contenido en el depósito.
      has_one :in, :item, model_class: Game::Database::Item, origin: :deposit
      
      # @!method instances
      # Relación con las estancias del depósito. Se puede acceder con el atributo +instances+.
      # @return [Game::Database::ItemDepositInstance] Estancias del depósito.
      has_many :out, :instances, model_class: Game::Database::Item, type: "geolocated_in", dependent: :destroy 
      
      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++
      
      # Crear un depósito de objetos.
      # @param item_ref [Game::Database::Item] Referencia a objeto de la base de datos.
      # @param extra_params [Hash] Parámetros a cargar. Véase el código para entender los parámetros.
      # @return [Game::Database::ItemDeposit] Depósito creado en la base de datos.
      def self.create_item_deposit(item_ref, extra_params)
        if item_ref == nil or !item_ref.is_a? Game::Database::Item
          raise "Invalid item."
        end
        
        params = GenericUtils.default_params( {}, extra_params, [:weight, :min_ammount, :max_ammount])
        
        return self.create( item: item_ref, weight: params[:weight], min_ammount: params[:min_ammount], max_ammount: params[:max_ammount] )
      end
      
      #-- --------------------------------------------------
      #                      Métodos
      #   -------------------------------------------------- #++
      
      # Borrar el depósito y sus estancias.
      def remove()
        # Exportar el nodo
        Game::Database::DatabaseManager.export_neo4jnode(self, self.rels)
        
        # Destruir estancias del depósito
        self.instances.each do |i|
          i.remove()
        end
        
        # Borrar el nodo.
        self.destroy()
      end
      
      # Estanciar depósito en una posición geolocalizada.
      # 
      # @param geolocation [Hash<Symbol, Float>] Posición en la que se colocará la estancia.
      # @return [Game::Database::ItemDepositInstance] Estancia creada.
      def instance(geolocation = {latitude: 0.0, longitude: 0.0})
        return Game::Database::ItemDepositInstance.create_item_deposit_instance( self, {geolocation: geolocation, total_uses: 10} )
      end
      
    end
  end
end