require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'omniauth-spotify'
require 'data_mapper'
require 'dm-sqlite-adapter'
require_relative 'lib/spotify'
require_relative 'lib/user'

# Config
configure do  
  DataMapper::Logger.new($stdout, :debug)
  DataMapper.setup(:default, "sqlite::memory:")
  DataMapper.setup(:default, "sqlite:///#{Dir.getwd}/app.db")
  DataMapper.auto_upgrade!

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

  @user = User.first_or_create({ uid: env['omniauth.auth'].uid }, {
    uid: env['omniauth.auth'].uid,
    token: env['omniauth.auth'].credentials.token,
    refresh_token: env['omniauth.auth'].credentials.refresh_token,
    expires_at: DateTime.strptime(env['omniauth.auth'].credentials.expires_at.to_s, '%s')
  })

  logger.info @user
  unless @user.saved?
    logger.error "user not saved, redirectig to failure"
    @user.errors.each do |error|
      logger.error error
    end
    redirect 'auth/failure'
  end
    
  # saving the user id for session
  logger.info "user saved, redrecting to profile"
  session['user'] = @user.uid
  redirect '/me' 
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
