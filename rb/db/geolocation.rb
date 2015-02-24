# encoding: UTF-8

require 'neo4j'

module Game
  module Database

    # Clase que representa una posición geolocalizada en la base de datos.
    class Geolocation
      include Neo4j::ActiveNode

      # -------------------------
      #        Constantes
      # -------------------------
      MIN_LATITUDE  = -90
      MAX_LATITUDE  =  90
      MIN_LONGITUDE = -180
      MAX_LONGITUDE =  180

      # -------------------------
      #        Atributos
      # -------------------------
      attr_reader :is_updating # Variable auxiliar para comprobar si el objeto está siendo actualizado.

      # -------------------------
      #      Atributos (DB)
      # -------------------------
      property :latitude,  type: Float # Latitud
      property :longitude, type: Float # Longitud

      # -------------------------
      #      Callbacks (DB)
      # -------------------------
      after_save :after_save_callback # Callback posterior a la modificación de la latitud y longitud

      # Creación de posiciones geolocalizadas
      # lat  -> latitud de la posición
      # long -> longitud de la posición
      def self.create_geolocation(lat = 0.0, long = 0.0)
        return create( {latitude: lat, longitude: long} ).clamp
      end

      # Ajustar posición a valores reales (véase http://www.geomidpoint.com/latlon.html)
      def clamp()
        self.latitude  = [MIN_LATITUDE,  self.latitude,  MAX_LATITUDE ].sort[1]
        self.longitude = [MIN_LONGITUDE, self.longitude, MAX_LONGITUDE].sort[1]
        self.save
        return self
      end

      # Stringificar objeto
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
    end
  end
end




