require 'sinatra'
require 'json'

get '/__dev/msj/lista' do
  mensajes = Juego::Mensaje.all
  erb :"mensaje/lista", :locals => {:mensajes => mensajes }
end

# Los mensajes se deben mandar al usuario como un objeto JSON (modularidad)
get '/__dev/msj/all' do
  mensajes = Juego::Mensaje.all
  
  # Retornar array JSON
  return JSON.generate(mensajes)
end

get '/__dev/msj/form' do
  erb :"mensaje/form"
end

get '/__dev/msj/:id?' do |id|
  mensaje = Juego::Mensaje.first(:id => id)
  if mensaje
    return JSON.generate(mensaje)
  else
    return "NOT FOUND"
  end
end

post '/__dev/msj/form' do
  # Usar la variable ruby "params"
  # |- latitud   =>  Latitud
  # |- longitud  =>  Longitud
  # |- mensaje   =>  Mensaje
  
  m = Juego::Mensaje.new
  m.latitud = params[:latitud]
  m.longitud = params[:longitud]
  m.mensaje = params[:mensaje]
  m.save
  
  return "Guardado: " + JSON.generate(m)
end