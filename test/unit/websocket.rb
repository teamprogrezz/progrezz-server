# encoding: UTF-8

ENV['RACK_ENV'] = 'test'

require './main'
require 'test/unit'
require 'rack/test'

require_relative 'helpers'

class WebSocketTest < Test::Unit::TestCase
  include Rack::Test::Methods

  # Iniciar aplicación como "app"
  def app; Sinatra::ProgrezzServer end

  # WebSocket request method
  def ws_request()
    Sinatra::API::WebSocket::Methods.send( "ws__" + @request[:request][:type].to_s, app, @response, @session )
    GenericUtils.symbolize_keys_deep!(@response)
  end
  
  # ---------------------------
  #           Setup
  # ---------------------------
  
  # Inicializar antes de cada prueba.
  def setup
    # Cargar usuarios y mensajes (referencias)
    @users = CustomTestSuite.users
    @messages = CustomTestSuite.messages
    
    # Iniciar transaccion
    @transaction = Game::Database::DatabaseManager.start_transaction()
    
    # Setup other things.
    @request = {
      metada: {},
      request: { }
    }
    
    @response = {
      metadata: {},
      request: @request,
      response: {}
    }
    
    @session = { user_id: "test" }
  end
  
  # Cerrar antes de cada prueba
  def teardown
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    
    # Deshacer cambios en la base de datos.
    Game::Database::DatabaseManager.rollback_transaction(@transaction)
    Game::Database::DatabaseManager.stop_transaction(@transaction)
  end
  
  # ---------------------------
  #            Echo
  # ---------------------------
  
  # Probar "echo"
  def test_echo
    @request[:request][:type] = "echo"
    @request[:request][:data] = { name: "wikiti" }
    ws_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Hello, wikiti!"
  end
  
  
  
  # ---------------------------
  #            User
  # ---------------------------
  
  # Probar "user_update_geolocation"
  def test_user_update_geolocation
    authenticate()
    
    @request[:request][:type] = "user_update_geolocation"
    @request[:request][:data] = { user_id: "test", latitude: 23, longitude: -16 }
    ws_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "User geolocation changed to 23.0, -16.0"
  end
  
  # Probar "user_get_nearby_users"
  def test_user_get_nearby_users
    authenticate()
    
    @users[1].online(false)
    @request[:request][:type] = "user_get_nearby_users"
    @request[:request][:data] = { user_id: "test" }
    ws_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:users], []
    
    @users[1].online(true)
    @request[:request][:type] = "user_get_nearby_users"
    @request[:request][:data] = { user_id: "test" }
    ws_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:users], [ @users[1].to_hash ]
  end
  
  
end