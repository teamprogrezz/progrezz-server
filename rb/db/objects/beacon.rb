# encoding: UTF-8

require 'date'
require 'progrezz/geolocation'

require_relative './item_geo'

module Game
  module Database

    class LevelProfile; end
    # Forward declaration
    
    # Clase que representa una baliza (beacon) geolocalizado.
    class Beacon < ItemGeolocatedObject
      include Neo4j::ActiveNode
      
      #-- --------------------------------------------------
      #                      Constantes
      #   -------------------------------------------------- #++

      # Mensaje por defecto.
      DEFAULT_MESSAGE = "Progrezz's beacon."

      # Identificador del objeto geolocalizado.
      RELATED_ITEM = "geo_beacon"
      
      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++

      # Mensaje del usuario que ha dejado la baliza.
      # @return [String] Contenido del mensaje.
      property :message, type: String, default: DEFAULT_MESSAGE

      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++

      # @!method :level_profile
      # Relación con el nivel de la baliza (#Game::Database::LevelProfile). Se puede acceder con el atributo +level_profile+.
      # @return [Game::Database::LevelProfile] Nivel de la baliza.
      has_one :out, :level_profile, model_class: Game::Database::LevelProfile, type: "profiles_in", dependent: :destroy

      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++

      # Crear un objeto.
      # @param args [Array] Array de argumentos. args[0] es el usuario que ha colocado el objeto. args[1] es el hash de datos extra.
      # @return [Game::Database::Beacon] Objeto creado y asociado.
      def self.create_item(*args)
        user         = args[0]
        extra_params = args[1] || {}

        raise ::GenericExceptio.new("Invalid user.") if user == nil

        params = GenericUtils.default_params( {
          message: DEFAULT_MESSAGE
        }, extra_params )

        # Crear baliza.
        beacon = self.create( message: params[:message], duration: Game::Mechanics::BeaconMechanics.data[:base][:duration].to_f )

        # Asociar al usuario.
        beacon.link_owner( user, RELATED_ITEM )

        # Crear nivel de baliza.
        beacon.level_profile = Game::Database::LevelProfile.create_level_profile( )

        # Ajustar geolocalización
        geo = user.geolocation()
        beacon.set_geolocation( geo[:latitude], geo[:longitude] )

        # Lanzar evento de creación
        beacon.dispatch(:OnCreate)

        # Retornar baliza.
        return beacon
      end

      # Getter del objeto de la baliza (inventario).
      # @return [Game::Database::Item] Referencia al objeto en la base de datos.
      def self.get_item()
        item = Game::Database::Item.find_by( item_id: RELATED_ITEM )
        raise ::GenericException.new("Invalid beacon reference for item id '" + RELATED_ITEM.to_s + "'.") if item == nil

        return item
      end

      # Limpiar balizas caducadas de la base de datos.
      # @return [Integer] Retorna el número de balizas que han sido borrados.
      def self.clear_caducated()
        count = 0

        Game::Database::DatabaseManager.run_nested_transaction do |t|
          Game::Database::Beacon.as(:b).where("b.duration <> 0").each do |beacon|
            if beacon.caducated?
              beacon.remove()
              count += 1
            end
          end
        end

        return count
      end

      # Buscar balizas cercanas en un determinado radio de busqueda (circula), especificado en +km+.
      # @param geolocation [Hash] Punto de búsqueda, de la forma +{latitude: lat, longitude: lon}+
      # @param radius [Float] Radio de busqueda, especificado en km.
      # @return [Array] Lista de Balizas cercanas.
      def self.search_by_radius(geolocation, radius)

        lat = Progrezz::Geolocation.distance_to_latitude(radius, :km)
        lon = Progrezz::Geolocation.distance_to_longitude(radius, :km)

        # Generar una lista de referencias
        beacons = self.query_as(:b)
         .where("b.latitude  > {l1} and b.latitude  < {l2} and b.longitude > {l3} and b.longitude < {l4}")
         .params(
            l1: (geolocation[:latitude] - lat),
            l2: (geolocation[:latitude] + lat),
            l3: (geolocation[:longitude] - lon),
            l4: (geolocation[:longitude] + lon)
         ).pluck(:b).to_a

        # Borrar balizas lejanas (fuera del círculo).
        beacons.delete_if { |b| Progrezz::Geolocation.distance(geolocation, b.geolocation, :km) > radius }

        # Retornar lista
        return beacons
      end

      #-- --------------------------------------------------
      #                      Métodos
      #   -------------------------------------------------- #++

      # Añadir tiempo de vida a la baliza.
      # @param time [Float] Tiempo de vida a añadir, especificado en minutos.
      # @return [Float] Tiempo añadido. Debería ser equivalente al parámetro +time+.
      def add_life_time(time)
        raise ::GenericException.new("Invalid time value.") if time == nil || time <= 0

        self.update( duration: self.duration + time )

        return time
      end

      # Borrar baliza.
      def remove()
        # Lanzar evento
        self.dispatch(:OnRemove)

        # Exportar el nodo
        Game::Database::DatabaseManager.export_neo4jnode(self, self.rels)

        # Destruir nodo
        self.destroy()
      end


      # Comprobar si una baliza ha caducado (ya no debería existir).
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

      # Peso (o probabilidad) Añadida a balizas cercanas.
      # Depende principalmente de su nivel.
      # @return [Float] Valor del peso a añadir.
      def weight_per_deposit
        Game::Mechanics::BeaconMechanics._weight_per_level( self.level_profile.level )
      end

      # Radio de acción de la baliza.
      # Depende principalmente de su nivel.
      # @return [Float] Radio de acción de la baliza.
      def action_radius
        Game::Mechanics::BeaconMechanics._radius_per_level( self.level_profile.level )
      end

      # Transformar objeto a un hash
      # @param exclusion_list [Array<Symbol>] Elementos a omitir en el hash de resultado.
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash(exclusion_list = [:owner] )
        output = {}

        if !exclusion_list.include?(:beacon)
          output[:beacon] = {
           uuid:        self.uuid,
           deploy_date: self.created_at.strftime('%Q'),
           duration:    self.duration
          }
        end

        if !exclusion_list.include?(:stats)
          lp = self.level_profile
          output[:stats] = {
            level:              lp.level,
            level_exp:          lp.level_exp,
            action_radius:      self.action_radius,
            weight_per_deposit: self.weight_per_deposit
          }
        end

        if !exclusion_list.include?(:neighbours)
          # TODO: Completar vecionas hash de una baliza
        end

        if !exclusion_list.include?(:owner)
          output[:owner] = owner.alias if owner != nil || owner.alias != nil
        end

        return output
      end

      #-- --------------------------------------------------
      #                    Callbacks (juego)
      #   -------------------------------------------------- #++

      add_event_listener :OnCreate, lambda { |beacon|
         raise ::GenericException.new("Invalid beacon.") if (beacon == nil)

         # TODO: ...
         puts "Beacon " + beacon.uuid.to_s + " created."
       }

      # Callback de subida de nivel.
      add_event_listener :OnLevelUp, lambda { |beacon, new_level|
         raise ::GenericException.new("Invalid beacon.") if (beacon == nil)

         new_level ||= beacon.level_profile.level

         # TODO: Ajustar parámetros de la baliza con el nuevo nivel.
         puts "Beacon " + beacon.uuid.to_s + " leveled to " + new_level.to_s + "!!"
       }

      add_event_listener :OnRemove, lambda { |beacon|
         raise ::GenericException.new("Invalid beacon.") if (beacon == nil)

         # TODO: ...
         puts "Beacon " + beacon.uuid.to_s + " destroyed :(."
       }

      # Lanzar un evento desde la baliza actual.
      #
      # Lista de eventos registrados:
      # - +:OnCreate (beacon)+: Al crear la baliza.
      # - +:OnLevelUp (beacon, new_level)+: Al subir de nivel.
      # - +:OnRemove (breaco)+: Al borrar la baliza.
      #
      # @param event_name [Object] Nombre del evento a lanzar.
      # @param args [Object] Argumentos a pasar a los callbacks (además de +self+).
      def dispatch(event_name, *args)
        self.class.dispatch_event(event_name, self, *args)
      end
    end
  end
end