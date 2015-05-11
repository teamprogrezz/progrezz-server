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