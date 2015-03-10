
module Game
  module API
    
    # Clase de ayuda para generar respuestas json.
    class JSONResponse
      
      # Plantilla de una respuesta JSON
      # @param auto_timer [Boolean] Iniciar cálculo de tiempo de cómputo.
      def self.get_template(auto_timer = false)
        output = {}
        
        auto_metadata(output)
        
        output[:response] = {
          timestamp: DateTime.now.strftime('%Q'), process_time: 0
        }
        
      end
      
      # Ajustar metadatos de manera automática.
      # @param response [Hash] Respuesta a ajustar.
      # @param data [Hash] Valores a ajustar.
      def self.auto_metadata( response, data = {} )
        # ...
      end
      
      def self.start_timer(response, ticks)
        
      end
      
      # Finalizarcontador de cómputo (en ms).
      # param response [Hash] Respuesta a ajustar.
      def self.stop_timer(response, ticks)
        
      end
      
    end
    
  end
end