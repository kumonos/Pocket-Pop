unless Rails.env == 'production' || Rails.env == 'staging'
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
end
