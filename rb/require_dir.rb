# encoding: UTF-8

# Requerir un directorio de ficheros fuente.
#
# Se buscarán e incluirán ficheros según se indiquen en los parámetros.
# 
# * *Argumentos* :
#   - +dir_regexp+: Expresión regular de la carpeta a incluir.
#   - +msg+: Mensaje que se muestra antes de cargar el fichero. Si es nil, no se muestra nada.
def require_dir(dir_regexp, msg = nil)
  Dir["./rb/game/**/*.rb"].each {|file|
    if msg != nil; puts msg + file.split(/\.rb/)[0] end
    require file.split(/\.rb/)[0]
  }
end