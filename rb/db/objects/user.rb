# encoding: UTF-8

require_relative 'geolocated_object'
require_relative '../relations/user-message_fragment'
require_relative '../relations/user-completed_message'

module Game
  module Database
    
    #-- Forward declarations #++
    class Message; end
    
    # Clase que representa a un jugador cualquiera en la base de datos.
    #
    # Se caracteriza por estar enlazado con diversos tipos de nodos, 
    # además de tener una serie de propiedades o atributos.
    #
    # Se considera un objeto geolocalizado.
    class User < GeolocatedObject
      include Neo4j::ActiveNode
      
      #-- -------------------------
      #        Constantes
      #   ------------------------- #++
      
      # Fragmentos en los que se partirán los mensajes de un usuario.
      USER_MESSAGE_FRAGMENTS = 1 
      
      #-- -------------------------
      #        Atributos (DB)
      #   ------------------------- #++
      property :user_id, constraint: :unique  # Identificador de usuario (correo, único en la BD)
      property :alias                         # Alias o nick del usuario.
      property :created_at                    # Timestamp o fecha de creación del usuario.
      
      #-- -------------------------
      #     Relaciones (DB)
      #   ------------------------- #++
      
      # Relación de mensajes creados por el usuario.
      #
      # Si se borra el usuario, se borrarán todos sus mensajes.
      #
      # Se puede acceder con el atributo +written_messages+.
      has_many :out, :written_messages, model_class: Game::Database::Message, type: "has_written", dependent: :destroy
      
      # Relación de fragmentos recolectados por el usuario. Se puede acceder con el atributo +collected_fragment_messages+.
      has_many :out, :collected_fragment_messages, rel_class: Game::Database::RelationShips::UserFragmentMessage, model_class: Game::Database::MessageFragment
      
      # Relación de mensajes completados por el usuario. Se puede acceder con el atributo +collected_completed_messages+.
      has_many :out, :collected_completed_messages, rel_class: Game::Database::RelationShips::UserCompletedMessage, model_class: Game::Database::Message
      
      #-- -------------------------
      #      Métodos de clase
      #   ------------------------- #++

      # Creación de nuevos usuarios.
      #
      # En caso de error, lanzará una excepción como una String (Exception).
      #
      # * *Argumentos* :
      #   - +al+: Alias o nick del usuario.
      #   - +uid+: Identificador de usuario (correo electrónico).
      def self.sign_up(al, uid)
        begin
          user = create( { alias: al, user_id: uid } );
              
        rescue Exception => e
          puts e.message
          puts e.backtrace
          raise "DB ERROR: Cannot create user '" + al + " with unique id '" + uid + "': \n\t" + e.message;
        end
        
        return user
      end

      #-- -------------------------
      #          Métodos
      #   ------------------------- #++
      
      # Añadir nuevo mensaje.
      #
      # * *Argumentos* :
      #   - +message+: Nuevo mensaje a añadir, de tipo +Game::Database::Message+.
      def add_msg(message)
        self.written_messages << message
      end
      
      # Escribir nuevo mensaje.
      #
      # * *Argumentos* :
      #   - +message+: Nuevo mensaje a añadir, de tipo +Game::Database::Message+.
      #
      # * *Retorna* :
      #   - Referencia al nuevo mensaje escrito.
      def write_msg(content, resource = nil)
        Game::Database::Message.create_message(content, USER_MESSAGE_FRAGMENTS, resource, self, geolocation() )
      end
      
      # Recoger fragmento.
      #
      # No se recogerán fragmentos repetidos ni del propio usuario.
      # En caso de recoger todos los fragmentos, se añadirá el mensaje
      # a la lista de mensajes completados por el usuario. 
      #
      # * *Argumentos* :
      #   - +fragment+: Nuevo fragmento a añadir, de tipo +Game::Database::MessageFragment+.
      #
      # * *Retorna* :
      #   - Si añade el fragmento, devuelve la referencia al enlace del fragmento añadido.
      #   - Si se ha completado el mensaje, devuelve la referencia al enlace de dicho mensaje.
      #   - En cualquier otro caso, devuelve nil.
      def collect_fragment(fragment_message)
        if fragment_message != nil
          # Comprobar si es necesario añadir la relación
          
          # Si el fragmento es suyo, no recogerlo
          if (fragment_message.message.author != nil && fragment_message.message.author == self)
            return nil
          end
          
          # Si ya tiene el mensaje completado, no añadir el fragmento
          if ( self.collected_completed_messages.where(uuid: fragment_message.message.uuid).first != nil ) 
             return nil
          end
          
          # Si ya tiene el fragmento, no volver a añadirlo
          if ( self.collected_fragment_messages.where(uuid: fragment_message.uuid).first != nil )
            return nil
          end
          
          # Comprobar si es necesario quitarla, ya que ha completado el mensaje.
          #   En este punto, se han descartado fragmentos repetidos. Si la cantidad de
          #   fragmentos del mensaje del fragmento actual es el número total de fragmentos
          #   menos uno (el que falta), se borrarán dichas relaciones y se añadirá un nuevo mensaje
          #   marcado como completo. TODO: Mensajes de un sólo fragmento. 
          total_fragments_count         = fragment_message.message.total_fragments
          collected_fragments_rel       = self.collected_fragment_messages(:f, :rel).message.where(uuid: fragment_message.message.uuid).pluck(:rel)
          collected_fragments_rel_count = collected_fragments_rel.count

          if collected_fragments_rel_count == total_fragments_count - 1
            # Borrar los fragmentos
            collected_fragments_rel.each do |fragment_relation|
              fragment_relation.destroy
            end
            
            # Y Añadir el mensaje como completado
            Game::Database::RelationShips::UserCompletedMessage.create(from_node: self, to_node: fragment_message.message )
            
          else
            Game::Database::RelationShips::UserFragmentMessage.create(from_node: self, to_node: fragment_message )
          end
        end
        
        return nil
      end
      
      # Obtener mensajes completados por el usuario como un hash (usado para la API REST).
      #
      # * *Retorna* :
      #   - Se retornará una lista con las características de los mensajes completados por el usuario.
      def get_completed_messages()
        output = {}
        
        self.collected_completed_messages.each_with_rel do |msg, rel|
          output[msg.uuid] = msg.get_user_message(rel)
        end
        
        return output
      end
      
      # Obtener mensajes fragmentados de un usuario como un hash.
      #
      # Se usará principalmente para la API REST.
      #
      # El formato de respuesta es el siguiente:
      #
      #   { type: "json", completed_messages = { uuid1: { content: "...", author: "...", ... }, uuid2: {...}, ... }, fragmented_messages = { uuid1: { content: "...", author: "...", fragments: n, ... }, ... }  }
      #
      # * *Retorna* :
      #   - Se retornará una lista con las características de los mensajes fragmentados de un usuario.
      
      def get_fragmented_messages()
        output = {}
        
        collected_fragment_messages.each_with_rel do |fragment, rel|
          msg = fragment.message
          
          # Añadir mensaje por primeravez
          if output[msg.uuid] == nil
            output[msg.uuid] = msg.get_user_message(rel)
            output[msg.uuid][:fragments] = []
          end
        
          # Fragmentos
          output[msg.uuid][:fragments] << fragment.fragment_index
        end
        
        return output
      end

      # Stringificar objeto.
      #
      # * *Retorna* :
      #   - Objeto como string, con el formato "<User: +user_id+,+alias+,+geolocation+>".
      def to_s
        return "<User: " + self.user_id + ", " + self.alias + ", " + super.to_s + ">" 
      end
    end
  end
end
