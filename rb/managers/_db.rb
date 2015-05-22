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
    # Lista de transacciones.
    @@transactions = []
    
    # Fichero para guardar nodos borrados.
    DUMP_FILE_JSON = "tmp/db_dump.json"
    
    # Inicializa la base de datos.
    #
    # Si se encuentra la variable de entorno 'GRAPHENEDB_URL' (heroku), se usará dicha dirección como servidor
    # neo4j. En caso contrario, se usará (por defecto) el servidor loca, con el puerto 7474.
    def self.setup()
      #-- Cargar ficheros de objetos de la BD #++
      GenericUtils.require_dir("./rb/db/objects/**/*.rb",   "Leyendo Objetos de DB:      ")
      
      #-- Cargar ficheros de relaciones de la BD #++
      GenericUtils.require_dir("./rb/db/relations/**/*.rb", "Leyendo Objetos de DB:      ")
      
      begin    
        #-- Conectar a la base de datos #++
        neo4j_url = ENV['PROGREZZ_NEO4J_URL'] || ENV['GRAPHENDB_URL'] || 'http://localhost:7474' # En Heroku, o en localhost
        uri = URI.parse(neo4j_url)
        server_url = "http://#{uri.host}:#{uri.port}"
  
        Neo4j::Session.open(:server_db, server_url, basic_auth: { username: uri.user, password: uri.password})
        @@transactions = []
      rescue Exception => e
        raise ::GenericException.new( "Could not connect to database.", e)
      end
    end

    # Destruye el contenido de la base de datos.
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
      stop_all_transactions()
      
      if defined? DEV
        puts "--------------------------------------"
        puts "**        Forced saving DB          **"
        puts "--------------------------------------"
      end
    end
    
    # Exportar nodo neo4j y sus relaciones.
    #
    # Se accede a los atributos del nodo con node.attributes
    #   puts node.attributes
    #
    # Se accede a cada relación con node_relations.each
    #   node_relations.each do |rel|
    #     if rel.is_a? Neo4j::Server::CypherRelationship
    #       puts rel.start_node, rel.end_node # Acceso a nodos de la relación (genérica).
    #     else
    #       puts rel.from_node, rel.to_node   # Acceso a nodos de la relación (personalizada).
    #     end
    #     puts rel.attributes if rel.respond_to? :attributes  # Acceso a atributos de la relación (si existen).
    #   end
    #
    # @param node [Object] Nodo neo4j a exportar.
    # @param node_relations [Array<Object>] Relaciones de un nodo. Se puede acceder también con +node.rels+.
    # @param extra_params [Hash<Symbol, Object>] Parámetros extra, por si fueran necesario.
    def self.export_neo4jnode(node, node_relations, extra_params = {})
      params = GenericUtils.default_params( {
        export_type: :json
      }, extra_params )
      
      case params[:export_type]
      when :json
        # puts "Exporting..."
        
        output = {}
        output["node"] = {
          "id" => node.neo_id,
          "uuid" => node.uuid,
          "labels" => node.labels,
          "attributes" => node.attributes
        } if node != nil
        
        output["relations"] = []
        
        node_relations.each do |rel|
          relation = {}
          if rel.is_a? Neo4j::Server::CypherRelationship
            relation["from_node"] = rel.start_node.uuid
            relation["to_node"] = rel.end_node.uuid
          else
            relation["from_node"] = rel.from_node.uuid
            relation["to_node"] = rel.to_node.uuid
          end
          
          if rel.respond_to? :attributes
            relation["attributes"] = rel.attributes
          end
          
          output["relations"] << relation
        end
        
        # Escribir en un fichero
        File.open(DUMP_FILE_JSON, 'a') do |f|
          f.puts output.to_json + ","
        end
        
      else
        raise ::GenericException.new( "Unknow export type '" + params[:export_type].to_s + "'." )
      end
      
    end
    
    # Ejecutar transacciones anidadas.
    #
    # La base de datos se encargará de gestionar la finalización de las transacciones anidadas.
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
    def self.run_nested_transaction(&block)
      # Si no hay bloque, devolver error.
      raise ArgumentError.new("Expected a block to run in DatabaseManager.run_transaction_anidated") unless block_given?
      
      Neo4j::Transaction.run do |tx|
        begin
          @@transactions << tx
          block.call(tx)
          @@transactions.delete(tx)
        rescue
          @@transactions.delete(tx)
          raise
        end
      end
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
    
    # Forzar el cierre de todas las transacciones.
    def self.stop_all_transactions()
      @@transactions.reverse_each do |tx|
        tx.failure()
        tx.close()
      end
      
      @@transactions = []
    end
  end

  #-- Lanzar el método setup #++
  DatabaseManager.setup()

end
end
