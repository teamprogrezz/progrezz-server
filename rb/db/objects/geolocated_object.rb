# encoding: UTF-8

require 'neo4j'

module Game
  module Database

    class Geolocation; end #-- "forward declaration" #++

    # Clase abstracta que representa un objeto geolocalizado.
    class GeolocatedObject
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
      property :latitude,  type: Float, default: 0.0
      property :longitude, type: Float, default: 0.0
      #property :geolocated_pos, default: [0.0, 0.0], on: :create # Array que contiene la geolocalización, con formato [latitude, longitud].


      #-- -------------------------
      #      Callbacks (DB)
      #   ------------------------- #++
      after_save :after_save_callback # Callback posterior a la modificación de la latitud y longitud.
      
      #-- -------------------------
      #        Métodos
      #   ------------------------- #++

      # Cambiar latitud y longitud.
      #
      # * *Argumentos* :
      #   - +lat+: Nueva latitud  (usar nil para no modificar).
      #   - +long+: Nueva longitud (usar nil para no modificar).
      #   - +save_after+: Guardar el objeto. Por defecto, se guarda (costoso).
      def set_geolocation(lat = nil, long = nil, save_after = true)
        geolocated_pos = [] if geolocated_pos == nil
        
        if lat != nil;  self.latitude  = lat end
        if long != nil; self.longitude = long end

        self.save if save_after
      end

      # Getter de la posición.
      #
      # * *Retorna* :
      #   - Array con la latitud y la longitud, con el formato [latitud, longitud].
      def geolocation()
        return { latitude: self.latitude, longitude: self.longitude }
      end
      
      # Ajustar posición a valores reales.
      # * *Retorna* :
      #   - Referencia al objeto ajustado.
      def clamp()
        self.latitude = [MIN_LATITUDE,  self.latitude, MAX_LATITUDE ].sort[1]
        self.longitude = [MIN_LONGITUDE, self.longitude, MAX_LONGITUDE].sort[1]
        self.save
        return self
      end
      
      # Ajustar posición a valores reales (método estático).
      # * *Arguments*: 
      #   - +pos+: Hash con la posición geolocalizada.
      # * *Retorna* :
      #   - Referencia al objeto ajustado.
      def self.clamp(pos)
        pos[:latitude]  = [MIN_LATITUDE,  pos[:latitude],  MAX_LATITUDE ].sort[1]
        pos[:longitude] = [MIN_LONGITUDE, pos[:longitude], MAX_LONGITUDE].sort[1]
        
        return pos
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
      
      private   :after_save_callback

    end
  end
end
