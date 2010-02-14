require 'erb'

def load_settings(env)
  set_settings(YAML.load_file("config/settings/deploy.yml")[env.to_s])
end

def set_settings(params)
  params.each_pair do |k,v|
    set k.to_sym, v
  end
  if exists? :domain
    role :app, domain
    role :web, domain
    role :db,  domain, :primary => true
  end
end

# gem required: sudo gem install capistrano-ext
set :stages, %w(staging production)
require 'capistrano/ext/multistage'

set :application, 'collabbit'
set :use_sudo,    false
set :scm,         :git
set :deploy_via,  :remote_cache

# set :git_shallow_clone, 1

ssh_options[:paranoid] = false
default_run_options[:pty] = true

after "deploy:update_code", 'db:symlink', 'mail:symlink', 'attachments:symlink', 'exceptional:symlink', :gems
before "deploy:setup", :db, :mail, :attachments, :exceptional
  
namespace :passenger do

  desc <<-DESC
    Restarts your application. \
    This works by creating an empty `restart.txt` file in the `tmp` folder
    as requested by Passenger server.
  DESC
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end
  
  desc <<-DESC
    Starts the application servers. \
    Please note that this task is not supported by Passenger server.
  DESC
  task :start, :roles => :app do
    logger.info ":start task not supported by Passenger server"
  end
  
  desc <<-DESC
    Stops the application servers. \
    Please note that this task is not supported by Passenger server.
  DESC
  task :stop, :roles => :app do
    logger.info ":stop task not supported by Passenger server"
  end

end


namespace :deploy do

  desc <<-DESC
    Restarts your application. \
    Overwrites default :restart task for Passenger server.
  DESC
  task :restart, :roles => :app, :except => { :no_release => true } do
    passenger.restart
  end
  
  desc <<-DESC
    Starts the application servers. \
    Overwrites default :start task for Passenger server.
  DESC
  task :start, :roles => :app do
    passenger.start
  end
  
  desc <<-DESC
    Stops the application servers. \
    Overwrites default :start task for Passenger server.
  DESC
  task :stop, :roles => :app do
    passenger.stop
  end
end

namespace :db do
  desc "Create database yaml in shared path" 
  task :default do
    set :db_user do
      Capistrano::CLI.ui.ask 'Database Username: '
    end
    set :db_pass do
     Capistrano::CLI.password_prompt 'Database Password: '
    end
    db_config = ERB.new <<-EOF
    production:
      database: #{production_database}
      adapter: mysql
      encoding: utf8
      username: #{db_user}
      password: #{db_pass}
      
    development:
      database: #{development_database}
      adapter: mysql
      encoding: utf8
      username: #{db_user}
      password: #{db_pass}
    EOF

    run "mkdir -p #{shared_path}/config" 
    put db_config.result, "#{shared_path}/config/database.yml" 
  end

  desc "Make symlink for database yaml" 
  task :symlink do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml" 
  end
end

namespace :exceptional do
  desc "Create Exceptional"
  task :default do
    set :api_key do
      Capistrano::CLI.ui.ask 'Exceptional API key?'
    end
    
    exceptional_data = {
      'production' => {
        'api-key' => api_key,
        'enabled' => true
      }
    }
    
    run "mkdir -p #{shared_path}/config" 
    put exceptional_data.to_yaml, "#{shared_path}/config/exceptional.yml"
  end
  
  task :symlink do
    run "ln -nfs #{shared_path}/config/exceptional.yml #{release_path}/config/exceptional.yml" 
  end
  
end

namespace :mail do
  desc "Create mailserver yaml in shared path" 
  task :default do    
    smtp_settings = {
      'production' => {
        'port'     => 25,
        'domain'   => 'collabbit.org',
        'address'  => 'localhost',
        'tls'      => false,
        'authentication' => false
      }
    }

    run "mkdir -p #{shared_path}/config" 
    run "chmod 775 #{shared_path}/config"
  
    put smtp_settings.to_yaml, "#{shared_path}/config/smtp.yml"
    run "chmod 775 #{shared_path}/config/smtp.yml"
  end

  desc "Make symlink for database yaml" 
  task :symlink do
    run "ln -nfs #{shared_path}/config/smtp.yml #{release_path}/config/smtp.yml" 
  end
end

namespace :attachments do
  desc "Make shared attachments directory"
  task :default do
    run "mkdir -p #{shared_path}/attachments"
    run "chmod 775 #{shared_path}/attachments"
  end
  
  desc "Link shared attachments directory"
  task :symlink do
    run "ln -nfs #{shared_path}/attachments #{release_path}/attachments"
  end
end

namespace :gems do
  desc "Update gems"
  task :default do
    run "cd #{release_path} && rake gems:install && rake gems:unpack"
  end
end
