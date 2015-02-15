require 'data_mapper'
require 'date'

class User
  include DataMapper::Resource 

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
end

DataMapper.finalize
