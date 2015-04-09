# encoding: UTF-8

ENV['RACK_ENV'] = 'test'

require './main'
require 'test/unit'
require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'
require 'rack/test'

require_relative 'helpers'

# def puts(value); raise 'you found a puts'; end


# Pruebas unitarias de la API REST.
class RESTTest < Test::Unit::TestCase
  include Rack::Test::Methods

  # Iniciar aplicación como "app"
  def app; Sinatra::ProgrezzServer end

  # ---------------------------
  #           Setup
  # ---------------------------
  
  # REST request method
  def rest_request()
    get '/dev/api/rest', @request
    @response = eval(last_response.body)
    GenericUtils.symbolize_keys_deep!(@response)
  end
  
  # Inicializar antes de cada prueba.
  def setup
    # Cargar usuarios y mensajes (referencias)
    @users = CustomTestSuite.users
    @messages = CustomTestSuite.messages
    @deposit_instances = CustomTestSuite.deposit_instances
    
    # Iniciar transaccion
    @transaction = Game::Database::DatabaseManager.start_transaction()
    
    # Setup other things.
    @request = {
      metada: { },
      request: { }
    }
    
    @response = {
      metadata: { }
    }
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
    @request[:request][:data] = { name: "ProgrezzTest" }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Hello, ProgrezzTest!"
  end
  
  # Probar "echo_py"
  def test_echo_py
    @request[:request][:type] = "echo_py"
    @request[:request][:data] = { name: "ProgrezzTest" }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Hello, pythonist ProgrezzTest!"
  end
  
  # ---------------------------
  #           User
  # ---------------------------
  
  # Probar "user_who_am_i"
  def test_user_who_am_i
    authenticate()
    
    @request[:request][:type] = "user_who_am_i"
    @request[:request][:data] = { }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:user][:user_id], @users[0].user_id
    
  end
  
  # Probar "user_get_profile"
  def test_user_profile
    authenticate()
    
    @request[:request][:type] = "user_profile"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:profile][:info][:user_id], @users[0].user_id
    
  end
  
  # Probar "user_allowed_actions"
  def test_user_allowed_actions
    authenticate()
    
    @request[:request][:type] = "user_allowed_actions"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert @response[:response][:data][:allowed_actions].keys.include? :unlock_message
    assert @response[:response][:data][:allowed_actions].keys.include? :collect_fragment
    assert @response[:response][:data][:allowed_actions].keys.include? :search_nearby_fragments
    
  end
  
  # ---------------------------
  #       User messages
  # ---------------------------
  
  # Probar "user_unlock_message" y "user_read_message"
  def test_user_unlock_message
    authenticate()
    
    # Sin error
    @request[:request][:type] = "user_unlock_message"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[0].uuid }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Message unlocked."
    
    # Marcar como leído
    @request[:request][:type] = "user_read_message"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[0].uuid }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Message read."
    
    # Error
    @request[:request][:type] = "user_unlock_message"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[1].uuid }
    rest_request()
    
    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "User does not own message '" + @messages[1].uuid + "' to unlock."
  end
  
  # Probar "user_write_message"
  def test_user_write_message
    # No permitido
    @request[:request][:type] = "user_write_message"
    @request[:request][:data] = { user_id: @users[0].user_id, content: "Holaaaa!!" }
    rest_request()
    
    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "You are NOT authenticated as 'test'."
    
    authenticate()
    
    # Permitido
    @request[:request][:type] = "user_write_message"
    @request[:request][:data] = { user_id: @users[0].user_id, content: "Holaaaa!!" }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:written_message][:author][:author_alias], "test"
    assert_equal @response[:response][:data][:written_message][:message][:content], "Holaaaa!!"
  end
  
  # Probar "user_collect_message_fragment"
  def test_user_collect_message_fragment
    authenticate()
    
    # Mensaje no completado
    assert_equal @users[0].collected_completed_messages.count, 1
    
    # No permitir recoger un fragment ya recogido
    @request[:request][:type] = "user_collect_message_fragment"
    @request[:request][:data] = { user_id: @users[0].user_id, frag_uuid: @messages[1].fragments.where(fragment_index: 0).first.uuid }
    rest_request()
    
    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "The fragment could not be collected: Already collected."

    # Ni recoger fragmentos de mensajes ya completados.
    @request[:request][:type] = "user_collect_message_fragment"
    @request[:request][:data] = { user_id: @users[0].user_id, frag_uuid: @messages[0].fragments.where(fragment_index: 0).first.uuid }
    rest_request()
    
    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "The fragment could not be collected: Already completed."
     
    # Completar mensaje correctamente.
    @request[:request][:type] = "user_collect_message_fragment"
    @request[:request][:data] = { user_id: @users[0].user_id, frag_uuid: @messages[1].fragments.where(fragment_index: 1).first.uuid }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    
    # Mensaje completado!
    assert_equal @users[0].collected_completed_messages.count, 2
  end
  
  # Probar "user_get_nearby_message_fragments"
  def test_user_get_nearby_message_fragments
    authenticate()
    
    @users[0].set_geolocation(40, 30)
    
    @request[:request][:type] = "user_get_nearby_message_fragments"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert @response[:response][:data][:fragments][:system_fragments].count > 3
  end
  
  # Probar "user_get_messages"
  def test_user_get_messages
    authenticate()
    
    @request[:request][:type] = "user_get_messages"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:completed_messages].count, 1
    assert_equal @response[:response][:data][:fragmented_messages].count, 1
  end
  
  # Probar "user_get_messages"
  def test_user_get_collected_message_fragments
    authenticate()
    
    @request[:request][:type] = "user_get_collected_message_fragments"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[1].uuid  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:fragments].values[0].count, 2
  end
  
  # ---------------------------
  #       User items
  # ---------------------------
  
  # Probar "user_collect_item_from_deposit"
  def test_user_collect_item_from_deposit
    authenticate()
    
    @request[:request][:type] = "user_collect_item_from_deposit"
    @request[:request][:data] = { user_id: @users[0].user_id, deposit_uuid: @deposit_instances[0].uuid  }
    rest_request()
    puts @response

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Deposit collected."
    
    # Intentar recolectar de nuevo (error)
    rest_request()
    puts @response
    
    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "The deposit could not be collected: Already collected."

  end
  
  # ---------------------------
  #         Messages
  # ---------------------------
  # Probar "message_get"
  def test_message_get
    @request[:request][:type] = "message_get"
    @request[:request][:data] = { msg_uuid: @messages[1].uuid  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:info][:message][:uuid], @messages[1].uuid 
  end
  
  # Probar "message_get_unauthored"
  def test_message_get_unauthored
    @request[:request][:type] = "message_get_unauthored"
    @request[:request][:data] = { msg_uuid: @messages[1].uuid  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:messages].count, @messages.count
  end
  
  # Probar "message_get_from_fragment"
  def test_message_get_from_fragment
    @request[:request][:type] = "message_get_from_fragment"
    @request[:request][:data] = { frag_uuid: @messages[0].fragments.where(fragment_index: 0).first.uuid  }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @messages[0].uuid, @response[:response][:data][:message][:message][:uuid]
  end
  
  # ---------------------------
  #          Items
  # ---------------------------
  
  # Probar "item_get"
  def test_item_get
    @request[:request][:type] = "item_get"
    @request[:request][:data] = { item_id: "test_item"  }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:item][:name], "LAG Grenade"
  end
  
end

# Ejecutar test
Game::Database::DatabaseManager.run_nested_transaction do |tx|
  # Agregar ojetos de prueba
  #init_test_db()
  
  #Test::Unit::UI::Console::TestRunner.run(RESTTest)
  
  # Rollback
  #tx.failure
end
