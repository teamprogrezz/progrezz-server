# encoding: UTF-8

require 'open3'

# Clase de utilidades genéricas.
class GenericUtils

  # Requerir un directorio de ficheros fuente.
  #
  # Se buscarán e incluirán ficheros según se indiquen en los parámetros.
  # 
  # * *Argumentos* :
  #   - +dir_regexp+: Expresión regular de la carpeta a incluir.
  #   - +msg+: Mensaje que se muestra antes de cargar el fichero. Si es nil, no se muestra nada.
  def self.require_dir(dir_regexp, msg = nil)
    Dir[dir_regexp].each {|file|
      if msg != nil; puts msg + file.split(/\.rb/)[0] end
      require file.split(/\.rb/)[0]
    }
  end
  
  # Medir el tiempo que tarda en ejecutar un bloque de código.
  #
  # * *Devuelve* 
  #   - Tiempo que ha tardado en ejecutarse el bloque, en ms.
  #
  def self.timer()
    pre_time = Time.now
    yield
    return (Time.now - pre_time) * 1000.0
  end
  
  # Ejecuta un programa o script cualquiera.
  #
  # * *Argumentos*:
  #   - +executable+: Ejecutable o intérprete a lanzar (ejemplo: python, ruby, ls, executable_cpp, ...).
  #   - +arguments+:  Argumentos a pasar al ejecutable (ejemplo: file.py, main.rb, -la, ...).
  #   - +env_vars+:   Hash de variables de entorno a pasar al programa (ejemplo: {name: "wikiti", pass: "****"}, ...).
  #   - +input_str+:  Cadena de entrada sustituyendo al flujo STDIN.
  #
  # * *Devuelve* 
  #   - STDOUT y STDERR del script, como un hash, tal que {stdout: STDOUT, stderr: STDERR}.
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
  # Es un acceso directo al método GenericUtils.run_script con el intérprete de python.
  #
  # * *Argumentos*:
  #   - +script_file+: Fichero del script python.
  #   - +env_vars+:    Hash de variables de entorno (strings) a pasar al programa (ejemplo: {"name" => "wikiti", "pass" => "****"}, ...). Se accedencon python mediante ENV['variable'].
  #   - +input_str+:   Cadena de entrada sustituyendo al flujo STDIN.
  #
  # * *Devuelve* 
  #   - STDOUT y STDERR del script, como un hash, tal que {stdout: STDOUT, stderr: STDERR}.
  #
  def self.run_py(script_file, env_vars = {}, input_str = "")
    return GenericUtils.run_script('python', script_file, env_vars, input_str)
  end

  #-- ...  #++
end