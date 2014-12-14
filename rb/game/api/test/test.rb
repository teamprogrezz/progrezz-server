require 'sinatra'
require 'json'

get '/test_message' do
  # Mensaje 1
  message1 = Game::Database::Messages.new
  message1.total_fragments = 3
  message1.content = "Habia una vez un pinguino chiquitito :)"
  message1.resource_link = "http://www.example.com"
  message1.id_user = 1
  message1.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message1.id_msg
  message_geo.fragment_index = 1
  message_geo.latitude = 43.291310
  message_geo.longitude = -2.863652
  message_geo.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message1.id_msg
  message_geo.fragment_index = 2
  message_geo.latitude = 43.292074
  message_geo.longitude = -2.862922
  message_geo.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message1.id_msg
  message_geo.fragment_index = 3
  message_geo.latitude = 43.291373
  message_geo.longitude = -2.861903
  message_geo.save

  # Mensaje 2
  message2 = Game::Database::Messages.new
  message2.total_fragments = 3
  message2.content = "Pepitooooou"
  message2.resource_link = "http://www.example.com"
  message2.id_user = 1
  message2.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message2.id_msg
  message_geo.fragment_index = 1
  message_geo.latitude = 33.44
  message_geo.longitude = -5.2
  message_geo.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message2.id_msg
  message_geo.fragment_index = 2
  message_geo.latitude = 35.4489
  message_geo.longitude = -5.15
  message_geo.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message2.id_msg
  message_geo.fragment_index = 3
  message_geo.latitude = 36.4489
  message_geo.longitude = -5.15
  message_geo.save

  # Mensaje 3
  message3 = Game::Database::Messages.new
  message3.total_fragments = 4
  message3.content = "Este mensaje es falso"
  message3.resource_link = "http://www.example.com"
  message3.id_user = 1
  message3.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message3.id_msg
  message_geo.fragment_index = 1
  message_geo.latitude = 33.44
  message_geo.longitude = -5.2
  message_geo.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message3.id_msg
  message_geo.fragment_index = 2
  message_geo.latitude = 35.4489
  message_geo.longitude = -5.15
  message_geo.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message3.id_msg
  message_geo.fragment_index = 3
  message_geo.latitude = 38.4489
  message_geo.longitude = -2.15
  message_geo.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message3.id_msg
  message_geo.fragment_index = 4
  message_geo.latitude = 36.4489
  message_geo.longitude = -2.15
  message_geo.save

  # Mensaje 4
  message4 = Game::Database::Messages.new
  message4.total_fragments = 1
  message4.content = "Mensaje infragmentable"
  message4.resource_link = "http://www.example.com"
  message4.id_user = 1
  message4.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message4.id_msg
  message_geo.fragment_index = 1
  message_geo.latitude = 34.12
  message_geo.longitude = 12.2
  message_geo.save

  # Mensaje 5
  message5 = Game::Database::Messages.new
  message5.total_fragments = 1
  message5.content = "Mensaje infragmentable (1)"
  message5.resource_link = "http://www.example.com"
  message5.id_user = 1
  message5.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message5.id_msg
  message_geo.fragment_index = 1
  message_geo.latitude = 20.12
  message_geo.longitude = 18.2
  message_geo.save

  # Mensaje 6
  message6 = Game::Database::Messages.new
  message6.total_fragments = 1
  message6.content = "Mensaje infragmentable (2)"
  message6.resource_link = "http://www.example.com"
  message6.id_user = 1
  message6.save

  message_geo = Game::Database::MessageFragments.new
  message_geo.id_msg = message6.id_msg
  message_geo.fragment_index = 1
  message_geo.latitude = -30.12
  message_geo.longitude = -12.2
  message_geo.save

    # Mensajes de usuario
  # Fragmento1,1
  message_user = Game::Database::UserFragmentMessages.new
  message_user.id_msg = message1.id_msg
  message_user.id_user = 1
  message_user.fragment_index = 1
  message_user.save

  # Fragmento1,3
  message_user = Game::Database::UserFragmentMessages.new
  message_user.id_msg = message1.id_msg
  message_user.id_user = 1
  message_user.fragment_index = 3
  message_user.save

  # Fragmento2,1
  message_user = Game::Database::UserFragmentMessages.new
  message_user.id_msg = message2.id_msg
  message_user.id_user = 1
  message_user.fragment_index = 1
  message_user.save

  # Fragmento2,2
  message_user = Game::Database::UserFragmentMessages.new
  message_user.id_msg = message2.id_msg
  message_user.id_user = 1
  message_user.fragment_index = 2
  message_user.save

  # Fragmento3,1
  message_user = Game::Database::UserFragmentMessages.new
  message_user.id_msg = message3.id_msg
  message_user.id_user = 1
  message_user.fragment_index = 1
  message_user.save

  # Fragmento3,4
  message_user = Game::Database::UserFragmentMessages.new
  message_user.id_msg = message3.id_msg
  message_user.id_user = 1
  message_user.fragment_index = 4
  message_user.save

  # Fragmento4,1 COMPLETO!!
  message_user = Game::Database::UserCompletedMessages.new
  message_user.id_msg = message4.id_msg
  message_user.id_user = 1
  message_user.status = "read"
  message_user.save

  # Fragmento5,1 COMPLETO!!
  message_user = Game::Database::UserCompletedMessages.new
  message_user.id_msg = message5.id_msg
  message_user.id_user = 1
  message_user.status = "locked"
  message_user.save

  # Fragmento6,1 COMPLETO!!
  message_user = Game::Database::UserCompletedMessages.new
  message_user.id_msg = message6.id_msg
  message_user.id_user = 1
  message_user.status = "unread"
  message_user.save

  "Mensajes creado"
end


get '/test_list' do
  output = ""

  output += "Lista de mensajes:<br>"
  messages = Game::Database::Messages.all
  for message in messages
    output += message.id_msg.to_s + " -> contenido(\"" + message.content + "\"), fragmentos(" + message.total_fragments.to_s + ")<br>"
  end

  output += "Lista de fragmentos:<br>"
  messages = Game::Database::MessageFragments.all
  for message in messages
    output += message.id_msg.to_s + " -> indice(" + message.fragment_index.to_s + ") -> coords(" + message.latitude.to_s + " , " + message.longitude.to_s + ")<br>"
  end

  output += "Lista de fragmentos de usuario:<br>"
  messages = Game::Database::UserFragmentMessages.all
  for message in messages
    output += "id_user(" + message.id_user.to_s + "), id_msg(" + message.id_msg.to_s + ") -> " + "indice(" + message.fragment_index.to_s + ")<br>"
  end

  output += "Lista de mensajes completos de usuario:<br>"
  messages = Game::Database::UserCompletedMessages.all
  for message in messages
    output +=  "id_user(" + message.id_user.to_s + "), id_msg(" + message.id_msg.to_s + ") -> " + "estado(" + message.status + ")<br>"
  end

  output
end
