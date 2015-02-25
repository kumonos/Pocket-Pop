set :application, 'pocket-porter'
set :repo_url, -> { 'file://' + Dir.pwd + '/.git' }
set :scm, :gitcopy
set :branch, ENV['BRANCH'] || 'master'

# set up rbenv
set :rbenv_type, :user
set :rbenv_ruby, '2.1.1'
set :rbenv_map_bins, %w(rake gem bundle ruby rails)
set :rbenv_roles, :all # default value

# set up rails
set :assets_roles, [:web, :app]
set :normalize_asset_timestamps, %(
  public/images public/javascripts public/stylesheets)

# set up unicorn
set :unicorn_pid, '/apps/pocket-porter/tmp/unicorn.pid'
set :linked_files, %w(.env)
set :unicorn_rack_env, 'production'

# set up whenever
set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }
set :whenever_roles, :app

# override default tasks for local deploy
namespace :deploy do
  task :starting do
    invoke 'metrics:collect'
    invoke 'deploy:check'
    invoke 'deploy:set_previous_revision'
  end

  task updating: :new_release_path do
    invoke "#{scm}:create_release"
    invoke 'deploy:set_current_revision'
    invoke 'deploy:symlink:shared'
  end

  task :reverting do
    invoke 'deploy:revert_release'
  end

  task :publishing do
    invoke 'deploy:symlink:release'
  end

  task :finishing do
    invoke 'deploy:cleanup'
  end

  task :finishing_rollback do
    invoke 'deploy:cleanup_rollback'
  end

  task :finished do
    invoke 'deploy:log_revision'
  end

  desc 'Check required files and directories exist'
  task :check do
    invoke "#{scm}:check"
    invoke 'deploy:check:directories'
    invoke 'deploy:check:linked_dirs'
    invoke 'deploy:check:make_linked_dirs'
    invoke 'deploy:check:linked_files'
  end

  namespace :check do
    desc 'Check shared and release directories exist'
    task :directories do
      run_locally do
        execute :mkdir, '-p', shared_path, releases_path
      end
    end

    desc 'Check directories to be linked exist in shared'
    task :linked_dirs do
      next unless any? :linked_dirs
      run_locally do
        execute :mkdir, '-p', linked_dirs(shared_path)
      end
    end

    desc 'Check directories of files to be linked exist in shared'
    task :make_linked_dirs do
      next unless any? :linked_files
      run_locally do |_host|
        execute :mkdir, '-p', linked_file_dirs(shared_path)
      end
    end

    desc 'Check files to be linked exist in shared'
    task :linked_files do
      next unless any? :linked_files
      run_locally do |host|
        linked_files(shared_path).each do |file|
          unless test "[ -f #{file} ]"
            error t(:linked_file_does_not_exist, file: file, host: host)
            exit 1
          end
        end
      end
    end
  end

  namespace :symlink do
    desc 'Symlink release to current'
    task :release do
      run_locally do
        tmp_current_path = release_path.parent.join(current_path.basename)
        execute :ln, '-s', release_path, tmp_current_path
        execute :mv, tmp_current_path, current_path.parent
      end
    end

    desc 'Symlink files and directories from shared to release'
    task :shared do
      invoke 'deploy:symlink:linked_files'
      invoke 'deploy:symlink:linked_dirs'
    end

    desc 'Symlink linked directories'
    task :linked_dirs do
      next unless any? :linked_dirs
      run_locally do
        execute :mkdir, '-p', linked_dir_parents(release_path)

        fetch(:linked_dirs).each do |dir|
          target = release_path.join(dir)
          source = shared_path.join(dir)
          unless test "[ -L #{target} ]"
            execute :rm, '-rf', target if test "[ -d #{target} ]"
            execute :ln, '-s', source, target
          end
        end
      end
    end

    desc 'Symlink linked files'
    task :linked_files do
      next unless any? :linked_files
      run_locally do
        execute :mkdir, '-p', linked_file_dirs(release_path)

        fetch(:linked_files).each do |file|
          target = release_path.join(file)
          source = shared_path.join(file)
          next if test "[ -L #{target} ]"
          execute :rm, target if test "[ -f #{target} ]"
          execute :ln, '-s', source, target
        end
      end
    end
  end

  desc 'Clean up old releases'
  task :cleanup do
    run_locally do |host|
      releases = capture(:ls, '-xtr', releases_path).split
      if releases.count >= fetch(:keep_releases)
        info t(:keeping_releases, host: host.to_s, keep_releases: fetch(:keep_releases), releases: releases.count)
        directories = (releases - releases.last(fetch(:keep_releases)))
        if directories.any?
          directories_str = directories.map do |release|
            releases_path.join(release)
          end.join(' ')
          execute :rm, '-rf', directories_str
        else
          info t(:no_old_releases, host: host.to_s, keep_releases: fetch(:keep_releases))
        end
      end
    end
  end

  desc 'Remove and archive rolled-back release.'
  task :cleanup_rollback do
    run_locally do
      last_release = capture(:ls, '-xt', releases_path).split.first
      last_release_path = releases_path.join(last_release)
      if test "[ `readlink #{current_path}` != #{last_release_path} ]"
        execute :tar, '-czf',
                deploy_path.join("rolled-back-release-#{last_release}.tar.gz"),
                last_release_path
        execute :rm, '-rf', last_release_path
      else
        debug 'Last release is the current release, skip cleanup_rollback.'
      end
    end
  end

  desc 'Log details of the deploy'
  task :log_revision do
    run_locally do
      within releases_path do
        execute %(echo "#{revision_log_message}" >> #{revision_log})
      end
    end
  end

  desc 'Revert to previous release timestamp'
  task revert_release: :rollback_release_path do
    run_locally do
      set(:revision_log_message, rollback_log_message)
    end
  end

  task :new_release_path do
    set_release_path
  end

  task :rollback_release_path do
    run_locally do
      releases = capture(:ls, '-xt', releases_path).split
      if releases.count < 2
        error t(:cannot_rollback)
        exit 1
      end
      last_release = releases[1]
      set_release_path(last_release)
      set(:rollback_timestamp, last_release)
    end
  end

  desc 'Place a REVISION file with the current revision SHA in the current release path'
  task :set_current_revision  do
    invoke "#{scm}:set_current_revision"
    run_locally do
      within release_path do
        execute :echo, "\"#{fetch(:current_revision)}\" >> REVISION"
      end
    end
  end

  task :set_previous_revision do
    run_locally do
      target = release_path.join('REVISION')
      if test "[ -f #{target} ]"
        set(:previous_revision, capture(:cat, target, '2>/dev/null'))
      end
    end
  end

  task :restart
  task :failed
end

# override gitcopy
namespace :gitcopy do
  task :create_release do
    run_locally do
      execute :mkdir, '-p', release_path
    end
  end
end

# add restart task
namespace :deploy do
  desc 'Restart application'
  task :restart do
    run_locally do
      invoke 'deploy:migrate'
      invoke 'unicorn:stop'
      invoke 'unicorn:start'
    end
  end
  after :publishing, :restart
end

# override capistrano3-unicorn
namespace :unicorn do
  task :start do
    run_locally do
      within current_path do
        if test("[ -e #{fetch(:unicorn_pid)} ] && kill -0 #{pid}")
          info 'unicorn is running...'
        else
          with rails_env: fetch(:rails_env) do
            execute(:bundle, 'exec unicorn', '-c', fetch(:unicorn_config_path),
                    '-E', fetch(:unicorn_rack_env), '-D', fetch(:unicorn_options))
          end
        end
      end
    end
  end

  desc 'Stop Unicorn (QUIT)'
  task :stop do
    run_locally do
      within current_path do
        if test("[ -e #{fetch(:unicorn_pid)} ]")
          if test("kill -0 #{pid}")
            info 'stopping unicorn...'
            execute :kill, '-s QUIT', pid
          else
            info 'cleaning up dead unicorn pid...'
            execute :rm, fetch(:unicorn_pid)
          end
        else
          info 'unicorn is not running...'
        end
      end
    end
  end
end

# override gitcopy
namespace :gitcopy do
  archive_name =  "archive.#{ DateTime.now.strftime('%Y%m%d%m%s') }.tar.gz"

  desc "Archive files to #{archive_name}"
  file archive_name do |_file|
    system "git ls-remote #{fetch(:repo_url)} | grep #{fetch(:branch)}"
    if $?.exitstatus == 0
      system "git archive --remote #{fetch(:repo_url)} --format=tar #{fetch(:branch)}:#{fetch(:sub_directory)}" \
        " | gzip > #{ archive_name }"
    else
      puts "Can't find commit for: #{fetch(:branch)}"
    end
  end

  task deploy: fetch(:archive_name) do |file|
    tarball = file.prerequisites.first
    run_locally do
      # Make sure the release directory exists
      execute :mkdir, '-p', release_path

      # Create a temporary file on the server
      tmp_file = release_path.tmp

      # Upload the archive, extract it and finally remove the tmp_file
      execute :copy, tarball, tmp_file
      execute :tar, '-xzf', tmp_file, '-C', release_path
      execute :rm, tmp_file
    end
  end
end
