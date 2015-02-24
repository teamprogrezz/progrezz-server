# encoding: UTF-8

require 'sinatra'
require 'neo4j'

  # Pruebas sencillas varias

# Tirar base de datos
get '/test/drop' do
  DatabaseManager.drop()
  redirect to('/test/list')
end

# Listar datos de prueba
get '/test/list' do
  erb :user_list, :views => "views/test/", :locals => {:users => Game::Database::User.all() }
end

# Añadir datos de prueba
get '/test/add' do
  begin
    Game::Database::User.sign_in('Wikiti', 'wikiti.doghound@gmail.com' )
    Game::Database::User.sign_in('Shylpx', 'cristogr.93@gmail.com' )

    redirect to('/test/list')

  rescue Exception => e
    return "<pre>" + e.class.name + " -> " + e.message + "</pre>"
  end
end
