# encoding: UTF-8

require 'pickup'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente a
    # los objetos del juego (recursos, básicamente).
    class ItemsManagement
      # Cantidad de fragmentos a generar por kilómetro cuadrado
      DEPOSIT_REPLICATION_PER_RADIUS_KM = 4

      # Número mínimo de depósitos en la zona para empezar a generar más.
      DEPOSIT_MIN_COUNT = 2
      
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
          raise ::GenericException.new( "Error while parsing item list: " + e.message, e)
        end
        
        # Para cada objeto
        item_id_list = []
        @@items.each do |i|
          item_id_list << i[:item_id]
          item = Game::Database::Item.find_by( item_id: i[:item_id] )

          if item == nil
            # Si no existe, añadir a la base de datos.
            item = Game::Database::Item.create_item( i )
          else
            # Si ya existe, actualizar todo
            item.update_item( i )
          end
          
          # Realizar gestión de depósitos
          if i[:deposit] != nil && !i[:deposit].empty?
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
        
        # Destruir los objetos que no esten en la base de datos.
        Game::Database::Item.all.each do |item|
          if !item_id_list.include? item.item_id
            item.remove()
          end
        end
        
        # Preparar lista de objetos (referencias)
        @@deposit_list = {}
        Game::Database::ItemDeposit.all.each { |id| @@deposit_list[id.item.item_id] = id }
        raise ::GenericException.new( "There are no deposits in the database to intantiate.") if @@deposit_list.empty?
        
        # Preparar lista de objetos (acceso rápido)
        @@items = Hash[@@items.map { |i| [i[:item_id], i ] } ]
      end
      
      # Getter de un objeto (más rápido que buscarlo en la base de datos).
      # @param item_id [String] Identificador del objeto.
      # @return [Hash, nil] Información del objeto. Si no encuentra nada, retornará +nil+.
      def self.find_item(item_id)
        return @@items[item_id].deep_clone
      end
      
      # Generar depósitos cercanos al usuario.
      # @param user [Game::Database::User] Referencia a un usuario.
      # @param deposits [Hash<Symbol, Object>] Depósitos cercanos a +user+.
      # @return [Integer] Número de depósitos generados.
      def self.generate_nearby_deposits(user, deposits_output)
        # El radio se obtiene directamente del usuario
        radius = user.get_current_search_radius(:deposits)
        
        # Depósitos cercanos al jugador
        deposits_count = deposits_output.length
        
        # Salir si ya hay suficientes depósitos.
        if deposits_count >= DEPOSIT_MIN_COUNT
          return
        end
        
        # Cantidad máxima de depósitos a generar
        max_deposits = (radius * DEPOSIT_REPLICATION_PER_RADIUS_KM).round
        
        # Preparar selector de objetos según su peso.
        ponderation = @@deposit_list.map { |key, value| [key, value.weight] }
        deposit_picker = Pickup.new(ponderation)
        
        # TODO: Aumentar probabilidad de generación si hay balizas cercanas
        # ...
        
        user_geo = user.geolocation

        # Empezar a generar
        Game::Database::DatabaseManager.run_nested_transaction do
          while deposits_count <= max_deposits do
            random_geolocation = {latitude: 0, longitude: 0} if random_geolocation == nil
            
            # Generar offsets a partir del radio
            random_geolocation[:latitude]  = user_geo[:latitude] + Progrezz::Geolocation.distance_to_latitude(  radius, :km )
            random_geolocation[:longitude] = user_geo[:longitude] + Progrezz::Geolocation.distance_to_longitude( radius, :km )
            
            # Elegir un depósito aleatoriamente según su peso y replicarlo
            new_instance = @@deposit_list[deposit_picker.pick].instantiate( random_geolocation )
            
            # Añadir a la salida
            deposits_output[new_instance.uuid] = new_instance
            
            # Incrementar número de depósitos generados
            deposits_count += 1
          end
        end
        
        return deposits_count
      end
      
    end
  end
end

Game::Mechanics::ItemsManagement.setup()
