# encoding: UTF-8

require 'rest-client'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente a posiciones geolocalizadas.
    class GeolocationManagement

      # Ajustar geolocalización.
      # @param geolocation [Hash<Symbol, Float>] Hash de la forma { latitude: +lat+, longitude: +lon+ }
      # @param [Hash<Symbol, Float>] Entrada ajustada.
      def self.snap_geolocation!(geolocation = {latitude: 0.0, longitude: 0.0} )
        if ENV['progrezz_disable_snap_geolocations'] != "true"
          url    = "http://open.mapquestapi.com/directions/v2/route?"
          key    = "key=" + ENV['progrezz_mapquest_key']
          params = "&ambiguities=ignore"
          from   = "&from=" + geolocation[:latitude].to_s + ", " + geolocation[:longitude].to_s
          to     = "&to=" + geolocation[:latitude].to_s + ", " + geolocation[:longitude].to_s

          result = RestClient.get(url + key + params + from + to)
          new_loc = JSON[result]["route"]["legs"][0]["maneuvers"][0]["startPoint"]
          
          geolocation[:latitude]  = new_loc["lat"]
          geolocation[:longitude] = new_loc["lng"]
        end
        
        return geolocation
      end
    
    end
  end
end