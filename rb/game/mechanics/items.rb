# encoding: UTF-8

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente a
    # los objetos del juego (recursos, básicamente).
    class ItemsManagement
      
      # Datos referentes a este gestor.
      DATAFILE = "data/items.json"
      
      # Lista de objetos (guardado por si hace falta usarlo).
      @@items = nil
      
      # Inicializar gestor de mecánicas de objetos.
      def self.setup()
        init_items()
      end
      
      # Inicializar objetos del juego (cargando desde un json).
      def self.init_items()
        # Leer de fichero
        begin
          @@items = JSON.parse( File.read(DATAFILE) )
          GenericUtils.symbolize_keys_deep!(@@items)
        rescue Exception => e
          raise "Error while parsing item list: " + e.message
        end
        
        # Para cada objeto
        @@items.each do |i|
          item = Game::Database::Item.find_by( item_id: i[:item_id] )

          if item == nil
            # Si no existe, añadir a la base de datos.
            item = Game::Database::Item.create_item( i )
          else
            # Si ya existe, actualizar todo
            item.update_item( i )
          end
          
          # Realizar gestión de depósitos
          if i[:deposit] != nil || !i[:deposit].empty?
            # Si se especifica, actualizar.
            
            if item.deposit != nil
              # Si existe, actualizarlo
              item.deposit.update( i[:deposit] )
            else
              # Si no, crearlo
              item.create_deposit( i[:deposit] )
            end
            
          else
            # Si no, borrar de la base de datos.
            item.deposit.remove() if item.deposit != nil
          end
          
        end
        
      end
      
    end
  end
end

Game::Mechanics::ItemsManagement.setup()
