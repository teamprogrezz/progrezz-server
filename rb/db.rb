# encoding: UTF-8

# Cargar ficheros de clases de la BD
Dir["./rb/db/*.rb"].each {|file|
  puts "Leyendo Objetos de DB: " +  file.split(/\.rb/)[0]
  require file.split(/\.rb/)[0]
}

# Acceso a la base de datos Neo4j
neo4j_url = ENV['GRAPHENEDB_URL'] || 'http://localhost:7474' # En Heroku, o en localhost
uri = URI.parse(neo4j_url)
server_url = "http://#{uri.host}:#{uri.port}"

Neo4j::Session.open(:server_db, server_url, basic_auth: { username: uri.user, password: uri.password})
