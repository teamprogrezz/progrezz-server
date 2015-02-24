require 'neo4j'

module Game
  module Database
    class Geolocation
      include Neo4j::ActiveNode

      property :latitude  # Latitud
      property :longitude # Longitud

      def self.create_geolocation(lat = 0.0, long = 0.0)
        return create( {latitude: lat, longitude: long} )
      end

      def to_s()
        return @latitude + "," + @longitude
      end
    end
  end
end




