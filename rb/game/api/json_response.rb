# encoding: UTF-8

module Game
  module API
    
    # Clase de ayuda para generar respuestas json.
    class JSONResponse
      
      # Plantilla de una respuesta JSON
      # @param auto_timer [Boolean] Iniciar cálculo de tiempo de cómputo.
      # @return [Hash] Respuesta generada.
      def self.get_template(auto_timer = true)
        output = {}
        
        auto_metadata!(output)
        
        output[:response] = {
          status: "ok"
        }
        
        if auto_timer; start_timer!(output) end
        
        return output
      end
      
      # Ajustar metadatos de manera automática.
      # @param response [Hash] Respuesta a ajustar.
      # @param data [Hash] Valores a ajustar.
      def self.auto_metadata!( response, data = {} )
        response[:metadata] = {
          timestamp: DateTime.now.strftime('%Q').to_i,
          process_time: 0,
          type: "response"
        }
      end
      
      # Iniciar contador de cómputo (en ms).
      # param response [Hash] Respuesta a ajustar.
      def self.start_timer!(response)
        response[:metadata][:process_time] = Time.now
      end
      
      # Finalizar contador de cómputo (en ms).
      # param response [Hash] Respuesta a ajustar.
      def self.stop_timer!(response)
        response[:metadata][:process_time] = ((Time.now - response[:metadata][:process_time]) * 1000.0).to_f
      end
      
      # Generar un error de respuesta.
      #
      # @param response [Hash] Hash de respuesta al usuario.
      # @param reason [String] Razón del error en sí (e.j. 'Me caes mal').
      def self.error_response!(response, reason)
        response[:type] = "system"
        
        response[:response].clear()
        response[:response][:status]  = "error"
        response[:response][:message] = reason
      end
      
      # Generar una respuesta.
      #
      # @param response [Hash] Hash de respuesta al usuario.
      # @param data [Hash] Estructura de datos a enviar al usuario.
      def self.ok_response!(response, data)
        response[:type] = "response"
        
        response[:response][:status]  = "ok"
        response[:response][:data]    = data
      end

      # Validar petición de usuario.
      # @param request [Hash] Comprobar petición.
      # @raise [GenericException] Lanza un error si no es válida.
      def self.validate_request(request)
        raise ::GenericException.new("Invalid request") unless request.is_a? Hash

        request[:request] ||= { }
        request[:request][:data] ||= { }
      end
      
    end
    
  end
end