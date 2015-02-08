unless Rails.env == 'production' || Rails.env == 'staging'
  require 'rspec/core/rake_task'

  desc 'Run turnip acceptance tests'
  RSpec::Core::RakeTask.new(:turnip) do |t|
    t.pattern = './spec{,/*/**}/*.feature'
    t.rspec_opts = ['-r turnip/rspec']
  end
end
