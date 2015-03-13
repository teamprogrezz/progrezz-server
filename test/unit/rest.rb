# encoding: UTF-8

ENV['RACK_ENV'] = 'test'

require './main'
require 'test/unit'
require 'rack/test'

# def puts(value); raise 'you found a puts'; end


# Pruebas unitarias de la API REST.
class RESTTest < Test::Unit::TestCase
  include Rack::Test::Methods

  # Iniciar aplicación como "app"
  def app; Sinatra::ProgrezzServer end
  
  # ---------------------------
  #          Helpers
  # ---------------------------
  
  # Auth an user.
  def authenticate(provider = "google_oauth2", profile = { user_id: "test", alias: "test" })
    OmniAuth.config.test_mode = true
    OmniAuth.config.add_mock( provider.to_sym() , {
      :uid => '222222222222222222222',
      :info => {
        :email => profile[:user_id],
        :name => profile[:alias]
      }
    })
    
    get '/auth/' + provider + '/callback', nil, {
      "omniauth.auth" => OmniAuth.config.mock_auth[ provider.to_sym() ]
    }
  end
  
  # Do a REST request
  def rest_request()
    get '/dev/api/rest', @request
    @response = eval(last_response.body)
    GenericUtils.symbolize_keys_deep!(@response)
  end
  
  # Init db
  def init_db()
    @users = []
    @messages = []
    
    @transaction = Game::Database::DatabaseManager.start_transaction()
    
    # Borrar contenido actual
    Neo4j::Session.current._query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
    
    # Añadir cositas
    @users << Game::Database::User.sign_up( "test", 'test', {latitude: 3.0, longitude: 2.0} )
    @users[0].write_msg( "Hola mundo!!!" )
    
    @messages << Game::Database::Message.create_message( "Hello, universe", 2, nil, nil, {latitude: 3.0, longitude: 2.0} )
    @messages << Game::Database::Message.create_message( "Hello, universe (2)", 3, nil, nil, {latitude: 3.2, longitude: 2.0} )
    
    @users[0].collect_fragment(@messages[0].fragments.where(fragment_index: 0).first)
    @users[0].collect_fragment(@messages[0].fragments.where(fragment_index: 1).first)
    
    @users[0].collect_fragment(@messages[1].fragments.where(fragment_index: 0).first)
    @users[0].collect_fragment(@messages[1].fragments.where(fragment_index: 2).first)
  end
  
  # Undo db
  def drop_db()
    if @transaction == nil
      return
    end

    # Deshacer cambios en la transacción
    Game::Database::DatabaseManager.rollback_transaction(@transaction)
    Game::Database::DatabaseManager.stop_transaction(@transaction)
  end

  # ---------------------------
  #           Setup
  # ---------------------------
  
  # Inicializar antes de cada prueba.
  def setup
    # Setup database
    init_db()
    
    # Setup other things.
    @request = {
      metada: {},
      request: { }
    }
    
    @response = {}
    
    @session = ENV['rack.session']
  end
  
  # Cerrar antes de cada prueba
  def teardown
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    
    # Deshacer cambios en la base de datos.
    drop_db()
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
  #       User messages
  # ---------------------------
  
  # Probar "user_change_message_status"
  def test_user_change_message_status
    authenticate()
    
    # Sin error
    @request[:request][:type] = "user_change_message_status"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[0].uuid, new_status: "unread" }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Message status changed to 'unread'."
    
    # Error
    @request[:request][:type] = "user_change_message_status"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[1].uuid, new_status: "unread" }
    rest_request()
    
    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "Could not change message status."
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
    assert_equal @response[:response][:data][:written_message][:author], "test"
    assert_equal @response[:response][:data][:written_message][:content], "Holaaaa!!"
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
    assert_equal @response[:response][:message], "The fragment could not be collected: Fragment already collected."

    # Ni recoger fragmentos de mensajes ya completados.
    @request[:request][:type] = "user_collect_message_fragment"
    @request[:request][:data] = { user_id: @users[0].user_id, frag_uuid: @messages[0].fragments.where(fragment_index: 0).first.uuid }
    rest_request()
    
    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "The fragment could not be collected: Message already completed."
     
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
    assert @response[:response][:data][:fragments].count > 3
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
  
end