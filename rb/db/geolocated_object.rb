require 'neo4j'

module Game
  module Database

    class Geolocation; end # "forward declaration"

    # Clase abstracta que representa un objeto geolocalizado.
    class GeolocatedObject
      include Neo4j::ActiveNode

      # -------------------------
      #     Relaciones (DB)
      # -------------------------
      has_one :out, :geolocation, model_class: Game::Database::Geolocation, type: "is_located_at" # Posición del objeto

      # -------------------------
      #        Métodos
      # -------------------------

      # Cambiar latitud y longitud
      # lat  -> Nueva latitud  (usar nil para no modificar)
      # long -> Nueva longitud (usar nil para no modificar)
      def set_position(lat = nil, long = nil)
        if lat != nil;  self.geolocation.latitude = lat end
        if long != nil; self.geolocation.longitude = long end

        geolocation.save
      end

      # Getter de la posición
      # -> Devuelve un array: [latitud, longitud]
      def get_position()
        return [self.geolocation.latitude, self.geolocation.longitude]
      end
      
      # Stringificar objeto
      def to_s()
        return self.geolocation.to_s
      end

    end
  end
end




