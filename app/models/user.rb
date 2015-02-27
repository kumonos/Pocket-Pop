# -*- coding: utf-8 -*-
# user
class User < ActiveRecord::Base
  validates :email, email_format: { message: ' メールアドレスの形式が不適切です' }

  def self.from_oauth(auth)
    where(auth.slice(:username)).first_or_initialize.tap do |user|
      user.name = auth['username']
      user.oauth_token = auth['access_token']
      user.save!(validate: false)
    end
  end
end
