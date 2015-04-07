# encoding: UTF-8

require_relative './geolocated_object'

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
      #                      Atributos (DB)
      #   -------------------------------------------------- #++
      
      # Usos totales del depósito.
      #
      # @return [Integer] Usos totales del depósito.
      property :total_uses, type: Integer, default: 0
      
      # Usos restantes del depósito.
      #
      # @return [Integer] Usos restantes del depósito.
      property :uses, type: Integer, default: 0
      
      # ...
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # @!method item
      # Relación con el objeto (#Game::Database::Item). Se puede acceder con el atributo +item+.
      # @return [Game::Database::Item] Objeto contenido en el depósito.
      has_one :in, :deposit, model_class: Game::Database::ItemDeposit, origin: :instances
      
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
        
        params = GenericUtils.default_params( {}, extra_params, [:total_uses, :geolocation])
        
        deposit_instance = self.create( deposit: deposit_ref, uses: params[:total_uses], total_uses: params[:total_uses] ) do |i|
          i.set_geolocation( params[:geolocation][:latitude], params[:geolocation][:longitude] )
        end
        
        return deposit_instance
      end
      
      #-- --------------------------------------------------
      #                      Métodos
      #   -------------------------------------------------- #++
      
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