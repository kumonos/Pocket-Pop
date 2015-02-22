role :web, 'localhost'
role :app, 'localhost'
role :db,  'localhost', primary: true

set :deploy_to, '/apps/pocket-porter'
set :unicorn_config_path, File.join(fetch(:deploy_to), 'current', 'config', 'unicorn.rb')
