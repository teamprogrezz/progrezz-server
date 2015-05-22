# encoding: UTF-8

require 'neo4j'

require_relative './geolocated_object'
require_relative '../relations/user-placed_item-geo'

module Game
  module Database

    # Clase abstracta que representa un objeto geolocalizado.
    class ItemGeolocatedObject < GeolocatedObject
      include Neo4j::ActiveNode
      extend  Evented # Eventos.

      # Duración por defecto de una baliza, especificado en minutos.
      DEFAULT_DURATION = 0

      # Timestamp o fecha de creación del objeto.
      # @return [DateTime] Fecha de creación.
      property :created_at

      # Duración (en días) de un objeto. Si es 0, durará eternamente.
      # @return [Integer] Días que durará la baliza.
      property :duration, type: Float, default: DEFAULT_DURATION

      # @!method owner
      # Relación con el usuario que ha colocado este objeto.
      # Se puede acceder con el atributo #owner.
      #
      # @return [Game::Database::RelationShips::UserPlaced_ItemsGeo]
      has_one :in, :owner, rel_class: Game::Database::RelationShips::UserPlaced_ItemsGeo, model_class: Game::Database::User

      # Crear objeto.
      # @note Sin implementar.
      def self.create_item(*args)
        raise ::GenericException.new("Method 'create_item' is not defined.")
      end

      # Limpiar objetos caducados de la base de datos.
      # @return [Integer] Retorna el número de objetos que han sido borrados.
      def self.clear_caducated()
        count = 0

        Game::Database::DatabaseManager.run_nested_transaction do |t|
          self.as(:it).where("it.duration <> 0").each do |it|
            if it.caducated?
              it.remove()
              count += 1
            end
          end
        end

        return count
      end

      # Lista de descendientes.
      # @return [Array<Class>] Lista de descendientes.
      def self.descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end

      # Asociar objeto a usuario.
      # @param user [Game::Database::User] Usuario a asociar.
      def link_owner(user, type = nil)
        raise ::GenericException.new( "Invalid user reference." ) if user == nil
        raise ::GenericException.new( "Item already linked." ) unless self.owner == nil

        type ||= "UNK"
        puts "WARNING! Item type is " + type.to_s + "!" if type == "UNK"

        Game::Database::RelationShips::UserPlaced_ItemsGeo.create( from_node: user, to_node: self, item_type: type )
      end

      # Comprobar si un objeto ha caducado (ya no debería existir).
      # @return [Boolean] Si ha caducado, retorna True. En caso contrario, False.
      def caducated?
        if duration == 0
          return false
        end

        if self.created_at + (duration / (24 * 60.0) ) <= Time.now
          return true
        end

        return false
      end

      # ...
    end
  end
end
