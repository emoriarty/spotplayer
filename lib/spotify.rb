require 'httparty'

# All methods return the next structure
# {
#   status: :error|:success,
#   result: error_message|success_result
# }
#
module Spotify
  include HTTParty

  def self.access_token(code, client_id, client_secret, log = nil)
    id_and_secret = Base64.strict_encode64("#{client_id}:#{client_secret}")
    res = post("https://accounts.spotify.com/api/token",
      :body => {
        :grant_type => "authorization_code",
        :code => code,
        :redirect_uri => "http://localhost:5000/auth/spotify/callback",
        :client_id => client_id,
        :client_secret => client_secret
      },
      :debug_output => log)
      
      yield res
  end

  def self.me(token)
    HTTParty.get("https://api.spotify.com/v1/me",
      headers: {
        "Authorization" => "Bearer #{ token }"
      })
  end
end
