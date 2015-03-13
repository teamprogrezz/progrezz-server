# encoding: UTF-8

require 'rest_client'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente a posiciones geolocalizadas.
    class GeolocationManagement

      # Ajustar geolocalización.
      # @param geolocation [Hash<Symbol, Float>] Hash de la forma { latitude: +lat+, longitude: +lon+ }
      # @param [Hash<Symbol, Float>] Entrada ajustada.
      def self.snap_geolocation(geolocation = {latitude: 0.0, longitude: 0.0} )
        url    = "http://open.mapquestapi.com/directions/v2/route?"
        key    = "key=" + ENV['progrezz_mapquest_key']
        params = "&ambiguities=ignore"
        from   = "&from=" + geolocation[:latitude].to_s + ", " + geolocation[:longitude].to_s
        to     = "&to=" + geolocation[:latitude].to_s + ", " + geolocation[:longitude].to_s
  
        result = RestClient.get(url + key + params + from + to)
        puts result 
      end
    
    end
  end
end