require 'sinatra'
require 'data_mapper'

# Clases del juego (mensaje)
require './rb/juego/mensajes/mensaje'

# Postgress(heroku) (cambiar ENV['DATABASE_URL']) o sqlite3
DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/database.db" )

DataMapper.finalize
DataMapper.auto_upgrade!

get '/' do
  erb :index, :locals => {:test => "Prueba" }
end

# Metodos HTTP (GET y POST)
require './rb/juego/mensajes/mensaje_manager'