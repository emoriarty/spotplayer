require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'omniauth-spotify'
require 'uri'
require 'digest'


# Config
configure do
  enable :sessions

  set :spotify_id, ENV['SPOTYFY_ID']
  set :spotify_key, ENV['SPOTIFY_KEY']
  set :spotify_scope, 'playlist-read-private user-read-private user-read-email playlist-modify-public playlist-modify-private user-library-modify user-library-read'
  
  use OmniAuth::Builder do
    provider :spotify, 
      settings.spotify_id, settings.spotify_key, scope: settings.spotify_scope
  end
end

# App
get '/' do
  File.read(File.join(settings.public_folder, 'index.html'))
end

get '/auth' do
  redirect ["https://accounts.spotify.com/authorize",
    "?client_id=#{settings.spotify_id}",
    "&response_type=code",
    "&redirect_uri=#{URI.encode "http://localhost:5000/callback"}",
    "&scope=#{settings.spotify_scope}",
    "&state=#{session[:spotify_state] = Digest::SHA256.hexdigest(settings.spotify_id) }"].join
end

get '/callback' do
  return "Is not the same session" unless params[:state] == session[:spotify_state]
  return "auth failed due to #{params[:error]}" if params[:error]
  
  "Your auth code is #{params[:code]}"
end
