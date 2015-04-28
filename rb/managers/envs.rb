# encoding: UTF-8

require 'json'

# Clase gestora de las variables env.
class EnvsManager
  # Estructura de datos a modificar.
  ENVS = ::ENV

  # Fichero de las variables a cargar.
  ENV_FILE  = "data/envs.json"

  # Datos cargados.
  @data = {}

  def self.setup()
    @data = JSON.parse( File.read( ENV_FILE ) )

    ENVS.merge!(@data)
  end

end

EnvsManager.setup()