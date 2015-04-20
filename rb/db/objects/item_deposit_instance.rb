# encoding: UTF-8

require 'date'

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
      DEFAULT_DURATION = 7
      
      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++
      
      # Recursos totales del depósito.
      #
      # @return [Integer] Recursos totales del depósito.
      property :total_amount, type: Integer
      
      # Recursos actuales del depósito.
      #
      # @return [Integer] Recursos actuales del depósito.
      property :current_amount, type: Integer
      
      # Timestamp o fecha de recolección del depósito.
      # @return [DateTime] Fecha de creación.
      property :created_at
      
      # Duración (en días) de un depósito. Si es 0, durará eternamente.
      # @return [Integer] Días que durará el depósito.
      property :duration, type: Integer, default: DEFAULT_DURATION
      
      
      # Acceso directo al identificador del objeto relacionado con este depósito.
      # @return [String] item_id del objeto en sí.
      property :item_id_shortcut, type: String, default: ""
      
      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++
      
      # @!method deposit
      # Relación con el depósito (#Game::Database::ItemDeposit). Se puede acceder con el atributo +deposit+.
      # @return [Game::Database::ItemDeposit] Depósito relacionado con la estancia.
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
          raise ::GenericException.new("Invalid deposit.")
        end
        
        params = GenericUtils.default_params( {}, extra_params, [:total_amount, :geolocation])
        
        deposit_instance = self.create({
          deposit: deposit_ref,
          item_id_shortcut: deposit_ref.item.item_id,
          total_amount: params[:total_amount],
          current_amount: params[:total_amount],
          latitude: params[:geolocation][:latitude],
          longitude: params[:geolocation][:longitude]
        })
        
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
      
      # Recoger recursos.
      # @param user [Game::Database::User] Usuario para la recolección.
      # @return [Integer] Recursos recogidos.
      def gather(user)
        raise ::GenericException.new("Invalid deposit (caducated).") if caducated?
        
        # Escoger una cantidad aleatoria de recursos
        resources = [self.current_amount, Random.new.rand(self.deposit.user_min_amount ... self.deposit.user_max_amount)].min
        
        output = user.backpack.add_item( self.deposit.item, resources )

        self.update( current_amount: self.current_amount - output[:added_amount] ) if output[:added_amount] > 0
        
        return output
      end
      
      # Comprobar si un depósito ha caducado (por tiempo o por falta de recursos).
      # @return [Boolean] Si ha caducado, retorna True. En caso contrario, False.
      def caducated?
        return true  if self.current_amount <= 0
        return false if self.duration == 0
        return true  if DateTime.now >= self.created_at + self.duration
        
        return false
      end
      
      # Borrar la estancia.
      def remove()
        # Exportar el nodo
        Game::Database::DatabaseManager.export_neo4jnode(self, self.rels)
        
        # Borrar el nodo.
        self.destroy()
      end

      # Retornar objeto como hash.
      # @param exclusion_list [Array<Symbol>] Lista de elementos a excluir.
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash(exclusion_list = [], user_rel = nil)
        output = {}
        
        # TODO: Acomodar para el cliente.
        output[:item_id]     = self.item_id_shortcut unless exclusion_list.include? :item_id

        output[:instance] = {
          uuid: self.uuid,
          total_amount: self.total_amount,
          current_amount: self.current_amount,
          created_at:  self.created_at.to_time.to_i,
          duration: self.duration,
          remaining_seconds: (duration * 86400) - (DateTime.now.to_time.to_i - self.created_at.to_time.to_i)
        }
        
        if user_rel == nil
          output[:user] = { in_cooldown: false }
        else
          output[:user] = user_rel.to_hash
        end
        
        return output
      end
      
    end
  end
end