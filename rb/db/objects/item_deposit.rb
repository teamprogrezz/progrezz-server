# encoding: UTF-8

module Game
  module Database
    
    class GeolocatedObject; end
    class ItemDepositInstance < GeolocatedObject; end
    # Forward declaration
    
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
      
      # Cantidad de recursos mínima obtenidos por un usuario al recolectar antes de saltar el cooldown.
      # @return [Integer] Cantidad mínima de usos o recursos recolectados.
      property :user_min_ammount, type: Integer
      
      # Cantidad de recursos máxima obtenidos por un usuario al recolectar antes de saltar el cooldown.
      # @return [Integer] Cantidad máxima de usos o recursos recolectados.
      property :user_max_ammount, type: Integer
      
      # Reutilización del usuario para el depósito.
      #
      # Especificado en segundos. Hasta que no transcurra el tiempo, el usuario no podrá volver a usar el
      # depósito para obtener recursos.
      #
      # @return [Integer] Segundos de cooldown.
      property :user_cooldown, type: Integer
      
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
      has_many :out, :instances, model_class: Game::Database::ItemDepositInstance, type: "geolocated_in", dependent: :destroy 
      
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
        
        params = GenericUtils.default_params( {}, extra_params, [:weight, :min_ammount, :max_ammount, :user_min_ammount, :user_max_ammount, :user_cooldown])
        
        return self.create( { 
          item: item_ref,
          weight: params[:weight],
          min_ammount: params[:min_ammount],
          max_ammount: params[:max_ammount],
          user_min_ammount: params[:user_min_ammount],
          user_max_ammount: params[:user_max_ammount],
          user_cooldown: params[:user_cooldown]
        } )
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
      # @param snap_to_road [Boolean] True si se desea ajustar el depósito creado a la carretera más próxima.
      # @return [Game::Database::ItemDepositInstance] Estancia creada.
      def instantiate(geolocation = {latitude: 0.0, longitude: 0.0}, snap_to_road = true)
        ammount = Random.new.rand( self.min_ammount .. self.max_ammount )
        
        Game::Mechanics::GeolocationManagement.snap_geolocation!(geolocation) if snap_to_road
        
        return Game::Database::ItemDepositInstance.create_item_deposit_instance( self, {geolocation: geolocation, total_ammount: ammount} )
      end
      
    end
  end
end