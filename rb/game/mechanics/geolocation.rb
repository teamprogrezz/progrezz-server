# encoding: UTF-8

require 'rest-client'
require 'progrezz/geolocation'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente a posiciones geolocalizadas.
    class GeolocationManagement
      
      # Distancia o ruio a añadir a los puntos ajustados, en km
      NOISE_KM        = 0.001
      
      # Ruido en latitud de NOISE_KM
      NOISE_LATITUDE  = Progrezz::Geolocation.distance_to_latitude( NOISE_KM, :km )
      
      # Ruido en longitud de NOISE_KM
      NOISE_LONGITUDE = Progrezz::Geolocation.distance_to_longitude( NOISE_KM, :km )

      # Ajustar geolocalización.
      # @param geolocation [Hash<Symbol, Float>] Hash de la forma { latitude: +lat+, longitude: +lon+ }
      # @return [Hash<Symbol, Float>] Entrada ajustada.
      def self.snap_geolocation!(geolocation = {latitude: 0.0, longitude: 0.0} )
        begin
          if ENV['progrezz_disable_routing'] != "true"
            new_loc = {}
            
            
            # Usar servidor OSRM
            if ENV['progrezz_matching_osrm'] != nil
              url      = ENV['progrezz_matching_osrm']
              request_uri = url + "/nearest?loc=" + geolocation[:latitude].to_s + "," + geolocation[:longitude].to_s
              
              result = RestClient.get(request_uri)
              new_loc = JSON[result]["mapped_coordinate"]
              new_loc = {latitude: new_loc[0], longitude: new_loc[1]}
            
            
            # User servicio de mapquest
            elsif ENV['progrezz_mapquest_key'] != nil
              # Usar mapquest por defecto
              url    = "http://open.mapquestapi.com/directions/v2/route?"
              key    = "key=" + ENV['progrezz_mapquest_key']
              params = "&ambiguities=ignore&routeType=pedestrian"
              from   = "&from=" + geolocation[:latitude].to_s + ", " + geolocation[:longitude].to_s
              to     = "&to=" + geolocation[:latitude].to_s + ", " + geolocation[:longitude].to_s
              
              # Realizar petición rest
              request_uri = url + key + params + from + to
              result = RestClient.get(request_uri)
              
              new_loc = JSON[result]["route"]["legs"][0]["maneuvers"][0]["startPoint"]
              new_loc = {latitude: new_loc["lat"], longitude: new_loc["lng"]}
            end
            
            geolocation[:latitude]  = new_loc[:latitude]
            geolocation[:longitude] = new_loc[:longitude]
          end
        rescue Exception => e
          puts "WARNING! Couldn't snap " + geolocation[:latitude].to_s + ", " + geolocation[:longitude].to_s + " to nearest road."
        end
      
        # Añadir ruido a la geolocalización
        random = Random.new
        geolocation[:latitude]  += random.rand(-NOISE_LATITUDE..NOISE_LATITUDE)
        geolocation[:longitude] += random.rand(-NOISE_LONGITUDE..NOISE_LONGITUDE)
        
        return geolocation
      end
    
    end
  end
end