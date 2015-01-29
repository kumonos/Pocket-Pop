require 'pocket'
require 'dotenv'

Dotenv::Railtie.load

Pocket.configure do |config|
  config.consumer_key = ENV['POCKET_CONSUMER_KEY']
end
