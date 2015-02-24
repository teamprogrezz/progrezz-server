require 'sinatra'
require 'neo4j'

get '/test/t1' do
  begin
    test_user = Game::Database::User.sign_in('Wikiti', 'wikiti.doghound@gmail.com' )
    puts test_user.class.name
    return "Hello, " + test_user.alias + " (" + test_user.user_id + ")";
    #all_users = Game::Database::User.all()
    #all_users.each do |user|
    #  result +=  "<br>"
    #end
  rescue Exception => e
    return "<pre>" + e.class.name + " -> " + e.message + "</pre>"
  end
end
