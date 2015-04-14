# encoding: UTF-8

require 'test/unit/testsuite'
require 'test/unit/ui/console/testrunner'

require_relative 'rest'
require_relative 'websocket'

class CustomTestSuite < Test::Unit::TestSuite
  def self.suite
    result = self.new(self.class.name)
    result << RESTTest.suite
    result << WebSocketTest.suite
    
    return result
  end

  def setup
    
    # Iniciar base de datos
    @@users = []
    @@messages = []
    @@deposit_instances = []
    
    # Borrar contenido actual
    Game::Database::User.all.each { |u| u.destroy }
    Game::Database::Message.all.each { |m| m.destroy }
    Game::Database::MessageFragment.all.each { |f| f.destroy }
    
    # Añadir cositas
    @@users << Game::Database::User.sign_up( "test", 'test', {latitude: 28.4694, longitude: -16.2738} )
    @@users[0].level_profile.update( {level: 6} )
    @@users[0].on_level_up()
    @@users[0].write_message( "Hola mundo!!!" )
    
    # Usuarios de prueba
    @@users << Game::Database::User.sign_up( "test11", 'test11', {latitude: 28.46673, longitude: -16.27357} )
    @@users << Game::Database::User.sign_up( "test22", 'test22', {latitude: 28.3396, longitude: -16.8373} )
    
    @@messages << Game::Database::Message.create_message( "Hello, universe", 2, { position: {latitude: 28.4694, longitude: -16.2738} })
    @@messages << Game::Database::Message.create_message( "Hello, universe (2)", 3, { position: {latitude: 28.2694, longitude: -16.7346} })
    
    @@deposit_instances << Game::Database::Item.find_by(item_id: "mineral_iron").deposit.instantiate( @@users[0].geolocation )
    
    @@users[0].collect_fragment(@@messages[0].fragments.where(fragment_index: 0).first)
    @@users[0].collect_fragment(@@messages[0].fragments.where(fragment_index: 1).first)
    
    @@users[0].collect_fragment(@@messages[1].fragments.where(fragment_index: 0).first)
    @@users[0].collect_fragment(@@messages[1].fragments.where(fragment_index: 2).first)
    
    @@users.each { |u| u.online(true) }
  end

  def teardown
    # Deshacer cambios en la base de datos.
    @@users.each { |u| u.destroy }
    @@messages.each { |m| m.destroy }
    @@deposit_instances.each { |d| d.destroy }
  end

  def run(*args)
    setup
    super
    teardown
  end
  
  def self.users
    @@users
  end
  
  def self.messages
    @@messages
  end
  
  def self.deposit_instances
    @@deposit_instances
  end
end

# Ejecutar pruebas
Test::Unit::UI::Console::TestRunner.run(CustomTestSuite)