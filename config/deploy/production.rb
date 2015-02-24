set :deploy_to, '/apps/pocketporter'
set :unicorn_config_path, File.join(fetch(:deploy_to), 'current', 'config', 'unicorn.rb')

role :app, 'localhost'
role :web, 'localhost'
role :db,  'localhost'
