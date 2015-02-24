$LOAD_PATH << File.dirname(__FILE__) + "\n"

require 'sinatra'
require 'data_mapper'

# Clases de la BD
Dir["./rb/data_mapper/*.rb"].each {|file|
  puts "Leyendo Objetos de DB: " +  file.split(/\.rb/)[0]
  require file.split(/\.rb/)[0]
}

# Postgress(heroku) (cambiar ENV['DATABASE_URL']) o sqlite3
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/database.db" )

DataMapper.finalize
DataMapper.auto_upgrade!

get '/' do
  erb :index, :locals => {:test => "Prueba" }
end

# Metodos HTTP (GET y POST)
Dir["./rb/game/**/*.rb"].each {|file|
  puts "Leyendo URIs: " + file.split(/\.rb/)[0]
  require file.split(/\.rb/)[0]
}

#require './rb/juego/mensajes/mensaje_manager'

