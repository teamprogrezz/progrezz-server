# encoding: UTF-8

require 'json'

# Clase gestora de las variables env.
#
# Usando el fichero data/envs.json, se pueden cargar las variables
# de entorno sin necesidad de especificarlas en el sistema
# operativo. De esta manera, se puede ejecutar el backend
# con docker o cualquier otra máquina virtual sin tener que
# definir dichas variables de entorno.
class EnvsManager
  # Estructura de datos a modificar.
  ENVS = ::ENV

  # Fichero de las variables a cargar.
  ENV_FILE  = "data/envs.json"

  # Datos cargados.
  @data = {}

  def self.setup()
    @data = JSON.parse( File.read( ENV_FILE ) )

    @data.each do |k,v|
      ENVS[k] = v
    end
  end

end

EnvsManager.setup()