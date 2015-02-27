# encoding: UTF-8

# Módulo que contiene estructuras referentes al juego (general).
module Game
# Módulo que contiene estructuras de datos referentes a la base de datos.
module Database

  # Clase gestora de la base de datos.
  #
  # Se encarga de realizar tareas sencillas, como inicializar el acceso a la base
  # de datos neo4j, reiniciar su estado, etc.
  class DatabaseManager

    # Inicializa la base de datos.
    #
    # Si se encuentra la variable de entorno 'GRAPHENEDB_URL' (heroku), se usará dicha dirección como servidor
    # neo4j. En caso contrario, se usará (por defecto) el servidor loca, con el puerto 7474.
    def self.setup()
      #-- Cargar ficheros de objetos de la BD #++
      GenericUtils.require_dir("./rb/db/objects/**/*.rb", "Leyendo Objetos de DB: ")
      
      #-- Cargar ficheros de relaciones de la BD #++
      GenericUtils.require_dir("./rb/db/relations/**/*.rb", "Leyendo Objetos de DB: ")
      
      #-- Conectar a la base de datos #++
      neo4j_url = ENV['GRAPHENEDB_URL'] || 'http://localhost:7474' # En Heroku, o en localhost
      uri = URI.parse(neo4j_url)
      server_url = "http://#{uri.host}:#{uri.port}"

      Neo4j::Session.open(:server_db, server_url, basic_auth: { username: uri.user, password: uri.password})
    end

    # Destruye todo el contenido de la base de datos.
    #
    # @warning ¡No se pueden revertir los cambios!
    def self.drop()
      Neo4j::Session.current._query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    end
  end

  #-- Lanzar el método setup #++
  DatabaseManager.setup()

end
end
