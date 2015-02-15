require 'httparty'
require 'data_mapper'
require 'date'

# All methods return the next structure
# {
#   status: :error|:success,
#   result: error_message|success_result
# }
#
module Spotify
  include HTTParty

  def self.before(*reject_names)
    names = instance_methods.reject{ |name| not reject_names.include?(name) }
    names.each do |name|
      m = instance_method(name)
      define_method(name) do |*args, &block|  
        yield
        m.bind(self).(*args, &block)
      end
    end
  end
  
  def access_token(code, client_id, client_secret, log = nil)
    res = post("https://accounts.spotify.com/api/token",
      :body => {
        :grant_type => "authorization_code",
        :code => code,
        :redirect_uri => "http://localhost:5000/auth/spotify/callback"
      },
      :headers => {
        "Authorize": "Basic #{id_and_secret_encoded(client_id, client_secret)}"
      },
      :debug_output => log)
      
      yield res
  end

  def refresh_token(token, client_id, client_secret, log)
    yield post("https://accounts.spotify.com/api/token",
      :body => {
        :grant_type => "resfresh_token",
        :refresh_token => token
      },
      :headers => {
        "Authorize": "Basic #{id_and_secret_encoded(client_id, client_secret)}"
      },
      :debug_output => log)
  end

  def id_and_secret_encoded(client_id, client_secret)
    Base64.strict_encode64("#{client_id}:#{client_secret}")
  end

  def refresh_token?(expires_at)
    expires_at <= DateTime.now
  end

  def me(token)
    HTTParty.get("https://api.spotify.com/v1/me",
      headers: {
        "Authorization" => "Bearer #{ token }"
      })
  end

  before(:me) do
    if refresh_token? expires_at
      res = refresh_token token, client_id, client_secret
      update_token res # This methods must exists in every class which includes this module
    end
  end
end
