# encoding: UTF-8

require 'open3'

# Clase de utilidades genéricas.
class GenericUtils
  # Requerir un directorio de ficheros fuente.
  #
  # Se buscarán e incluirán ficheros según se indiquen en los parámetros.
  # 
  # @param dir_regexp [String] Expresión regular de la carpeta a incluir.
  # @param msg [String] Mensaje que se muestra antes de cargar el fichero. Si es nil, no se muestra nada.
  def self.require_dir(dir_regexp, msg = nil)
    Dir[dir_regexp].each {|file|
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
    h.keys.each do |k|
      ks    = k.respond_to?(:to_sym) ? k.to_sym : k
      h[ks] = h.delete k # Preserve order even when k == ks
      symbolize_keys_deep! h[ks] if h[ks].kind_of? Hash
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
        raise "Parameter '" + r.to_s + "' (not provided) is required"
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
end