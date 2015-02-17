require 'data_mapper'
require 'date'
require_relative 'spotify'

class User
  include DataMapper::Resource 
  include Spotify::InstanceMethods
  extend Spotify::ClassMethods

  property :id, Serial
  property :uid, String
  property :token, String, length: 300
  property :refresh_token, String, length: 150
  property :expires_at, DateTime

  # Mandatory method
  def update_token(res)
    update token: res.access_token, expires_at: DateTime.now + res.expires_in
  end

  def authenticate(attempted_password)
    if self.password == attempted_password
      true
    else
      false
    end
  end
  
  pre_call do
    if refresh_token? expires_at
      res = refresh_token token, client_id, client_secret
      update_token res # This methods must exists in every class which includes this module
    end
  end

end

DataMapper.finalize
