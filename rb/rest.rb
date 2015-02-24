# encoding: UTF-8

# Clase gestora de la API REST.
#
#   Se encarga de realizar tareas sencillas, como inicializar el acceso a los métodos
# REST HTML (Sinatra).
class APIRestManager

  # Inicializa la API REST.
  #
  #   Principalmente, carga todos los ficheros fuente (.rb) contenidos
  # en el directorio *game/api/rest*.
  def self.setup()
    #-- Metodos HTTP (GET y POST) de la API REST #++
    require_dir("./rb/game/**/*.rb", "Leyendo URIs: ")
  end

end


