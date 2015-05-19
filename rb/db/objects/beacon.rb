# encoding: UTF-8

require 'date'

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
      # @param *args [Array] Array de argumentos. args[0] es el usuario que ha colocado el objeto. args[1] es el hash de datos extra.
      # @return [Game::Database::Beacon] Objeto creado y asociado.
      def self.create_item(*args)
        user         = args[0]
        extra_params = args[1]

        params = GenericUtils.default_params( {
          message: DEFAULT_MESSAGE
        }, extra_params, [:geolocation] )

        # Crear baliza.
        beacon = self.create( message: params[:message], duration: Game::Mechanics::BeaconMechanics.data[:base][:duration].to_f )

        # Asociar al usuario.
        beacon.link_owner( user, RELATED_ITEM )

        # Crear nivel de baliza.
        beacon.level_profile = Game::Database::LevelProfile.create_level_profile( )

        # Ajustar geolocalización
        beacon.set_geolocation( params[:geolocation][:latitude], params[:geolocation][:longitude] )

        # Retornar baliza.
        return beacon
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

      #-- --------------------------------------------------
      #                    Callbacks (juego)
      #   -------------------------------------------------- #++

      # Callback de subida de nivel.
      add_event_listener :OnLevelUp, lambda { |beacon, new_level|
         raise ::GenericException.new("Invalid beacon.") if (beacon == nil)

         new_level ||= beacon.level_profile.level

         # TODO: Ajustar parámetros de la baliza con el nuevo nivel.
         puts "Beacon " + beacon.uuid.to_s + " leveled to " + new_level.to_s + "!!"
       }

      # Lanzar un evento desde la baliza actual.
      #
      # Lista de eventos registrados:
      # - +:OnLevelUp (user, new_level)+: Al subir de nivel.
      #
      # @param event_name [Object] Nombre del evento a lanzar.
      # @param args [Object] Argumentos a pasar a los callbacks (además de +self+).
      def dispatch(event_name, *args)
        self.class.dispatch_event(event_name, self, *args)
      end
    end
  end
end