# user
class User < ActiveRecord::Base
  def self.from_oauth(auth)
    where(auth.slice(:username)).first_or_initialize.tap do |user|
      user.name = auth['username']
      user.oauth_token = auth['access_token']
      user.save!
    end
  end
end
