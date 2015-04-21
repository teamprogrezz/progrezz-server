# encoding: UTF-8

require 'json'

module Sinatra; module API ;module REST

  class Methods
    
    # Recolectar objetos de un depósito.
    def self.user_collect_item_from_deposit( app, response, session )
      user_id      = response[:request][:request][:data][:user_id]
      deposit_uuid = response[:request][:request][:data][:deposit_uuid]
      user     = Game::AuthManager.search_auth_user( user_id, session )
      deposit  = Game::Database::ItemDepositInstance.find_by( uuid: deposit_uuid)
      
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
        exp_gained: extra[:exp],
        mining_info: extra[:mining]
      })
    end
    
    # Recibir depósitos de objetos cercanos al usuario.
    def self.user_get_nearby_item_deposits( app, response, session )
      user_id      = response[:request][:request][:data][:user_id]
      user = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )

      # Geolocalizaciones (como arrays).
      output = user.search_nearby_deposits()

      # Añadir nuevos depósitos (si fuese necesario)
      Game::Mechanics::ItemsMechanics.generate_nearby_deposits(user, output)
      
      # Eliminar mensajes caducados
      output.delete_if { |k, v| v.caducated? }
      
      # Formatear salida según el usuario
      user_deposits = user.collected_item_deposit_instances(:d, :rel).pluck(:rel).to_a
      user_deposits = Hash[user_deposits.each.map { |value| [value.to_node.uuid, value] }]

      output.each do |k, v|
        user_rel  = user_deposits[k]
        output[k] = v.to_hash([], user_rel)
      end
    
      # Formatear output
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        deposits: output
      })
      
    end
    
    # Ver los datos de la mochila del usuario
    def self.user_get_backpack( app, response, session )
      user_id      = response[:request][:request][:data][:user_id]
      user     = Game::AuthManager.search_auth_user( response[:request][:request][:data][:user_id], session )
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        backpack: user.backpack.to_hash
      })
    end
    
    # Eliminar una cantidad de objetos del inventario.
    def self.user_exchange_backpack_stack( app, response, session )
      user_id      = response[:request][:request][:data][:user_id]
      stack_id     = response[:request][:request][:data][:stack_id]
      amount       = response[:request][:request][:data][:amount]

      user     = Game::AuthManager.search_auth_user( user_id, session )
      
      output = user.backpack.exchange_stack_amount(stack_id, amount)
      
      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        removed: output[:removed]
      })
    end

    # Particionar un stack de objetos del usuario dado.
    def self.user_split_backpack_stack( app, response, session)
      user_id        = response[:request][:request][:data][:user_id]
      stack_id       = response[:request][:request][:data][:stack_id].to_i
      restack_amount = response[:request][:request][:data][:restack_amount].to_i

      user   = Game::AuthManager.search_auth_user( user_id, session )
      output = user.backpack.split_stack( stack_id, restack_amount )

      Game::API::JSONResponse.ok_response!( response, {
        type: "json",
        old_stack: output[:old_stack],
        new_stack: output[:new_stack]
      })
    end
    
  end
  
end; end; end
