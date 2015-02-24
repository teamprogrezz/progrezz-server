require 'sinatra'
require 'neo4j'

get '/test/t1' do
  begin
    test_user = Game::Database::User.sign_in('Wikiti', 'wikiti.doghound@gmail.com' )
    return "Hello, " + test_user.alias + " (" + test_user.user_id + ")";
  rescue Exception => e
    geo = Game::Database::User.find_by(user_id: 'wikiti.doghound@gmail.com' ).geolocation
    geo.longitude = geo.longitude - 30.2;
    puts geo
    geo.save
    return "<pre>" + e.class.name + " -> " + e.message + "</pre>"
  end
end
