# encoding: UTF-8

require 'open3'
require 'nesty'

# Clase de utilidades genéricas.
class GenericUtils
  # Requerir un directorio de ficheros fuente.
  #
  # Se buscarán e incluirán ficheros según se indiquen en los parámetros.
  # 
  # @param dir_regexp [String] Expresión regular de la carpeta a incluir.
  # @param msg [String] Mensaje que se muestra antes de cargar el fichero. Si es nil, no se muestra nada.
  # @param colorize [Bool] Dar color por defecto.
  def self.require_dir(dir_regexp, msg = nil, colorize = true)
    msg = msg.cyan if colorize
    Dir[dir_regexp].sort.each {|file|
      if msg != nil; puts msg + file.split(/\.rb/)[0] end
      require file.split(/\.rb/)[0]
    }
  end
  
  # Medir el tiempo que tarda en ejecutar un bloque de código.
  #
  # @return Tiempo que ha tardado en ejecutarse el bloque, en ms.
  #
  def self.timer()
    pre_time = Time.now
    yield
    return (Time.now - pre_time) * 1000.0
  end
  
  # Ejecuta un programa o script cualquiera.
  #
  # @param executable [String] Ejecutable o intérprete a lanzar (ejemplo: python, ruby, ls, executable_cpp, ...).
  # @param arguments  [String] Argumentos a pasar al ejecutable (ejemplo: file.py, main.rb, -la, ...).
  # @param env_vars   [Hash<Symbol, String>] Hash de variables de entorno a pasar al programa (ejemplo: { name: "wikiti", pass: "****" }, ...).
  # @param input_str  [String] Cadena de entrada sustituyendo al flujo STDIN.
  #
  # @return [Hash<Symbol, String>] STDOUT y STDERR del script, como un hash, tal que { stdout: STDOUT, stderr: STDERR}.
  #
  def self.run_script(executable, arguments, env_vars = {}, input_str = "")
    cmd = executable + " " + arguments
    
    return Open3.popen3(env_vars, cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.puts input_str if input_str != ""
      return { stdout: stdout.read, stderr: stderr.read }
    end
  end
  
  # Ejecuta un programa python.
  #
  # Es un acceso directo al método #GenericUtils.run_script con el intérprete de python.
  #
  # @param script_file [String] Fichero del script python.
  # @param env_vars [Hash<Symbol, String>] Hash de variables de entorno (strings) a pasar al programa (ejemplo: { "name" => "wikiti", "pass" => "****" }, ...). Se accede con python mediante ENV ['variable'].
  # @param input_str [String]  Cadena de entrada sustituyendo al flujo STDIN.
  #
  # @return [Hash<Symbol, String>] STDOUT y STDERR del script, como un hash, tal que { stdout: STDOUT, stderr: STDERR }.
  #
  def self.run_py(script_file, env_vars = {}, input_str = "")
    return GenericUtils.run_script('python', script_file, env_vars, input_str)
  end
  
  # Convertir las claves de un Hash a claves.
  #
  # @param h [Hash] Hash a modificar.
  # @return [Hash] Hash convertido.
  def self.symbolize_keys_deep!(h)
    if h.is_a? Array
      h.each do |hash|
        symbolize_keys_deep!(hash)
      end
    elsif h.respond_to? :keys
      h.keys.each do |k|
        ks    = k.respond_to?(:to_sym) ? k.to_sym : k
        h[ks] = h.delete k # Preserve order even when k == ks
        symbolize_keys_deep! h[ks] if (h[ks].kind_of? Hash or h[ks].kind_of? Array)
      end
    end

    return h
  end
  
  # Calcular parámetros en base a unos por defecto y unos parámetros requeridos.
  # @param default [Hash<Symbol, Object>] Parámetros por defecto.
  # @param user_params [Hash<Symbol, Object>] Parámetros que ha introducido el usuario.
  # @param required_params [Array<Symbol>] Parámetros requeridos.
  # @raise [Exception] Si un parámetro requerido no se proporciona, se lanzará una excepción.
  def self.default_params(default, user_params, required_params = [])
    keys = user_params.keys
    for r in required_params
      if !keys.include? r
        raise ::GenericException.new( "Parameter '" + r.to_s + "' (not provided) is required" )
      end
    end
    
    return default.deep_merge(user_params)
  end
end

# Ruby hash
class ::Hash
  # Recursively merge two hashes (deep merge)
  # @param second [Hash] Second hash.
  # @return [Hash] Current hash deep merged with second hash.
  def deep_merge(second)
    merger = proc { |key, v1, v2| Hash === v1 && Hash === v2 ? v1.merge(v2, &merger) : v2 }
    self.merge(second, &merger)
  end
  
  # Clone current hash.
  def deep_clone()
    return Marshal.load(Marshal.dump(self))
  end
end

# Clase de excepción personalizada.
class GenericException < StandardError
  include ::Nesty::NestedError
end

# Módulo de eventos (dispatchers y listeners).
# 
# Para usarlo en la clase, deberá incluirse en la clase usando el método +extend*:
#
#   class Foo
#     extend Evented
#     ...
#   end
#
# Luego, se añade un listener (callback o lambda), y se llama cuando sea necesario:
#
#   Foo.add_event_listener :onWhatever, lambda { |a| puts "Hello, #{a.to_s}" }
#   Foo.add_event_listener :onWhatever, lambda { |a| puts "How are you?" }
#   Foo.dispatch_event :onWhatever, "foo"
#   # "Hello, foo"
#   # "How are you?"
module Evented
  # Conjunto de callbacks de un mismo evento (array).
  class Dispatcher < Array
    # Llamar a los callbacks del dispatcher.
    # @param args [Object] Argumentos (opcional).
    def call(*args)
      self.each { |e| e.call(*args) }
    end
  end
  
  # Conjunto de distintos callbacks (Hash). Cada valor se corresponderá con un #Dispatcher.
  class Dispatchers < Hash
    # Llamar a los callbacks del dispatcher +name+.
    # @param name [Object] Nombre del dispatcher.
    # @param args [Object] Argumentos (opcional).
    def call(name, *args)
      self[name].call(*args) if self[name]
    end
  end
  
  # Getter de la lista de dispatchers. Si no existe, se creará uno nuevo.
  # @return [Dispatchers] Referencia al objeto Dispatchers.
  private def dispatchers
    @dispatchers ||= Dispatchers.new
  end
  
  # Getter de un dispatcher. Si no existe, se creará uno nuevo.
  # @param name [Object] Nombre del dispatcher.
  # @return [Dispatcher] Referencia al objeto Dispatcher con nombre +name+.
  private def dispatcher(name)
    dispatchers[name] ||= Dispatcher.new
  end
  
  # Lanzar un evento.
  # @param name [Object] Nombre del dispatcher a activar.
  # @param args [Object] Parámetros adicionales que se pasarán a los callbacks del dispatcher. 
  def dispatch_event(name, *args)
    dispatcher(name).call(*args)
  end
  
  # Añadir un callback.
  # Se pueden añadir todas las funciones deseadas a un mismo evento.
  # @param name [Object] Nombre del evento (dispatcher) al que se le añadirá el callback o handler.
  # @param handler [Lambda] Función handler del evento.
  def add_event_listener(name, handler)
    dispatcher(name) << handler unless dispatcher(name).include? handler
  end
  
  # Eliminar un callback.
  # @param name [Object] Nombre del evento (dispatcher) al que se le quitará el callback o handler.
  # @param handler [Lambda] Función handler del evento.
  def remove_event_listener( name, handler )
    dispatcher(name).delete(handler) if dispatcher(name).include? handler
  end
end