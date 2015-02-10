require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'omniauth-spotify'
require 'uri'
require 'digest'
require 'net/http'
require 'base64'

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

get '/auth/spotify' do
  redirect ["https://accounts.spotify.com/authorize",
    "?client_id=#{settings.spotify_id}",
    "&response_type=code",
    "&redirect_uri=#{URI.encode 'http://localhost:5000/callback/spotify'}",
    "&scope=#{settings.spotify_scope}",
    "&state=#{session[:spotify_state] = Digest::SHA256.hexdigest(settings.spotify_id) }"].join
end

get '/callback/spotify' do
  if params[:code]
    return "Is not the same session" unless params[:state] == session[:spotify_state]
    return "auth failed due to #{params[:error]}" if params[:error]
    
    "Your auth code is #{params[:code]}"
    redirect "/token/spotify/#{params[:code]}"
  elsif params[:access_token]
    return "Your access_token is #{params[:access_token]}"
  end
end

get '/token/spotify/:code' do
=begin
  uri = URI.parse "https://accounts.spotify.com/api/token"
  params = {
    grant_type: "authorization_code",
    code: params[:code],
    redirect_uri: "http://localhost:5000/callback/spotify"
  }
  auth_base64 = Base64.enconde64 "#{settings.spotify_id}:#{settings.spotify_key}"

  post = Net::HTTP::Post.new uri
  post['Authorization'] = "Basic #{auth_base64}"
  post.set_from_data params
  #post.basic_auth settings.spotify_id, settings.spotify_key
  #
=end
  params[:grant_type] = "authorization_code"
  params[:redirect_uri] = "http://localhost:5000/callback/spotify" 
  
  redirect "https://accounts.spotify.com/api/token", 307
end
