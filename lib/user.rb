require 'data_mapper'
require 'dm-sqlite-adapter'


DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite::memory:")
DataMapper.setup(:default, "sqlite:///#{Dir.getwd}/app.db")

class User
  include DataMapper::Resource 

  property :id, Serial
  property :uid, String
  property :token, String
  property :refresh_token, String
  property :expires_at, DateTime

  def authenticate(attempted_password)
    if self.password == attempted_password
      true
    else
      false
    end
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!
