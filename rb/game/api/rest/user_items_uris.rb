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
  end
  
end; end; end
