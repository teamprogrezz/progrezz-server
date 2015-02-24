require 'sinatra'
require 'neo4j'

get '/test/t1' do
  begin
    test_user = Game::Database::User.sign_in('Wikiti', 'wikiti.doghound@gmail.com' )
    return "Hello, " + test_user.alias + " (" + test_user.user_id + ")";
    #all_users = Game::Database::User.all()
    #all_users.each do |user|
    #  result +=  "<br>"
    #end
  rescue Exception => e
    return e.message
  end

  result += "<br>" + test_user.class.name
end
