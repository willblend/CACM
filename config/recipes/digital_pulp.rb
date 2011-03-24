# Capistrano utilities and tasks that are common to multiple projects

require 'rubygems'
require 'active_support/core_ext/hash/indifferent_access'

Capistrano::Configuration.instance.load do
  
  namespace :deploy do
    
    after 'deploy', 'deploy:cleanup'
    
    desc "Change ownership of rails root"
    task :chown_rails_root, :roles => :app do
      sudo "chown -R deploy:deploy #{deploy_to}"
    end
    after 'deploy:setup', 'deploy:chown_rails_root'
    
    desc "Caches SVN credentials by doing an `svn info`."
    task :cache_svn_credentials, :roles => :web do
      dp.prompt(:svn_username, "Your SVN username")
      dp.prompt(:svn_password, "Your SVN password")
      run "svn info #{repository} --username #{svn_username} --password #{svn_password} > /dev/null"
    end
    # after 'deploy:setup', 'deploy:cache_svn_credentials'
    
    desc "Warn user about remote configuration"
    task :notify_about_remote_config do
      logger.yell ">>> REMOTE CONFIG NEEDED <<<"
      logger.yell "Please edit #{domain}:#{shared_path}/lib/local_config.rb "
      logger.yell "and #{domain}:#{shared_path}/config/database.yml with"
      logger.yell "the proper settings for your remote server. Be sure to create"
      logger.yell " a #{stage} database on #{domain} if you haven't already, such as:"
      logger.yell "`create database #{application}_#{stage} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci`"
    end
    after 'deploy:setup', 'deploy:notify_about_remote_config'
    
    namespace :web do
      maintenance_file = "#{current_path}/public/system/maintenance.html"
      
      task :disable, :on_error => :continue do
        run "ln -nfs #{current_path}/config/maintenance.html #{maintenance_file}"
      end
      before 'deploy:migrations', 'deploy:web:disable'
      
      task :enable, :on_error => :continue do
        run "rm -rf #{maintenance_file}"
      end
      after 'deploy:migrations', 'deploy:web:enable'
    end
    
    namespace :report do
      desc "Check revision of current release"
      task :revision do
        logger.info domain + ' is at r' + capture("cat #{current_path}/REVISION")
      end
    end
    
    desc "Do an initial migration and provide hook for other recipes"
    task :cold do
      update
      migrate
      restart
    end
  end
    
  module DigitalPulp
    module CapUtil
      WHEREIS_REGEX = /^\w+:\s*(\S+)/
      # Assigns configuration variable by prompt or default
      def prompt_with_default(var, default)
        set(var) do
          Capistrano::CLI.ui.ask "#{var} [#{default}] : "
        end
        set var, default if eval("#{var.to_s}.empty?")
      end
  
      # Assigns configuration variable from prompt
      def prompt(var, text=nil)
        set(var) do
          Capistrano::CLI.ui.ask "#{text||var} : "
        end
      end
      
      # Helps in finding commands on remote system
      def whereis(command, save_as_var=false)
        result = lambda { capture("whereis #{command}") =~ WHEREIS_REGEX ? $1 : nil }
        if save_as_var
          # cache the result
          set(command, &result) unless exists?(command)
          fetch(command)
        else
          result.call
        end
      end
      
      def file_exists?(path)
        capture("test -e #{path} ; echo $?").chomp == '0'
      end
      
      def enable_startup_script(startup_script)          
        startup_cmd = %w(chkconfig update-rc.d).map{|c| dp.whereis(c) }.compact.first
        case startup_cmd
          when /chkconfig/ # CentOS, RHEL
            sudo "#{startup_cmd} --level 345 #{startup_script} on"
          when /update-rc.d/ # Ubuntu
            sudo "#{startup_cmd} #{startup_script} defaults"
        end
      end
      
      def download_file(url, destination_dir)
        dp.whereis("wget", true)
        run "cd #{destination_dir} && #{wget} #{url}"
      end
      
      def download_and_unpack_file(url, destination_dir)
        dp.download_file(url, destination_dir)
        basename = File.basename(url)
        unzip_cmd = case basename
          when /(\.tar\.gz|\.tgz)$/
            dp.whereis("tar", true)
            "#{tar} xzf #{basename}"
          when /(\.zip)$/
            dp.whereis("unzip", true)
            "#{unzip} #{basename}"
          when /\.tar$/
            dp.whereis("tar", true)
            "#{tar} xf #{basename}"
          when /\.tar\.bz2$/
            dp.whereis("bunzip2", true)
            dp.whereis("tar", true)
            "(#{bunzip2} -c #{basename} | tar x)"
        end
        capture "cd #{destination_dir} && #{unzip_cmd}"
      end
      
      def sudo_commands(commands)
        sudo "sh -c \"#{commands}\""
      end

      def fix_permissions(path)
        # Note: I probably should have added an -R to each of these
        #       but it's currently working on production so I'm not
        #       going to messs with it
        # sudo "chgrp -h #{group} #{path}" # This is a good idea too
        #                              -jjb
        sudo "chgrp #{group} #{path}"
        sudo "chmod g+w      #{path}"
      end

      def countdown(seconds)
         (0..seconds).to_a.reverse.each{ |n| sleep 1; print "." }
         puts ''
      end
      
      def symlink(path)
        run "rm -rf #{path}"
        run "ln -sf #{shared_path}/#{path} #{current_path}/#{path}"
      end
      
      def get_db_config(env='production')
        yaml = capture('cat ' + File.join(current_path, %w(config database.yml)))
        config = YAML::load(yaml)
        HashWithIndifferentAccess.new { |hash,key| hash[key] = config[env.to_s][key] }
      end
      
    end
  end
  
  module Capistrano
    class Logger
      def yell(message, line_prefix=nil)
        log(INFO, "\033[31m#{message}\033[0m", line_prefix)
      end
    end
  end
  
  Capistrano.plugin :dp, DigitalPulp::CapUtil

end
