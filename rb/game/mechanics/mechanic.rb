# encoding: UTF-8

require 'pickup'

module Game
  module Mechanics

    # Clase gestora de las mecánicas de juego referente al
    # inventario o mochila de los diferentes usuarios.
    class Mechanic

      # Palabra clave de comentario.
      COMMENT_KEY = "_comment"

      # Variable de estancia de clase.
      @data = nil
      
      # Inicializar módulo.
      # @param data [Object] Datos de entrada.
      def self.setup(data = nil)
        # ...
      end
      
      # Actualizar módulo.
      def self.update(data = nil)
        self.setup(data)
      end

      # Borrar comentarios de un hash de datos.
      # @param hash_data [Hash] Hash a limpiar.
      def self.remove_comment!(hash_data)
         if hash_data.is_a? Hash
           hash_data.each do |key, val|
             if key == COMMENT_KEY
               hash_data.delete(key)
             elsif val.is_a? Hash
               self.remove_comment! val
             end
           end
         end

         return hash_data
      end

      # Parsear json.
      # @param data [String] Cadena de entrada (json).
      def self.parse_JSON(data)
        begin
          @data = JSON.parse(data)
          remove_comment!(@data)
        rescue Exception => e
          raise ::GenericException.new "Error occurred while reading json: " + e.message, e
        end

        return @data
      end
      
    end
  end
end