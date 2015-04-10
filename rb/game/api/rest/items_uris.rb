# encoding: UTF-8

module Sinatra
  module API
  module REST
    class Methods
     
      # Getter de la información de un objeto dado su identificador.
      def self.item_get(app, response, session)
        begin
          item_id = response[:request][:request][:data][:item_id]
          item = Game::Database::Item.find_by(item_id: item_id)
          
          raise ::GenericException.new( "Item not found in database." ) if item == nil
          
        rescue Exception => e
          raise ::GenericException.new( "Invalid item id '" + item_id.to_s + "': " + e.message, e)
        end
        
        Game::API::JSONResponse.ok_response!( response, {
          type: "json",
          item: item.to_hash
        })
      end
      
      # ...
    end
  end
  end
end