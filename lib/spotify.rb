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
  
  REFRESH_METHODS = [:me]

  module ClassMethods
    def pre_call(names = nil)
      names = names ? names.concat(REFRESH_METHODS) : REFRESH_METHODS
      names = instance_methods.reject{ |name| !names.include?(name) }
      puts names.inspect
      names.each do |name|
        m = instance_method(name)
        define_method(name) do |*args, &block|  
          yield
          m.bind(self).(*args, &block)
        end
      end
    end
  end
  
  module InstanceMethods
    # Block argument
    def access_token(code, client_id, client_secret, log = nil)
      return nil unless block_given?    
      yield post("https://accounts.spotify.com/api/token",
        :body => {
          :grant_type => "authorization_code",
          :code => code,
          :redirect_uri => "http://localhost:5000/auth/spotify/callback"
        },
        :headers => {
          "Authorize": "Basic #{id_and_secret_encoded(client_id, client_secret)}"
        },
        :debug_output => log)
    end

    def refresh_token(token, client_id, client_secret, log)
      return nil unless block_given?    
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
      return nil unless block_given?    
      yield get("https://api.spotify.com/v1/me",
        headers: {
          "Authorization" => "Bearer #{ token }"
        })
    end
  end

end
