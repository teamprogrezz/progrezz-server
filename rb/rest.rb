# encoding: UTF-8

# Metodos HTTP (GET y POST) de la API REST
Dir["./rb/game/**/*.rb"].each {|file|
  puts "Leyendo URIs: " + file.split(/\.rb/)[0]
  require file.split(/\.rb/)[0]
}

