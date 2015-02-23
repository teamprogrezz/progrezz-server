require 'sinatra'
require 'neo4j'

get '/test/t1' do
  result = "hola"
  test_user = Game::Database::User.create( {alias: 'prueba', user_id: 'id'} )

  all_users = Game::Database::User.all()
  all_users.each do |user|
    result +=  "<br>"
  end
 
  return result;
end
