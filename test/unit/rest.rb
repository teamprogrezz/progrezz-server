ENV['RACK_ENV'] = 'test'

require './main'
require 'test/unit'
require 'rack/test'

# Pruebas unitarias de la API REST.
class RESTTest < Test::Unit::TestCase
  include Rack::Test::Methods

  # Iniciar aplicación como "app"
  def app; Sinatra::ProgrezzServer end
  
  # ---------------------------
  #          Helpers
  # ---------------------------
  def authenticate(provider = "google_ouath2")
    get '/auth/google_oauth2/callback', nil, {"omniauth.auth" => OmniAuth.config.mock_auth[:google_oauth2]}
  end
  
  # ---------------------------
  #           Setup
  # ---------------------------
  
  # Inicializar antes de cada prueba.
  def setup

    # Setup omniauth
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock(:google_oauth2, {
      :uid => '222222222222222222222',
      :info => {
        :email => "test@example.com",
        :name => 'test'
      }
    })
    
    # Setup database
    @users = []
    @messages = []
    
    begin 
      tx = Game::Database::DatabaseManager.start_transaction()
      
      @users << Game::Database::User.sign_up( "test", "test@example.com", {latitude: 3.0, longitude: 2.0} )
      @users[0].write_msg( "Hola mundo!!!" )
      
      @messages << Game::Database::Message.create_message( "Hello, universe", 2, nil, nil, {latitude: 3.0, longitude: 2.0} )
      @messages << Game::Database::Message.create_message( "Hello, universe (2)", 2, nil, nil, {latitude: 3.2, longitude: 2.0} )
      
      @users[0].collect_fragment(@messages[0].fragments[0])
      @users[0].collect_fragment(@messages[0].fragments[1])
      @users[0].collect_fragment(@messages[1].fragments[0])
    
    rescue Exception => e
      puts "ERROR: " + e.message + "\n" + e.backtrace
      Game::Database::DatabaseManager.rollback_transaction(tx)
    ensure
      Game::Database::DatabaseManager.stop_transaction(tx)
    end
    
    # Setup other things.
    @request = {
      metada: {},
      request: { }
    }
    
    @session = ENV['rack.session']
  end
  
  # Cerrar antes de cada prueba
  def teardown
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    
    @users.each do |usr|
      usr.destroy
    end
    
    @messages.each do |msg|
      msg.destroy
    end
  end

  # ---------------------------
  #            Echo
  # ---------------------------
  
  # Probar "echo"
  def test_echo
    @request[:request][:type] = "echo"
    @request[:request][:data] = { name: "ProgrezzTest" }
    
    get '/dev/api/rest', @request
    response = eval(last_response.body)
    GenericUtils.symbolize_keys_deep!(response)

    assert_equal response[:response][:status], "ok"
    assert_equal response[:response][:data][:message], "Hello, ProgrezzTest!"
  end
  
  # Probar "echo_py"
  def test_echo_py
    @request[:request][:type] = "echo_py"
    @request[:request][:data] = { name: "ProgrezzTest" }
    
    get '/dev/api/rest', @request
    response = eval(last_response.body)
    GenericUtils.symbolize_keys_deep!(response)

    assert_equal response[:response][:status], "ok"
    assert_equal response[:response][:data][:message], "Hello, pythonist ProgrezzTest!"
  end
  
  # ---------------------------
  #       User messages
  # ---------------------------
  def test_user_change_message_status
    authenticate()
    
    @request[:request][:type] = "user_change_message_status"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[0].uuid, new_status: "unread" }
    
    get '/dev/api/rest', @request
    response = eval(last_response.body)
    GenericUtils.symbolize_keys_deep!(response)
    
    assert_equal response[:response][:status], "ok"
    assert_equal response[:response][:data][:message], "Message status changed to 'unread'."
  end
  
  def test_user_change_message_status
    authenticate()
    
    @request[:request][:type] = "user_change_message_status"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[0].uuid, new_status: "unread" }
    
    get '/dev/api/rest', @request
    response = eval(last_response.body)
    GenericUtils.symbolize_keys_deep!(response)
    
    assert_equal response[:response][:status], "ok"
    assert_equal response[:response][:data][:message], "Message status changed to 'unread'."
  end
end