require 'sinatra'
require 'json'

puts "waaat"

get '/game/dba/geoloc' do
  params.keys.each do |k|  
    puts k + " -> " + params[k]
  end

  return params[:callback] + "(" + { :msg => 'Hola mundiiiiiis' }.to_json + ")"
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

  puts output
  return output.to_json()
  #return params[:callback] + "(" + output.to_json + ")"
end 
