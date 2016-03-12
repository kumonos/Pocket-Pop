# -*- coding: utf-8 -*-
env = ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'staging'

worker_processes 1

# socket
listen 3311
if env == 'production'
  listen '/apps/pocketporter/tmp/unicorn.sock'
  pid '/apps/pocketporter/tmp/unicorn.pid'
else
  listen File.expand_path("../../tmp/sockets/unicorn_#{env}.sock", __FILE__)
  pid File.expand_path("../../tmp/pids/unicorn_#{env}.pid", __FILE__)
end

# logs
if env == 'production'
  stderr_path '/var/log/apps/pocketporter/unicorn.log'
  stdout_path '/var/log/apps/pocketporter/unicorn.log'
else
  stderr_path File.expand_path("../../log/unicorn_#{env}.log", __FILE__)
  stdout_path File.expand_path("../../log/unicorn_#{env}.log", __FILE__)
end

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
