require 'sinatra'
require 'sinatra/jsonp'
require 'json'
require 'geocoder'

before '/game/dba/geoloc' do
  content_type 'application/javascript'
end

get '/game/dba/geoloc' do
  #params.keys.each do |k|  
  #  puts k + " -> " + params[k]
  #end

  output = []

  u_geo = [params['latitude'], params['longitude']]
  message_list = Game::Database::MessageGeo.all
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
      :content       => mf.content,
      :id_user       => mf.id_user,
      :resource_link => mf.resource_link,
      :message_full  => mf.message_full,
      :status        => mf.status
    }
  end

  # Mensajes fragmentados
  message_list = Game::Database::UserMessages.all(:id_user => params[:id_user])
  message_list.each do |message|
    # Identificador
    if output[:messages][message.id_msg] == nil
      mf = Game::Database::Messages.get(message.id_msg)
      output[:messages][message.id_msg] = {
        :content       => mf.content,
        :id_user       => mf.id_user,
        :resource_link => mf.resource_link,
        :message_full  => mf.message_full,
        :status        => "incomplete",
        :fragments     => []
      }
    end

    # Fragmentos
    output[:messages][message.id_msg]["fragments"] << message.fragment_index
  end

  return params[:callback] + "(" + output.to_json + ")"
end 
