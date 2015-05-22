# encoding: UTF-8

ENV['RACK_ENV'] = 'test'

require './main'
require 'test/unit'
require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'
require 'rack/test'

require_relative 'helpers'

# def puts(value); raise ::GenericException.new( 'you found a puts' ); end


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
  
  def ok?
    if @exec_ok == false
      $EXIT_ERROR = ($EXIT_ERROR || 0) + 1

      puts JSON.pretty_generate(@response)
    end
  end
  
  def ok
    @exec_ok = true
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
      request: {
        type: "",
        data: { }
      }
    }
    
    @response = {
      metadata: { }
    }
    
    @exec_ok = false
  end
  
  # Cerrar antes de cada prueba
  def teardown
    OmniAuth.config.mock_auth[:google_oauth2] = nil
    
    # Deshacer cambios en la base de datos.
    Game::Database::DatabaseManager.rollback_transaction(@transaction)
    Game::Database::DatabaseManager.stop_transaction(@transaction)
    
    ok?
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
    
    ok
  end
  
  # Probar "echo_py"
  def test_echo_py
    @request[:request][:type] = "echo_py"
    @request[:request][:data] = { name: "ProgrezzTest" }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Hello, pythonist ProgrezzTest!"
    
    ok
  end
  
  # ---------------------------
  #           User
  # ---------------------------
  
  # Probar "user_who_am_i"
  def test_user_who_am_i
    authenticate()
    
    @request[:request][:type] = "user_who_am_i"
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:user][:user_id], @users[0].user_id
    
    ok
    
  end
  
  # Probar "user_get_profile"
  def test_user_profile
    authenticate()
    
    @request[:request][:type] = "user_profile"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:profile][:info][:user_id], @users[0].user_id
    
    ok
    
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
    
    ok
    
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
    
    ok
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
    
    ok
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
    
    ok
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
    
    ok
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
    
    ok
  end
  
  # Probar "user_get_messages"
  def test_user_get_collected_message_fragments
    authenticate()
    
    @request[:request][:type] = "user_get_collected_message_fragments"
    @request[:request][:data] = { user_id: @users[0].user_id, msg_uuid: @messages[1].uuid  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:fragments].values[0].count, 2
    
    ok
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

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Deposit collected."
    
    # Intentar recolectar de nuevo (error)
    rest_request()
    
    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "The deposit could not be collected: Deposit in cooldown."
    
    ok

  end
  
  # Probar "user_get_nearby_item_deposits"
  def test_user_get_nearby_item_deposits
    authenticate()
    
    # Recoger depósitos cercanos
    @request[:request][:type] = "user_get_nearby_item_deposits"
    @request[:request][:data] = { user_id: @users[0].user_id  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:deposits].count, 8
    
    # Recoger depósito
    @request[:request][:type] = "user_collect_item_from_deposit"
    @request[:request][:data] = { user_id: @users[0].user_id, deposit_uuid: @deposit_instances[0].uuid  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Deposit collected."
    
    # Comprobar que está en cooldown
    @request[:request][:type] = "user_get_nearby_item_deposits"
    @request[:request][:data] = { user_id: @users[0].user_id  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert @response[:response][:data][:deposits][@deposit_instances[0].uuid.to_sym][:user][:in_cooldown]
    
    ok

  end
  
  # Probar "user_get_backpack"
  def test_user_get_backpack
    authenticate()
    
    # Recolectar depósito
    @request[:request][:type] = "user_collect_item_from_deposit"
    @request[:request][:data] = { user_id: @users[0].user_id, deposit_uuid: @deposit_instances[0].uuid  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    
    # Ver el inventario
    @request[:request][:type] = "user_get_backpack"
    @request[:request][:data] = { user_id: @users[0].user_id  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:backpack][0][:item_id], @deposit_instances[0].deposit.item.item_id

    ok
  end
  
  # Probar "user_exchange_backpack_stack"
  def test_user_exchange_backpack_stack
    authenticate()
    
    # Añadir objeto al inventario
    @users[0].backpack.add_item(@deposit_instances[0].deposit.item, 20)
    
    # Eliminar
    @request[:request][:type] = "user_exchange_backpack_stack"
    @request[:request][:data] = { user_id: @users[0].user_id, stack_id: (@users[0].backpack.last_stack_id - 1), amount: 10  }
    rest_request()

    @users[0].reload

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:removed], 10
    assert_equal @users[0].energy, Game::Mechanics::ItemsMechanics.get_item_energy( @deposit_instances[0].deposit.item.item_id ) * 10

    ok
  end

  # Probar "user_craft_item"
  def test_user_craft_item
    authenticate()

    # Añadir objetos al inventario
    @users[0].backpack.add_item(Game::Database::Item.find_by(item_id: "mineral_iron"), 10)
    @users[0].backpack.add_item(Game::Database::Item.find_by(item_id: "mineral_coal"), 12)

    # Craftear objeto

    @request[:request][:type] = "user_craft_item"
    @request[:request][:data] = { user_id: @users[0].user_id, recipe_id: "craft_steel"  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @users[0].backpack.to_hash.count, 2
    assert @users[0].backpack.to_hash.any? { |i| i[:item_id] == "mineral_coal" and i[:stack][:amount] = 2 }
    assert @users[0].backpack.to_hash.any? { |i| i[:item_id] == "metal_steel" and i[:stack][:amount] = 10 }

    ok
  end


  # Probar "user_get_craft_recipes"
  def test_user_get_craft_recipes
    authenticate()

    # Obtener recetas
    @request[:request][:type] = "user_get_craft_recipes"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert @response[:response][:data][:recipes].keys.include? :rank_d
    assert @response[:response][:data][:recipes].keys.include? :rank_c
    assert @response[:response][:data][:recipes].keys.include? :rank_b

    ok
  end

  # Probar "user_split_backpack_stack"
  def test_user_split_backpack_stack
    authenticate()

    # Añadir objeto al inventario
    @users[0].backpack.add_item(@deposit_instances[0].deposit.item, 20)

    # Dividir
    stack_id = 1

    @request[:request][:type] = "user_split_backpack_stack"
    @request[:request][:data] = { user_id: @users[0].user_id, stack_id: stack_id - 1, restack_amount: 9  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:old_stack][:amount], 11
    assert_equal @response[:response][:data][:new_stack][:amount], 9

    # Dividir a otro stack
    stack_id = 2

    @request[:request][:type] = "user_split_backpack_stack"
    @request[:request][:data] = { user_id: @users[0].user_id, stack_id: stack_id - 1, target_stack_id: stack_id - 2, restack_amount: 5  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:old_stack][:amount], 4
    assert_equal @response[:response][:data][:new_stack][:amount], 16

    # Traspasar todo
    @request[:request][:type] = "user_split_backpack_stack"
    @request[:request][:data] = { user_id: @users[0].user_id, stack_id: stack_id - 2, target_stack_id: stack_id - 1, restack_amount: 16  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:old_stack][:amount], 0
    assert_equal @response[:response][:data][:new_stack][:amount], 20
    assert_equal @users[0].backpack.to_hash.length, 1

    ok
  end

  # ---------------------------
  #       User beacons
  # ---------------------------

  # Probar "user_deploy_beacon"
  def test_user_deploy_beacon
    authenticate()

    # Añadir baliza
    @users[0].backpack.add_item( Game::Database::Item.find_by(item_id: Game::Database::Beacon::RELATED_ITEM), 1)

    # Desplegar baliza
    @request[:request][:type] = "user_deploy_beacon"
    @request[:request][:data] = { user_id: @users[0].user_id, message: "This will deploy correctly." }
    rest_request()

    assert_equal @response[:response][:status], "ok"

    # Intentar desplegarla de nuevo
    @request[:request][:type] = "user_deploy_beacon"
    @request[:request][:data] = { user_id: @users[0].user_id, message: "This will not." }
    rest_request()

    assert_equal @response[:response][:status], "error"
    assert_equal @response[:response][:message], "Could not deploy beacon: User does not own 1 of Energy beacon"

    ok
  end

  # Probar "user_get_deployed_beacons"
  def test_user_get_deployed_beacons
    authenticate()

    # Comprobar balizas del usuario
    @request[:request][:type] = "user_get_deployed_beacons"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:beacons].count, 0

    # Añadir y desplegar baliza
    @users[0].backpack.add_item( Game::Database::Item.find_by(item_id: Game::Database::Beacon::RELATED_ITEM), 1)
    @users[0].deploy_beacon("weeeeeeeee")

    # Comprobar de nuevo
    @request[:request][:type] = "user_get_deployed_beacons"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:beacons].count, 1
    assert_equal @response[:response][:data][:beacons].values.first[:info][:message], "weeeeeeeee"

    ok
  end

  # Probar "user_get_nearby_beacons"
  def test_user_get_nearby_beacons
    authenticate()

    # Comprobar balizas cercanas al usuario
    @request[:request][:type] = "user_get_nearby_beacons"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:beacons].count, 0

    # Añadir y desplegar baliza
    @users[1].backpack.add_item( Game::Database::Item.find_by(item_id: Game::Database::Beacon::RELATED_ITEM), 1)
    @users[1].deploy_beacon("waaaaaa")

    # Comprobar de nuevo
    @request[:request][:type] = "user_get_nearby_beacons"
    @request[:request][:data] = { user_id: @users[0].user_id }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:beacons].count, 1
    assert_equal @response[:response][:data][:beacons].values.first[:info][:message], "waaaaaa"

    ok
  end

  # Probar "user_yield_energy"
  def test_user_yield_energy
    authenticate()

    # Añadir y desplegar baliza
    @users[0].backpack.add_item( Game::Database::Item.find_by(item_id: Game::Database::Beacon::RELATED_ITEM), 1)
    @users[0].update(energy: 1000)
    beacon = @users[0].deploy_beacon("waaaaaa")

    # Ceder energía
    @request[:request][:type] = "user_yield_energy"
    @request[:request][:data] = { user_id: @users[0].user_id, beacon_uuid: beacon.uuid, energy: 900 }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:message], "Energy added correctly."

    beacon.reload
    @users[0].reload

    assert_equal beacon.energy_gained, 900
    assert_equal @users[0].energy, 1000 - 900

    ok
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
    
    ok
  end
  
  # Probar "message_get_unauthored"
  def test_message_get_unauthored
    @request[:request][:type] = "message_get_unauthored"
    @request[:request][:data] = { msg_uuid: @messages[1].uuid  }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert_equal @response[:response][:data][:messages].count, @messages.count
    
    ok
  end
  
  # Probar "message_get_from_fragment"
  def test_message_get_from_fragment
    @request[:request][:type] = "message_get_from_fragment"
    @request[:request][:data] = { frag_uuid: @messages[0].fragments.where(fragment_index: 0).first.uuid  }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert_equal @messages[0].uuid, @response[:response][:data][:message][:message][:uuid]
    
    ok
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
    
    ok
  end
  
  # Probar "item_list"
  def test_item_list
    @request[:request][:type] = "item_list"
    @request[:request][:data] = { }
    rest_request()
    
    assert_equal @response[:response][:status], "ok"
    assert !@response[:response][:data][:item_list].empty?
    
    ok
  end

  # Probar "item_craft_list"
  def test_item_craft_list
    @request[:request][:type] = "item_craft_list"
    @request[:request][:data] = { }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    assert !@response[:response][:data][:recipes].empty?

    ok
  end

  # Probar "item_craft_related"
  def test_item_craft_related
    @request[:request][:type] = "item_craft_related"
    @request[:request][:data] = { item_id: "mineral_iron" }
    rest_request()

    assert_equal @response[:response][:status], "ok"
    @response[:response][:data][:recipes].each do |rank_id, rank|
      rank.each do |r_id, r|
        assert (r[:input].any? { |i| i[:item_id] == "mineral_iron" }) || r[:output][:item_id] == "mineral_iron"
      end
    end

    ok
  end


  
end
