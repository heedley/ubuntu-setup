# application domain
set :application, "%domain%"

# your application repository
set :scm, "git"
set :repository,  "[some git repository]"
set :branch, "master"

# the deployer user
set :user, "%username%"
set :runner, user

# the application deployment path
set :deploy_to, "/home/#{user}/website"
set :current, "#{deploy_to}/current"

# the ssh port
set :port, 22

# do not run commands as sudoer
set :use_sudo, false

# set the roles
role :app, application
role :web, application
role :db,  application, :primary => true

# commands
set :nginx_cmd, "/etc/init.d/nginx"
set :thin_cmd, "/etc/init.d/thin"
set :memcached_cmd, "/etc/init.d/memcached"

# Display the maintenance page
# This assumes that the file public/maintenance.html exists
deploy.web.task :disable, :roles => :web do
  run "if [ ! -f #{current}/public/maintenance.html ]; then ln -s #{current}/public/maintenance.html #{current}/public/index.html; fi"
end

# Remove the symbolic link to the maintenance page
deploy.web.task :enable, :roles => :web do
  run "if [ -f #{current}/public/index.html ]; then rm #{current}/public/index.html; fi"
end

# Override the restart task to do something better
deploy.task :restart, :roles => :app do
  # copy database file from $HOME/conf/database.yml to application
  run "if [ ! -f #{current}/config/database.yml ]; then ln -s /home/#{user}/conf/database.yml #{current}/config/database.yml; fi"
  
  # should migrations be runned?
  yesno "Do you want to run the migrations?" do
    migrate
  end
  
  # should memcached be restarted?
  memcached.restart
  
  # restart thin
  thin.restart
  
  # restart nginx
  nginx.restart
  
  # remove maintenance page
  sleep 3
  deploy.web.enable
end

# When stopping the application
deploy.task :stop, :roles => :app do
  deploy.web.disable
  thin.stop
end

namespace :memcached do
  desc "Restart Memcached"
  task :restart, :roles => :app do
    daemon(:memcached, :restart, "Do you want to restart Memcache?")
  end
  
  desc "Stop Memcached"
  task :stop, :roles => :app do
    daemon(:memcached, :stop, "Do you want to stop Memcache?")
  end
  
  desc "Start Memcached"
  task :start, :roles => :app do
    daemon(:memcached, :start, "Do you want to start Memcache?")
  end
end

# Nginx tasks
namespace :nginx do
  desc "Restart nginx"
  task :restart, :roles => :app do
    daemon(:nginx, :restart)
  end
  
  desc "Stop nginx"
  task :stop, :roles => :app do
    daemon(:nginx, :stop)
  end
  
  desc "Start nginx"
  task :start, :roles => :app do
    daemon(:nginx, :start)
  end
end

# Thin tasks
namespace :thin do
  desc "Restart thin"
  task :restart, :roles => :app do
    daemon(:thin, :restart)
  end
  
  desc "Stop thin"
  task :stop, :roles => :app do
    daemon(:thin, :stop)
  end
  
  desc "Start thin"
  task :start, :roles => :app do
    daemon(:thin, :start)
  end
end

def yesno(message, &block)
  yield if Capistrano::CLI.ui.agree("#{message} (yes/no): ")
end

def daemon(cmd, action, ask=nil)
  cmd = send("#{cmd}_cmd")
  
  if ask
    yesno(ask) do
      stream "#{sudo} #{cmd} #{action}", :pty => true
    end
  else
    stream "#{sudo} #{cmd} #{action}", :pty => true
  end
end