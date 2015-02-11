require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'omniauth-spotify'
require 'base64'
require_relative 'lib/spotify'

# Config
configure do
  enable :sessions, :logging
  set :template, :erb

  set :spotify_id, ENV['SPOTYFY_ID']
  set :spotify_key, ENV['SPOTIFY_KEY']
  set :spotify_scope, 'playlist-read-private user-read-private user-read-email playlist-modify-public playlist-modify-private user-library-modify user-library-read'
  
  use OmniAuth::Builder do
    provider :spotify, 
      settings.spotify_id, settings.spotify_key, scope: settings.spotify_scope
  end
end

register do
  def auth(type)
    condition do
      redirect "/login" unless authorize?
    end
  end
end

helpers do
  def authorize?
    @user != nil
  end

  def login
    @user = true
  end
  
end

before do
  @user = session[:user]
end

# App
get '/', auth: :user do
  erb :home
end

get '/login' do
  erb :auth
end

get '/auth/spotify/callback' do
  redirect "/auth/failure" if params[:error]

  session[:user] = true
  session[:token] = env['omniauth.auth'].credentials.token
  session[:refresh_token] = env['omniauth.auth'].credentials.refresh_token

  redirect "/me" 
end

get '/auth/failure' do
  erb :error
end

get '/me' do
  response = Spotify.me session[:token]
  @profile = response.parsed_response
  logger.info @profile
  erb :profile
end
