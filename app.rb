require 'sinatra'
require 'sinatra/contrib'
require "sinatra/reloader" if development?
require 'omniauth-spotify'
require 'uri'
require 'digest'
require 'json'
require 'typhoeus'

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
  
  def refresh_token(code)
    request = Typhoeus::Request.new("https://accounts.spotify.com/api/token",
      method: :post,
      body: { 
        grant_type: "authorization_code",
        code: code,
        redirect_uri: "http://localhost:5000/auth/spotify/callback"
      },
      headers: { 
        "Authorization": "Basic #{Base64.strict_encode64("#{settings.spotify_id}:#{settings.spotify_key}")}"
      },
      followlocation: true
    )

    logger.info request.inspect

    request.on_complete do |response|
      logger.info "[]" * 100
      logger.info response
      if response.success?
        logger.info "SUCCESS"
      elsif response.timed_out?
        logger.info "TIMED OUT"
      elsif response.code == 0
        logger.info response.return_message
      else
        logger.info "HTTP request failed: #{response.code.to_s}"
        redirect '/auth/failure'
      end
    end

    request.run
    
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
  template = nil
  
  if params[:code]
    #return "Is not the same session" unless params[:state] == session[:spotify_state]
    return "auth failed due to #{params[:error]}" if params[:error]
    refresh_token params[:code]
    template = :token
  elsif params[:access_token]
    return "Your access_token is #{params[:access_token]}"
    session[:user] = true
    redirect '/home'
  end

  erb template 
end

get '/auth/failure' do
  erb :error
end

