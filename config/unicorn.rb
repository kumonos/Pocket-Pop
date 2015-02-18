# -*- coding: utf-8 -*-
env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'staging'

worker_processes 2

# socket
listen 3300
listen File.expand_path("tmp/sockets/unicorn_#{env}.sock", __FILE__)
pid File.expand_path("tmp/pids/unicorn_#{env}.pid", __FILE__)

# logs
stderr_path '/var/log/apps/pocket_porter/unicorn.log'
stdout_path '/var/log/apps/pocket_porter/unicorn.log'

preload_app true

before_fork do |server, _worker|
  defined?(ActiveRecord::Base) && ActiveRecord::Base.connection.disconnect!

  old_pid = "#{ server.config[:pid] }.oldbin"
  unless old_pid == server.pid
    begin
      Process.kill :QUIT, File.read(old_pid).to_i
    rescue Errno::ENOENT, Errno::ESRCH
      p $ERROR_INFO
    end
  end
end

after_fork do |_server, _worker|
  defined?(ActiveRecord::Base) && ActiveRecord::Base.establish_connection
end