require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?

get '/' do
  File.read(File.join(settings.public_folder, 'index.html'))
end
