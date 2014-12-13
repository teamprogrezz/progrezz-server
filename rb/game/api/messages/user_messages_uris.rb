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
  
  message_list = Game::Database::UserMessages.all(:id_user => params[:id_user])

  message_list.each do |message|
    # Identificador
    if output[:messages][message.id_msg] == nil
      output[:messages][message.id_msg] = {}
      
      message_full = Game::Database::Messages.get(message.id_msg)
      output[:messages][message.id_msg]["content"] = message_full.content
      #TODO: Comprobar si tiene todos los fragmentos para realizar las operaciones oportunas.
      #output[:messages][message.id_msg]["status"] = message_full.status
      output[:messages][message.id_msg]["id_user"] = message_full.id_user
      output[:messages][message.id_msg]["resource_link"] = message_full.resource_link
      output[:messages][message.id_msg]["total_fragments"] = message_full.total_fragments

      output[:messages][message.id_msg]["fragments"] = []
    end

    # Fragmentos
    output[:messages][message.id_msg]["fragments"] << message.fragment_index
  end

  return params[:callback] + "(" + output.to_json + ")"
end 
