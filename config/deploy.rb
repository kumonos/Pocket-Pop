set :application, 'pocket-porter'
set :repo_url, -> { 'file://' + Dir.pwd + '/.git' }
set :scm, :rsync
set :branch, ENV['BRANCH'] || 'master'

# set up rbenv
set :rbenv_type, :user
set :rbenv_ruby, '2.1.1'
set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} " \
  "RBENV_VERSION=#{fetch(:rbenv_ruby)} " \
  "#{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w(rake gem bundle ruby rails)
set :rbenv_roles, :all # default value

# set up rails
set :assets_roles, [:web, :app]
set :normalize_asset_timestamps, %(
  public/images public/javascripts public/stylesheets)

# set up rsync
set :rsync_src_path, '.'
set :rsync_options, %w(
  --recursive --delete --delete-excluded --exclude='vendor/bundle/'
  --exclude='.git/' --exclude='log/'
)

# set up unicorn
set :unicorn_pid, '/apps/pocket-porter/tmp/unicorn.pid'
set :linked_files, %w(.env)
set :unicorn_rack_env, 'production'

# set up whenever
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
set :whenever_roles, :app

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke 'deploy:migrate'
      invoke 'unicorn:stop'
      invoke 'unicorn:start'
    end
  end
  after :db_migrate, :restart
end

Rake::Task['metrics:collect'].clear_actions
