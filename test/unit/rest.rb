ENV['RACK_ENV'] = 'test'

require './main'
require 'test/unit'
require 'rack/test'

# Pruebas unitarias de la API REST.
class RESTTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::ProgrezzServer
  end
  
  def setup
    @request = {
      metada: {},
      request: { }
    }
    
    @session = ENV['rack.session']
  end

  def test_echo
    @request[:request][:type] = "echo"
    @request[:request][:data] = { name: "ProgrezzTest" }
    
    get '/dev/api/rest', @request
    response = eval(last_response.body)
    GenericUtils.symbolize_keys_deep!(response)

    assert_equal response[:response][:status], "ok"
    assert_equal response[:response][:data][:message], "Hello, ProgrezzTest!"
  end
  
  def test_echo_py
    @request[:request][:type] = "echo_py"
    @request[:request][:data] = { name: "ProgrezzTest" }
    
    get '/dev/api/rest', @request
    response = eval(last_response.body)
    GenericUtils.symbolize_keys_deep!(response)

    assert_equal response[:response][:status], "ok"
    assert_equal response[:response][:data][:message], "Hello, pythonist ProgrezzTest!"
  end
end