$LOAD_PATH << File.dirname(__FILE__) + "\n"

require 'sinatra'

# Clases de la BD
Dir["./rb/db/*.rb"].each {|file|
  puts "Leyendo Objetos de DB: " +  file.split(/\.rb/)[0]
  require file.split(/\.rb/)[0]
}

# Acceso a la base de datos
neo4j_url = ENV['GRAPHENEDB_URL'] || 'http://localhost:7474'
uri = URI.parse(neo4j_url)
server_url = "http://#{uri.host}:#{uri.port}"

Neo4j::Session.open(:server_db, server_url, basic_auth: { username: uri.user, password: uri.password})

get '/' do
  erb :index, :locals => {:test => "Prueba" }
end

# Metodos HTTP (GET y POST)
Dir["./rb/game/**/*.rb"].each {|file|
  puts "Leyendo URIs: " + file.split(/\.rb/)[0]
  require file.split(/\.rb/)[0]
}

