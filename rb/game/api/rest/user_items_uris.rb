# encoding: UTF-8

require 'json'

module Sinatra; module API ;module REST

  class Methods
    
    # Recolectar objetos de un depósito.
    def self.user_collect_item_from_deposit( app, response, session )
      user     = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      deposit  = Game::Database::ItemDepositInstance.find_by( uuid: response[:request][:request][:data][:deposit_uuid] )
      
      extra = {}
      relation = nil
      
      begin
        relation = user.collect_item_from_deposit( deposit, extra )
      rescue Exception => e
        raise ::GenericException.new( "The deposit could not be collected: " + e.message, e)
      end
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        message: "Deposit collected.",
        exp_gained: extra[:exp]
      })
    end
    
    # Recibir depósitos de objetos cercanos al usuario.
    def self.user_get_nearby_item_deposits( app, response, session )
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )

      # Geolocalizaciones (como arrays).
      output = user.search_nearby_deposits()

      # Añadir nuevos depósitos (si fuese necesario)
      Game::Mechanics::ItemsManagement.generate_nearby_deposits(user, output)
      
      # Eliminar mensajes caducados
      output.delete_if { |k, v| v.caducated? }
      
      # Formatear salida según el usuario
      user_deposits = user.collected_item_deposit_instances(:d, :rel).pluck(:rel).to_a
      user_deposits = Hash[user_deposits.each.map { |value| [value.to_node.uuid, value] }]

      output.each do |k, v|
        user_rel  = user_deposits[k]
        output[k] = v.to_hash([:item], user_rel)
      end
    
      # Formatear output
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        deposits: output
      })
      
    end
  end
  
end; end; end
