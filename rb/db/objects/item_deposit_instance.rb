# encoding: UTF-8

require_relative './geolocated_object'
require_relative '../relations/user-collected_item-deposit-instance'

module Game
  module Database
    
    class ItemDeposit; end
    # Forward declaration
    
    # Clase que representa un depósito o veta de objetos geolocalizado.
    # 
    # A diferencia de #Game::Database::ItemDeposit, los
    # objetos de este tipo sí están geolocalizados.
    class ItemDepositInstance < GeolocatedObject
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                      Constantes
      #   -------------------------------------------------- #++
      
      # Duración por defecto de un depósito, especificado en días.
      DEFAULT_DURATION = 1
      
      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++
      
      # Usos totales del depósito.
      #
      # @return [Integer] Usos totales del depósito.
      property :ammount, type: Integer, default: 0
      
      # Timestamp o fecha de recolección del depósito.
      # @return [DateTime] Fecha de creación.
      property :created_at
      
      # Duración (en días) de un depósito. Si es 0, durará eternamente.
      # @return [Integer] Días que durará el depósito.
      property :duration, type: Integer, default: DEFAULT_DURATION
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # @!method item
      # Relación con el objeto (#Game::Database::Item). Se puede acceder con el atributo +item+.
      # @return [Game::Database::Item] Objeto contenido en el depósito.
      has_one :in, :deposit, model_class: Game::Database::ItemDeposit, origin: :instances
      
      # @!method collectors
      # Relación de usuarios que han recolectado este depósito. Se puede acceder con el atributo #collectors.
      # @return [Game::Database::RelationShips::UserFragmentMessage] 
      has_many :in, :collectors, rel_class: Game::Database::RelationShips::UserCollected_ItemDepositInstance, model_class: Game::Database::User
      
      
      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++
      
      # Crear una estancia de un depósito de objetos.
      # @param deposit_ref [Game::Database::ItemDeposit] Referencia a depósito de objeto de la base de datos.
      # @param extra_params [Hash] Parámetros a cargar. Véase el código para entender los parámetros.
      # @return [Game::Database::ItemDeposit] Depósito creado en la base de datos.
      def self.create_item_deposit_instance(deposit_ref, extra_params)
        if deposit_ref == nil or !deposit_ref.is_a? Game::Database::ItemDeposit
          raise "Invalid deposit."
        end
        
        params = GenericUtils.default_params( {}, extra_params, [:ammount, :geolocation])
        
        deposit_instance = self.create( deposit: deposit_ref, ammount: params[:ammount] ) do |i|
          i.set_geolocation( params[:geolocation][:latitude], params[:geolocation][:longitude] )
        end
        
        return deposit_instance
      end
      
      # Limpiar depósitos caducados de la base de datos.
      # @return [Integer] Retorna el número de depósitos que han sido borrados.
      def self.clear_caducated()
        count = 0
        
        Game::Database::DatabaseManager.run_nested_transaction do |t|
          Game::Database::ItemDepositInstance.as(:i).where("i.duration <> 0").each do |idi|
            if idi.caducated?
              idi.remove()
              count += 1
            end
          end
        end
        
        return count
      end
      
      #-- --------------------------------------------------
      #                      Métodos
      #   -------------------------------------------------- #++
      
      # Comprobar si un depósito ha caducado.
      # @return [Boolean] Si ha caducado, retorna True. En caso contrario, False.
      def caducated?
        if duration == 0
          return false
        end
        
        if self.created_at + duration <= Time.now
          return true
        end
        
        return false
      end
      
      # Borrar la estancia.
      def remove()
        # Exportar el nodo
        Game::Database::DatabaseManager.export_neo4jnode(self, self.rels)
        
        # Borrar el nodo.
        self.destroy()
      end
      
      def to_hash(exclusion_list = [])
        output = {}
        
        output[:item]     = self.deposit.item.to_hash([]) if !exlusion_list.include? :item
        output[:instance] = self.deposit.item.to_hash([]) if !exlusion_list.include? :item
        
        return output
      end
      
    end
  end
end