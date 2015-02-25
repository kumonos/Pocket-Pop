set :deploy_to, '/apps/pocketporter'
set :unicorn_config_path, File.join(fetch(:deploy_to), 'current', 'config', 'unicorn.rb')
set :rbenv_path, '/usr/local/rbenv/bin/rbenv'
