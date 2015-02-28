require 'json'
require 'geocoder'

get '/game/dba/geoloc' do
  #params.keys.each do |k|  
  #  puts k + " -> " + params[k]
  #end

  output = []

  u_geo = [params['latitude'], params['longitude']]
  message_list = Game::Database::MessageFragments.all
  cont_msg = 0
  for message in message_list do
    if cont_msg >= params['n_msg'].to_i
      break;
    end

    msg_geo = [message.latitude, message.longitude]
 
    distance = Geocoder::Calculations.distance_between(u_geo, msg_geo, {:units => :km})
    puts "-> Distancia: " + distance.to_s
    if distance <= params['radio'].to_f
      output << message
      cont_msg += 1
    end
  end

  return params[:callback] + "(" + output.to_json() + ")"
end


# Recibir lista de mensajes de un usuario
before '/game/dba/msg_user_list' do
  content_type 'application/javascript'
end

get '/game/dba/msg_user_list' do
  output = { :messages => {} }

  # Mensajes ya completados
  message_list = Game::Database::UserCompletedMessages.all(:id_user => params[:id_user])
  message_list.each do |message|
    mf = Game::Database::Messages.get(message.id_msg)
    output[:messages][message.id_msg] = {
      :content         => mf.content,
      :id_user         => mf.id_user,
      :total_fragments => mf.total_fragments,
      :resource_link   => mf.resource_link,
      :status          => message.status
    }
  end

  # Mensajes fragmentados
  message_list = Game::Database::UserFragmentMessages.all(:id_user => params[:id_user])
  message_list.each do |message|
    # Identificador
    if output[:messages][message.id_msg] == nil
      mf = Game::Database::Messages.get(message.id_msg)
      output[:messages][message.id_msg] = {
        :content         => mf.content,
        :id_user         => mf.id_user,
        :total_fragments => mf.total_fragments,
        :resource_link   => mf.resource_link,
        :status          => "incomplete",
        :fragments       => []
      }
    end

    # Fragmentos
    output[:messages][message.id_msg][:fragments] << message.fragment_index
  end

  return params[:callback] + "(" + output.to_json + ")"
end

# Actualizar fragmentos encontrados
before '/game/dba/msg_user_get_fragment' do
  content_type 'application/javascript'
end

get '/game/dba/msg_user_get_fragment' do
  # Comprobaciones iniciales: comprobar que el mensaje y el usuario existe.
  # ...

  output = {}

  # Comprobar que el mensaje no esta completado y el fragmento no se ha recogido antes.
  if Game::Database::UserCompletedMessages.get(params['id_user'], params['id_msg']) != nil || Game::Database::UserFragmentMessages.get(params['id_user'], params['id_msg'], params['fragment_index']) != nil
    return params[:callback] + "(" + output.to_json + ")"
  end

  # Añadir el mensaje a la base de datos de la lista de fragmentos de un usuario
  user_fragment = Game::Database::UserFragmentMessages.new
  user_fragment.id_user = params['id_user']
  user_fragment.id_msg  = params['id_msg']
  user_fragment.fragment_index  = params['fragment_index']
  user_fragment.save
  
  # Actualizar mensajes completados del usuario para un id de mensaje dado
  number_user_fragments = Game::Database::UserFragmentMessages.count( {:id_msg => params['id_msg'], :id_user => params['id_user'] } )
  if number_user_fragments == Game::Database::Messages.get( params['id_msg'] ).total_fragments
    # Añadir nuevo mensaje como "completado" pero como bloqueado (por defecto)
    completed_message = Game::Database::UserCompletedMessages.new
    completed_message.id_msg = params['id_msg']
    completed_message.id_user = params['id_user']
    #completed_message.status =  por defecto
    completed_message.save

    Game::Database::UserFragmentMessages.all( {:id_msg => params['id_msg'], :id_user => params['id_user'] } ).destroy
  end
end

