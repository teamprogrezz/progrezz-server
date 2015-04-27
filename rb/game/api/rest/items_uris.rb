# encoding: UTF-8

module Sinatra
  module API
  module REST
    class Methods
     
      # Getter de la información de un objeto dado su identificador.
      def self.rest__item_get(app, response, session)
        begin
          item_id = response[:request][:request][:data][:item_id]
          item = Game::Database::Item.find_by(item_id: item_id)

          raise ::GenericException.new( "Item not found in database." ) if item == nil
          
        rescue Exception => e
          raise ::GenericException.new( "Invalid item id '" + item_id.to_s + "': " + e.message, e)
        end
        
        Game::API::JSONResponse.ok_response!( response, {
          type: "json",
          item: item.to_hash([])
        })
      end
      
      # Getter de todos los objetos
      def self.rest__item_list(app, response, session)
        output = {}
        Game::Database::Item.as(:i).where("i.quality <> {q}").params(q: Game::Database::Item::NULL_QUALITY).each do |i|
          output[i.item_id] = i.to_hash([])
        end
        
        Game::API::JSONResponse.ok_response!( response, {
          type: "json",
          item_list: output
        })
      end

      # Getter de todas las recetas de crafteo.
      def self.rest__item_craft_list(app, response, session)
        Game::API::JSONResponse.ok_response!( response, {
          type: "json",
          recipes: Game::Mechanics::CraftingMechanics.recipes()
         })
      end

      # Getter de todas las recetas de crafteo relacionadas con un objeto..
      def self.rest__item_craft_related(app, response, session)
        item_id = response[:request][:request][:data][:item_id] || ""

        Game::API::JSONResponse.ok_response!( response, {
          type: "json",
          recipes: Game::Mechanics::CraftingMechanics.related_recipes(item_id)
         })
      end


    end
  end
  end
end