# encoding: UTF-8

require 'neo4j'

module Game
  module Database

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
      
      # Latitud del objeto geolocalizado. 
      # @return [Float] Por defecto toma el valor 0.0
      property :latitude,  type: Float, default: 0.0, index: :exact
      
      # Longitud del objeto geolocalizado. 
      # @return [Float] Por defecto toma el valor 0.0
      property :longitude, type: Float, default: 0.0, index: :exact


      #-- -------------------------
      #      Callbacks (DB)
      #   ------------------------- #++
      
      # Callback posterior a la modificación de la latitud y longitud.
      # @return Lista de callbacks a ejecutar después de guardar el objeto en la base de datos.
      after_save :after_save_callback 
      
      #-- -------------------------
      #        Métodos
      #   ------------------------- #++

      # Cambiar latitud y longitud.
      #
      # @param lat [Float, nil] Nueva latitud  (usar nil para no modificar).
      # @param long [Float, nil] Nueva longitud (usar nil para no modificar).
      def set_geolocation(lat = nil, long = nil)
        lat = User.clamp_latitude(lat)
        long = User.clamp_longitude(long)
        
        if lat != nil && long != nil
          self.update( { latitude: lat, longitude: long } )
        elsif lat == nil && long != nil
          self.update( { longitude: long } )
        elsif lat != nil && long == nil
          self.update( { latitude: lat } )
        end
      end

      # Getter de la posición.
      #
      # @return [Hash<Symbol, Float>] Hash con la latitud y la longitud, con el formato {latitude: +lat+, longitude: +lon+ }.
      def geolocation()
        return { latitude: self.latitude, longitude: self.longitude }
      end
      
      # Ajustar posición a valores reales (véase las constantes de la clase #Game::Database::GeolocatedObject).
      # @return [Game::Database::GeolocatedObject] Referencia al objeto ajustado.
      def clamp()
        self.update( GeolocatedObject.clamp!(geolocation) )
        return self
      end
      
      # Ajustar posición a valores reales (método estático).
      # @param pos [Hash<Symbol, Float>] Hash con la posición geolocalizada, con el formato {latitude: +lat+, longitude: +lon+ }.
      # @return [Hash<Symbol, Float>] Referencia a la posición ajustada.
      def self.clamp!(pos)
        pos[:latitude]  = clamp_latitude(pos[:latitude])
        pos[:longitude] = clamp_longitude(pos[:longitude])
        
        return pos
      end
      
      # Ajustar latitud.
      # @param lat [Float] Latitud a acotar.
      # @return [Float] Latitud acotada.
      def self.clamp_latitude(lat)
        if(lat == nil)
          return nil
        else
          return [MIN_LATITUDE, lat,  MAX_LATITUDE ].sort[1]
        end
      end
      
      # Ajustar longitud.
      # @param long [Float] Longitud a acotar.
      # @return [Float] Longitud acotada.
      def self.clamp_longitude(long)
        if(long == nil)
          return nil
        else
          return [MIN_LONGITUDE, long,  MAX_LONGITUDE ].sort[1]
        end
      end
      
      # Stringificar objeto.
      #
      # @return [String] Objeto como string, con el formato "<Geolocation: +latitud+,+longitud+>".
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
