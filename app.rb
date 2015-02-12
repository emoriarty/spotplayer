require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'omniauth-spotify'
require_relative 'lib/spotify'
require_relative 'lib/user'

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

helpers do
  def authorize?
    logger.info "AUTHORIZE?"
    redirect '/login' if session['user'] == nil
  end

  def logout!
    session['user'] = nil
  end
end

# App
get '/' do
  authorize?
  erb :home
end

get '/login' do
  erb :auth
end

get '/logout' do
  logout!
  redirect '/'
end

get '/auth/spotify/callback' do
  redirect "/auth/failure" if params[:error]
  logger.info env['omniauth.auth']
  @user = nil
  if @user = User.first(uid: env['omniauth.auth'].uid)
    @user.update token: env['omniauth.auth'].credentials.token,
      refresh_token: env['omniauth.auth'].credentials.refresh_token,
      expires_at: env['omniauth.auth'].credentials.expires_at
  else
    logger.info env['omniauth.auth'].uid
    logger.info env['omniauth.auth'].credentials.token
    @user = User.create(uid: env['omniauth.auth'].uid,
      token: env['omniauth.auth'].credentials.token,
      refresh_token: env['omniauth.auth'].credentials.refresh_token,
      expires_at: env['omniauth.auth'].credentials.expires_at)
  end
  logger.info @user.save
  logger.info "redirecting to home"
  session['user'] = @user.uid
  redirect '/' 
end

get '/auth/failure' do
  erb :error
end

get '/me' do
  authorize?
  logger.info "ME"
  logger.info session['user']
  response = Spotify.me User.first(uid: session['user']).token
  @profile = response.parsed_response
  logger.info @profile
  erb :profile
end
