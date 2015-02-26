# encoding: UTF-8

module Game
  module Database

    # Clase que representa una posición geolocalizada en la base de datos.
    #
    # Se usará, principalmente, por clases que heredan de Game::Database::GeolocatedObject.
    #
    # Véase http://www.geomidpoint.com/latlon.html para entender el formato de la posición geolocalizada.
    class Geolocation
      include Neo4j::ActiveNode

      #-- -------------------------
      #        Constantes
      #   ------------------------- #++
      
      # Mínima latitud posible.
      MIN_LATITUDE  = -90
      # Máxima latitud posible.
      MAX_LATITUDE  =  90
      # Mínima longitud posible.
      MIN_LONGITUDE = -180
      # Máxima longitud posible.
      MAX_LONGITUDE =  180

      #-- -------------------------
      #        Atributos
      #   ------------------------- #++
      
      # Variable auxiliar para comprobar si el objeto está siendo actualizado.
      attr_reader :is_updating

      #-- -------------------------
      #      Atributos (DB)
      #   ------------------------- #++
      
      # Latitud.
      property :latitude,  type: Float
      # Longitud.
      property :longitude, type: Float

      #-- -------------------------
      #      Callbacks (DB)
      #   ------------------------- #++
      after_save :after_save_callback # Callback posterior a la modificación de la latitud y longitud.

      # Creación de nodos de posiciones geolocalizadas.
      #
      # * *Argumentos* :
      #   - +lat+: Latitud de la posición.
      #   - +long+: Longitud de la posición.
      #
      # * *Retorna* :
      #   - Referencia al objeto creado en la base de datos, de tipo Game::Database::Geolocation.
      def self.create_geolocation(lat = 0.0, long = 0.0)
        return create( {latitude: lat, longitude: long} ).clamp
      end

      # Ajustar posición a valores reales.
      # * *Retorna* :
      #   - Referencia al objeto ajustado.
      def clamp()
        self.latitude  = [MIN_LATITUDE,  self.latitude,  MAX_LATITUDE ].sort[1]
        self.longitude = [MIN_LONGITUDE, self.longitude, MAX_LONGITUDE].sort[1]
        self.save
        return self
      end

      # Stringificar objeto.
      #
      # * *Retorna* :
      #   - Objeto como string, con el formato "<Geolocation: +latitud+,+longitud+>".
      def to_s()
        return "<Geolocation: " + self.latitude.to_s + "," + self.longitude.to_s + ">"
      end

      # Callback lanzado después de guardar el objeto, para hacer comprobaciones (posición real, etc).
      def after_save_callback()
        if @is_updating == true; return end
        @is_updating = true

        clamp()

        @is_updating = false
      end
      
      private :after_save_callback
    end
  end
end




