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

# Init db
def init_db()
  @users = []
  @messages = []
  
  @transaction = Game::Database::DatabaseManager.start_transaction()
  
  # Borrar contenido actual
  Neo4j::Session.current._query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
  
  # Añadir cositas
  @users << Game::Database::User.sign_up( "test", 'test', {latitude: 28.4694, longitude: -16.2738} )
  @users[0].write_msg( "Hola mundo!!!" )
  
  @messages << Game::Database::Message.create_message( "Hello, universe", 2, nil, nil, {latitude: 28.4694, longitude: -16.2738} )
  @messages << Game::Database::Message.create_message( "Hello, universe (2)", 3, nil, nil, {latitude: 28.2694, longitude: -16.7346} )
  
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