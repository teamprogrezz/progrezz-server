require 'sinatra'

get '/admin/enviar_mensaje' do
  erb :form_message
end

post '/admin/enviar_mensaje_resultado' do
  # Crear mensajes
  message = Game::Database::Messages.new
  message.content = params["content"]
  message.resource_link = params["resource_link"]
  message.total_fragments = params["total_fragments"].to_i
  message.id_user = params["id_user"].to_i
  message.save

  # Añadir fragmentos (geolocalizacion)
  geoloc = []
  params["geoloc"].split(/\r\n/).each do |geo|
    geoloc << geo.split(/\s*,\s*/)
  end

  print "\n", geoloc, "\n"

  for i in 0...(params["total_fragments"].to_i)
    message_fragment = Game::Database::MessageFragments.new
    message_fragment.id_msg = message.id_msg
    message_fragment.fragment_index = i
    
    message_fragment.latitude  = geoloc[i][0].to_f
    message_fragment.longitude = geoloc[i][1].to_f
    message_fragment.save
  end

  return "Mensaje enviado correctamente"
end

