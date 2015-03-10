# encoding: UTF-8

if development?
  # Variable global de depuración.
  DEV = true
end

# Módulo que contiene estructuras referentes al juego (general).
module Game
# Módulo que contiene estructuras de datos referentes a la base de datos.
module Database
  
  # Lista de transacciones.
  @@transactions = []

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
      begin
        #-- Cargar ficheros de objetos de la BD #++
        GenericUtils.require_dir("./rb/db/objects/**/*.rb",   "Leyendo Objetos de DB:    ")
        
        #-- Cargar ficheros de relaciones de la BD #++
        GenericUtils.require_dir("./rb/db/relations/**/*.rb", "Leyendo Objetos de DB:    ")
        
        #-- Conectar a la base de datos #++
        neo4j_url = ENV['PROGREZZ_NEO4J_URL'] || ENV['GRAPHENDB_URL'] || 'http://localhost:7474' # En Heroku, o en localhost
        uri = URI.parse(neo4j_url)
        server_url = "http://#{uri.host}:#{uri.port}"
  
        Neo4j::Session.open(:server_db, server_url, basic_auth: { username: uri.user, password: uri.password})
        @@transactions = []
      rescue
        raise "Could not connect to database."
      end
    end

    # Destruye todo el contenido de la base de datos.
    #
    # @note ¡No se pueden revertir los cambios!
    def self.drop()
      self.force_save()
      Neo4j::Session.current._query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    end
    
    # Guardar de manera forzada el contenido en la base de datos.
    #
    # Se ignorará el tiempo mínimo para guardar datos en la DB.
    def self.force_save()
      # Borrar y cancelar transacciones actuales.
      for tx in @@transactions do
        tx.failure()
        tx.close()
      end
      
      @@transactions = []
      
      if defined? DEV
        puts "--------------------------------------"
        puts "**        Forced saving DB          **"
        puts "--------------------------------------"
      end
    end
    
    # Ejecutar transacciones anidadas.
    # 
    # Por ejemplo, basta con realizar un bloque de la siguiente manera:
    #   DatabaseManager.run_nested_transaction do |tx1|
    #     DatabaseManager.run_nested_transaction do |tx2|
    #       modificacion1()
    #     end
    #     modificacion2()
    #   end
    #
    # @return [Object] Resultado o retorno del último bloque de código ejecutado.
    def self.run_nested_transaction()
      # Si no hay bloque, devolver error.
      raise ArgumentError.new("Expected a block to run in DatabaseManager.run_transaction_anidated") unless block_given?
      
      begin
        tx = Neo4j::Transaction.new # Crear transacción
        output = yield tx           # Ejecutar bloque
        tx.success                  # Cerrarla
      rescue Exception
        tx.failure unless tx.nil?
        raise
      ensure
        tx.finish unless tx.nil?
      end
      
      return output
    end
    
    # Iniciar una nueva transacción.
    #
    # @return [Neo4j::Transaction] Referencia a la transacción creada.
    def self.start_transaction()
      tx = Neo4j::Transaction.new
      @@transactions << tx
      return tx
    end
    
    # Termina y guarda una transacción.
    #
    # @param tx [Neo4j::Transaction] Referencia a la transacción.
    def self.stop_transaction(tx)
      @@transactions.delete(tx)
      tx.close()
    end
    
    # Deshace los cambios de una transacción (rollback).
    #
    # @param tx [Neo4j::Transaction] Referencia a la transacción.
    def self.rollback_transaction(tx)
      tx.failure()
    end
    
  end

  #-- Lanzar el método setup #++
  DatabaseManager.setup()

end
end
