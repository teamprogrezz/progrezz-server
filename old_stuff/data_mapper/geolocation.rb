require 'data_mapper'

module Game
  module Database
    class Geolocation < DataMapper::Property::Object
      attr_accessor :latitude
      attr_accessor :longitude

      def initialize(lat = 0.0, long = 0.0)
        @latitude  = lat
        @longitude = long
      end

      def dump(value)
        value.to_s()
      end

      def load(value)
        split = value.split(',')
        Geolocation.new(split[0].to_f(), split[1].to_f())
      end

      def to_s()
        return @latitude + "," + @longitude
      end
    end
  end
end




