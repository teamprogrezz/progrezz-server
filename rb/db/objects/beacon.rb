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

      # Tamaño mínimo del mensaje.
      MESSAGE_MIN_LENGHT = 5

      # Tamaño máximo del mensaje.
      MESSAGE_MAX_LENGHT = 255

      #-- --------------------------------------------------
      #                      Atributos (DB)
      #   -------------------------------------------------- #++

      # Mensaje del usuario que ha dejado la baliza.
      # @return [String] Contenido del mensaje.
      property :message, type: String, default: DEFAULT_MESSAGE

      # Cantidad de energía que ha recibido la baliza.
      # @return [Integer] Cantidad de energía.
      property :energy_gained, type: Integer, default: 0

      # Variable auxiliar para evitar bucles infinitos.
      # @return [Boolean] false si no está marcada para borrar. true en caso contrario.
      property :mark_as_removed, type: Boolean, default: false

      #-- --------------------------------------------------
      #                     Relaciones (DB)
      #   -------------------------------------------------- #++

      # @!method :level_profile
      # Relación con el nivel de la baliza (#Game::Database::LevelProfile). Se puede acceder con el atributo +level_profile+.
      # @return [Game::Database::LevelProfile] Nivel de la baliza.
      has_one :out, :level_profile, model_class: Game::Database::LevelProfile, type: "profiles_in", dependent: :destroy


      # @!method :connected_beacons
      # Relación con otras balizas (triangulizables). Se puede acceder con el atributo +connected_beacons+.
      # @return [Game::Database::Beacon] Balizas relacionadas.
      has_many :both, :connected_beacons, model_class: Game::Database::Beacon, type: "connected_to"

      # Alias de vecinos
      alias_method :neighbours, :connected_beacons

      #-- --------------------------------------------------
      #                    Métodos de clase
      #   -------------------------------------------------- #++

      # Crear un objeto.
      # @param args [Array] Array de argumentos. args[0] es el usuario que ha colocado el objeto. args[1] es el hash de datos extra.
      # @return [Game::Database::Beacon] Objeto creado y asociado.
      def self.create_item(*args)
        user         = args[0]
        extra_params = args[1] || {}

        raise ::GenericException.new("Invalid user.") if user == nil

        params = GenericUtils.default_params( {
          message: DEFAULT_MESSAGE
        }, extra_params )

        raise ::GenericException.new("Message is too short ( less than " + MESSAGE_MIN_LENGHT.to_s + ").") if params[:message].length < MESSAGE_MIN_LENGHT
        raise ::GenericException.new("Message is too long ( greather than " + MESSAGE_MAX_LENGHT.to_s + ").") if params[:message].length > MESSAGE_MAX_LENGHT

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

      # Retornar baliza dada una uuid.
      # @param uuid [String] Identificador de la base de datos.
      # @return [Game::Database::Beacon, nil] Retorna la baliza si la encuentra. Si no, retornará nil.
      def self.get_beacon(uuid)
        beacon = self.find_by(uuid: uuid)

        if beacon.caducated?
          beacon.remove()
          beacon = nil
        end

        return beacon
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
         ).pluck(:b)

        # Convertir a una lista
        beacons = beacons.to_a

        # Borrar balizas lejanas (fuera del círculo) y caducadas.
        beacons.delete_if do |b|
          if b.caducated?
            b.remove()
            true
          else
            Progrezz::Geolocation.distance(geolocation, b.geolocation, :km) > radius
          end
        end

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
        return if self.mark_as_removed == true
        self.update(mark_as_removed: true)

        # Lanzar evento
        self.dispatch(:OnRemove)

        # Exportar el nodo
        Game::Database::DatabaseManager.export_neo4jnode(self, self.rels)

        # Destruir nodo
        self.destroy()
      end

      # Peso (o probabilidad) Añadida a balizas cercanas.
      # Depende principalmente de su nivel.
      # @return [Float] Valor del peso a añadir.
      def weight_per_deposit
        Game::Mechanics::BeaconMechanics._weight_per_level( self.level_profile.level )
      end

      # Radio de acción de la baliza, en km.
      # Depende principalmente de su nivel.
      # @return [Float] Radio de acción de la baliza, en km.
      def action_radius
        Game::Mechanics::BeaconMechanics._radius_per_level( self.level_profile.level )
      end

      # Máximo número de conexiones de esta baliza.
      # @return [Integer] Máximo número de conexiones de esta baliza.
      def max_connections
        return Game::Mechanics::BeaconMechanics.max_connections(self)
      end

      # Actualizar conexiones con balizas cercanas.
      #
      # 1. Primero, se buscará las balizas en el máximo radio de conexión.
      # 2. Se ordenarán por distancia a la baliza actual.
      # 3. Para cada baliza, se comprobará si está lo suficientemente cerca.
      # 4. De ser así, se connectará con la nueva baliza.
      # 5. Se repetirán los pasos 3 y 4 hasta que se agoten las balizas o se llegue al máximo número de conexiones.
      def update_neighbours()
        # Comprobar si la baliza está muerta
        if self.caducated?
          self.remove()
          return
        end

        max_radius      = Game::Mechanics::BeaconMechanics._radius_per_level( Game::Mechanics::BeaconMechanics.max_level )
        radius          = self.action_radius

        # Comprobar si ha muerto alguna baliza vecina

        self.check_neighbours

        # Comprobar si ya ha suficientes balizas
        neighbours_count = self.neighbours.count
        return if neighbours_count >= self.max_connections

        geo = self.geolocation

        # Si no, buscar balizas cercanas
        beacons = Game::Database::Beacon.search_by_radius( geo, max_radius )

        # Eliminarse a sí mismo
        beacons.delete(self)

        # Ordenarlas por cercanía a la posición
        beacons.sort! { |a, b| Progrezz::Geolocation.distance(geo, a) <=> Progrezz::Geolocation.distance(geo, b) }

        # Para cada una, intentar asociarla si está lo suficientemente cerca
        beacons.each do |b|
          # Seleccionar el radio más grande
          current_radius = (radius > b.action_radius)? radius : b.action_radius

          # Si está cerca, conectar e intentar salir
          if Progrezz::Geolocation.distance( geo, b.geolocation, :km ) <= current_radius
            neighbours_count += 1 if connect_to(b)

            # Salir si ya hay suficientes conexiones
            break if neighbours_count >= self.max_connections
          end
        end
      end

      # Comprobar estado de vecinos.
      # Comprueba si los vecinos están muertos, y los borra en tal caso.
      def check_neighbours
        self.neighbours.each { |b| b.remove() if b.caducated? }
      end

      # Conectar a una baliza.
      # @param beacon [Game::Database::Beacon] Baliza a conectar.
      # @return [Boolean] true si se ha añadido correctamente. false en caso contrario.
      private def connect_to(beacon)
        raise ::GenericException.new("Invalid beacon.") if beacon == nil

        # Comprobar estado de los vecinos de la baliza a conectar
        beacon.check_neighbours()

        # Si hay demasiados vecinos, retornar false
        return false if beacon.neighbours.count >= beacon.max_connections

        # Connectar la baliza
        self.neighbours << beacon
        return true
      end

      # Desconectarse de una baliza.
      # @param beacon [Game::Database::Beacon] Baliza a desconectar.
      def disconnect(beacon)
        raise ::GenericException.new("Invalid beacon.") if beacon == nil
        self.neighbours(:b, :rel).match_to(beacon).delete_all(:rel)
      end

      # Transformar objeto a un hash
      # @param exclusion_list [Array<Symbol>] Elementos a omitir en el hash de resultado.
      # @return [Hash<Symbol, Object>] Objeto como hash.
      def to_hash(exclusion_list = [:owner] )
        output = {}

        if !exclusion_list.include?(:beacon)
          output[:info] = {
           uuid:        self.uuid,
           message:     self.message,
           deploy_date: self.created_at.strftime('%Q').to_i,
           duration:    self.duration
          }
        end

        if !exclusion_list.include?(:stats)
          lp = self.level_profile
          output[:stats] = {
            level:              lp.level,
            level_exp:          lp.level_exp,
            exp_to_next_level:  Game::Mechanics::BeaconMechanics.exp_to_next_level(lp.level + 1),
            energy_gained:      self.energy_gained,
            action_radius:      self.action_radius,
            weight_per_deposit: self.weight_per_deposit
          }
        end

        if !exclusion_list.include?(:neighbours)
          output[:neighbours] = []
          self.neighbours.each { |b| output[:neighbours] << b.uuid }
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

         # Actualizar conexiones
         beacon.update_neighbours

         puts "Beacon " + beacon.uuid.to_s + " created."
       }

      # Callback de subida de nivel.
      add_event_listener :OnLevelUp, lambda { |beacon, new_level|
         raise ::GenericException.new("Invalid beacon.") if (beacon == nil)

         new_level ||= beacon.level_profile.level

         # Actualizar conexiones
         beacon.update_neighbours

         puts "Beacon " + beacon.uuid.to_s + " leveled to " + new_level.to_s + "!!"
       }

      add_event_listener :OnRemove, lambda { |beacon|
         raise ::GenericException.new("Invalid beacon.") if (beacon == nil)

         # Actualizar conexiones de las balizas vecinas.
         beacon.neighbours.each do |b|
           beacon.disconnect( b )
           b.update_neighbours
         end

         max_radius = Game::Mechanics::BeaconMechanics._radius_per_level( Game::Mechanics::BeaconMechanics.max_level )

         # Y actualizar conexiones de las balizas cercanas
         nearby_beacons = Game::Database::Beacon.search_by_radius( beacon.geolocation, max_radius )
         nearby_beacons.delete(beacon)
         nearby_beacons.each { |b| b.update_neighbours }

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