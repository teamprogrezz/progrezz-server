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
  #   - Tiempo que ha tardado en ejecutarse el bloque.
  #
  def self.timer()
    pre_time = Time.now
    yield
    return Time.now - pre_time
  end
  
  # Ejecuta un programa python.
  #
  # * *Argumentos*:
  #   - +script_file+: Fichero del script python.
  #   - +input_str+: Cadena de entrada sustituyendo al flujo STDIN.
  #
  # * *Devuelve* 
  #   - Salida estándar del script del flujo STDOUT.
  #
  def self.run_py(script_file, input_str)
    cmd = 'python ' + script_file
    
    return Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
      stdin.puts input_str
      return { stdout: stdout.read, stderr: stderr.read }
    end
  end

  #-- ...  #++
end